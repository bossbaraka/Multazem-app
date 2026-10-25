# 🛠️ بناء «مُلتزم» باستخدام Google Antigravity — الخطوات الكاملة

> دليل عملي من الصفر حتى تشغيل التطبيق على هاتفك، ثم إدارة بقية المراحل عبر وكلاء Antigravity.
> **الوضع الحالي للمستودع:** كود `lib/` مكتمل + `pubspec.yaml` + ملفات النشر في `deploy/`، لكن مجلدَي
> `android/` و`ios/` **غير مولّدَين** بعد (يُولَّدان بأمر واحد). لا توجد خلفية/سيرفر — التطبيق محلي بالكامل.

---

## ⚡ الخلاصة في ٦ خطوات

| # | الخطوة | الوقت |
|---|---|---|
| ١ | ثبّت Flutter + Android Studio + Git + Python3 | ٢٥–٤٠ د |
| ٢ | `git clone` المستودع ثم `bash scripts/setup_platforms.sh` | ٥ د |
| ٣ | `flutter run` على محاكي/هاتف — تأكيد أن التطبيق يقلع | ٥ د |
| ٤ | ثبّت Antigravity وسجّل بجوجل، إعداد **Review-driven** | ١٠ د |
| ٥ | أنشئ Project على مجلد المستودع وفعّل إضافة **Dart and Flutter** | ٥ د |
| ٦ | أول محادثة تحقّق، ثم ابدأ المهام من قسم «خطة البناء» أدناه | مستمر |

---

## ١) متطلبات الجهاز

### ١.١ Flutter SDK (3.24 أو أحدث — يُفضّل آخر stable)

**macOS**
```bash
brew install --cask flutter
```
**Windows** — نزّل حزمة ZIP من <https://docs.flutter.dev/get-started/install/windows>، فكّها في مسار بلا مسافات
(مثل `C:\src\flutter`)، وأضف `C:\src\flutter\bin` إلى `PATH`، ثم افتح **PowerShell جديداً**.
**Linux** — `sudo snap install flutter --classic` (أو اتبع صفحة التثبيت الرسمية).

تحقّق:
```bash
flutter --version
flutter doctor -v
```

### ١.٢ Android Studio (للمحاكي وأدوات Android)

- نزّله من <https://developer.android.com/studio>، وثبّت أثناء الإعداد: **Android SDK**,
  **Platform-Tools**, **Build-Tools**, **Android Emulator**, **Command-line Tools**.
- JDK ١٧ يأتي مع Android Studio — لا تحتاج تثبيت Java منفصلاً.
- أقبل التراخيص ثم تحقّق:
```bash
flutter doctor --android-licenses
flutter doctor          # يجب أن تكون علامات Android ✓
```
- أنشئ جهازاً افتراضياً من **Device Manager** (Pixel، Android 14).

### ١.٣ أدوات مساعدة
```bash
git --version        # موجود مسبقاً غالباً
python3 --version    # يستخدمه سكربت desugaring
node --version       # اختياري — لتثبيت مهارات Flutter للوكيل (npx)
```

> **لا تملك جهازاً قوياً / لا تريد تثبيت Flutter؟** يمكنك لاحقاً بناء APK سحابياً عبر
> `codemagic.yaml` الموجود في المستودع (انظر `deploy/PRIVATE.md`)، لكن تطوير الواجهات فعلياً
> يحتاج `flutter run` محلياً — لذلك الخطوة ١ أساسية.

---

## ٢) تحضير المستودع محلياً (مرة واحدة)

```bash
git clone https://github.com/bossbaraka/Multazem-app.git multazim
cd multazim
git checkout main          # أو الفرع الذي تعمل عليه
```

ثم **أمر واحد** يجهّز كل المنصّات:

```bash
# macOS / Linux
bash scripts/setup_platforms.sh
```

```powershell
# Windows (PowerShell)
powershell -ExecutionPolicy Bypass -File scripts\setup_platforms.ps1
```

ماذا يفعل السكربت؟
1. `flutter create . --org com.multazim.app --platforms=android,ios` (يولّد `android/` و`ios/` ويحفظ كودك).
2. ينسخ `deploy/android/app/src/main/AndroidManifest.xml` (الأذونات الصحيحة للأذان والموقع).
3. ينسخ أيقونات الإطلاق من `deploy/icons/android/res/`.
4. يشغّل `deploy/android/apply_android_gradle.py` ⇒ يفعّل **Core Library Desugaring** (إلزامي
   لـ `flutter_local_notifications`، بدونه يتوقف البناء).
