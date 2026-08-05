# Build and Release per Platform

> This guide covers how to **compile the app on each platform** (Android, iOS, Windows and Web) and the **requirements** for each one. For the initial project setup, environment variables and conventions, see the [Developer guide](10-developer-guide.md). For the pre-release checklist, see the [Production checklist](PRODUCTION_CHECKLIST.md).

---

## Global prerequisites

- **Flutter** (stable channel) with **Dart 3.12+** — `pubspec.yaml` requires `sdk: ^3.12.2`;
- Before any build, validate the environment:

```bash
flutter doctor -v
flutter pub get
```

- **App version:** `version: 1.0.0+1` in `pubspec.yaml` (applied automatically to `versionCode`/`versionName` on Android and `CFBundleVersion` on iOS).

> ⚠️ **SaaS vs. local mode:** the app uses the **embedded** Supabase credentials (`lib/core/config/supabase_config.dart`). To point a production build at another project, pass them via `--dart-define` (the anon key is public by design — real security comes from RLS; **never** embed the service role key):

```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ...
```

## Platform summary

| Platform | OS required to **build** | Main requirements | Release command | Generated artifact |
| -------- | ------------------------ | ----------------- | --------------- | ------------------ |
| **Android** | Windows, macOS, Linux | JDK 17 + Android SDK | `flutter build appbundle --release` | `app-release.aab` |
| **iOS** | **macOS** (mandatory) | Xcode + CocoaPods + Apple Developer account | `flutter build ios --release` | `Runner.app` (or `.ipa` via Xcode) |
| **Windows** | Windows 10/11 | Visual Studio 2022 (C++ workload) | `flutter build windows --release` | `dumbhanengue.exe` |
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
- Without the file (CI/dev) → the release build falls back to the **debug** keystore (not publishable).

### Commands

```bash
# Single APK (direct distribution / testing)
flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk

# Per-ABI APK (smaller, per architecture: armeabi-v7a, arm64-v8a, x86_64)
flutter build apk --split-per-abi

# AAB — the format required by Google Play
flutter build appbundle --release
# → build/app/outputs/bundle/release/app-release.aab

# Test on a device/emulator (debug, with hot reload)
flutter run
```

> R8/minify are **disabled** (Flutter template default). To shrink the APK, enable `isMinifyEnabled`/`isShrinkResources` together with the libraries' `-keep` rules (checklist 7.7). Before publishing, set the final **Application ID** in `android/app/build.gradle.kts` (currently a placeholder: `com.dumbhanengue.dumbhanengue`).

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

> ⚠️ `supabase_flutter` and `flutter_secure_storage` work on iOS without extra setup. Remember to declare the proper permissions in `Info.plist` if you ever add camera/location.

---

## Windows

### Requirements

- **Windows 10/11** with **Visual Studio 2022** — install the **"Desktop development with C++"** workload, which includes the toolchains required by Flutter.

### Commands

```bash
# Release build (native exe)
flutter build windows --release
# → build/windows/x64/runner/Release/dumbhanengue.exe

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

> ⚠️ **Web limitation:** native sqlite3 does not run in the browser (`dart:ffi` does not exist there). On this platform the app uses the **in-memory** datasources (same contracts — identical UI), and **SaaS (Supabase)** is the recommended production mode for the web. Secure storage on web is also weaker (the encryption key lives in `localStorage`).

---

## Linux and macOS (desktop)

The `linux/` and `macos/` folders have **not been created** in this project yet. To enable them:

```bash
flutter create --platforms=linux,macos .
```

Then run `flutter build linux --release` (requires GTK/clang) and `flutter build macos --release` (requires macOS + Xcode).

---

## CI (GitHub Actions)

The `.github/workflows/ci.yml` workflow already runs on every push/PR:

1. **analyze** — `flutter analyze` (zero errors/warnings);
2. **test** — `flutter test --coverage` + coverage summary;
3. **build** — `flutter build apk --release` (debug signing, since CI has no `key.properties`) and uploads the APK as an artifact;
4. **sql-check** — smoke test of `supabase/schema.sql` + RLS against a real Postgres.

To produce **publishable** artifacts in CI, decode the keystore from a secret (see `android/key.properties.example` and the [Developer guide](10-developer-guide.md#android-release-signing)).

---

## Quick checklist before publishing

- [ ] `flutter analyze` and `flutter test` green;
- [ ] `flutter doctor -v` with no critical issues for the target platform;
- [ ] **Android:** final Application ID + `key.properties` + AAB tested in Play Console (Internal testing);
- [ ] **iOS:** signing team in Xcode + archive tested on TestFlight;
- [ ] **Windows/Web:** local release build validated and artifact distributable;
- [ ] **SaaS:** `--dart-define` pointing to the production Supabase project;
- [ ] Review the [Production checklist](../pt/PRODUCTION_CHECKLIST.md) and the [Audit report](../pt/AUDIT_REPORT.md).
