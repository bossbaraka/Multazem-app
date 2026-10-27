import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ─────────────────────────────────────────────────────────────────────────────
// توقيع الإصدار (اختياري)
//
// ⚠ سطرا الـ import أعلاه إلزاميان ولا يجوز حذفهما:
// داخل سكربت تطبيق أندرويد الاسم `java` محجوز لـ«extension» الخاص بإضافة جافا
// (JavaPluginExtension) وليس للحزمة `java`. لذلك كتابة الاسم الكامل
// `java.util.Properties()` هنا تفشل بثلاثة أخطاء ترجمة للسكربت:
//     Unresolved reference: util
//     Unresolved reference: io
//     Expression expected, but a package name found   ← على سطر storeFile
// (في android/settings.gradle.kts لا توجد هذه الإضافة، لذا الاسم الكامل يعمل هناك.)
//
// • وُجد android/key.properties + ملف المخزن ⇒ توقيع release بمفتاحك (للمتاجر).
// • لم يوجد ⇒ توقيع debug تلقائياً، وهو كافٍ للتثبيت الشخصي على جهازك.
// ─────────────────────────────────────────────────────────────────────────────
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// مسار المخزن نسبيّاً إلى android/app/ (مثال: ../multazim-keystore.jks).
// نتحقّق من وجود الملف فعلاً حتى لا يفشل البناء برسالة توقيع غامضة.
val keystorePath: String = keystoreProperties.getProperty("storeFile")?.trim().orEmpty()
val keystoreFile = if (keystorePath.isEmpty()) {
    null
} else {
    file(keystorePath).takeIf { candidate -> candidate.isFile }
}

if (keystorePropertiesFile.exists() && keystoreFile == null) {
    logger.warn(
        "مُلتزم: android/key.properties موجود لكن تعذّر العثور على مخزن المفاتيح " +
            "«$keystorePath» ⇒ سيُستخدم توقيع debug بدلاً من release."
    )
}

android {
    namespace = "com.multazim.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.multazim.app"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            // getProperty تعيد String? مباشرةً — بلا `as String` ولا `it as String`.
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storeFile = keystoreFile
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystoreFile != null) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }

            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
