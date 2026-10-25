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

## ٣. مفتاح التوقيع (Android — الخطوة الحرجة!)

```bash
# مرة واحدة فقط — احفظ الملف في ٣ أماكن آمنة منفصلة
keytool -genkey -v -keystore ~/multazim-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias multazim -storetype JKS

cp deploy/android/key.properties.template android/key.properties
# ثم عدّله بمعلومات مفتاحك
```

> ⚠️ **حذف أو فقدان `multazim-keystore.jks` = استحالة تحديث تطبيقك على Play مستقبلاً.** احتفظ بـ ٣ نسخ (USB، سحابة خاصة، ورقة مشفرة).

---

## ٤. البناء والاختبار النهائي

```bash
# اختبار سريع على هاتفك
flutter run --release

# حزم الإصدار
flutter build apk --release                          # APK موحّد
flutter build apk --release --split-per-abi          # APKs أخفّ حسب المعمارية
flutter build appbundle --release                    # ⭐ المطلوب رسمياً لـ Google Play

# iOS (على Mac)
flutter build ios --release
# ثم: Xcode → Product → Archive → Distribute App → App Store Connect
```

**تجربة يدوية إلزامية قبل الرفع (١٥ دقيقة):**
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
