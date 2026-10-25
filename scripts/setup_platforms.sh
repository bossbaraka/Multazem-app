#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────
#  تجهيز منصّات «مُلتزم» محلياً (macOS / Linux)
#  الاستخدام:  bash scripts/setup_platforms.sh
#
#  يولّد android/ و ios/ ثم يطبّق ملفات النشر الإلزامية:
#   • AndroidManifest بالأذونات الصحيحة
#   • أيقونات الإطلاق
#   • Core Library Desugaring (إلزامي لـ flutter_local_notifications)
#   • مفاتيح iOS في Info.plist
#  آمن للتشغيل المتكرر (idempotent).
# ─────────────────────────────────────────────────────────────────
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

green() { printf '\033[1;32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[1;33m%s\033[0m\n' "$*"; }
red() { printf '\033[1;31m%s\033[0m\n' "$*"; }

# ── ١) فحص المتطلبات ─────────────────────────────────────────────
command -v flutter >/dev/null 2>&1 || {
  red "✗ أمر flutter غير موجود في PATH."
  echo "  ثبّت Flutter: https://docs.flutter.dev/get-started/install"
  exit 1
}
command -v python3 >/dev/null 2>&1 || {
  red "✗ python3 مطلوب (يستخدمه سكربت desugaring)."
  exit 1
}

green "▸ إصدار Flutter:"
flutter --version | head -1

# ── ٢) توليد مجلدات المنصات ──────────────────────────────────────
green "▸ توليد android/ و ios/ (لا يمسّ lib/ ولا pubspec.yaml)…"
flutter create . --org com.multazim.app --platforms=android,ios

# ── ٣) ملفات النشر ───────────────────────────────────────────────
green "▸ نسخ AndroidManifest وأيقونات الإطلاق…"
mkdir -p android/app/src/main
cp deploy/android/app/src/main/AndroidManifest.xml android/app/src/main/AndroidManifest.xml
mkdir -p android/app/src/main/res
cp -R deploy/icons/android/res/. android/app/src/main/res/
cp deploy/android/app/proguard-rules.pro android/app/proguard-rules.pro

# ── ٤) Desugaring (إلزامي) ───────────────────────────────────────
green "▸ تفعيل Core Library Desugaring…"
python3 deploy/android/apply_android_gradle.py

# ── ٥) iOS Info.plist ────────────────────────────────────────────
if [ -f ios/Runner/Info.plist ]; then
  green "▸ دمج مفاتيح iOS في Info.plist…"
  python3 scripts/apply_ios_plist.py
fi

# ── ٦) الاعتماديات والتحليل ──────────────────────────────────────
green "▸ flutter pub get…"
flutter pub get

green "▸ flutter analyze (تقرير فقط — لا يوقف السكربت)…"
flutter analyze || yellow "⚠ يوجد ملاحظات تحليل أعلاه — راجعها قبل الـ commit."

cat <<'EOF'

✅ جاهز. الخطوات التالية:
   flutter devices              # تأكّد من ظهور المحاكي/الهاتف
   flutter run                  # تشغيل التطبيق
   flutter test                 # (بعد إضافة اختبارات)

   لبناء APK للاستخدام الخاص:
   flutter build apk --release --split-per-abi
EOF
