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

- **Versão do app:** `version: 2.1.1+21` em `pubspec.yaml` (aplicada automaticamente ao `versionCode`/`versionName` no Android e ao CFBundleVersion no iOS).

> **Atenção:** **Modo SaaS vs. local:** o app usa as credenciais do Supabase **embutidas** (`lib/core/config/supabase_config.dart`) apontando para o projeto de DESENVOLVIMENTO — em release isso é erro de configuração (guarda S2 + **A1**). Desde a auditoria (Aug 5) o projeto tem **flavors `dev`/`prod`** com dart-defines **obrigatórios** via `--dart-define-from-file` (o `main.dart` bloqueia release sem `--flavor prod`). **A1 (auditoria Set/2026):** todo RELEASE exige credenciais **explícitas** — `SupabaseBootstrap` rejeita em `kReleaseMode` qualquer build com os defaults embutidos, em qualquer flavor. Como o Dart não distingue por valor um define idêntico ao default (o deployment atual usa o projeto ÚNICO `dotklbpqmlnhcdifiukd` partilhado dev/prod), os defines de `SUPABASE_URL`/`SUPABASE_ANON_KEY` vêm acompanhados do marcador `SUPABASE_CREDENTIALS_EXPLICIT=true` (já presente em `env/prod.env.example`, `env/dev.env`, fastlane e CI). **Passo de infra pendente:** criar o projeto Supabase de PRODUÇÃO separado e atualizar `env/prod.env`:

```bash
# Desenvolvimento (debug/hot reload)
flutter run --flavor dev --dart-define-from-file=env/dev.env

# Produção (release)
flutter build appbundle --flavor prod --release \
 --dart-define-from-file=env/prod.env
```

> A anon key é pública por design (a segurança real vem do RLS — **nunca** embuta a service role key). `env/dev.env` é commitado (valores de dev); `env/prod.env` **nunca** é versionado (ver `.gitignore`) e `env/prod.env.example` é o modelo.

## Resumo por plataforma

| Plataforma | SO para **buildar** | Requisitos principais | Comando de release | Artefato gerado |
| ---------- | ------------------- | --------------------- | ------------------ | --------------- |
| **Android** | Windows, macOS, Linux | JDK 17 + Android SDK | `flutter build appbundle --flavor prod --release --dart-define-from-file=env/prod.env` | `app-prod-release.aab` |
| **iOS** | **macOS** (obrigatório) | Xcode + CocoaPods + conta Apple Developer | `flutter build ios --release` | `Runner.app` (ou `.ipa` via Xcode) |
| **Windows** | Windows 10/11 | Visual Studio 2022 (workload C++) | `flutter build windows --release` | `tareqo.exe` |
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

> **Guarda de produção (auditoria 2.4):** o Gradle falha o build de `prodRelease` se `android/key.properties` não existir — um AAB de produção nunca é assinado com a chave de debug. No CI, o workflow `release.yml` descodifica o keystore do secret `KEYSTORE_BASE64` antes do build (via Fastlane).

### Comandos

```bash
# ── Flavors (auditoria 2.4) ────────────────────────────────────────────
# dev → applicationId com.tareqo.tareqo.dev, label "Dev"
# prod → applicationId de produção com.tareqo.tareqo

# APK dev (distribuição direta / testes)
flutter build apk --release --flavor dev --dart-define-from-file=env/dev.env
# → build/app/outputs/flutter-apk/app-dev-release.apk

# AAB de PRODUÇÃO — formato obrigatório para o Google Play
flutter build appbundle --flavor prod --release \
 --dart-define-from-file=env/prod.env
# → build/app/outputs/bundle/prodRelease/app-prod-release.aab

# AAB de produção com ofuscação Dart (recomendado antes de publicar)
flutter build appbundle --flavor prod --release \
 --dart-define-from-file=env/prod.env \
 --obfuscate --split-debug-info=build/symbols

# Testar em dispositivo/emulador (debug, com hot reload)
flutter run --flavor dev --dart-define-from-file=env/dev.env
```

> **R8/minify estão ATIVADOS** (auditoria S7, Aug 5): `isMinifyEnabled`/`isShrinkResources` no `build.gradle.kts`. Para ofuscar também o código **Dart**, adicione ao comando de release: `flutter build apk --release --obfuscate --split-debug-info=build/symbols` (e faça o upload dos símbolos ao Sentry: `sentry-cli debug-files upload`). Para reduzir o APK de 61 MB, use `--split-per-abi` (ou `flutter build appbundle` — formato exigido pela Play). Com os flavors (Aug 5), `prod` mantém o Application ID `com.tareqo.tareqo` e `dev` ganhou o sufixo `.dev`. Atenção: **O package de produção é imutável após o primeiro upload ao Play** — se um dia decidir mudá-lo, será um app NOVO no console (sem herdar reviews/installs).

#### Aviso conhecido no build (sentry_flutter + KGP) — rastreado upstream

