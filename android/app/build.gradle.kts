plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    // 🔥 This plugin connects your google-services.json to the app
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.nutrix"
    compileSdk = 36 // Supports the latest Android 15/16 features
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.example.nutrix"

        // 🚀 CRITICAL FIX: Firestore & AI libs are heavy.
        // This line stops the "Infinite Loading" caused by method limits.
        multiDexEnabled = true

        // Camera and AI work best with minSdk 23
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Adds support for MultiDex on older Android devices
    implementation("androidx.multidex:multidex:2.0.1")
}
