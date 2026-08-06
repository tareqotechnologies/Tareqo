# 14 — Go-Live: operações externas (checklist)

> Este capítulo cobre **tudo o que não está no repositório** — os passos que
> exigem as consolas (Google Play, Apple Developer, Supabase) e os secrets
> do CI. O código de release está pronto (workflows + Fastlane); estes
> passos são manuais e únicos.

## 0. Estado atual

- ✅ Keystore de upload gerado (`android/app/upload-keystore.jks`, gitignored)
  + `android/key.properties` — assinatura Android pronta.
- ✅ `release.yml` (Android → Play *Internal testing*) e `ios.yml`
  (iOS → TestFlight) prontos; disparados por tag `v*`.
- ❌ Secrets do CI por configurar; contas de loja; ativações nas consolas.

## 1. Secrets do GitHub (Settings → Secrets and variables → Actions)

| Secret | Origem |
|---|---|
| `SUPABASE_URL_PROD` | URL do projeto de produção (dashboard Supabase) |
| `SUPABASE_ANON_KEY_PROD` | anon key do projeto de produção |
| `SENTRY_DSN` (opcional) | projeto Sentry |
| `KEYSTORE_BASE64` | `base64 -w0 android/app/upload-keystore.jks` (já existe em `android/app/upload-keystore.jks.b64` — copiar o conteúdo, depois apagar o ficheiro) |
| `KEYSTORE_PASSWORD` | `storePassword` de `android/key.properties` (PKCS12: a mesma para `keyPassword`) |
| `KEY_ALIAS` | `keyAlias` de `android/key.properties` (padrão `upload`) |
| `PLAY_SERVICE_ACCOUNT_JSON` | service account do Play Console (API Google Play Developer) — ver §3 |
| `APPLE_ISSUER_ID` | App Store Connect → Users and Access → Integrations → App Store Connect API → Issuer ID |
| `APPLE_KEY_ID` | id da API key criada no mesmo ecrã |
| `APPLE_KEY_CONTENT` | conteúdo **base64** do ficheiro `.p8` da mesma API key |
| `APPLE_TEAM_ID` | Apple Developer → Membership → Team ID |

## 2. Supabase (projeto de produção)

1. **Confirmação de e-mail ON** — Authentication → Providers → Email →
   "Confirm email" **ligado** (mitiga auto-registo e é pré-requisito de segurança).
2. **2FA na conta do super admin** — ativar na conta de e-mail do `super_admins`
   (ou, idealmente, TOTP no próprio Supabase quando disponível).
3. **`password_min_length = 8`** — Authentication → Settings (alinha com o cliente).
4. **Aplicar o upgrade consolidado** ao projeto de produção: SQL Editor ←
   conteúdo de `supabase/upgrade.sql` (leva um banco EXISTENTE ao estado
   atual — substitui as antigas migrações 002..011; 100% idempotente, seguro
   reexecutar). Para projetos novos, só o `supabase/schema.sql` basta.
5. Rate limits de e-mail: deixar os padrões (o cadastro de funcionário não usa
   e-mail — RPC `create_employee_account`).

## 3. Google Play Console

1. Criar o app com o Application ID **`com.dumbhanengue.dumbhanengue`**
   (imutável após o primeiro upload).
2. Ativar o **Play App Signing** e registar o SHA-256 da chave de upload
   (de `keytool -list -v -keystore upload-keystore.jks`).
3. Criar a service account com permissão de upload (Play Console → Setup →
   API access) e guardar o JSON no secret `PLAY_SERVICE_ACCOUNT_JSON`.
4. Lançar o primeiro release: `git tag v1.0.0 && git push --tags` → o CI
   builda e envia para o track **Internal testing**.
5. Assets da loja: ícone (já gerado), feature graphic, screenshots,
   descrição, política de privacidade + ToS (links obrigatórios).

## 4. Apple (iOS)

1. **Apple Developer Program** ativo + App ID `com.dumbhanengue.dumbhanengue`.
2. Configurar a assinatura automática no Xcode (team) OU usar `match`
   (alternativa documentada na lane `ios beta`).
3. Criar a API key da App Store Connect (ficheiro `.p8`) e adicionar os 3
   secrets Apple (§1). A lane `fastlane ios beta` valida primeiro a
   compilação sem assinatura (`--no-codesign`) e só depois assina e envia.
4. **Nota:** o build iOS exige macOS — o CI usa `macos-14`. Localmente
   (Windows) não é possível validar o IPA; a validação acontece no workflow.

## 5. Antes do primeiro tag

- [ ] Secrets do §1 todos preenchidos
- [ ] Supabase: confirmação de e-mail ON + 2FA + migração 008 aplicada
- [ ] Play App Signing ativado + service account criada
- [ ] Apple Developer + API key criadas
- [ ] Política de privacidade + ToS publicadas (links nas lojas)
- [ ] `flutter test` verde + `sql_check.sh` 9/9 (CI valida em cada push)

## 6. Depois do primeiro upload

- [ ] Testar o APK/AAB do Internal testing num dispositivo real (dono,
  gerente e funcionário — matriz de acesso)
- [ ] Verificar no Sentry (se DSN configurado) que não há erros em release
- [ ] Promover de Internal → Closed/Open testing após aprovação manual