5. يدمج مفاتيح iOS المطلوبة في `ios/Runner/Info.plist` (الموقع، الإشعارات، الصوت في الخلفية).
6. `flutter pub get` ثم `flutter analyze`.

بعدها:
```bash
flutter devices
flutter run                    # على المحاكي أو هاتف موصول بـ USB
```

✅ **معيار النجاح:** تظهر شاشة Onboarding الزمرّدية بالعربية RTL، وتطلب الموقع، ثم تصل لـ«يومي».
إن ظهر خطأ، راجع قسم [استكشاف الأخطاء](#-استكشاف-الأخطاء).

> 💡 **تحقّق بصري سريع بدون Flutter:** افتح `preview/index.html` في المتصفح — معاينة HTML
> تفاعلية للتصميم. مفيدة لكي تُري الوكيل «الشكل المرجعي» عند طلب تعديلات UI.

### ٢.١ أول commit محلي
```bash
git add -A
git commit -m "chore: scaffold android/ios platforms locally"
```
> لا ترفع هذا الـ commit إن أردت إبقاء المستودع نظيفاً — `flutter create` يولّد ملفات كثيرة
> (وهذا مقصود في هذا المشروع: المنصات تُولَّد على جهازك وعلى CI). أبقِه محلياً:
> `git reset --soft HEAD~1` إن غيّرت رأيك.

---

## ٣) تثبيت Antigravity وإعداده

### ٣.١ التثبيت
1. نزّل من <https://antigravity.google/download> (نسخة macOS / Windows / Linux).
2. سجّل الدخول بحساب Google.
3. في شاشة *«How do you want to use Antigravity»* اختر **Review-driven development** — أي
   «وافق على كل أمر قبل تنفيذه». هذا الأهم في مشروع ديني فيه محتوى شرعي ومفاتيح توقيع.
   (يمكن تغييره لاحقاً من Settings.)

### ٣.٢ إنشاء Project
1. من **Agent Manager** اضغط أيقونة **New Project** (مجلد +).
2. **Add Folder** ⇒ اختر مجلد `multazim` (جذر المستودع، الذي فيه `pubspec.yaml` و`AGENTS.md`).
3. **Create**، وانتظر انتهاء الفهرسة (Indexing) قبل أول مهمة.
4. عند بدء أول مهمة اختر:
   - **Local Mode** — الوكيل يعمل على مجلداتك مباشرة (للمهمة الواحدة المتتابعة).
   - **New Worktree Mode** — نسخة git معزولة (ممتاز لتشغيل **عدة وكلاء بالتوازي** على ميزات مختلفة، ثم تدمج الفروع بنفسك).
5. التنقل: `Cmd/Ctrl + E` بين Agent Manager والمحرر، و`Cmd/Ctrl + L` لفتح لوحة الوكيل داخل المحرر.

### ٣.٣ إضافة أدوات Dart و Flutter (مهم جداً)
1. **Settings** (`Cmd/Ctrl + ,`) ⇒ تبويب **Customizations**.
2. قسم **Build with Google Plugins** ⇒ **Customize**.
3. اضغط **Download** بجانب **Dart and Flutter**.
4. تأكيد: افتح لوحة الوكيل واسأله:
   > `Summarize the Dart and Flutter tools and skills available in this project.`

هذه الإضافة تعطي الوكيل: مهارات Flutter/Dart الرسمية + قواعد + **MCP server** يقرأ مخرجات
`flutter analyze` وشجرة الودجات وحالة التطبيق أثناء التشغيل — أي أنه يصلح أخطاءه بنفسه.

**اختياري — مهارات إضافية عبر CLI:**
```bash
npx skills add flutter/agent-plugins --skill '*' --agent universal --yes
npx skills add dart-lang/skills --skill '*' --agent universal --yes
```
**اختياري — MCP للتيرمنال:** ملف `.agents/mcp_config.json` جاهز في المستودع يربط Dart MCP server؛
استخدمه مع `agy` (Antigravity CLI) إن أحببت العمل من الطرفية.

### ٣.٤ ضبط مسار Flutter (إن لم يُكتشف تلقائياً)
Settings ⇒ ابحث عن `flutter.sdkPath` ⇒ ضع مسار Flutter:
macOS/Linux: `/opt/homebrew/bin/flutter` أو مسار `bin/flutter`، Windows: `C:\src\flutter`.
ثم `Developer: Reload Window`.

### ٣.٥ AGENTS.md جاهز
ملف **`AGENTS.md`** في جذر المستودع يشرح للوكيل: المعمارية، الأوامر، القيود الصارمة
(لا حزمة `vibration`، لا خلفية، لا تتبّع، توثيق المصادر الشرعية)، ومعيار «تمّت المهمة».
**لا تحذفه** — هو أهم سبب في جودة النتائج. حدّثه كلما أضفت قاعدة جديدة.

---

## ٤) أول محادثة مع الوكيل — تحقّق من البيئة

الصق هذا في لوحة الوكيل:

```text
اقرأ AGENTS.md و README.md و docs/MASTER-PROMPT.md أولاً، ثم:
1) شغّل `flutter --version` و`flutter doctor` و`flutter pub get` و`flutter analyze` وأبلغني بالنتيجة.
2) لخّص لي بنية lib/ في 10 أسطر: أين الثيم، أين الراوتر، أين خدمات الإشعارات، وأين تُحفظ البيانات.
3) اذكر 5 مخاطر تقنية تراها في المشروع قبل النشر (بحسب الملفات الفعلية، لا التخمين).
لا تعدّل أي ملف في هذه المهمة.
```

بعد نجاحها، جرّب أول مهمة صغيرة حقيقية (خيار واحد):

```text
شغّل التطبيق على المحاكي وافتح تبويب «يومي». صِف ما تراه، والتقط أي خطأ في console.
إن كانت هناك مشكلة واحدة واضحة فقط، اقترح إصلاحها (لا تطبّقه) وانتظر موافقتي.
```

---

## ٥) كيف تُدير العمل مع Antigravity بفاعلية (قواعد ذهبية)

| القاعدة | السبب |
|---|---|
| **مهمة واحدة لكل محادثة** | السياق الطويل يضعف الدقة؛ ابدأ محادثة جديدة لكل ميزة واذكر `@AGENTS.md`. |
| **اطلب خطة أولاً** ثم «نفّذ» | تراجع المنهج قبل كتابة ٨٠٠ سطر. |
| **Worktree Mode عند التوازي** | ميزتان في وقت واحد بلا تعارض في الملفات. |
| **وافق على الأوامر بيدك** | خاصة `flutter build`, `git`, `rm`. |
| **اطلب دائماً**: `flutter analyze` + `flutter test` قبل «تمّت» | يكشف أخطاء لا يراها الوكيل. |
| **راجع الـ diff** (زر Review) ولا تقبل تعديلات واسعة غير مطلوبة | يمنع «إعادة هيكلة» تفسد ما يعمل. |
| **مرجعك البصري**: `preview/index.html` + `docs/MASTER-PROMPT.md` | يقلّل الانحراف في الهوية. |
| **لا مفاتيح ولا أسرار في المحادثة** | التوقيع والمفاتيح تبقى محلية. |

**قالب مهمة جاهز (انسخه لأي ميزة):**
```text
المهمة: <سطر واحد>
السياق: اقرأ @AGENTS.md و<الملفات ذات الصلة>.
المطلوب: <تفصيل ٣–٦ نقاط>
ممنوع: إضافة حزم جديدة، تغيير مفاتيح Hive، تعديل deploy/.
التسليم: خطة قصيرة → كود → `flutter analyze` + `flutter test` → قائمة الملفات المتغيرة + خطوات اختبار يدوي.
```

---

## ٦) 📋 خطة البناء المتبقية — مهام جاهزة للصق

مرتّبة بالأولوية الفعلية للمشروع (راجع قسم «خارطة الطريق» في README). نفّذ واحدة، راجع، اعتمد، ثم التالية.

### المهمة ١ — الأصول الناقصة (صوت الأذان + خط المصحف)
```text
اقرأ assets/sounds/README.txt و assets/fonts/README.txt و lib/core/services/notification_service.dart.
المطلوب:
1) وثّق بدقة كل ملف صوت/خط يتوقعه الكود ولماذا، في جدول: المسار | المستخدم في | الأثر عند غيابه | بديل مؤقت.
2) اكتب سكربت scripts/check_assets.sh يتحقق من وجودها ويطبع تقريراً (exit code غير صفري إن ناقص).
3) اضبط pubspec.yaml لعنوان الخط المحلي مع fallback لـ Google Fonts إن لم يوجد الملف.
4) أضف في docs/ASSETS.md قائمة أذونات/تراخيص مطلوبة لكل ملف (لا تنسخ ملفات محمية بحقوق).
ممنوع: تنزيل أي ملف صوت أو خط من الإنترنت.
```

### المهمة ٢ — أيقونة/سبلاش + بناء أول APK حقيقي
```text
بعد flutter pub get: شغّل `dart run flutter_launcher_icons` و`dart run flutter_native_splash:create`،
ثم `flutter build apk --release` وأبلغني بالمسار والحجم. أصلح فقط أخطاء البناء المتعلقة بهذه الخطوة
(desugaring / JDK / minSdk) ولا تغيّر أي كود واجهة.
```

### المهمة ٣ — اختبارات Widget أساسية (أهم مهمة جودة)
```text
أضف اختبارات widget تغطي: onboarding، شاشة يومي (بطاقة الصلاة القادمة)، سجل الصلاة، السبحة، خطة الختمة.
استخدم fake/override لـ HiveProvider والموقع والمواقيت — بلا شبكة وبلا إشعارات حقيقية.
الهدف: `flutter test` يمرّ، وتغطية منطق الحالة (لا الواجهة فقط).
```

### المهمة ٤ — فحص الإتاحة والأداء
```text
1) راجع كل الشاشات: أحجام اللمس ≥48dp، تباين النصوص فوق الزمردي/الذهبي، دعم تكبير الخط 2.0،
   semantic labels عربية للأزرار الأيقونية.
2) ابحث عن أسباب الـ jank: rebuilds غير ضرورية، صور/زخارف ثقيلة في قوائم، حسابات في build().
3) أصلح أعلى 5 مشكلات فقط، بفروق صغيرة ومراجعة سهلة + تقرير قبل/بعد.
```

### المهمة ٥ — المصحف في ٦٠٤ صفحات + فهرس الأجزاء
```text
راجع lib/features/quran/. المطلوب: نموذج بيانات للصفحات (page → surah/ayah range) مع مصدر البيانات
المستخدم حالياً، وفهرس أجزاء/أحزاب، وتنقّل «انتقل إلى صفحة/جزء»، مع الحفاظ على وضع السور الحالي.
لا تكسر «آخر قراءة» ولا التفسير. أضف اختبار وحدة لتقسيم الصفحات.
```

### المهمة ٦ — خطة الحفظ والمراجعة
```text
أضف داخل features/learn_quran (أو feature جديدة) خطة حفظ: هدف (سورة/صفحة) + مراجعة متباعدة
(يوم/٣/٧/٣٠) + سجل في Hive + شاشة تقدّم. التزم بثيم المشروع وRTL. لا حزم جديدة.
```

### المهمة ٧ — حصن المسلم الكامل بمصادره
```text
وسّع lib/features/adhkar/data/adhkar_seed.dart إلى بنية قابلة للتغذية من assets/data/adhkar_full.json،
مع تحميل سلس مع fallback للبذور الحالية. لا تُدخل أي ذكر بلا مصدر (اسم الكتاب/الرقم).
اترك TODO(مصدر:) لأي عنصر غير متأكد منه.
```

### المهمة ٨ — جاهزية النشر (بعد اكتمال ما سبق)
```text
راجع deploy/RELEASE.md وطبّق: توقيع release عبر android/key.properties (بدون commit للمفاتيح)،
التحقق من ProGuard/R8 على نسخة release، وتشغيل قائمة «تجربة يدوية إلزامية» في RELEASE.md،
وتوليد appbundle + توثيق النتائج في docs/RELEASE-CHECKLIST.md.
```

> **نصيحة ترتيب:** ١ → ٢ → ٣ → ٤ ثم اختر ٥/٦/٧ حسب أولويتك. لا تبدأ ٨ قبل أن يمرّ `flutter test`
> وتجربة التنبيهات على جهاز حقيقي.

---

## ٧) التشغيل على جهازك أو نشره

- **تشغيل خاص (بدون متاجر):** `deploy/PRIVATE.md` — بناء APK على جهازك أو عبر Codemagic المجاني;
  لا حاجة لمفتاح توقيع. iOS: Mac + Xcode أو SideStore.
- **نشر على Google Play / App Store:** `deploy/RELEASE.md` خطوة بخطوة (توقيع، Data Safety، سياسة خصوصية، ASO).
- **ملاحظة مهمة:** استخدم **نفس التوقيع** في كل تحديث، وإلا رُفض التحديث أو فُقدت بيانات Hive عند إعادة التثبيت.

---

## 🧯 استكشاف الأخطاء

| المشكلة | الحل |
|---|---|
| `Dependency 'flutter_local_notifications' requires core library desugaring` | شغّل `python3 deploy/android/apply_android_gradle.py` ثم `flutter clean`. تأكّد `desugar_jdk_libs:2.1.4`. |
| `Unsupported class file major version` / Gradle يفشل | JDK غير متوافق: `flutter config --jdk-dir "…/Android Studio/jbr"` (JDK ١٧). |
| `flutter: command not found` | أضف `flutter/bin` إلى `PATH` وأعد فتح الطرفية. في Antigravity: `flutter.sdkPath` في Settings. |
| امتداد Flutter لا يعمل داخل Antigravity | View ⇒ Output ⇒ اختر Flutter/Dart واقرأ الخطأ، ثم أعد تحميل النافذة وتأكّد من `flutter.sdkPath`. |
| `Target of URI doesn't exist` | `flutter pub get` ثم Restart Analysis Server. |
| المحاكي لا يظهر في `flutter devices` | شغّل الجهاز من Android Studio Device Manager، ثم `adb devices`؛ على Windows فعّل Virtualization (WHPX). |
| `minSdkVersion` منخفض لأحد الملحقات | ارفع `minSdk = 23` في `android/app/build.gradle.kts` (Flutter الحديث افتراضياً ٢١+). |
| الإشعارات لا تصل على Android 13+ | يجب طلب إذن `POST_NOTIFICATIONS` وقت التشغيل + `SCHEDULE_EXACT_ALARM` (موجود في المانيفست المنسوخ). اختبر على جهاز حقيقي. |
| iOS: توقّف عن الجدولة بعد عدد معيّن | iOS يحدّ الإشعارات المعلّقة بـ **٦٤** — جدول اليوم فقط (كما في `main.dart`) ولا تجدول أسبوعاً كاملاً. |
| iOS: `Podfile` يشكو من platform | `platform :ios, '13.0'` في `ios/Podfile` ثم `pod install`. |
| النص العربي يظهر مربّعات | خطوط `google_fonts` تحتاج إنترنت أول مرة — للنص القرآني استخدم `assets/fonts/AmiriQuran-Regular.ttf` محلياً. |
| بناء release ينهار بينما debug يعمل | غالباً R8/ProGuard: راجع `deploy/android/app/proguard-rules.pro` أو أطفئ `isMinifyEnabled` مؤقتاً. |
| فشل تحديث APK على الهاتف | توقيع مختلف بين البناءين: أزل التطبيق القديم مرة، أو استخدم نفس keystore (الأفضل). |

---

## 📎 ملحق — أوامر تحتاجها كثيراً

```bash
flutter pub get && flutter analyze && flutter test      # قبل كل commit
flutter clean && flutter pub get                        # بعد تغيير gradle/pubspec
flutter run --release --profile                       # قياس الأداء الحقيقي
dart format lib/                                        # تنسيق
git status --short && git diff --stat                   # مراجعة قبل الاعتماد
```

**مراجع:** المستودع (`README.md`, `deploy/RELEASE.md`, `docs/MASTER-PROMPT.md`) ·
توثيق Antigravity <https://antigravity.google/docs> ·
توثيق Flutter لـ Antigravity <https://docs.flutter.dev/ai/antigravity>

*«قليلٌ دائم خيرٌ من كثيرٍ منقطع» — رواه البخاري ٦٤٦٤*