> **Atenção:** **Sep 18:** o Flutter 3.47 com AGP 9+ e `android.builtInKotlin=true` ainda emite um **aviso** ao configurar o Gradle de QUALQUER build Android (dev ou prod):
>
> ```
> WARNING: Your app uses the following plugins that apply Kotlin Gradle Plugin (KGP): sentry_flutter
> Future versions of Flutter will fail to build if your app uses plugins that apply KGP.
> ```
>
> - **É benigno hoje** — apenas um aviso informativo; o build passa normalmente (confirmado no `assembleDevRelease` e no `assembleProdRelease`).
> - **Causa:** a deteção do Flutter Gradle Plugin é **textual** (regex sobre o `android/build.gradle` do plugin) e ainda encontra a linha `apply plugin: 'kotlin-android'` do `sentry_flutter` — que com built-in Kotlin ativo **não é executada** (a aplicação é condicional a `builtInKotlin=false`; o mesmo padrão bimodal existe no `mobile_scanner 7.4.2`).
> - **Rastreio upstream:** **getsentry/sentry-dart#3738** (DART-382) — a migração do plugin para Kotlin built-in está prevista para o **v10 estável**, bloqueada no pacote `jni` (dart-lang/native#3415).
> - **Ação quando o v10 sair:** subir `sentry_flutter` para `^10.0.0` no `pubspec.yaml` — o aviso desaparece sozinho.
> - **Histórico (Aug 8):** até 17 de set, o projeto rodava em modo legado (`android.builtInKotlin=false`, adicionado pelo migrator do 3.44). Nesse modo o `mobile_scanner` quebrava o build release (o FGP aplicava KGP ao subprojeto depois da avaliação do script e o `GeneratedPluginRegistrant` não achava a classe do plugin). A migração para built-in Kotlin (Sep 18) desbloqueou o build de release.

### Publicação via CI (Fastlane)

O passo final antes de publicar é o workflow **`.github/workflows/release.yml`**, disparado por uma tag `v*`:

```bash
git tag v1.1.0
git push origin v1.1.0
```

O workflow roda `flutter analyze` + `flutter test` e, em seguida, o **Fastlane** (`fastlane/Fastfile`, lane `deploy`), que:

1. valida os defines/credenciais de produção (fail-fast — `UI.user_error!` se faltar algum secret);
2. descodifica o upload keystore do secret `KEYSTORE_BASE64` e monta `android/key.properties`;
3. builda o **AAB** (`--flavor prod --release --obfuscate --split-debug-info=build/symbols`);
4. faz upload para o track **Internal testing** do Play Console (service account do secret `PLAY_SERVICE_ACCOUNT_JSON`).

**Secrets exigidos** (GitHub → Settings → Secrets and variables → Actions): `SUPABASE_URL_PROD`, `SUPABASE_ANON_KEY_PROD`, `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `PLAY_SERVICE_ACCOUNT_JSON`, e `SENTRY_DSN` (opcional).

**Pré-requisito único manual:** o app `com.tareqo.tareqo` tem de existir no Play Console com o primeiro AAB/APK enviado e o **Play App Signing** ativado (upload key registada). Depois disso, todas as atualizações podem sair pela tag `v*`. Para enviar os símbolos Dart ao Sentry: `sentry-cli debug-files upload --org <org> --project <proj> build/symbols`.

#### Preparação dos secrets do GitHub

Crie os secrets em **GitHub → Settings → Secrets and variables → Actions** antes do primeiro `v*`:

| Secret | Valor | Como obter |
| --- | --- | --- |
| `KEYSTORE_BASE64` | upload keystore em base64 | Linux/macOS: `base64 -w0 android/app/upload-keystore.jks` · Windows/git-bash: `openssl base64 -in android/app/upload-keystore.jks -A` |
| `KEYSTORE_PASSWORD` | senha do cofre | `android/key.properties` (PKCS12: a mesma senha para store e key) |
| `KEY_ALIAS` | alias da chave | `android/key.properties` (padrão `upload`) |
| `SUPABASE_URL_PROD` | URL do projeto de produção | Supabase → Project Settings → API |
| `SUPABASE_ANON_KEY_PROD` | anon key (pública por design — RLS é a segurança) | Supabase → Project Settings → API |
| `PLAY_SERVICE_ACCOUNT_JSON` | JSON da service account do Play | Play Console → Setup and testing → API access → criar/associar service account (papel de upload/release do app) → gerar chave JSON → colar o conteúdo na íntegra |
| `SENTRY_DSN` (opcional) | DSN do Sentry | Sentry → Settings → Projects → Client Keys (DSN) |

> **Atenção:** A **service account** precisa de permissão de **upload/release** no app (papel "Release manager" do app no Play Console). O secret `PLAY_SERVICE_ACCOUNT_JSON` é o ficheiro JSON da chave na íntegra.

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

> **Atenção:** O `supabase_flutter` e o `flutter_secure_storage` funcionam em iOS sem configuração extra. Lembre-se de declarar as permissões adequadas no `Info.plist` se um dia adicionar câmera/localização.

---

## Windows

### Requisitos

- **Windows 10/11** com **Visual Studio 2022** — instale o workload **"Desenvolvimento para desktop com C++"** (Desktop development with C++), que inclui os toolchains exigidos pelo Flutter.

### Comandos

```bash
# Build de release (exe nativo)
flutter build windows --release
# → build/windows/x64/runner/Release/tareqo.exe

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

> **Atenção:** **Limitação da web:** o `sqlite3` nativo não roda no navegador (`dart:ffi` não existe lá). Nesta plataforma o app usa os datasources **em memória** (mesmos contratos — a UI é idêntica), e o **SaaS (Supabase)** é o modo de produção recomendado para a web. O armazenamento seguro na web também é mais fraco (chave em `localStorage`).

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
4. **sql-check** — smoke test do `supabase/schema.sql` + `supabase/upgrade.sql` (aplicação dupla = idempotência + migração W4 NUMERIC→centavos), RLS por loja, RPCs atômicas do dinheiro e agregações server-side (`get_dashboard_kpis`/`get_cash_flow`/`get_sales_report` — W5/H2) contra um Postgres 16 real — **12 passos**.

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
