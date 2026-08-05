import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Assinatura de RELEASE via `android/key.properties` — arquivo NUNCA
// versionado (ver .gitignore e `android/key.properties.example`).
//
// - Com `key.properties` presente: assinatura de PRODUÇÃO (upload keystore
//   + Play App Signing). O caminho do keystore em `storeFile` é relativo a
//   `android/app/`.
// - Sem o arquivo (CI ou dev): o build de release cai para a assinatura de
//   DEBUG — serve para testar, mas o APK NÃO é publicável na loja.
//
// Para gerar o keystore:
//   keytool -genkey -v -keystore upload-keystore.jks -alias upload \
//     -keyalg RSA -keysize 2048 -validity 10000
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.dumbhanengue.dumbhanengue"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: definir o Application ID definitivo antes de publicar
        // (ex.: br.com.<empresa>.dumbhanengue) — atualmente é um
        // placeholder (nome duplicado).
        applicationId = "com.dumbhanengue.dumbhanengue"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                // Erro claro se key.properties existir mas estiver incompleto.
                keyAlias = keystoreProperties["keyAlias"] as String?
                    ?: error("key.properties: 'keyAlias' ausente")
                keyPassword = keystoreProperties["keyPassword"] as String?
                    ?: error("key.properties: 'keyPassword' ausente")
                storeFile = file(
                    keystoreProperties["storeFile"] as String?
                        ?: error("key.properties: 'storeFile' ausente"),
                )
                storePassword = keystoreProperties["storePassword"] as String?
                    ?: error("key.properties: 'storePassword' ausente")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                // Fallback dev/CI — nunca publicar um APK assim.
                signingConfigs.getByName("debug")
            }
            // R8/minify seguem desativados (padrão do template Flutter).
            // Para reduzir o APK, habilite junto com as -keep rules das
            // libs (checklist 7.7):
            // isMinifyEnabled = true
            // isShrinkResources = true
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
