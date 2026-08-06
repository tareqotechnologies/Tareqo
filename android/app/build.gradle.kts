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
// - Sem o arquivo (CI/dev): o build de release cai para a assinatura de
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
        // Application ID de PRODUÇÃO (flavor prod). O flavor `dev` recebe o
        // sufixo `.dev` — os dois podem coexistir no mesmo dispositivo.
        // ⚠️ O package de produção é imutável após o primeiro upload ao Play
        // Console (a Play associa o app ao applicationId).
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
                // Fallback dev/CI — nunca publicar um APK assim. O guarda
                // abaixo (prodRelease) impede que PRODUÇÃO seja assinada
                // assim.
                signingConfigs.getByName("debug")
            }
            // R8/minify ativos (auditoria S7): reduz o APK e dificulta a
            // engenharia reversa do bytecode Android. O código Dart só é
            // ofuscado com `flutter build --obfuscate
            // --split-debug-info=build/symbols` (ver docs de release).
            isMinifyEnabled = true
            isShrinkResources = true
        }
    }

    // Flavors de ambiente (auditoria 2.4 — configuração por ambiente):
    //   dev  → applicationId `com.dumbhanengue.dumbhanengue.dev`, label
    //          "Dumbhanengue Dev"; nunca publicável no Play.
    //   prod → applicationId de produção `com.dumbhanengue.dumbhanengue`.
    // Os dart-defines obrigatórios (SUPABASE_URL, SUPABASE_ANON_KEY,
    // FLUTTER_APP_FLAVOR) são fornecidos via --dart-define-from-file
    // (env/dev.env e env/prod.env) ou --dart-define no build.
    flavorDimensions += "env"
    productFlavors {
        create("dev") {
            dimension = "env"
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
        }
        create("prod") {
            dimension = "env"
        }
    }
}

// Guarda de produção (auditoria 2.4/S7): um build de PROD em RELEASE SEM o
// keystore de produção deve FALHAR na configuração do Gradle — nunca deixar
// um AAB de produção ser assinado com o keystore de debug (a Play rejeita).
// Detectamos a variante pedida pelo nome da task Gradle
// (bundleProdRelease / assembleProdRelease).
// Nota: com taskNames vazio (ex.: sync do IDE) a guarda não dispara — o
// keystore é exigido de facto pelos comandos de build de produção.
val buildingProdRelease = gradle.startParameter.taskNames.any { task ->
    task.contains("ProdRelease")
}
if (buildingProdRelease && !hasReleaseKeystore) {
    throw GradleException(
        "Build de PRODUÇÃO exige assinatura de release: crie android/key.properties " +
            "a partir de android/key.properties.example (ver docs/13-build-e-publicacao.md " +
            "e o Guia do desenvolvedor). No CI, o workflow release.yml descodifica o " +
            "keystore do secret KEYSTORE_BASE64 antes do build.",
    )
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
