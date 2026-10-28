# 🚀 دليل النشر النهائي — «مُلتزم» v1.0.0

> كل ما تحتاجه لتحويل هذا المشروع إلى تطبيق منشور على Google Play و/أو App Store، خطوة بخطوة. المدة المقدّرة: يوم عمل واحد.

---

## ✅ قائمة الجاهزية (كلها مُنجزة مسبقاً في هذا المشروع)

| العنصر | الحالة | المكان |
|---|---|---|
| الهوية الزمرّدية/الذهبية والاسم `مُلتزم` | ✅ | `lib/core/theme/` |
| أيقونة Launcher (كل دقّات أندرويد وiOS + adaptive) | ✅ | `deploy/icons/` |
| صورة Splash | ✅ | `assets/branding/splash.png` |
| أغلفة المتجر (512 + 1024×500) | ✅ | `deploy/icons/store/` |
| AndroidManifest بأذونات مبرّرة | ✅ | `deploy/android/app/src/main/` |
| قالب التوقيع وقواعد ProGuard | ✅ | `deploy/android/` |
| إعدادات iOS الأساسية | ✅ | `deploy/ios/` |
| سياسة الخصوصية (إلزامية للمتجر) | ✅ | `deploy/privacy-policy.md` |
| وصف المتجر ASO جاهز | ✅ | `deploy/store-listing.md` |
| رمز تحليل Dart نظيف بدون تحذيرات حرجة | ✅ | `analysis_lints: flutter_lints` |

> ⚠️ **ملاحظتا توافق تبني عليهما كل خطوات النشر:**
> 1. **لا تُضف حزمة `vibration`**: نسخة `1.x` تعتمد v1 embedding المزال من Flutter، فتُفشل بناء أندرويد بـ `cannot find symbol: class Registrar`. الاهتزاز في «مُلتزم» يتم عبر `HapticFeedback` المدمجة في Flutter (السبحة/الأذكار). إن احتجت أنماط اهتزاز مخصّصة مستقبلاً فاستخدم `vibration: ^3.2.1` (يتطلب Flutter ‎3.41+‎ وDart ‎3.11+‎).
> 2. **`flutter_local_notifications` يتطلب Core Library Desugaring** — يفعّله `deploy/android/apply_android_gradle.py` تلقائياً (محلياً وعلى Codemagic). بدونه يتوقف البناء: *"requires core library desugaring to be enabled"*.

---

## ١. المتطلّبات (تشغّلها على جهازك)

```bash
# تأكد من البيئة
flutter --version          # 3.24+ (يفضّل آخر stable)
flutter doctor              # كل المتطلّبات ✓

# من داخل مجلد المشروع
cd multazim
flutter create . --org com.multazim.app --platforms=android,ios
flutter pub get
flutter analyze             # يجب أن يمرّ نظيفاً
flutter test                # (اختياري — أضف اختبارات لاحقاً)
```

---

## ٢. نسخ ملفات النشر إلى المشروع

```bash
# أندرويد
cp deploy/android/app/src/main/AndroidManifest.xml android/app/src/main/
cp deploy/android/app/proguard-rules.pro android/app/

# ⭐ إلزامي: تفعيل Core Library Desugaring في build.gradle.kts
#    (بدونه يفشل البناء برسالة "requires core library desugaring")
python3 deploy/android/apply_android_gradle.py

# ثم — اختيارياً — دمج باقي additions (مفتاح التوقيع/R8) في
# build.gradle.kts الناتج من flutter create:
# (افتح الملفين واطبّق التعديلات من deploy/android/app/build.gradle.kts.additions)
#
# ⚠ إن أضفت كود مفتاح التوقيع يدوياً فضع في أعلى الملف (قبل plugins { }):
#       import java.io.FileInputStream
#       import java.util.Properties
#   ثم استخدم Properties() و FileInputStream() بالاسم المختصر.
#   السبب: داخل build.gradle.kts الخاص بالتطبيق الاسم `java` هو extension إضافة
#   جافا وليس الحزمة، فكتابة java.util.Properties() تُفشل البناء بثلاثة أخطاء:
#       Unresolved reference: util  /  Unresolved reference: io
#       Expression expected, but a package name found
#   (السكربت apply_android_gradle.py يصلحها آلياً لو وقعت.)

# أيقونات أندرويد الجاهزة (فوق الافتراضية)
cp -r deploy/icons/android/res/* android/app/src/main/res/

# iOS (داخل Xcode أو يدوياً)
# ١) انسخ deploy/ios/Info.plist-additions.xml → داخل <dict> في ios/Runner/Info.plist
# ٢) Assets.xcassets: ضع أيقونات deploy/icons/ios/ في AppIcon.appiconset
#    (أو استخدم flutter_launcher_icons بعد pub get — أسهل)
```

