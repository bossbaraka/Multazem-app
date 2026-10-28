#!/usr/bin/env python3
"""Safely prepare and remove Android release signing material for CI builds.

The keystore and passwords are supplied through the same four environment
variables in GitHub Actions and Codemagic. No secret value is accepted on the
command line or written to standard output.
"""

from __future__ import annotations

import argparse
import base64
import binascii
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
from typing import Mapping, Sequence

REQUIRED_ENV = (
    "ANDROID_KEYSTORE_BASE64",
    "ANDROID_KEYSTORE_PASSWORD",
    "ANDROID_KEY_PASSWORD",
    "ANDROID_KEY_ALIAS",
)
STATE_FILENAME = ".multazim-signing-state.json"
KEYSTORE_FILENAME = "multazim-keystore.jks"
ROOT = Path(__file__).resolve().parents[1]


class SigningError(Exception):
    """A safe-to-display signing configuration error (never contains values)."""


def escape_java_property(value: str) -> str:
    """Return an ASCII Java-Properties-compatible escaped value.

    Escaping spaces and property delimiters everywhere also protects leading
    whitespace and passwords containing characters such as ``=`` or ``\\``.
    Non-ASCII code points are encoded as UTF-16 ``\\uXXXX`` sequences, as
    required by ``Properties.load(InputStream)``.
    """
    escaped: list[str] = []
    for character in value:
        codepoint = ord(character)
        if character == "\\":
            escaped.append("\\\\")
        elif character == "\t":
            escaped.append("\\t")
        elif character == "\n":
            escaped.append("\\n")
        elif character == "\r":
            escaped.append("\\r")
        elif character == "\f":
            escaped.append("\\f")
        elif character == " ":
            escaped.append("\\ ")
        elif character in "=:#!":
            escaped.append("\\" + character)
        elif codepoint < 0x20 or codepoint > 0x7E:
            utf16 = character.encode("utf-16-be")
            escaped.extend(
                f"\\u{int.from_bytes(utf16[index:index + 2], 'big'):04X}"
                for index in range(0, len(utf16), 2)
            )
        else:
            escaped.append(character)
    return "".join(escaped)


def _is_within(path: Path, parent: Path) -> bool:
    try:
        path.relative_to(parent)
        return True
    except ValueError:
        return False


def _write_private_file(path: Path, content: bytes) -> None:
    """Create a new mode-0600 file without overwriting anything."""
    descriptor = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    try:
        with os.fdopen(descriptor, "wb") as output:
            output.write(content)
            output.flush()
            os.fsync(output.fileno())
    except BaseException:
        path.unlink(missing_ok=True)
        raise
    try:
        path.chmod(0o600)
    except OSError:
        path.unlink(missing_ok=True)
        raise


def _validate_keystore(
    keystore: Path,
    alias: str,
    environment: Mapping[str, str],
) -> None:
    """Validate the store password, alias, private-key entry, and key password."""
    keytool_path = shutil.which("keytool", path=environment.get("PATH"))
    if keytool_path is None:
        raise SigningError("Java 17 keytool was not found; configure Java 17 before signing.")

    # keytool's :env password modifiers keep passwords out of process arguments.
    keytool_environment = dict(environment)
    keytool_environment.pop("ANDROID_KEYSTORE_BASE64", None)
    list_command = [
        keytool_path,
        "-list",
        "-keystore",
        str(keystore),
        "-storepass:env",
        "ANDROID_KEYSTORE_PASSWORD",
        "-alias",
        alias,
    ]
    try:
        listed = subprocess.run(
            list_command,
            env=keytool_environment,
            capture_output=True,
            text=True,
            check=False,
        )
    except OSError:
        raise SigningError("Could not run keytool to validate the keystore and alias.") from None
    if listed.returncode != 0:
        raise SigningError(
            "Keystore validation failed; check the Base64 keystore, store password, and alias."
        )

    # A CSR proves that this alias is a private-key entry and that keyPassword
    # works, without modifying the source keystore. The temporary CSR is deleted.
    request_file = keystore.parent / ".key-validation.csr"
    request_command = [
        keytool_path,
        "-certreq",
        "-keystore",
        str(keystore),
        "-storepass:env",
        "ANDROID_KEYSTORE_PASSWORD",
        "-keypass:env",
        "ANDROID_KEY_PASSWORD",
        "-alias",
        alias,
        "-dname",
        "CN=Multazim temporary signing validation",
        "-file",
        str(request_file),
    ]
    try:
        try:
            requested = subprocess.run(
                request_command,
                env=keytool_environment,
                capture_output=True,
                text=True,
                check=False,
            )
        except OSError:
            raise SigningError("Could not run keytool to validate the private signing key.") from None
        if requested.returncode != 0 or not request_file.is_file():
            raise SigningError(
                "Private-key validation failed; check the key password and ensure the alias is a private key."
            )
    finally:
        request_file.unlink(missing_ok=True)


