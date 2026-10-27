# قواعد الحماية — مُلتزم
# Flutter + حزم الإشعارات والصوت والموقع

# Flutter supplies its own embedding/plugin rules via the Gradle plugin.
# Do not keep io.flutter.** wholesale: this retains unused Play Store deferred
# component classes and makes R8 require Play Core in standalone APK builds.

# flutter_local_notifications + timezone
-keep class com.dexterous.** { *; }

# just_audio / audio_service
-keep class com.ryanheise.** { *; }

# adhan (مواقيت)
-keep class com.batoulapps.** { *; }

-dontwarn com.google.errorprone.annotations.Immutable
-dontwarn org.checkerframework.checker.nullness.qual.**
