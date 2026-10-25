#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
تجهيز `android/app/build.gradle(.kts)` بعد `flutter create` ليبني الإصدار بنجاح.

لماذا هذا السكربت؟
──────────────────
حزمة flutter_local_notifications (النسخة ١٠ وما بعدها — والمشروع على ١٧.x)
تعتمد على «Core Library Desugaring» لتشغيل java.time على أندرويد الأقدم.
إن لم يكن مفعّلاً في تطبيقك يتوقّف البناء بالرسالة:

    Dependency ':flutter_local_notifications' requires core library
    desugaring to be enabled for :app.

ملف publish هذا (deploy/) لا يحتوي مجلد android كاملاً، لأن Codemagic
يولّده بـ `flutter create .`، لذا نطبّق التعديل المطلوب آلياً وبشكل idempotent.

الاستخدام (من جذر المشروع، بعد flutter create وبعد flutter pub get):
    python3 deploy/android/apply_android_gradle.py

يعمل مع Kotlin DSL (`build.gradle.kts`) وGroovy (`build.gradle`)،
وتشغيله أكثر من مرة لا يكرّر أي سطر.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

# إصدار desugar الموصى به من flutter_local_notifications (2.1.4+)
DESUGAR_VERSION = "2.1.4"

FLAG_KTS = "isCoreLibraryDesugaringEnabled = true"
FLAG_GROOVY = "coreLibraryDesugaringEnabled true"


def app_build_file() -> Path:
    """يعيد مسار build.gradle(.kts) الخاص بالتطبيق."""
    app_dir = Path(__file__).resolve().parents[2] / "android" / "app"
    for name in ("build.gradle.kts", "build.gradle"):
        candidate = app_dir / name
        if candidate.is_file():
            return candidate
    sys.exit(
        f"✗ لم أجد android/app/build.gradle(.kts)\n"
        f"  شغّل أولاً: flutter create . --org com.multazim.app --platforms=android"
    )


def indent_of(line: str) -> str:
    """المسافة البادئة للسطر."""
    return line[: len(line) - len(line.lstrip())]


def find_block(lines: list[str], name: str, top_level_only: bool = False) -> int:
    """يبحث عن أول سطر يفتح بلوك `name {` ويعيد رقمه، أو -1."""
    depth = 0
    pattern = re.compile(rf"^{re.escape(name)}\s*\{{")
    for i, line in enumerate(lines):
        stripped = line.strip()
        if pattern.match(stripped) and (depth == 0 or not top_level_only):
            return i
        depth += line.count("{") - line.count("}")
    return -1


def add_desugaring_flag(lines: list[str], kotlin_dsl: bool) -> bool:
    """يضيف سطر تفعيل الـ desugaring داخل compileOptions. يعيد True إن عدّل شيئاً."""
    source = "".join(lines)
    if "isCoreLibraryDesugaringEnabled" in source or "coreLibraryDesugaringEnabled" in source:
        return False

    flag = FLAG_KTS if kotlin_dsl else FLAG_GROOVY
    index = find_block(lines, "compileOptions")

    if index >= 0:
        # أدخل السطر كأول سطر داخل compileOptions
        pad = indent_of(lines[index]) + "    "
        lines.insert(index + 1, f"{pad}{flag}\n")
        return True

    index = find_block(lines, "android", top_level_only=True)
    if index < 0:
        return False

    pad = indent_of(lines[index]) + "    "
    lines[index + 1 : index + 1] = [
        f"{pad}compileOptions {{\n",
        f"{pad}    {flag}\n",
        f"{pad}}}\n",
        "\n",
    ]
    return True


def add_desugaring_dependency(lines: list[str], kotlin_dsl: bool) -> bool:
    """يضيف coreLibraryDesugaring إلى dependencies. يعيد True إن عدّل شيئاً."""
    # نتحقق من وجود الاعتمادية نفسها (‎desugar_jdk_libs‎) لا من كلمة
    # coreLibraryDesugaring وحدها، لأن سطر التفعيل في Groovy يحويها أيضاً.
    if "desugar_jdk_libs" in "".join(lines):
        return False

    if kotlin_dsl:
        entry = f'coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:{DESUGAR_VERSION}")'
    else:
        entry = f"coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:{DESUGAR_VERSION}'"

    index = find_block(lines, "dependencies", top_level_only=True)
    if index >= 0:
        pad = indent_of(lines[index]) + "    "
        lines.insert(index + 1, f"{pad}{entry}\n")
        return True

    lines.append("\n")
    lines.append("dependencies {\n")
    lines.append(f"    {entry}\n")
    lines.append("}\n")
    return True


def main() -> int:
    path = app_build_file()
    kotlin_dsl = path.suffix == ".kts"
    original = path.read_text(encoding="utf-8")
    lines = original.splitlines(keepends=True)

    changed_flag = add_desugaring_flag(lines, kotlin_dsl)
    changed_dep = add_desugaring_dependency(lines, kotlin_dsl)

    if not changed_flag and not changed_dep:
        print(f"✓ {path.name}: desugaring مفعّل مسبقاً — لا تغيير.")
        return 0

    updated = "".join(lines)
    if updated == original:
        print(f"✓ {path.name}: لا حاجة لتعديل.")
        return 0

    path.write_text(updated, encoding="utf-8")

    print(f"✓ حُدّث {path.name}:")
    if changed_flag:
        print("  • تفعيل core library desugaring داخل compileOptions")
    if changed_dep:
        print(f"  • إضافة desugar_jdk_libs {DESUGAR_VERSION} إلى dependencies")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
