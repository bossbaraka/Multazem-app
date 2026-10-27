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

كذلك يُصلح خطأً شائعاً في Kotlin DSL: كتابة `java.util.Properties()` /
`java.io.FileInputStream(...)` داخل `android/app/build.gradle.kts`. الاسم `java`
هناك محجوز لـ«extension» إضافة جافا وليس للحزمة، فيفشل بناء الإصدار بثلاثة أخطاء:

    Unresolved reference: util
    Unresolved reference: io
    Expression expected, but a package name found

يحوّلها السكربت إلى الأسماء المختصرة (`Properties()` / `FileInputStream()`)
ويضمن وجود سطري الـ import في أعلى الملف.

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

if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

# إصدار desugar الموصى به من flutter_local_notifications (2.1.4+)
DESUGAR_VERSION = "2.1.4"

FLAG_KTS = "isCoreLibraryDesugaringEnabled = true"
FLAG_GROOVY = "coreLibraryDesugaringEnabled true"

# ── أسماء جافا التي يجب استيرادها صراحةً في Kotlin DSL ──────────────────────
# المفتاح: الاسم الكامل المعطوب — القيمة: (الاسم المختصر، سطر الـ import)
SHADOWED_JAVA_NAMES = {
    "java.util.Properties": ("Properties", "import java.util.Properties"),
    "java.io.FileInputStream": ("FileInputStream", "import java.io.FileInputStream"),
}


def import_insertion_point(lines: list[str]) -> int:
    """موضع إدراج سطر import: بعد آخر import قائم، وإلا قبل أول بيان."""
    last_import = -1
    for i, line in enumerate(lines):
        stripped = line.strip()
        if not stripped or stripped.startswith(("//", "/*", "*")):
            continue
        if stripped.startswith("import "):
            last_import = i
            continue
        return last_import + 1 if last_import >= 0 else i
    return last_import + 1 if last_import >= 0 else len(lines)


def insert_import(lines: list[str], statement: str) -> bool:
    """يضيف سطر import في أعلى السكربت إن لم يكن موجوداً. يعيد True إن أضاف."""
    if any(line.strip() == statement for line in lines):
        return False
    lines.insert(import_insertion_point(lines), f"{statement}\n")
    return True


def ensure_blank_line_after_imports(lines: list[str]) -> bool:
    """يفصل مجموعة الـ import عن أول بيان بعدها بسطر فارغ (تنسيق فقط)."""
    last_import = max(
        (i for i, line in enumerate(lines) if line.strip().startswith("import ")),
        default=-1,
    )
    if last_import < 0 or last_import + 1 >= len(lines):
        return False
    if lines[last_import + 1].strip():
        lines.insert(last_import + 1, "\n")
        return True
    return False


def is_comment_line(line: str) -> bool:
    """هل السطر شرح (‎//‎ أو داخل ‎/* */‎)؟ لا نلمس الشروحات أبداً."""
    return line.strip().startswith(("//", "/*", "*"))


def is_import_line(line: str) -> bool:
    """هل السطر بيان import؟"""
    return line.strip().startswith("import ")


def fix_shadowed_java_names(lines: list[str], kotlin_dsl: bool) -> bool:
    """
    يستبدل `java.util.Properties` / `java.io.FileInputStream` بالأسماء المختصرة
    ويضمن وجود الـ import المطابق. يعيد True إن عدّل شيئاً.

    السبب: في `android/app/build.gradle.kts` يرتبط الاسم `java` بـ extension إضافة
    جافا (JavaPluginExtension) فيصبح `java.util` مرجعاً غير معروف. أما في
    `settings.gradle.kts` فلا توجد تلك الإضافة ويعمل الاسم الكامل — لذلك يُطبَّق
    هذا الإصلاح على سكربت التطبيق فقط.

    أسطر الشرح وأسطر الـ import تُستثنى من الاستبدال: الشرح قد يذكر الاسم الكامل
    للتوضيح، والـ import ‏`import java.util.Properties` هو المكان الوحيد الصحيح له —
    واستبداله هناك يُنتج `import Properties` ويُفسد الملف.
    """
    if not kotlin_dsl:
        return False

    changed = False
    needed: list[str] = []

    for i, line in enumerate(lines):
        if is_comment_line(line) or is_import_line(line):
            continue
        new_line = line
        for qualified, (short, import_line) in SHADOWED_JAVA_NAMES.items():
            # الاسم الكامل: نستبدله سواء جاء نداءً `Properties()` أو نوعاً `: Properties`
            qualified_re = rf"(?<![\w.]){re.escape(qualified)}(?!\w)"
            # الاسم المختصر مستعمل فعلاً لكن الـ import ناقص
            short_re = rf"(?<![\w.]){re.escape(short)}\s*\("
            if re.search(qualified_re, new_line):
                new_line = re.sub(qualified_re, short, new_line)
            elif not re.search(short_re, new_line):
                continue
            if import_line not in needed:
                needed.append(import_line)
        if new_line != line:
            lines[i] = new_line
            changed = True

    for import_line in sorted(needed):
        if insert_import(lines, import_line):
            changed = True

    if changed:
        ensure_blank_line_after_imports(lines)
    return changed


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

    changed_imports = fix_shadowed_java_names(lines, kotlin_dsl)
    changed_flag = add_desugaring_flag(lines, kotlin_dsl)
    changed_dep = add_desugaring_dependency(lines, kotlin_dsl)

    if not (changed_imports or changed_flag or changed_dep):
        print(f"✓ {path.name}: desugaring مفعّل واستيراد الأصناف سليم — لا تغيير.")
        return 0

    updated = "".join(lines)
    if updated == original:
        print(f"✓ {path.name}: لا حاجة لتعديل.")
        return 0

    path.write_text(updated, encoding="utf-8")

    print(f"✓ حُدّث {path.name}:")
    if changed_imports:
        print("  • إصلاح أسماء جافا المحجوبة (Properties / FileInputStream) + إضافة الـ import")
    if changed_flag:
        print("  • تفعيل core library desugaring داخل compileOptions")
    if changed_dep:
        print(f"  • إضافة desugar_jdk_libs {DESUGAR_VERSION} إلى dependencies")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
