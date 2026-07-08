plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.sgqrdemo.bankaapp"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures {
        resValues = true
    }

    defaultConfig {
        applicationId = "com.sgqrdemo.bankaapp"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        resValue("string", "app_name", "Bank A")
        // This app's custom URL scheme, e.g. bankademo://pay?token=xyz
        manifestPlaceholders["urlScheme"] = "bankademo"
        // Common host for the SGQR-style universal link. All three bank apps
        // register an *unverified* intent-filter for this same host, so
        // Android always shows the disambiguation dialog (app chooser)
        // instead of auto-opening a single "default" app. Change this to your
        // real deployed backend host before testing the chooser on a device.
        manifestPlaceholders["deepLinkHost"] = "example.com"
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