الخيار الأسهل للأيقونات (مولّد تلقائياً من `assets/branding/logo.png`):
```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

---

## ٣. توقيع Android الثابت وحماية التحديث

حتى يثبت APK فوق النسخة القديمة ويبقى Hive محفوظاً، يجب أن يبقى `applicationId` كما هو (`com.multazim.app`)، وأن يُوقّع كل إصدار بالمفتاح نفسه، وأن يزيد `versionCode`. لا تغيّر معرّف التطبيق أو مفاتيح Hive أو مخطط البيانات.

### إذا كان لديك إصدار Release موقّع بالفعل

**لا تنشئ مفتاحاً جديداً.** استعمل ملف keystore نفسه، واسم `keyAlias` نفسه، وكلمتي مرور المخزن والمفتاح نفسيهما اللتين وُقّع بهما الإصدار المثبّت. إذا لم تعرف أي مفتاح استُخدم، قارن بصمة شهادة APK القديم والجديد بالطريقة في القسم ٤ قبل التوزيع. في Google Play مع Play App Signing، فرّق بين مفتاح الرفع ومفتاح توقيع التطبيق؛ تحديث Play يجب أن يمر عبر مسار Play، أما التثبيت المباشر فيحتاج الشهادة المطابقة للنسخة المثبّتة.

### إنشاء مفتاح جديد (فقط إن لم يوجد مفتاح Release سابق)

```bash
# keytool يطلب كلمتي المرور تفاعلياً؛ لا تضعهما في سطر الأمر
keytool -genkeypair -v -keystore multazim-keystore.jks -alias multazim \
  -keyalg RSA -keysize 2048 -validity 10000 -storetype JKS
```

احتفظ بثلاث نسخ مشفّرة وآمنة من `multazim-keystore.jks` واسم alias وكلمتي المرور. فقدانها قد يمنع تحديث النسخ المثبّتة بهذا المفتاح. **لا ترسل المفتاح أو كلمات المرور في المحادثة ولا ترفعها إلى Git.**

### إدخال الأسرار في GitHub Actions

من المستودع: **Settings → Secrets and variables → Actions → New repository secret**. أضف هذه الأسرار الأربعة:

- `ANDROID_KEYSTORE_BASE64` — محتوى keystore بعد تحويله إلى Base64 في سطر واحد.
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_PASSWORD`
- `ANDROID_KEY_ALIAS` — alias الموجود فعلياً في keystore، وليس بالضرورة `multazim`.

### إدخال القيم نفسها في Codemagic

في Codemagic افتح **Team settings** أو **App settings → Environment variables**، وأنشئ مجموعة باسم `multazim-android-signing`. أضف إليها **الأسماء الأربعة والقيم نفسها** الموجودة في GitHub، واجعلها كلها `Secure`، ثم اربط المجموعة بسير العمل `android-apk`. خزّن `ANDROID_KEYSTORE_BASE64` كقيمة نصية Base64، لا كمتغير ملف: لا يعتمد الإعداد على `CM_KEYSTORE_PATH` أو على افتراض إنشاء لاحقة `_PATH` تلقائياً؛ السكربت المشترك يفك Base64 إلى ملف مؤقت بنفسه.

