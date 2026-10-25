#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
دمج مفاتيح iOS المطلوبة في ios/Runner/Info.plist بشكل آمن وidempotent.

يُستدعى تلقائياً من scripts/setup_platforms.sh / .ps1 بعد `flutter create`.
يمكن تشغيله يدوياً في أي وقت:  python3 scripts/apply_ios_plist.py

لا يستبدل أي قيمة موجودة عندك — يضيف المفاتيح الناقصة فقط،
ويضيف القيم الناقصة داخل المصفوفات (UIBackgroundModes / CFBundleLocalizations).
"""

from __future__ import annotations

import plistlib
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PLIST = ROOT / "ios" / "Runner" / "Info.plist"

# نص عربي يظهر للمستخدم — يبقى الموقع على الجهاز فقط
LOCATION_TEXT = (
    "نستخدم موقعك لحساب مواقيت الصلاة واتجاه القبلة بدقة، ويبقى موقعك على جهازك فقط."
)
NOTIFICATIONS_TEXT = "نحتاج إذن الإشعارات للأذان والتذكيرات الدينية في وقتها."

# مفاتيح نصية: تُضاف فقط إن لم تكن موجودة
STRING_KEYS = {
    "NSLocationWhenInUseUsageDescription": LOCATION_TEXT,
    "NSUserNotificationsUsageDescription": NOTIFICATIONS_TEXT,
}

# مفاتيح مصفوفية: تُدمج القيم الناقصة فقط
LIST_KEYS = {
    "UIBackgroundModes": ["audio", "fetch"],
    "CFBundleLocalizations": ["ar", "en"],
}


def main() -> int:
    if not PLIST.is_file():
        print(f"✗ لم أجد {PLIST.relative_to(ROOT)}")
        print("  شغّل أولاً: flutter create . --org com.multazim.app --platforms=ios")
        return 1

    with PLIST.open("rb") as fh:
        data = plistlib.load(fh)

    changes: list[str] = []
    notes: list[str] = []

    for key, value in STRING_KEYS.items():
        current = data.get(key)
        if current == value:
            continue
        if current in (None, ""):
            data[key] = value
            changes.append(f"+ {key}")
        else:
            # موجود بنص مختلف من عندك — لا نلمسه
            notes.append(f"= {key} موجود مسبقاً بنصك الخاص (لم يُغيّر)")

    for key, values in LIST_KEYS.items():
        current = data.get(key)
        if not isinstance(current, list):
            data[key] = list(values)
            changes.append(f"+ {key} = {values}")
            continue
        missing = [v for v in values if v not in current]
        if missing:
            data[key] = current + missing
            changes.append(f"+ {key} ← {missing}")

    if changes:
        with PLIST.open("wb") as fh:
            plistlib.dump(data, fh)
        print("✓ تم تحديث ios/Runner/Info.plist:")
        for line in changes:
            print("   " + line)
    else:
        print("✓ Info.plist مُجهّز مسبقاً — لا تغييرات.")

    for note in notes:
        print("   " + note)
    return 0


if __name__ == "__main__":
    sys.exit(main())
