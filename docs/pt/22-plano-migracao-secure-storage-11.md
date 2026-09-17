# 22 · Plano de Migração — flutter_secure_storage 10 → 11

> **Estado:** PLANEJADO (não executado). Base: changelog oficial do pacote
> (pub.dev, consultado em 2026-09-17) + auditoria do uso real no TAREQO.
> Versão atual: **10.3.2** (upgrade patch para 10.3.4 já feito em `445dd3c`).

## 1 · Uso real no TAREQO (evidência)

Todo o acesso passa por **duas abstrações próprias** — nenhum arquivo usa
`FlutterSecureStorage` diretamente além do backend:

| Camada | Arquivo | Uso |
|---|---|---|
| Backend único | `lib/core/security/secure_storage_service.dart` | `FlutterSecureStorage()` const, `read/write/delete` — **sem options** (sem `AndroidOptions`, sem `EncryptedSharedPreferences`, sem `sharedPreferencesName`) |
| Sessão Supabase | `lib/core/security/secure_supabase_local_storage.dart` | `SecureSupabaseLocalStorage` (chave `sb_session`) + `SecureGotrueAsyncStorage` (PKCE verifier) sobre o mesmo backend |
| Chave do outbox | `lib/core/security/pending_op_payload_cipher.dart` | chave mestra AES-256-GCM (`pending_ops_key_v1`) no Keystore |
| Consumidores | `ServiceLocator`, `auth_providers`, `mfa_auth_use_case`, `biometric_auth_use_case` | usam apenas `SecureStorageService` (abstração) |

Chaves persistidas: `access_token`, `refresh_token`, `api_key`,
`biometric_enabled`, `mfa_enabled`, `mfa_secret`, `sb_session`,
`pending_ops_key_v1` + verifier PKCE.

## 2 · Breaking changes da v11 — relevância para o TAREQO

| Change da v11 | Afeta o TAREQO? |
|---|---|
| Remove algoritmos pré-v10 (`RSA_ECB_PKCS1Padding`, `AES_CBC_PKCS7Padding`) | **Não** — o app nasceu já em v10; dados existentes usam os algoritmos atuais (OAEP/GCM). Condição "se usou versão < v10" não se aplica |
| Remove `encryptedSharedPreferences` de `AndroidOptions` (Jetpack Security) | **Não** — o app não passa nenhuma option |
| Remove `sharedPreferencesName` (usar `storageNamespace`) | **Não** — não usado |
| **minSdk 24 / compileSdk 37** | **Verificar** — o app usa `flutter.minSdkVersion`/`flutter.compileSdkVersion` (default do SDK). O Flutter 3.47 default já atende (minSdk do template ≥ 24); confirmar no `flutter build apk --release` |
| Novidades (biometria por operação, `checkUpgradeStatus`, namespace scoping) | Opcionais — sem obrigação de adotar |

**Conclusão de risco:** a superfície do app (API básica read/write/delete sem
options) não toca nenhuma API removida. O risco real é **comportamental**
(plugin nativo novo no Keystore/Keychain), não de API Dart.

## 3 · O que pode quebrar e o fallback de sessão

O dado mais crítico é a **sessão Supabase** (`sb_session`) e a **chave do
outbox** (`pending_ops_key_v1`). Cenário de risco: o plugin v11 não ler o
valor gravado pela v10 em algum dispositivo (não documentado como esperado,
mas Keystore é hardware-dependente).

**Fallback de sessão (defesa em profundidade):** no bootstrap, ao
inicializar o `Supabase`, se a sessão persistida falhar ou o refresh token
for rejeitado (401/`AuthException`), o app **já força reautenticação**
(fluxo `AuthGate` → login). A migração adiciona uma etapa explícita:

1. Tentar ler `sb_session` com a v11.
2. Se falhar (exception ou null inesperado), logar evento no Sentry
   (`secure_storage_migration_failure`) e seguir sem sessão → login limpo.
3. **Nunca** perder os outros dados: `pending_ops_key_v1` é gerado
   on-demand — se perdida, o outbox recria a chave; ops pendentes antigas
   não cifradas com a chave nova devem ser descartadas com aviso ao
   utilizador (a fila é cifrada — ver `PendingOpPayloadCipher`).

## 4 · Passos de migração (ordem exata)

1. **Pré-voo:** executar `flutter build apk --release` atual e registrar o
   minSdk/compileSdk efetivos (baseline).
2. Bump `pubspec.yaml`: `flutter_secure_storage: ^11.2.0` (+ `pub get`).
3. Build release Android + instalar em dispositivo real; validar:
   login/logout persistente (matar o app e reabrir — sessão sobrevive),
   MFA enable/verify, biometria enable/unlock, venda offline + sync.
4. Testes automatizados: suíte inteira (os testes usam backend em memória —
   imunes à migração) + **novo teste** de roundtrip do
   `SecureSupabaseLocalStorage` (persist → read → remove) já coberto pelos
   testes existentes de segurança.
5. **Staged rollout:** como o dado é local ao dispositivo, a migração é
   individual por instalação. Monitorar Sentry por
   `secure_storage_migration_failure` e quedas na taxa de sessão persistida
   nos primeiros 7 dias de distribuição.

## 5 · Critérios de aceite

- `flutter analyze` limpo; suíte 100% verde.
- Build release Android assinado e instalado em device real com os 4 fluxos
  do passo 3 aprovados.
- Zero eventos `secure_storage_migration_failure` acima de ruído em staging.

## 6 · Rollback

Reverter o pubspec para `^10.3.4` e recompilar. Como nenhum algoritmo de
dados mudou no nosso uso (GCM/OAEP já em vigor na v10), dados gravados pela
v11 são legíveis pela v10 — rollback de código não trava utilizadores.
Exceção: se a v11 alterar o wrapper de arquivo no dispositivo (não
documentado), os utilizadores afetados fazem login novamente e a fila
offline é recriada (perda máxima: ops pendentes não sincronizadas — mesmo
impacto de reinstalar o app).
