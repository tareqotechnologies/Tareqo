# Build and Release per Platform

> This guide covers how to **compile the app on each platform** (Android, iOS, Windows and Web) and the **requirements** for each one. For the initial project setup, environment variables and conventions, see the [Developer guide](10-developer-guide.md). For the pre-release checklist, see the [Production checklist](../pt/PRODUCTION_CHECKLIST.md).

---

## Global prerequisites

- **Flutter** (stable channel) with **Dart 3.12+** — `pubspec.yaml` requires `sdk: ^3.12.2`;
- Before any build, validate the environment:

```bash
flutter doctor -v
flutter pub get
```

- **App version:** `version: 1.1.0+2` in `pubspec.yaml` (applied automatically to `versionCode`/`versionName` on Android and `CFBundleVersion` on iOS).

> **Warning:** **SaaS vs. local mode (flavors dev/prod):** credentials are supplied via `--dart-define-from-file` — `env/dev.env` (committed, dev project) and `env/prod.env` (**never** versioned; model in `env/prod.env.example`). `FLUTTER_APP_FLAVOR` is a **reserved define** injected from `--flavor`. A **release** build without `--flavor prod` **throws at startup** (`main.dart` fail-fast); additionally `SupabaseBootstrap` throws in a NON-prod release with the embedded dev defaults (fail-fast S2 — **adjusted Aug 9**: the deployment uses a SINGLE Supabase project `dotklbpqmlnhcdifiukd` shared by dev/prod, so a `prod` release with the project's own credentials is legitimate); the Gradle config also **fails `prodRelease` without `android/key.properties`**. The anon key is public by design — real security comes from RLS; **never** embed the service role key:

```bash
# Development (debug/hot reload)
flutter run --flavor dev --dart-define-from-file=env/dev.env

# Production (release)
flutter build appbundle --flavor prod --release \
 --dart-define-from-file=env/prod.env
```

## Platform summary

| Platform | OS required to **build** | Main requirements | Release command | Generated artifact |
| -------- | ------------------------ | ----------------- | --------------- | ------------------ |
| **Android** | Windows, macOS, Linux | JDK 17 + Android SDK + `key.properties` | `flutter build appbundle --flavor prod --release --dart-define-from-file=env/prod.env` | `app-prod-release.aab` |
| **iOS** | **macOS** (mandatory) | Xcode + CocoaPods + Apple Developer account | `flutter build ios --release` | `Runner.app` (or `.ipa` via Xcode) |
| **Windows** | Windows 10/11 | Visual Studio 2022 (C++ workload) | `flutter build windows --release` | `tareqo.exe` |
| **Web** | Any OS | A browser (for testing) | `flutter build web --release` | `build/web/` (static site) |

---

## Android

### Requirements

- **JDK 17** (`build.gradle.kts` uses `JavaVersion.VERSION_17` — CI uses Temurin 17);
- **Android SDK** (installed by Android Studio); `compileSdk`, `minSdk` and `targetSdk` follow the Flutter defaults (`flutter.compileSdkVersion`, etc.);
- To publish: a **signing keystore** (see below) and a **Google Play Console** developer account (one-time US$ 25 fee).

### Release signing

Release signing reads `android/key.properties` (never versioned — see `android/key.properties.example` and the [Developer guide](10-developer-guide.md#android-release-signing)):

- With `key.properties` present → **production** signing (upload keystore + Play App Signing);
- Without the file (CI/dev) → the release build falls back to the **debug** keystore (not publishable);
- **Gradle guard (Aug 5):** a `prodRelease` build **fails at configuration time** without `key.properties` — a production AAB can never be debug-signed. The CI build (`ci.yml`) therefore uses the **dev** flavor (`com.tareqo.tareqo.dev`) purely as a compile validation.

### Commands

```bash
# ── Flavors ────────────────────────────────────────────────────────────
# dev → applicationId com.tareqo.tareqo.dev, label "Dev"
# prod → production applicationId com.tareqo.tareqo

# Dev APK (direct distribution / testing)
flutter build apk --release --flavor dev --dart-define-from-file=env/dev.env
# → build/app/outputs/flutter-apk/app-dev-release.apk

# PROD AAB — the format required by Google Play
flutter build appbundle --flavor prod --release \
 --dart-define-from-file=env/prod.env
# → build/app/outputs/bundle/prodRelease/app-prod-release.aab

# PROD AAB with Dart obfuscation (recommended before publishing)
flutter build appbundle --flavor prod --release \
 --dart-define-from-file=env/prod.env \
 --obfuscate --split-debug-info=build/symbols

# Test on a device/emulator (debug, with hot reload)
flutter run --flavor dev --dart-define-from-file=env/dev.env
```

> **R8/minify are ENABLED** (`isMinifyEnabled`/`isShrinkResources`, Aug 5) — the Dart code can additionally be obfuscated with `--obfuscate --split-debug-info` (upload the symbols to Sentry: `sentry-cli debug-files upload`). The prod flavor keeps the immutable `applicationId com.tareqo.tareqo`; the dev flavor has the `.dev` suffix so both can coexist on one device.

#### Known build warning (sentry_flutter + KGP) — tracked upstream

> **Warning:** **Aug 8:** Flutter 3.44+ with AGP 9+ prints a **warning** while configuring Gradle for ANY Android build (dev or prod):
>
> ```
> WARNING: Your app uses the following plugins that apply Kotlin Gradle Plugin (KGP): sentry_flutter
> Future versions of Flutter will fail to build if your app uses plugins that apply KGP.
> ```
>
> - **Benign today** — it is only an informational warning; the build completes normally (verified on `assembleDevRelease`). Only **future** Flutter versions will fail on this.
> - **Cause:** `sentry_flutter`'s `android/build.gradle` applies `kotlin-android` (KGP) unconditionally, and Flutter's tooling flags such plugins when AGP ≥ 9 (this project uses 9.3.1). There is **no** published version that fixes it (9.26.0, `10.0.0-alpha.3` and sentry-dart `main` still apply KGP) and no suppression flag in Flutter 3.44.
> - **Upstream tracking:** **getsentry/sentry-dart#3738** (DART-382) — the plugin's migration to Built-in Kotlin is targeted for the **v10 stable (~end of Aug/mid-Sep 2026)**, blocked on the `jni` package (dart-lang/native#3415).
> - **Action when v10 ships:** bump `sentry_flutter` to `^10.0.0` in `pubspec.yaml` — the warning disappears on its own.

---

## iOS

### Requirements

- **macOS** with **Xcode** (iOS builds are only possible on macOS);
- **CocoaPods** (or Xcode's native package manager) — the `Podfile` is generated automatically on the first build;
- **Apple Developer account** (US$ 99/year) with a **distribution certificate** and **provisioning profile**;
- Minimum deployment target: **iOS 13.0** (`IPHONEOS_DEPLOYMENT_TARGET`).

### Commands

```bash
# Release build with signing (requires account/certificate configured in Xcode)
flutter build ios --release

# LOCAL build without signing (testing, no developer account)
flutter build ios --release --no-codesign
# → build/ios/iphoneos/Runner.app

# Run on simulator/device (debug)
flutter run
```

### App Store publishing

1. Open `ios/Runner.xcworkspace` in Xcode;
2. Select the signing **team** under *Signing & Capabilities*;
3. **Product → Archive**, then upload via **App Store Connect** (Transporter or *Distribute App*);
4. Configure the app in App Store Connect (metadata, privacy, screenshots) and submit for review.

> **Warning:** `supabase_flutter` and `flutter_secure_storage` work on iOS without extra setup. Remember to declare the proper permissions in `Info.plist` if you ever add camera/location.

---

## Windows

### Requirements

- **Windows 10/11** with **Visual Studio 2022** — install the **"Desktop development with C++"** workload, which includes the toolchains required by Flutter.

### Commands

```bash
# Release build (native exe)
flutter build windows --release
# → build/windows/x64/runner/Release/tareqo.exe

# Run in debug mode with hot reload
flutter run -d windows
```

The generated executable depends on the DLLs in the `Release` folder — distribute the **whole folder** (or package it with MSIX via the `msix` tool / Visual Studio's "Add App Package" for the Microsoft Store).

---

## Web

### Requirements

- Any OS (the build runs on pure Dart — no native toolchain);
- A browser for testing (`flutter run -d chrome`).

### Commands

```bash
# Production build (static site ready to deploy)
flutter build web --release
# → build/web/

# Dev mode with hot reload
flutter run -d chrome

# (Optional) WebAssembly build — see the `flutter build web` warnings
flutter build web --release --wasm
```

### Deploy

`build/web/` is a **static site**: host it on any server/CDN (Firebase Hosting, Vercel, Netlify, GitHub Pages, nginx...). Configure a fallback to `index.html` (SPA) if you use routes.

> **Warning:** **Web limitation:** native sqlite3 does not run in the browser (`dart:ffi` does not exist there). On this platform the app uses the **in-memory** datasources (same contracts — identical UI), and **SaaS (Supabase)** is the recommended production mode for the web. Secure storage on web is also weaker (the encryption key lives in `localStorage`).

---

## Linux and macOS (desktop)

The `linux/` and `macos/` folders have **not been created** in this project yet. To enable them:

```bash
flutter create --platforms=linux,macos .
```

Then run `flutter build linux --release` (requires GTK/clang) and `flutter build macos --release` (requires macOS + Xcode).

---

## CI/CD (GitHub Actions)

**`.github/workflows/ci.yml`** (every push/PR):

1. **analyze** — `flutter analyze` (zero errors/warnings);
2. **test** — `flutter test --coverage` + **45% coverage gate**;
3. **build** — `flutter build apk --release --flavor dev --dart-define-from-file=env/dev.env` (dev-only, compile validation — debug signing) + APK artifact;
4. **sql-check** — `scripts/sql_check.sh` against a real Postgres 16 service (schema apply + super admin + RLS by store + **atomic RPC execution**).

**`.github/workflows/release.yml`** (tag `v*` — publishable AAB): runs analyze + test, then **Fastlane** (`fastlane/Fastfile`, lane `deploy`):

1. validates the production defines/secrets (fail-fast);
2. decodes the upload keystore from `KEYSTORE_BASE64` and writes `android/key.properties`;
3. builds the **prod AAB** (`--flavor prod --release --obfuscate --split-debug-info=build/symbols`);
4. uploads to the **Internal testing** track via the service account from `PLAY_SERVICE_ACCOUNT_JSON`.

> Secrets required: `SUPABASE_URL_PROD`, `SUPABASE_ANON_KEY_PROD`, `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `PLAY_SERVICE_ACCOUNT_JSON` (+ optional `SENTRY_DSN`). Full setup: `docs/pt/13-build-e-publicacao.md`.

---

## Quick checklist before publishing

- [ ] `flutter analyze` and `flutter test` green;
- [ ] `flutter doctor -v` with no critical issues for the target platform;
- [ ] **Android:** final Application ID + `key.properties` + AAB tested in Play Console (Internal testing);
- [ ] **iOS:** signing team in Xcode + archive tested on TestFlight;
- [ ] **Windows/Web:** local release build validated and artifact distributable;
- [ ] **SaaS:** prod flavor + `env/prod.env` pointing to the production Supabase project;
- [ ] Review the [Production checklist](../pt/PRODUCTION_CHECKLIST.md) and the [Audit report](../pt/AUDIT_REPORT.md).