يعمل `scripts/android_signing.py` في الخدمتين بالتحقق من اكتمال القيم، وصحة Base64، وصلاحية المخزن والـalias وكلمة مرور المفتاح عبر `keytool` قبل البناء. لا يطبع القيم، ويكتب `android/key.properties` بترميز Java Properties آمن ثم يحذفه مع keystore المؤقت حتى عند فشل البناء. لا يصل توقيع المستودع إلى فحوص Pull Request الخارجية؛ بناء التوزيع الموقّع يعمل من `main` فقط، بينما APK التحقق منفصل وموسوم بأنه غير مخصص للتوزيع.

### تحويل keystore إلى Base64

على macOS أو Linux:

```bash
base64 < multazim-keystore.jks | tr -d '\r\n'
```

على Windows PowerShell:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes((Resolve-Path .\multazim-keystore.jks)))
```

انسخ الناتج مباشرة إلى الحقل الآمن المناسب؛ لا تضعه في ملف بالمستودع أو في سجل الأوامر.

---

## ٤. البناء والترقيم واختبار التحديث

مصدر رقم البناء المشترك هو `pubspec.yaml` فقط: في `version: 0.1.0+1`، الجزء `0.1.0` هو `versionName` والجزء بعد `+` هو `versionCode` على Android. زد `versionCode` يدوياً إلى رقم أعلى **لكل إصدار توزيع** (مثلاً `0.1.0+2`) وغيّر `versionName` عند إصدار نسخة منتج جديدة. لا تستخدم `github.run_number` أو عدّاد Codemagic، ولا تغيّر الرقم لفحوص PR؛ الخدمتان تبنيان رقم المصدر نفسه.

```bash
# التوزيع بهذا المفتاح فقط بعد إعداد android/key.properties محلياً
flutter build apk --release          # APK شامل — الصيغة الموحّدة للتحديثات المباشرة
flutter build appbundle --release    # ⭐ Google Play
```

في CI، لا يبدأ بناء التوزيع إذا غاب التوقيع أو كان غير صالح. أما بناء PR فهو بناء تحقق غير قابل للتوزيع، ومسمّى بوضوح.

**لا تبدّل بين APK شامل و`--split-per-abi` على سجل التثبيت نفسه.** Flutter يضيف إلى `versionCode` المقسّم إزاحة `ABI_VERSION × 1000`؛ لذلك تكون أكواد split أعلى من APK الشامل، وقد يرفض Android الرجوع إلى APK شامل كأنه أقدم حتى مع الشهادة نفسها ([وثائق Flutter](https://docs.flutter.dev/deployment/android)). لهذا تقتصر مخرجات التوزيع هنا على APK شامل وAAB. إن اخترت البناء المقسّم محلياً، فحافظ على صيغة التقسيم نفسها وعلى ABI الجهاز في كل تحديث.

### فحص تطابق شهادة التوقيع

تحتاج `apksigner` من Android SDK Build Tools. افحص APK القديم الذي ثُبّت منه والجديد:

```bash
apksigner verify --print-certs old-release.apk
apksigner verify --print-certs new-release.apk
```

قارن قيمة `Signer #1 certificate SHA-256 digest` في الناتجين؛ يجب أن تتطابق تماماً للتحديث المباشر.

### اختبار تثبيت وحفظ Hive يدوياً

نجاح البناء وحده لا يثبت حفظ البيانات. قبل التوزيع:

1. ثبّت APK إصدار أول موقّع بالمفتاح الثابت، ثم أضف بيانات اختبار داخل التطبيق (مثل سجل صلاة/ذكر/إعداد محفوظ في Hive).
2. ارفع رقم `versionCode` في `pubspec.yaml` فقط، وابنِ APK شاملاً بالإعداد والمفتاح نفسيهما.
3. ثبّت الإصدار الأعلى **فوق القديم** (مثلاً `adb install -r new-release.apk`) من دون حذف التطبيق أو مسح بياناته.
4. افتح التطبيق وتحقق من بقاء البيانات السابقة، ثم اختبر التصدير والاستعادة اختيارياً.

