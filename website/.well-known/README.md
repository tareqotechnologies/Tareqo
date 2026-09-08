# Deep links verificados (App Links / Universal Links) — auditoria M4

Estes arquivos **templates** habilitam os deep links verificados pelo SO
como alternativa ao custom scheme `tareqo://callback` (que qualquer app
Android pode tentar registrar — risco de hijack de scheme).

## Passos de infra (pendentes — exigem acesso ao domínio/assinatura)

1. **Hospedar os arquivos** em `https://tareqo.app/`:
   - `.well-known/assetlinks.json` (Android);
   - `.well-known/apple-app-site-association` (iOS — sem extensão, com
     `Content-Type: application/json` no servidor).
   Depois de fazer o deploy do site, validar:
   - `https://tareqo.app/.well-known/assetlinks.json` — responder o JSON
     com o fingerprint real;
   - `https://tareqo.app/.well-known/apple-app-site-association` —
     `curl -i` deve retornar 200 com o JSON.

2. **Fingerprint real do cert de assinatura** (Android):
   ```bash
   # Com o keystore de produção (android/key.properties):
   keytool -list -v -keystore upload-keystore.jks -alias upload \
     | grep -A1 'SHA256:' | head -2
   ```
   Substituir `SUBSTITUIR_PELO_SHA256_DO_CERT_DE_ASSINATURA` no
   `assetlinks.json`. Com Play App Signing, usar o fingerprint do
   **app signing key** (Play Console → Setup → App signing) — o upload
   key só assina o upload; quem assina o APK final é a Google.

3. **iOS — Associated Domains**: habilitar a capability
   `Associated Domains` no Xcode (Runner) com `applinks:tareqo.app`, e
   trocar `TEAMID` no `apple-app-site-association` pelo Apple Team ID.

4. **Supabase Auth — site_url**: mudar o `site_url` (Authentication →
   URL Configuration) de `tareqo://callback` para
   `https://tareqo.app/callback` — os links de confirmação/magic link
   passam a ser HTTPS. O `DeepLinkHandler` já aceita os dois formatos
   (ver `lib/core/network/deep_link_handler.dart`).

5. **Testar**:
   - `adb shell am start -W -a android.intent.action.VIEW -d "https://tareqo.app/callback?code=x"` (Android);
   - no iOS, tocar num link real de confirmação do e-mail.

Enquanto o passo 4 não for feito, o fluxo continua 100% no custom scheme
(`tareqo://callback`) — o filtro https fica dormente no Android.