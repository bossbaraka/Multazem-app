"""Regression tests for Android release signing setup (no Java/Flutter needed)."""

from __future__ import annotations

import ast
import base64
from contextlib import redirect_stderr, redirect_stdout
from io import StringIO
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parent))
import android_signing  # noqa: E402

REPOSITORY = Path(__file__).resolve().parents[1]


class AndroidSigningTests(unittest.TestCase):
    def setUp(self) -> None:
        self.scratch = tempfile.TemporaryDirectory(prefix="multazim-signing-test-")
        self.scratch_path = Path(self.scratch.name)
        self.project = self.scratch_path / "project"
        (self.project / "android").mkdir(parents=True)
        self.signing_dir = self.scratch_path / "signing-temp"
        self.environment = {
            "ANDROID_KEYSTORE_BASE64": base64.b64encode(b"temporary test keystore").decode("ascii"),
            "ANDROID_KEYSTORE_PASSWORD": "STORE-secret-#:=\\ value",
            "ANDROID_KEY_PASSWORD": "KEY-secret-!:=\\ value",
            "ANDROID_KEY_ALIAS": "multazim-test",
            "PATH": os.environ.get("PATH", os.defpath),
        }

    def tearDown(self) -> None:
        self.scratch.cleanup()

    @staticmethod
    def _successful_keytool(command, **_kwargs):
        if "-file" in command:
            Path(command[command.index("-file") + 1]).write_text("temporary CSR", encoding="ascii")
        return subprocess.CompletedProcess(command, 0, stdout="ignored tool output", stderr="")

    def _mock_keytool(self):
        return (
            patch.object(android_signing.shutil, "which", return_value="/temporary/bin/keytool"),
            patch.object(android_signing.subprocess, "run", side_effect=self._successful_keytool),
        )

    def test_missing_secrets_fail_before_creating_any_files(self) -> None:
        with patch.object(android_signing.shutil, "which") as find_keytool:
            with self.assertRaises(android_signing.SigningError) as caught:
                android_signing.prepare_signing(self.project, self.signing_dir, {})
        self.assertIn("ANDROID_KEYSTORE_BASE64", str(caught.exception))
        self.assertFalse(self.signing_dir.exists())
        self.assertFalse((self.project / "android" / "key.properties").exists())
        find_keytool.assert_not_called()

    def test_invalid_base64_is_rejected_without_echoing_the_input(self) -> None:
        invalid = "NOT-BASE64-DO-NOT-LEAK-#"
        self.environment["ANDROID_KEYSTORE_BASE64"] = invalid
        with self.assertRaises(android_signing.SigningError) as caught:
            android_signing.prepare_signing(self.project, self.signing_dir, self.environment)
        self.assertIn("not valid Base64", str(caught.exception))
        self.assertNotIn(invalid, str(caught.exception))
        self.assertFalse(self.signing_dir.exists())

    def test_invalid_store_or_alias_fails_closed_and_tool_output_is_suppressed(self) -> None:
        secret_values = [self.environment[name] for name in android_signing.REQUIRED_ENV]

        def rejected(command, **_kwargs):
            return subprocess.CompletedProcess(
                command,
                1,
                stdout="tool output " + " ".join(secret_values),
                stderr="password error " + " ".join(secret_values),
            )

        with (
            patch.object(android_signing.shutil, "which", return_value="/temporary/bin/keytool"),
            patch.object(android_signing.subprocess, "run", side_effect=rejected) as run_keytool,
        ):
            with self.assertRaises(android_signing.SigningError) as caught:
                android_signing.prepare_signing(self.project, self.signing_dir, self.environment)

        message = str(caught.exception)
        for secret in secret_values:
            self.assertNotIn(secret, message)
        run_keytool.assert_called_once()
        command = run_keytool.call_args.args[0]
        self.assertIn("ANDROID_KEYSTORE_PASSWORD", command)
        self.assertNotIn(self.environment["ANDROID_KEYSTORE_PASSWORD"], command)
        self.assertFalse(self.signing_dir.exists())
        self.assertFalse((self.project / "android" / "key.properties").exists())

    def test_cli_does_not_print_secrets_or_suppressed_keytool_output(self) -> None:
        secret_values = [self.environment[name] for name in android_signing.REQUIRED_ENV]

        def rejected(command, **_kwargs):
            return subprocess.CompletedProcess(
                command,
                1,
                stdout="captured secret " + " ".join(secret_values),
                stderr="captured password " + " ".join(secret_values),
            )

        stdout = StringIO()
        stderr = StringIO()
        with (
            patch.dict(os.environ, self.environment, clear=True),
            patch.object(android_signing.shutil, "which", return_value="/temporary/bin/keytool"),
            patch.object(android_signing.subprocess, "run", side_effect=rejected),
            redirect_stdout(stdout),
            redirect_stderr(stderr),
        ):
            status = android_signing.main([
                "prepare",
                "--project-root",
                str(self.project),
                "--temp-dir",
                str(self.signing_dir),
            ])

        self.assertEqual(status, 2)
        output = stdout.getvalue() + stderr.getvalue()
        for secret in secret_values:
            self.assertNotIn(secret, output)
        self.assertNotIn("captured secret", output)
        self.assertNotIn("captured password", output)

    def test_wrong_key_password_is_rejected_without_leaking_tool_output(self) -> None:
        secret_values = [self.environment[name] for name in android_signing.REQUIRED_ENV]
        calls = 0

        def fail_private_key(command, **_kwargs):
            nonlocal calls
            calls += 1
            if "-file" in command:
                return subprocess.CompletedProcess(
                    command,
                    1,
                    stdout="private key output " + " ".join(secret_values),
                    stderr="bad password " + " ".join(secret_values),
                )
            return subprocess.CompletedProcess(command, 0, stdout="", stderr="")

        with (
            patch.object(android_signing.shutil, "which", return_value="/temporary/bin/keytool"),
            patch.object(android_signing.subprocess, "run", side_effect=fail_private_key),
        ):
            with self.assertRaises(android_signing.SigningError) as caught:
                android_signing.prepare_signing(self.project, self.signing_dir, self.environment)

        self.assertIn("Private-key validation failed", str(caught.exception))
        for secret in secret_values:
            self.assertNotIn(secret, str(caught.exception))
        self.assertEqual(calls, 2)
        self.assertFalse(self.signing_dir.exists())
        self.assertFalse((self.project / "android" / "key.properties").exists())

    def test_java_properties_escape_special_and_non_ascii_values(self) -> None:
        self.environment["ANDROID_KEYSTORE_PASSWORD"] = " leading =:# !\\ ending "
        self.environment["ANDROID_KEY_PASSWORD"] = "مفتاح\\كلمة"
        self.environment["ANDROID_KEY_ALIAS"] = "alias:release"
        which_patch, run_patch = self._mock_keytool()
        with which_patch, run_patch as run_keytool:
            android_signing.prepare_signing(self.project, self.signing_dir, self.environment)

        properties_file = self.project / "android" / "key.properties"
        contents = properties_file.read_text(encoding="ascii")
        self.assertIn(
            "storePassword=" + android_signing.escape_java_property(self.environment["ANDROID_KEYSTORE_PASSWORD"]),
            contents,
        )
        self.assertIn(
            "keyPassword=" + android_signing.escape_java_property(self.environment["ANDROID_KEY_PASSWORD"]),
            contents,
        )
        self.assertIn("keyAlias=alias\\:release", contents)
        self.assertIn("storeFile=" + android_signing.escape_java_property(str(self.signing_dir.resolve() / android_signing.KEYSTORE_FILENAME)), contents)
        self.assertEqual(properties_file.stat().st_mode & 0o777, 0o600)
        self.assertEqual((self.signing_dir / android_signing.KEYSTORE_FILENAME).stat().st_mode & 0o777, 0o600)
        self.assertFalse((self.signing_dir / ".key-validation.csr").exists())

        commands = [call.args[0] for call in run_keytool.call_args_list]
        flattened = [argument for command in commands for argument in command]
        for name in ("ANDROID_KEYSTORE_PASSWORD", "ANDROID_KEY_PASSWORD"):
            self.assertIn(name, flattened)
            self.assertNotIn(self.environment[name], flattened)

    def test_cleanup_removes_only_owned_signing_files(self) -> None:
        which_patch, run_patch = self._mock_keytool()
        with which_patch, run_patch:
            android_signing.prepare_signing(self.project, self.signing_dir, self.environment)
        properties_file = self.project / "android" / "key.properties"
        self.assertTrue(properties_file.is_file())
        self.assertTrue(self.signing_dir.is_dir())

        android_signing.cleanup_signing(self.project, self.signing_dir)
        self.assertFalse(properties_file.exists())
        self.assertFalse(self.signing_dir.exists())

    def test_cleanup_refuses_unowned_directory(self) -> None:
        unowned = self.scratch_path / "unowned"
        unowned.mkdir()
        sentinel = unowned / "keep.txt"
        sentinel.write_text("keep", encoding="utf-8")
        with self.assertRaises(android_signing.SigningError):
            android_signing.cleanup_signing(self.project, unowned)
        self.assertEqual(sentinel.read_text(encoding="utf-8"), "keep")

    def test_temp_files_must_be_outside_the_repository(self) -> None:
        with self.assertRaises(android_signing.SigningError):
            android_signing.prepare_signing(
                self.project,
                self.project / "android" / "temporary-signing",
                self.environment,
            )
        self.assertFalse((self.project / "android" / "key.properties").exists())

    def test_nonempty_temp_directory_is_not_deleted_on_rejection(self) -> None:
        self.signing_dir.mkdir()
        sentinel = self.signing_dir / "keep.txt"
        sentinel.write_text("keep", encoding="utf-8")
        with self.assertRaises(android_signing.SigningError):
            android_signing.prepare_signing(self.project, self.signing_dir, self.environment)
        self.assertEqual(sentinel.read_text(encoding="utf-8"), "keep")

    def test_preexisting_key_properties_are_not_overwritten(self) -> None:
        properties_file = self.project / "android" / "key.properties"
        properties_file.write_text("do-not-overwrite", encoding="utf-8")
        with self.assertRaises(android_signing.SigningError):
            android_signing.prepare_signing(self.project, self.signing_dir, self.environment)
        self.assertEqual(properties_file.read_text(encoding="utf-8"), "do-not-overwrite")
        self.assertFalse(self.signing_dir.exists())


