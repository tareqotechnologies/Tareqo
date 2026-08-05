# Build e Publicação por Plataforma

> Este guia cobre como **compilar o app em cada plataforma** (Android, iOS, Windows e Web) e os **requisitos** de cada uma. Para o setup inicial do projeto, variáveis de ambiente e convenções, veja o [Guia do desenvolvedor](10-guia-desenvolvedor.md). Para a lista de verificação antes de publicar, veja o [Checklist de produção](PRODUCTION_CHECKLIST.md).

---

## Pré-requisitos globais

- **Flutter** (canal `stable`) com **Dart 3.12+** — o `pubspec.yaml` exige `sdk: ^3.12.2`;
- Antes de qualquer build, valide o ambiente:

```bash
flutter doctor -v
flutter pub get
```

- **Versão do app:** `version: 1.0.0+1` em `pubspec.yaml` (aplicada automaticamente ao `versionCode`/`versionName` no Android e ao CFBundleVersion no iOS).

> ⚠️ **Modo SaaS vs. local:** o app usa as credenciais do Supabase **embutidas** (`lib/core/config/supabase_config.dart`). Para apontar o build de produção para outro projeto, passe via `--dart-define` (a anon key é pública por design — a segurança real vem do RLS; **nunca** embuta a service role key):

```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://seu-projeto.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ...
```

## Resumo por plataforma

| Plataforma | SO para **buildar** | Requisitos principais | Comando de release | Artefato gerado |
| ---------- | ------------------- | --------------------- | ------------------ | --------------- |
| **Android** | Windows, macOS, Linux | JDK 17 + Android SDK | `flutter build appbundle --release` | `app-release.aab` |
| **iOS** | **macOS** (obrigatório) | Xcode + CocoaPods + conta Apple Developer | `flutter build ios --release` | `Runner.app` (ou `.ipa` via Xcode) |
| **Windows** | Windows 10/11 | Visual Studio 2022 (workload C++) | `flutter build windows --release` | `dumbhanengue.exe` |
| **Web** | Qualquer SO | Navegador (para testar) | `flutter build web --release` | `build/web/` (site estático) |

---

## Android

### Requisitos

- **JDK 17** (o `build.gradle.kts` usa `JavaVersion.VERSION_17` — o CI usa Temurin 17);
- **Android SDK** (instalado pelo Android Studio); `compileSdk`, `minSdk` e `targetSdk` seguem os padrões do Flutter (`flutter.compileSdkVersion` etc.);
- Para publicar: **keystore de assinatura** (ver abaixo) e conta de desenvolvedor no **Google Play Console** (taxa única de US$ 25).

### Assinatura de release

