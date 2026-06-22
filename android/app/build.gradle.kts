import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// قراءة المفتاح من android/local.properties (ملف غير مرفوع على GitHub —
// راجع .gitignore). لو الملف أو المفتاح غير موجود، نستخدم placeholder
// واضح بدل ما نفشل البناء بالكامل، عشان تقدر تكمل تطوير باقي الميزات
// من غير الحاجة لمفتاح فعلي.
val secretsProperties = Properties()
val secretsFile = rootProject.file("local.properties")
if (secretsFile.exists()) {
    secretsProperties.load(FileInputStream(secretsFile))
}
val mapsApiKey: String = secretsProperties.getProperty("MAPS_API_KEY") ?: "MISSING_MAPS_API_KEY"

android {
    namespace = "com.example.car"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
    jvmTarget = "1.8"
}

    defaultConfig {
        applicationId = "com.example.car"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["MAPS_API_KEY"] = mapsApiKey
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:1.2.2")
}