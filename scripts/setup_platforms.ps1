# ─────────────────────────────────────────────────────────────────
#  تجهيز منصّات «مُلتزم» على Windows (PowerShell)
#  الاستخدام:  powershell -ExecutionPolicy Bypass -File scripts\setup_platforms.ps1
#
#  نسخة مطابقة لـ scripts/setup_platforms.sh:
#   • توليد android/ و ios/ (iOS يحتاج Mac للبناء، لكن المجلد يُنشأ هنا)
#   • AndroidManifest + أيقونات الإطلاق + ProGuard
#   • Core Library Desugaring (إلزامي لـ flutter_local_notifications)
#   • مفاتيح iOS في Info.plist (إن وُجد مجلد ios)
#  آمن للتشغيل المتكرر.
# ─────────────────────────────────────────────────────────────────
$ErrorActionPreference = 'Stop'

$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

function Write-Step([string]$Text) { Write-Host "▸ $Text" -ForegroundColor Green }
function Write-Warn([string]$Text) { Write-Host "⚠ $Text" -ForegroundColor Yellow }

# ── ١) المتطلبات ─────────────────────────────────────────────────
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "✗ أمر flutter غير موجود في PATH." -ForegroundColor Red
    Write-Host "  ثبّت Flutter ثم أعد فتح PowerShell: https://docs.flutter.dev/get-started/install/windows"
    exit 1
}
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Host "✗ Python مطلوب (يستخدمه سكربت desugaring)." -ForegroundColor Red
    Write-Host "  ثبّته من https://python.org (فعّل Add to PATH)."
    exit 1
}

Write-Step "إصدار Flutter:"
flutter --version | Select-Object -First 1

# ── ٢) توليد المنصات ─────────────────────────────────────────────
Write-Step "توليد android/ و ios/ (لا يمسّ lib/ ولا pubspec.yaml)…"
flutter create . --org com.multazim.app --platforms=android,ios

# ── ٣) ملفات النشر ───────────────────────────────────────────────
Write-Step "نسخ AndroidManifest وأيقونات الإطلاق…"
New-Item -ItemType Directory -Force -Path "android\app\src\main\res" | Out-Null
Copy-Item "deploy\android\app\src\main\AndroidManifest.xml" "android\app\src\main\AndroidManifest.xml" -Force
Copy-Item "deploy\icons\android\res\*" "android\app\src\main\res\" -Recurse -Force
Copy-Item "deploy\android\app\proguard-rules.pro" "android\app\proguard-rules.pro" -Force

# ── ٤) Desugaring ────────────────────────────────────────────────
Write-Step "تفعيل Core Library Desugaring…"
python deploy\android\apply_android_gradle.py
if ($LASTEXITCODE -ne 0) { Write-Host "✗ فشل تفعيل desugaring" -ForegroundColor Red; exit $LASTEXITCODE }

# ── ٥) iOS Info.plist ────────────────────────────────────────────
if (Test-Path "ios\Runner\Info.plist") {
    Write-Step "دمج مفاتيح iOS في Info.plist…"
    python scripts\apply_ios_plist.py
}

# ── ٦) الاعتماديات والتحليل ──────────────────────────────────────
Write-Step "flutter pub get…"
flutter pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Step "flutter analyze (تقرير فقط)…"
flutter analyze
if ($LASTEXITCODE -ne 0) { Write-Warn "توجد ملاحظات تحليل أعلاه — راجعها قبل الـ commit." }

Write-Host @"

✅ جاهز. الخطوات التالية:
   flutter devices
   flutter run
   flutter build apk --release --split-per-abi
"@ -ForegroundColor Cyan
