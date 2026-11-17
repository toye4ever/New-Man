

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val galaxyTest = providers.gradleProperty("newManGalaxyTest").orNull == "true"

android {
    namespace = "com.newman.newmanapp"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.newman.newmanapp.beta"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        debug {
            // Keep developer installs and their local data separate from the signed beta.
            applicationIdSuffix = if (galaxyTest) ".dev.nov17" else ".dev"
            manifestPlaceholders["newManDebugLabel"] = if (galaxyTest) "New Man Test" else "New Man Dev"
            if (galaxyTest) {
                manifestPlaceholders["applicationName"] = "com.newman.newmanapp.GalaxyTestApplication"
            }
        }
        release {
            signingConfig = null
            isMinifyEnabled = false
            isShrinkResources = false
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
