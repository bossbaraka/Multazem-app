import os
import shutil
import json
from pathlib import Path

ROOT = Path(r"c:\Users\victus\Downloads\multazem\Multazem-app")

print(f"Scaffolding full release-ready platforms in {ROOT}...")

# ── 1. Android Directory Structure ──────────────────────────────────────────
android_dir = ROOT / "android"
app_dir = android_dir / "app"
src_main_dir = app_dir / "src" / "main"
kotlin_dir = src_main_dir / "kotlin" / "com" / "multazim" / "app"
res_dir = src_main_dir / "res"
raw_dir = res_dir / "raw"
drawable_dir = res_dir / "drawable"
drawable_v21_dir = res_dir / "drawable-v21"
values_dir = res_dir / "values"

for d in [android_dir, app_dir, src_main_dir, kotlin_dir, res_dir, raw_dir, drawable_dir, drawable_v21_dir, values_dir]:
    d.mkdir(parents=True, exist_ok=True)

# 1.1 android/settings.gradle.kts
settings_gradle_kts = """pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").takeIf { it.exists() }?.inputStream()?.use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        assert(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.3.2" apply false
    id("org.jetbrains.kotlin.android") version "1.9.24" apply false
}

include(":app")
"""
(android_dir / "settings.gradle.kts").write_text(settings_gradle_kts, encoding="utf-8")

# 1.2 android/build.gradle.kts
build_gradle_kts = """allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
"""
(android_dir / "build.gradle.kts").write_text(build_gradle_kts, encoding="utf-8")

# 1.3 android/gradle.properties
gradle_properties = """org.gradle.jvmargs=-Xmx4G -XX:MaxMetaspaceSize=1G -XX:+HeapDumpOnOutOfMemoryError
android.useAndroidX=true
android.enableJetifier=true
"""
(android_dir / "gradle.properties").write_text(gradle_properties, encoding="utf-8")

# 1.4 android/app/build.gradle.kts
app_build_gradle_kts = """plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = java.util.Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(java.io.FileInputStream(keystorePropertiesFile))
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
            keyAlias = keystoreProperties["keyAlias"] as String? ?: ""
            keyPassword = keystoreProperties["keyPassword"] as String? ?: ""
            storeFile = keystoreProperties["storeFile"]?.let { file(it as String) }
            storePassword = keystoreProperties["storePassword"] as String? ?: ""
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists())
                signingConfigs.getByName("release")
            else
                signingConfigs.getByName("debug")

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
"""
(app_dir / "build.gradle.kts").write_text(app_build_gradle_kts, encoding="utf-8")

# 1.5 MainActivity.kt
main_activity_kt = """package com.multazim.app

import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity()
"""
(kotlin_dir / "MainActivity.kt").write_text(main_activity_kt, encoding="utf-8")

# 1.6 Copy AndroidManifest.xml from deploy/
shutil.copy2(ROOT / "deploy" / "android" / "app" / "src" / "main" / "AndroidManifest.xml", src_main_dir / "AndroidManifest.xml")

# 1.7 Copy ProGuard rules from deploy/
shutil.copy2(ROOT / "deploy" / "android" / "app" / "proguard-rules.pro", app_dir / "proguard-rules.pro")

# 1.8 Copy key.properties.template
shutil.copy2(ROOT / "deploy" / "android" / "key.properties.template", android_dir / "key.properties.template")

# 1.9 Copy icons from deploy/icons/android/res/* to android/app/src/main/res/
icons_src = ROOT / "deploy" / "icons" / "android" / "res"
for item in icons_src.iterdir():
    dest = res_dir / item.name
    if item.is_dir():
        if dest.exists():
            shutil.rmtree(dest)
        shutil.copytree(item, dest)
    else:
        shutil.copy2(item, dest)

# 1.10 Copy sound files from assets/sounds/ to android/app/src/main/res/raw/
sounds_src = ROOT / "assets" / "sounds"
for s in sounds_src.glob("*.mp3"):
    shutil.copy2(s, raw_dir / s.name)

# 1.11 styles.xml and launch backgrounds
styles_xml = """<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="LaunchTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowBackground">@drawable/launch_background</item>
    </style>
    <style name="NormalTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowBackground">?android:colorBackground</item>
    </style>
</resources>
"""
(values_dir / "styles.xml").write_text(styles_xml, encoding="utf-8")

colors_xml = """<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#0B5D3B</color>
    <color name="emerald">#0B5D3B</color>
</resources>
"""
(values_dir / "colors.xml").write_text(colors_xml, encoding="utf-8")

