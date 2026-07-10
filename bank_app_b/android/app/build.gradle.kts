import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Shared release keystore for all 3 bank apps — see keystore.properties at the
// repo root (gitignored). Real Android App Link verification checks the
// actual signing certificate fingerprint, so this can't be debug-signed.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("../../keystore.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.sgqrdemo.bankbapp"
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
        applicationId = "com.sgqrdemo.bankbapp"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        resValue("string", "app_name", "Bank B")
        // This app's custom URL scheme, e.g. bankbdemo://pay?token=xyz
        manifestPlaceholders["urlScheme"] = "bankbdemo"
        // Common host for the SGQR-style universal link. All three bank apps
        // declare a *verified* intent-filter (autoVerify="true") for this
        // same host — Android checks each app's real signing certificate
        // against /.well-known/assetlinks.json on this host, and since all 3
        // verify successfully, it shows the native chooser directly on the
        // link tap with no browser interstitial. Change this to your real
        // deployed backend host if it ever moves.
        manifestPlaceholders["deepLinkHost"] = "sgqr-deep-link-demo.onrender.com"
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
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
