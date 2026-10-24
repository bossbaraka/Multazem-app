# قواعد الحماية — مُلتزم
# Flutter + حزم الإشعارات والصوت والموقع

-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# flutter_local_notifications + timezone
-keep class com.dexterous.** { *; }

# just_audio / audio_service
-keep class com.ryanheise.** { *; }

# adhan (مواقيت)
-keep class com.batoulapps.** { *; }

-dontwarn com.google.errorprone.annotations.Immutable
-dontwarn org.checkerframework.checker.nullness.qual.**