class ReleaseConfigurationTests(unittest.TestCase):
    def test_github_workflow_matches_scaffold_template_byte_for_byte(self) -> None:
        workflow_path = REPOSITORY / ".github" / "workflows" / "build-apk.yml"
        scaffold_path = REPOSITORY / "scripts" / "scaffold_platforms.py"
        tree = ast.parse(scaffold_path.read_text(encoding="utf-8"))
        workflow_template = None
        for node in ast.walk(tree):
            if isinstance(node, ast.Assign) and any(
                isinstance(target, ast.Name) and target.id == "github_ci"
                for target in node.targets
            ):
                workflow_template = ast.literal_eval(node.value)
                break
        self.assertIsNotNone(workflow_template)
        self.assertEqual(workflow_path.read_bytes(), workflow_template.encode("utf-8"))

    def test_pull_requests_have_no_secrets_or_pull_request_target(self) -> None:
        workflow = (REPOSITORY / ".github" / "workflows" / "build-apk.yml").read_text(encoding="utf-8")
        self.assertIn("  pull_request:", workflow)
        self.assertNotIn("pull_request_target", workflow)
        verification_job = workflow.split("  signed-release:", 1)[0]
        self.assertNotIn("secrets.ANDROID_", verification_job)
        self.assertIn("debug-signed-not-for-distribution", verification_job)

    def test_signed_workflow_is_main_only_and_codemagic_uses_the_same_secret_names(self) -> None:
        workflow = (REPOSITORY / ".github" / "workflows" / "build-apk.yml").read_text(encoding="utf-8")
        codemagic = (REPOSITORY / "codemagic.yaml").read_text(encoding="utf-8")
        release_docs = (REPOSITORY / "deploy" / "RELEASE.md").read_text(encoding="utf-8")
        for name in android_signing.REQUIRED_ENV:
            self.assertIn(name, workflow)
            self.assertIn(name, release_docs)
        self.assertIn("github.ref == 'refs/heads/main'", workflow)
        self.assertIn("workflow_dispatch", workflow)
        self.assertIn("multazim-android-signing", codemagic)
        self.assertIn("${CM_BRANCH:-}", codemagic)
        self.assertIn("pattern: main", codemagic)
        android_workflow = codemagic.split("  ios-ipa:", 1)[0]
        self.assertNotIn("- pull_request", android_workflow)
        self.assertLess(android_workflow.index("${CM_BRANCH:-}"), android_workflow.index("cp deploy/"))
        self.assertNotIn("CM_KEYSTORE_PATH", codemagic)
        self.assertNotIn("--build-number", workflow + codemagic)

    def test_signing_material_is_ignored_and_not_uploaded_as_an_artifact(self) -> None:
        ignore = (REPOSITORY / ".gitignore").read_text(encoding="utf-8")
        workflow = (REPOSITORY / ".github" / "workflows" / "build-apk.yml").read_text(encoding="utf-8")
        codemagic = (REPOSITORY / "codemagic.yaml").read_text(encoding="utf-8")
        self.assertIn("**/android/key.properties", ignore)
        self.assertIn("**/*.jks", ignore)
        self.assertNotIn("key.properties", workflow.split("      - name: Upload", 1)[1])
        self.assertNotIn("*.jks", workflow)
        self.assertNotIn("key.properties", codemagic.split("    artifacts:", 1)[1])
        self.assertNotIn("*.jks", codemagic)


if __name__ == "__main__":
    unittest.main()