launch_bg_xml = """<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@color/emerald" />
    <item>
        <bitmap
            android:gravity="center"
            android:src="@mipmap/ic_launcher" />
    </item>
</layer-list>
"""
(drawable_dir / "launch_background.xml").write_text(launch_bg_xml, encoding="utf-8")
(drawable_v21_dir / "launch_background.xml").write_text(launch_bg_xml, encoding="utf-8")

print("Android scaffold complete.")

# ── 2. iOS Directory Structure ──────────────────────────────────────────────
ios_dir = ROOT / "ios"
runner_dir = ios_dir / "Runner"
assets_xcassets_dir = runner_dir / "Assets.xcassets"
app_icon_dir = assets_xcassets_dir / "AppIcon.appiconset"
launch_img_dir = assets_xcassets_dir / "LaunchImage.imageset"
base_lproj_dir = runner_dir / "Base.lproj"

for d in [ios_dir, runner_dir, assets_xcassets_dir, app_icon_dir, launch_img_dir, base_lproj_dir]:
    d.mkdir(parents=True, exist_ok=True)

# 2.1 ios/Runner/Info.plist
info_plist = """<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>$(DEVELOPMENT_LANGUAGE)</string>
	<key>CFBundleDisplayName</key>
	<string>مُلتزم</string>
	<key>CFBundleExecutable</key>
	<string>$(EXECUTABLE_NAME)</string>
	<key>CFBundleIdentifier</key>
	<string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>multazim</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>$(FLUTTER_BUILD_NAME)</string>
	<key>CFBundleSignature</key>
	<string>????</string>
	<key>CFBundleVersion</key>
	<string>$(FLUTTER_BUILD_NUMBER)</string>
	<key>LSRequiresIPhoneOS</key>
	<true/>
	<key>UILaunchStoryboardName</key>
	<string>LaunchScreen</string>
	<key>UIMainStoryboardFile</key>
	<string>Main</string>
	<key>UISupportedInterfaceOrientations</key>
	<array>
		<string>UIInterfaceOrientationPortrait</string>
		<string>UIInterfaceOrientationLandscapeLeft</string>
		<string>UIInterfaceOrientationLandscapeRight</string>
	</array>
	<key>UISupportedInterfaceOrientations~ipad</key>
	<array>
		<string>UIInterfaceOrientationPortrait</string>
		<string>UIInterfaceOrientationPortraitUpsideDown</string>
		<string>UIInterfaceOrientationLandscapeLeft</string>
		<string>UIInterfaceOrientationLandscapeRight</string>
	</array>
	<key>CADisableMinimumFrameDurationOnPhone</key>
	<true/>
	<key>UIApplicationSupportsIndirectInputEvents</key>
	<true/>
	<key>NSLocationWhenInUseUsageDescription</key>
	<string>نستخدم موقعك لحساب مواقيت الصلاة واتجاه القبلة بدقة، ويبقى موقعك على جهازك فقط.</string>
	<key>NSUserNotificationsUsageDescription</key>
	<string>نحتاج إذن الإشعارات لصلاة الأذان والتذكيرات الدينية في وقتها.</string>
	<key>UIBackgroundModes</key>
	<array>
		<string>audio</string>
		<string>fetch</string>
	</array>
	<key>CFBundleLocalizations</key>
	<array>
		<string>ar</string>
		<string>en</string>
	</array>
</dict>
</plist>
"""
(runner_dir / "Info.plist").write_text(info_plist, encoding="utf-8")

# 2.2 AppDelegate.swift
app_delegate_swift = """import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
"""
(runner_dir / "AppDelegate.swift").write_text(app_delegate_swift, encoding="utf-8")

# 2.3 ios/Podfile
podfile = """# Uncomment this line to define a global platform for your project
platform :ios, '13.0'

# CocoaPods analytics sends network stats synchronously affecting flutter build latency.
ENV['COCOAPODS_DISABLE_STATS'] = 'true'

project 'Runner', {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}

def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'Generated.xcconfig'), __FILE__)
  unless File.exist?(generated_xcode_build_settings_path)
    raise "#{generated_xcode_build_settings_path} must exist. If you're running pod install manually, make sure flutter pub get is executed first"
  end

  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/FLUTTER_ROOT\\=(.*)/)
    return matches[1].strip if matches
  end
  raise "FLUTTER_ROOT not found in #{generated_xcode_build_settings_path}. Try deleting Generated.xcconfig, then run flutter pub get"
end

require File.expand_path(File.join('packages', 'flutter_tools', 'bin', 'podhelper'), flutter_root)

flutter_ios_podfile_setup

target 'Runner' do
  use_frameworks!
  use_modular_headers!

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
  target 'RunnerTests' do
    inherit! :search_paths
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'PERMISSION_LOCATION=1',
        'PERMISSION_NOTIFICATIONS=1'
      ]
    end
  end
end
"""
(ios_dir / "Podfile").write_text(podfile, encoding="utf-8")