def prepare_signing(
    project_root: Path,
    temp_dir: Path,
    environment: Mapping[str, str] | None = None,
) -> None:
    """Decode, validate, and write a private Android key.properties file."""
    env = dict(os.environ if environment is None else environment)
    missing = [name for name in REQUIRED_ENV if not env.get(name, "")]
    if missing:
        raise SigningError(
            "Missing required Android signing inputs: " + ", ".join(missing) + "."
        )

    encoded = "".join(env["ANDROID_KEYSTORE_BASE64"].split())
    try:
        keystore_bytes = base64.b64decode(encoded.encode("ascii"), validate=True)
    except (UnicodeEncodeError, binascii.Error, ValueError):
        raise SigningError("ANDROID_KEYSTORE_BASE64 is not valid Base64.") from None
    if not keystore_bytes:
        raise SigningError("ANDROID_KEYSTORE_BASE64 decodes to an empty keystore.")

    root = project_root.resolve()
    android_dir = root / "android"
    properties_file = android_dir / "key.properties"
    if not android_dir.is_dir():
        raise SigningError("The project has no android/ directory; scaffold Android first.")
    if properties_file.exists():
        raise SigningError(
            "Refusing to overwrite existing android/key.properties; remove or back it up first."
        )

    signing_dir = temp_dir.expanduser().resolve()
    if _is_within(signing_dir, root):
        raise SigningError("Temporary signing files must be outside the repository.")
    if signing_dir == signing_dir.parent:
        raise SigningError("The temporary signing directory is not safe to use.")

    created_properties = False
    owns_temp_dir = False
    try:
        if signing_dir.exists():
            if not signing_dir.is_dir() or any(signing_dir.iterdir()):
                raise SigningError("The temporary signing directory must be new or empty.")
            owns_temp_dir = True
        else:
            signing_dir.mkdir(parents=True, mode=0o700)
            owns_temp_dir = True
        signing_dir.chmod(0o700)

        keystore_file = signing_dir / KEYSTORE_FILENAME
        _write_private_file(keystore_file, keystore_bytes)
        _validate_keystore(keystore_file, env["ANDROID_KEY_ALIAS"], env)

        state = {
            "version": 1,
            "project_root": str(root),
            "properties_file": str(properties_file.resolve()),
            "keystore_file": str(keystore_file.resolve()),
        }
        _write_private_file(
            signing_dir / STATE_FILENAME,
            (json.dumps(state, sort_keys=True) + "\n").encode("utf-8"),
        )

        properties = {
            "storeFile": str(keystore_file.resolve()),
            "storePassword": env["ANDROID_KEYSTORE_PASSWORD"],
            "keyPassword": env["ANDROID_KEY_PASSWORD"],
            "keyAlias": env["ANDROID_KEY_ALIAS"],
        }
        body = "".join(
            f"{name}={escape_java_property(value)}\n"
            for name, value in properties.items()
        ).encode("ascii")
        _write_private_file(properties_file, body)
        created_properties = True
    except BaseException:
        if created_properties:
            properties_file.unlink(missing_ok=True)
        if owns_temp_dir:
            shutil.rmtree(signing_dir, ignore_errors=True)
        raise


def cleanup_signing(project_root: Path, temp_dir: Path | str | None) -> None:
    """Remove only signing files created by ``prepare_signing``."""
    if temp_dir is None or not str(temp_dir).strip():
        return

    root = project_root.resolve()
    signing_dir = Path(temp_dir).expanduser().resolve()
    if _is_within(signing_dir, root) or signing_dir == signing_dir.parent:
        raise SigningError("Refusing to clean an unsafe signing directory.")
    if not signing_dir.exists():
        return

    marker = signing_dir / STATE_FILENAME
    if not marker.is_file():
        # A failed validation may already have removed its temporary directory.
        # Never delete a directory that lacks our ownership marker.
        if any(signing_dir.iterdir()):
            raise SigningError("Refusing to clean a directory not owned by the signing helper.")
        signing_dir.rmdir()
        return

    try:
        state = json.loads(marker.read_text(encoding="utf-8"))
        properties_file = Path(state["properties_file"]).resolve()
        keystore_file = Path(state["keystore_file"]).resolve()
        expected_properties = (root / "android" / "key.properties").resolve()
        if (
            state.get("version") != 1
            or Path(state.get("project_root", "")).resolve() != root
            or properties_file != expected_properties
            or not _is_within(keystore_file, signing_dir)
            or keystore_file.name != KEYSTORE_FILENAME
        ):
            raise ValueError
    except (OSError, ValueError, KeyError, TypeError, json.JSONDecodeError):
        raise SigningError("Signing cleanup state is invalid; refusing to remove files.") from None

    properties_file.unlink(missing_ok=True)
    shutil.rmtree(signing_dir)


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Prepare or clean temporary Android signing material.")
    subparsers = parser.add_subparsers(dest="command", required=True)
    for command in ("prepare", "cleanup"):
        child = subparsers.add_parser(command)
        child.add_argument(
            "--project-root",
            type=Path,
            default=ROOT,
            help=argparse.SUPPRESS,
        )
        child.add_argument("--temp-dir", required=True, type=Path)
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    args = _parser().parse_args(argv)
    try:
        if args.command == "prepare":
            prepare_signing(args.project_root, args.temp_dir)
            print("Android signing inputs validated; temporary release signing is ready.")
        else:
            cleanup_signing(args.project_root, args.temp_dir)
            print("Temporary Android signing files cleaned.")
    except SigningError as error:
        print(f"Android signing setup failed: {error}", file=sys.stderr)
        return 2
    except OSError:
        print("Android signing setup failed because a temporary file could not be accessed.", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