A assinatura de produção lê `android/key.properties` (nunca versionado — veja `android/key.properties.example` e o [Guia do desenvolvedor](10-guia-desenvolvedor.md#assinatura-de-release-android)):

- Com `key.properties` presente → assinatura de **produção** (upload keystore + Play App Signing);
- Sem o arquivo (CI/dev) → o build de release cai para o keystore de **debug** (não publicável).

### Comandos

```bash
# APK único (distribuição direta / testes)
flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk

# APK por ABI (menor, por arquitetura: armeabi-v7a, arm64-v8a, x86_64)
flutter build apk --split-per-abi

# AAB — formato obrigatório para o Google Play
flutter build appbundle --release
# → build/app/outputs/bundle/release/app-release.aab

# Testar em dispositivo/emulador (debug, com hot reload)
flutter run
```

> R8/minify estão **desativados** (padrão do template). Para reduzir o APK, habilite `isMinifyEnabled`/`isShrinkResources` junto com as `-keep` rules das libs (checklist 7.7). Antes de publicar, defina o **Application ID** definitivo (`android/app/build.gradle.kts` — hoje é placeholder `com.dumbhanengue.dumbhanengue`).

---

## iOS

### Requisitos

- **macOS** com **Xcode** (o build de iOS só é possível no macOS);
- **CocoaPods** (ou o gerenciador de pacotes nativo do Xcode) — o `Podfile` é gerado automaticamente no primeiro build;
- **Conta Apple Developer** (US$ 99/ano) com **certificado de distribuição** e **provisioning profile**;
- Deployment target mínimo: **iOS 13.0** (`IPHONEOS_DEPLOYMENT_TARGET`).

### Comandos

```bash
# Build de release com assinatura (requer conta/certificado configurados no Xcode)
flutter build ios --release

# Build LOCAL sem assinatura (testes, sem conta de desenvolvedor)
flutter build ios --release --no-codesign
# → build/ios/iphoneos/Runner.app

# Rodar em simulador/dispositivo (debug)
flutter run
```

### Publicação na App Store

1. Abra `ios/Runner.xcworkspace` no Xcode;
2. Selecione o **team** de assinatura em *Signing & Capabilities*;
3. **Product → Archive** e envie pelo **App Store Connect** (Transporter ou *Distribute App*);
4. Configure o aplicativo no App Store Connect (metadados, privacidade, capturas) e submeta à revisão.

> ⚠️ O `supabase_flutter` e o `flutter_secure_storage` funcionam em iOS sem configuração extra. Lembre-se de declarar as permissões adequadas no `Info.plist` se um dia adicionar câmera/localização.

---

## Windows

### Requisitos

- **Windows 10/11** com **Visual Studio 2022** — instale o workload **"Desenvolvimento para desktop com C++"** (Desktop development with C++), que inclui os toolchains exigidos pelo Flutter.

### Comandos

```bash
# Build de release (exe nativo)
flutter build windows --release
# → build/windows/x64/runner/Release/dumbhanengue.exe

# Rodar em modo debug com hot reload
flutter run -d windows
```

O executável gerado depende das DLLs da pasta `Release` — distribua a **pasta inteira** (ou empacote com MSIX via `msix` / "Add App Package" do Visual Studio para a Microsoft Store).

---

## Web

### Requisitos

- Qualquer SO (build acontece em Dart puro — sem toolchain nativo);
- Um navegador para testar (`flutter run -d chrome`).

### Comandos

```bash
# Build de produção (site estático pronto para deploy)
flutter build web --release
# → build/web/

# Modo dev com hot reload
flutter run -d chrome

# (Opcional) Build WebAssembly — veja os avisos do `flutter build web`
flutter build web --release --wasm
```

### Deploy

`build/web/` é um **site estático**: hospede em qualquer servidor/CDN (Firebase Hosting, Vercel, Netlify, GitHub Pages, nginx...). Configure um fallback para `index.html` (SPA) se usar rotas.

> ⚠️ **Limitação da web:** o `sqlite3` nativo não roda no navegador (`dart:ffi` não existe lá). Nesta plataforma o app usa os datasources **em memória** (mesmos contratos — a UI é idêntica), e o **SaaS (Supabase)** é o modo de produção recomendado para a web. O armazenamento seguro na web também é mais fraco (chave em `localStorage`).

---

## Linux e macOS (desktop)

Os diretórios `linux/` e `macos/` ainda **não foram criados** neste projeto. Para habilitá-los:

```bash
flutter create --platforms=linux,macos .
```

Depois, `flutter build linux --release` (requer GTK/clang) e `flutter build macos --release` (requer macOS + Xcode).

---

## CI (GitHub Actions)

O workflow `.github/workflows/ci.yml` já executa em todo push/PR:

1. **analyze** — `flutter analyze` (zero erros/avisos);
2. **test** — `flutter test --coverage` + resumo de cobertura;
3. **build** — `flutter build apk --release` (assinatura debug, pois o CI não tem `key.properties`) e publica o APK como artefato;
4. **sql-check** — smoke test do `supabase/schema.sql` + RLS num Postgres real.

Para gerar artefatos **publicáveis** no CI, decodifique o keystore de um secret (ver `android/key.properties.example` e o [Guia do desenvolvedor](10-guia-desenvolvedor.md#assinatura-de-release-android)).

---

## Checklist rápido antes de publicar

- [ ] `flutter analyze` e `flutter test` verdes;
- [ ] `flutter doctor -v` sem pendências críticas na plataforma alvo;
- [ ] **Android:** Application ID definitivo + `key.properties` + AAB testado no Play Console (Internal testing);
- [ ] **iOS:** team de assinatura no Xcode + arquivo testado no TestFlight;
- [ ] **Windows/Web:** build release local validado e artefato distribuível;
- [ ] **SaaS:** `--dart-define` apontando para o Supabase de produção;
- [ ] Conferir o [Checklist de produção](PRODUCTION_CHECKLIST.md) e o [Relatório de auditoria](AUDIT_REPORT.md).