**استثناء مهم للنسخ الحالية:** إذا كان التطبيق المثبّت موقّعاً بمفتاح Debug مختلف ولا نملك ذلك المفتاح، فلا يمكن ضمان تحديث مباشر يحفظ البيانات. قبل أي حذف، افتح **الإعدادات ← نسخ احتياطي**، صدّر JSON واحفظ `multazim_backup.json` خارج التطبيق (مثلاً على الكمبيوتر/سحابة خاصة). بعدها احذف النسخة القديمة مرة واحدة، وثبّت النسخة ذات المفتاح الثابت، ثم افتح **الإعدادات ← النسخ الاحتياطي ← استعادة** والصق محتوى ملف JSON. من تلك النقطة استخدم المفتاح الثابت نفسه لكل الإصدارات.

**تجربة يدوية إضافية قبل الرفع:**
- [ ] الأذان يصدر وإن كان التطبيق مغلقاً؟ (افعل القفل وانتظر المواقيت)
- [ ] القرآن يعمل بدون إنترنت بعد أول فتح سورة؟
- [ ] الصدقة تُحفظ مخفية وتبقى بعد إعادة التشغيل؟
- [ ] مؤشر الأخلاق + المحاور البيانية تُحدّث؟
- [ ] التسجيل في سجل الصلوات ينعكس فوراً في «يومي» والرسم؟
- [ ] الثيم الداكن يعمل في كل الشاشات الـ ١١؟

---

## ٥. الرفع على Google Play (٢٥$ لمرة واحدة)

1. https://play.google.com/console ⟶ «إنشاء تطبيق»
2. الداخلية (Internal) ⟶ ارفع `.aab` ⟶ أضف مختبريين (أنت + ٥ أصدقاء أولاً)
3. Store presence ⟶ انسخ من `deploy/store-listing.md` بالترتيب
4. **Data Safety** ⟵ الصيغة الجاهزة *«لا نجمع لا نشارك»* من قسم البيانات في الملف
5. Privacy Policy ⟶ ارفع `deploy/privacy-policy.md` على GitHub Pages وألصق رابطه
6. Content Rating ⟶ «للجميع» ⟵ الأسئلة تجيب عنها بلا في كل شيء
7. رسل للنشر الإنتاجي بعد أسبوع اختبار ناجح

## ٦. الرفع على App Store (٩٩$/سنة — MAC مطلوب)

1. https://developer.apple.com ⟶ App Store Connect ⟶ «+ تطبيق»
2. Bundle ID: `com.multazim.app` (مثل المنو). يجب تطابقه مع توقيع iOS
3. Archive من Xcode ⟶ Upload
4. بطاقة الوصف نفسها من `store-listing.md` (App Review يميل لتقصير فروع العطاء — أدرج الرد الجاهز من الملف)
5. Privacy Nutrition Labels ⟵ لاحظ: «لا بيانات مقترنة بك» لكل نوع
6. أرسل للمراجعة (تستغرق ٢٤–٤٨ ساعة)

> 💡 **لا تملك Mac؟** استخدم خدمة (MacInCloud / CodeMagic / GitHub Actions macOS runner) لبناء ملف IPA نهائي. أو أطلق أولاً على Android فقط (٨٠٪+ من جمهورك العربي).

---

## ٧. بعد النشر (مقترحات قوية)

- **رمضان**: إمساكية قابلة للمشاركة PNG + وضع العشر الأواخر — رافعة تحميلات طبيعية
- إصدار شهري(es): ١.١ أصوات أذان إضافية · ١.٢ وضع تسجيل التسميع · ١.٣ Widget أندرويد للمواقيت
- استمع لتقييمات المتجر: «ما الذي تمنيت وجوده في مُلتزم؟»

---

*«قليلٌ دائم خيرٌ من كثيرٍ منقطع» — جعلها الله صدقة جارية لك ولنا ولكل من حملها 🤍*
