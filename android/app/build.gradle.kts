import java.util.Properties
import java.io.FileInputStream
import com.android.build.api.dsl.ApplicationExtension

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    id("com.google.firebase.firebase-perf")
    id("kotlin-kapt")
}

val keystoreProperties = Properties().apply {
    val keystorePropertiesFile = rootProject.file("key.properties")
    if (keystorePropertiesFile.exists()) {
        load(FileInputStream(keystorePropertiesFile))
    }
}

val hasReleaseKeystore = rootProject.file("key.properties").exists() &&
    keystoreProperties.getProperty("storeFile")?.isNotBlank() == true

android {
    namespace = "com.example.faso_style"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.faso_style"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"
        multiDexEnabled = true

        // Résolution des conflits de version pour les dépendances critiques
        configurations.all {
            resolutionStrategy {
                force("androidx.camera:camera-core:1.3.1")
                force("androidx.camera:camera-camera2:1.3.1")
                force("androidx.camera:camera-lifecycle:1.3.1")
                force("androidx.camera:camera-video:1.3.1")
                force("androidx.core:core-ktx:1.12.0")
                force("org.jetbrains.kotlin:kotlin-stdlib:1.9.20")
                force("com.google.android.gms:play-services-basement:18.3.0")
            }
        }
    }

    signingConfigs {
        create("release") {
            if (hasReleaseKeystore) {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
            enableV1Signing = true
            enableV2Signing = true
        }
        getByName("debug") {
            val localDebugKeystore = file("${projectDir}/my-release-key.jks")
            if (localDebugKeystore.exists()) {
                storeFile = localDebugKeystore
                storePassword = "14209575"
                keyAlias = "elegantfaso"
                keyPassword = "14209575"
            }
            enableV1Signing = true
            enableV2Signing = true
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            isDebuggable = false
            isZipAlignEnabled = true
        }
        getByName("debug") {
            signingConfig = signingConfigs.getByName("debug")
            isDebuggable = true
            versionNameSuffix = "-debug"
            // Désactivation de la minification pour le debug
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    packaging {
        resources {
            pickFirsts += listOf(
                "**/libc++_shared.so",
                "**/libjsc.so"
            )
            // Exclusion des fichiers inutiles
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }

    lint {
        checkReleaseBuilds = false
        abortOnError = false
    }

    // Optimisation pour les builds
    buildFeatures {
        buildConfig = true
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Desugaring pour les nouvelles APIs Java
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("androidx.multidex:multidex:2.0.1")

    // Firebase BOM (Bill of Materials) avec version stable
    implementation(platform("com.google.firebase:firebase-bom:33.0.0"))

    // Dépendances Firebase (versions gérées par le BOM)
    implementation("com.google.firebase:firebase-analytics-ktx")
    implementation("com.google.firebase:firebase-auth-ktx")
    implementation("com.google.firebase:firebase-messaging-ktx")
    implementation("com.google.firebase:firebase-common-ktx")

    // AndroidX Core
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.work:work-runtime-ktx:2.9.0")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.6.2")
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("androidx.activity:activity-ktx:1.8.2")

    // CameraX
    implementation("androidx.camera:camera-core:1.3.1")
    implementation("androidx.camera:camera-camera2:1.3.1")
    implementation("androidx.camera:camera-lifecycle:1.3.1")

    // Kotlin
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.7.3")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8:1.9.20")

    // Autres dépendances
    implementation("com.google.guava:guava:31.0.1-android")
    implementation("org.reactivestreams:reactive-streams:1.0.4")
}