# 2.4 Copy iOS Icons and create Contents.json
ios_icons_src = ROOT / "deploy" / "icons" / "ios"
for icon in ios_icons_src.glob("*.png"):
    shutil.copy2(icon, app_icon_dir / icon.name)

contents_json = {
  "images": [
    { "size": "20x20", "idiom": "iphone", "filename": "Icon-App-40.png", "scale": "2x" },
    { "size": "20x20", "idiom": "iphone", "filename": "Icon-App-60.png", "scale": "3x" },
    { "size": "29x29", "idiom": "iphone", "filename": "Icon-App-58.png", "scale": "2x" },
    { "size": "29x29", "idiom": "iphone", "filename": "Icon-App-87.png", "scale": "3x" },
    { "size": "40x40", "idiom": "iphone", "filename": "Icon-App-80.png", "scale": "2x" },
    { "size": "40x40", "idiom": "iphone", "filename": "Icon-App-120.png", "scale": "3x" },
    { "size": "60x60", "idiom": "iphone", "filename": "Icon-App-120.png", "scale": "2x" },
    { "size": "60x60", "idiom": "iphone", "filename": "Icon-App-180.png", "scale": "3x" },
    { "size": "20x20", "idiom": "ipad", "filename": "Icon-App-20.png", "scale": "1x" },
    { "size": "20x20", "idiom": "ipad", "filename": "Icon-App-40.png", "scale": "2x" },
    { "size": "29x29", "idiom": "ipad", "filename": "Icon-App-29.png", "scale": "1x" },
    { "size": "29x29", "idiom": "ipad", "filename": "Icon-App-58.png", "scale": "2x" },
    { "size": "40x40", "idiom": "ipad", "filename": "Icon-App-40.png", "scale": "1x" },
    { "size": "40x40", "idiom": "ipad", "filename": "Icon-App-80.png", "scale": "2x" },
    { "size": "76x76", "idiom": "ipad", "filename": "Icon-App-76.png", "scale": "1x" },
    { "size": "76x76", "idiom": "ipad", "filename": "Icon-App-152.png", "scale": "2x" },
    { "size": "83.5x83.5", "idiom": "ipad", "filename": "Icon-App-167.png", "scale": "2x" },
    { "size": "1024x1024", "idiom": "ios-marketing", "filename": "Icon-App-1024.png", "scale": "1x" }
  ],
  "info": { "version": 1, "author": "xcode" }
}
(app_icon_dir / "Contents.json").write_text(json.dumps(contents_json, indent=2), encoding="utf-8")

print("iOS scaffold complete.")

# ── 3. GitHub Actions CI for Cloud APK/AAB Builds ───────────────────────────
workflows_dir = ROOT / ".github" / "workflows"
workflows_dir.mkdir(parents=True, exist_ok=True)

github_ci = """name: Build Multazim Release APK & Bundle

on:
  push:
    branches: [ main, master ]
  pull_request:
    branches: [ main, master ]
  workflow_dispatch:

jobs:
  build:
    name: Build Android Release
    runs-on: ubuntu-latest

    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Setup Java 17
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '17'

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.27.4'
          channel: 'stable'
          cache: true

      - name: Flutter Doctor
        run: flutter doctor -v

      - name: Install Dependencies
        run: flutter pub get

      - name: Verify Code Quality (Analyze)
        run: flutter analyze

      - name: Build APK (Release & Split ABI)
        run: |
          flutter build apk --release
          flutter build apk --release --split-per-abi

      - name: Build App Bundle (Google Play AAB)
        run: flutter build appbundle --release

      - name: Upload Release APKs
        uses: actions/upload-artifact@v4
        with:
          name: multazim-release-apks
          path: build/app/outputs/flutter-apk/*.apk

      - name: Upload Google Play AAB Bundle
        uses: actions/upload-artifact@v4
        with:
          name: multazim-google-play-bundle
          path: build/app/outputs/bundle/release/*.aab
"""
(workflows_dir / "build-apk.yml").write_text(github_ci, encoding="utf-8")

print("GitHub Actions workflow created.")
print("DONE! Platform scaffold, icons, sounds, desugaring, and CI are 100% prepared.")
