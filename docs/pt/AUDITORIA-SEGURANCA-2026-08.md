# Auditoria de Segurança End-to-End — Dumbhanengue ERP

**Data:** 18 de agosto de 2026
**Escopo:** código-fonte Flutter/Dart, configuração Android/iOS, backend Supabase (schema + RLS + RPCs), CI/CD, supply chain, privacidade.
**Metodologia:** OWASP MASVS v2 · OWASP Mobile Top 10 (2024) · OWASP ASVS · CWE · CVSS v3.1 · princípio do menor privilégio · defesa em profundidade.
**Regra aplicada:** nenhuma vulnerabilidade foi inventada — cada achado tem **evidência** no repositório ou está marcado como **"necessita validação"** quando o fato depende de configuração externa (ex.: dashboard do Supabase).

---

## 1. Executive Summary

O Dumbhanengue é um ERP financeiro multi-tenant (vendas, caixa, fiado, compras, relatórios) com modo **offline-first** (SQLite + outbox) e modo **SaaS** (Supabase), autenticação GoTrue, e um backend PostgreSQL com **Row Level Security em todas as tabelas** e RPCs `SECURITY DEFINER` idempotentes.

**Postura geral: acima da média para apps Flutter da mesma classe.** Os fundamentos estão corretos: sessão criptografada no Keychain/Keystore (não em SharedPreferences em claro), RLS por tenant+loja com triggers anti-forja, RPCs do dinheiro validadas no servidor (total = Σ itens, estoque travado com `FOR UPDATE`, idempotência por id), super-admin por tabela (não por e-mail hardcoded), backups Android desativados (`allowBackup=false` + regras de extração), R8/minify + ofuscação Dart no release, sem analytics/tracking, e CI com gate de cobertura e teste SQL/RLS real.

**Riscos mais relevantes encontrados (nem todos são "falhas" — alguns são decisões com trade-off):**

1. **SQLite local com criptografia parcial (corrigido em 18/08)** — o outbox `pending_ops` (vendas/fiado/compras offline) era o dado mais sensível em repouso e agora é cifrado com AES-256-GCM (chave no Keystore/Keychain). **Pendente:** o banco principal (`dumbhanengue.db`) ainda é texto claro — SQLCipher completo na Fase 1/2 (MSTG-STORAGE-1/2/8).
2. **Sem pinning de certificado (corrigido em 18/08)** — o client do Supabase agora é ancorado no intermediário WE1 (`SecurityContext(withTrustedRoots: false)`): MITM com CA user-installed é rejeitado no handshake (fail-closed), verificado E2E no dispositivo real contra o Supabase. O leaf pode rotacionar (set/2026) sem quebrar o app.
3. **`create_employee_account` grava senha via RPC e o dono a define em texto** — fluxo documentado e justificado (atomicidade), mas a senha trafega como parâmetro e o dono a vê/define. Sem email de confirmação para funcionários (decisão de produto).
4. **Sem MFA/biometria** para uma app que movimenta dinheiro.
5. **Sem detecção de root/jailbreak, debugger ou tampering** — a app roda em dispositivos comprometidos sem aviso.
6. **iOS: sem exclusão de backup explícita dos arquivos locais (corrigido em 18/08)** — `BackupExclusion` marca `dumbhanengue.db` + `product_images` como excluídos do backup do iCloud/iTunes (`NSURLIsExcludedFromBackupKey`) via channel nativo; no-op fora do iOS.
7. **Web: sessão no localStorage** (limitação documentada do `flutter_secure_storage` 10.x) — a web é superfície adicional com criptografia fraca.
8. **Rate limiting** — dependente do plano/configuração do Supabase (GoTrue tem limites por IP por padrão; RPCs customizadas dependem de configuração externa). Necessita validação no dashboard.

**Veredito:** a base é sólida e a maioria dos controles exigidos pelo MASVS L1 está presente. As lacunas estão em **hardening avançado** (L2+) e em **decisões a validar fora do repositório** (config do projeto Supabase, keystore, lojas). Nenhuma vulnerabilidade crítica de exploração remota sem autenticação foi encontrada no código.

---

## 2. Mapa da Superfície de Ataque

| Superfície | Descrição | Exposição |
|---|---|---|
| **App Android/iOS** | APK/IPA com secrets embutidos (anon key, SENTRY_DSN, URL Supabase), SQLite local, outbox offline, deep links `dumbhanengue://callback` | Atacante com o binário: extração de secrets, engenharia reversa, repackaging |
| **Armazenamento local** | `dumbhanengue.db` (SQLite), `product_images/*.jpg`, outbox `pending_ops` (payloads JSON de vendas/fiado/compras) | Root/JB, backup não cifrado, malware com acesso ao sandbox, extração de dados |
| **Rede** | HTTPS para `*.supabase.co` (GoTrue, PostgREST, Storage, Realtime WebSocket), Sentry | MITM ativo (CA malicioso/proxy), sniffer passivo, downgrade |
| **API Supabase** | ~17 RPCs `SECURITY DEFINER` (process_sale, register_debt, settle_debt, process_purchase, cancel_sale, close_cash_register, adjust_product_stock, create_employee_account, set_employee_active, update_tenant_settings, get_*...) + PostgREST CRUD com RLS | Atacante autenticado (cliente adulterado), IDOR/BOLA, mass assignment, race conditions |
| **Admin console** | Super admin (tabela `super_admins`), decisões de tenant/plano, audit log | Comprometimento da conta admin = controle total multi-tenant |
| **CI/CD** | GitHub Actions (ci/release/ios/ipa), Fastlane, secrets (keystore, Play, Apple, Supabase prod) | Supply chain, secrets vazados em logs/artefatos |
| **Deep links** | `dumbhanengue://callback` (Android intent-filter + iOS CFBundleURLTypes) | Aplicativo malicioso registrando o mesmo scheme (Android) |
| **Web** | Build web (session em localStorage, sem secure storage) | XSS na origem, roubo de sessão via localStorage |

---

## 3. Threat Model

### Ativos
- **Dados financeiros**: vendas, caixa, fiado (dívidas), compras, fechos de caixa.
- **PII**: nome/email do dono e funcionários, nome/telefone/email de clientes, NUIT/endereço da loja.
- **Sessões**: access + refresh tokens (GoTrue JWT), PKCE verifier.
- **Chave de assinatura**: upload keystore (Play) / distribuição App Store.
- **Credenciais de infra**: service account do Play, API key da App Store Connect, senhas do Supabase.

### Atacantes
| Atacante | Motivação | Capacidade |
|---|---|---|
| **Funcionário desonesto/curioso** | Fraude, espiar dados, adulterar estoque/fiado | Acesso legítimo ao app e à loja |
| **Cliente ou terceiro com o APK** | Engenharia reversa, repackaging, extração de secrets | Binário em mãos, dispositivo próprio |
| **Atacante remoto** | IDOR/BOLA, brute-force, abuso de RPCs | Rede + credenciais roubadas/anon key |
| **Malware no dispositivo** | Roubar tokens/dados | Acesso ao sandbox/armazenamento (se root) |
| **MITM** | Ler/alterar tráfego | Rede comprometida, CA user-installed |
| **Admin comprometido** | Controle multi-tenant | Conta super admin |

### Trust boundaries
```
[Dispositivo] ──TLS──▶ [Supabase: GoTrue/PostgREST/Storage/Realtime]
      │  ▲                              │
      ▼  │ RLS: auth.uid()              ▼ RLS: auth.uid() + is_my_store()
[SQLite local + outbox]              [PostgreSQL: tenants/stores/RLS/RPCs]
      │                                              │
      ▼                                              ▼
[Backup SO / iCloud]                     [Super admin: super_admins/audit_log]
```

### Attack surface resumido (mapeado nas seções 4–10)
Auth (login/senha/recovery) · sessão persistida · RPCs de dinheiro · RLS/triggers · storage de fotos (bucket público) · deep links · armazenamento local · rede · build/release · CI/CD · web.

---

## 4. Tabela de Vulnerabilidades Priorizadas

| ID | Título | Severidade | CVSS | Local | Status |
|---|---|---|---|---|---|
| **V1** | SQLite local sem criptografia (dados financeiros + PII em repouso) | **Alta** | 6.5 | `lib/core/database/app_database_io.dart`, datasources SQLite | **Parcialmente corrigida (18/08):** outbox `pending_ops` cifrado com AES-256-GCM (chave no Keystore/Keychain); DB principal ainda em texto claro — SQLCipher completo em Fase 1/2 |
| **V2** | Ausência de certificate pinning | **Média** | 5.9 | `SupabaseBootstrap`, `TimeoutRetryHttpClient` | **Corrigida (18/08):** `SecurityContext(withTrustedRoots: false)` ancorado no intermediário WE1 (Google Trust Services) injetado no client do Supabase; MITM com CA user-installed é rejeitado no handshake (verificado E2E no dispositivo) |
| **V3** | Sem MFA/biometria para conta financeira | **Média** | 5.3 | Auth (GoTrue) | Aberta (Fase 3) |
| **V4** | Sem root/jailbreak/debugger/tamper detection | **Média** | 5.3 | App inteiro | Aberta (Fase 3) |
| **V5** | Senha de funcionário definida/visível pelo dono e trafegada via RPC | **Média** | 4.8 | `create_employee_account`, `stores_screen.dart` | Aberta (decisão documentada) |
| **V6** | Web: sessão em localStorage (sem secure storage) | **Média** | 4.3 | `SupabaseBootstrap` (kIsWeb) | Limitação documentada |
| **V7** | Rate limiting de RPCs/endpoints não verificável do repo | **Média** | — | Supabase dashboard | **Necessita validação** |
| **V8** | Deep link custom scheme `dumbhanengue://` — hijack em Android | **Baixa** | 3.7 | `AndroidManifest.xml`, `Info.plist`, `DeepLinkHandler` | **Parcialmente corrigida (18/08):** URI validada (scheme+host exatos) antes do gotrue; registro do scheme no SO inalterado |
| **V9** | iOS sem exclusão explícita de backup dos arquivos locais | **Baixa** | 3.3 | `app_database_io.dart`, `product_image_store_local.dart` | **Corrigida (18/08):** `BackupExclusion` (facade condicional) + channel nativo no `AppDelegate.swift` setando `NSURLIsExcludedFromBackupKey` no DB e no diretório de fotos; no-op fora do iOS; best-effort (falha nunca derruba o boot) |
| **V10** | `changePassword` reautentica e troca senha (correto) — mas sem rate limit visível no client | **Baixa** | 3.1 | `supabase_auth_remote_data_source.dart` | Parcialmente mitigada (GoTrue limita) |
| **V11** | Secrets embutidos no binário (anon key, SENTRY_DSN, URL) — esperado, mas enumerável | **Info** | 2.0 | `supabase_config.dart`, `crash_reporting.dart` | Aceito por design |
| **V12** | `app_links` recebe qualquer URI `dumbhanengue://` e passa a `getSessionFromUrl` | **Baixa** | 3.1 | `deep_link_handler.dart` | **Corrigida (18/08):** `isAuthCallbackUri` (scheme+host exatos) filtra cold e warm start |
| **V13** | Audit log não cobre operações de negócio (só decisões de admin) | **Info** | 2.6 | `schema.sql` (triggers) | Melhoria |
| **V14** | Artefatos de release do CI carregam símbolos (`build/symbols`) no GitHub Actions | **Info** | 2.2 | `release.yml`, `ipa.yml` | **Corrigida (18/08):** `retention-days: 14` no artefato de símbolos |

---

## 5. Quick Wins (executar primeiro, baixo esforço)

> **Implementado em 18/08/2026:** V1 (outbox) · V2 (pinning) · V8 (parcial — validação de URI) · V9 · V12 · V14. Os itens marcados como **pendente** continuam abertos.

1. **V1 (parcial — FEITO):** o outbox `pending_ops` agora é cifrado com **AES-256-GCM** (`PendingOpPayloadCipher`, chave no Keystore/Keychain) — `pending_op_queue_sqlite_impl.dart` + wire no `ServiceLocator`. **Pendente:** DB principal (`dumbhanengue.db`) com SQLCipher (Fase 1/2).
2. **V8 (parcial — FEITO):** `DeepLinkHandler.isAuthCallbackUri` valida scheme+host exatos (`dumbhanengue://callback`) antes de tocar o gotrue. **Pendente:** verificação de handler padrão no Android (App Links).
3. **V12 (FEITO):** `initialUri` (cold start) e URIs do stream (warm start) filtrados pela mesma validação antes de `getSessionFromUrl`.
4. **V9 (FEITO):** `BackupExclusion` (facade condicional + channel nativo no `AppDelegate.swift`) seta `NSURLIsExcludedFromBackupKey` no `dumbhanengue.db` e no diretório `product_images`; no-op fora do iOS; best-effort.
5. **V5 (parcial):** forçar `ChangePasswordSheet`/troca de senha no primeiro login do funcionário (senha temporária). Esforço: ~1 dia.
6. **V13:** estender o audit log com triggers de escrita nas tabelas de dinheiro (ou pelo menos `sales`/`financial_transactions`). Esforço: ~1 dia.
7. **V14 (FEITO):** artefato `dart-symbols` com `retention-days: 14` (janela curta de re-engenharia a partir do CI).

---

## 6. Correções Críticas (detalhe técnico + exemplo)

### V1 — SQLite sem criptografia (Alta)

**Evidência:** `app_database_io.dart` abre `sqlite3.open(documents/dumbhanengue.db)` sem SQLCipher; `_schemaV1/_schemaV2` criam tabelas de vendas, caixa, fiado e `pending_ops` (outbox com payload JSON completo) em texto claro. Tokens **estão** protegidos (Keychain/Keystore — correto), mas os dados de negócio não.

**Cenário:** dispositivo com root/JB, ou backup (Android/iOS) extraído, ou malware com acesso ao sandbox → lê histórico de vendas, fiado com nomes de clientes, valores, NUIT.

**Correção (opções em ordem de impacto):**
1. *(Recomendada)* Usar **SQLCipher** via `sqlcipher_flutter_libs` + `package:sqlite3` com chave derivada do `flutter_secure_storage` (a chave mestra fica no Keystore/Keychain). Migração: `ATTACH DATABASE` + `sqlcipher_export` + troca de arquivo. Documentada em `docs/pt/04-dados.md` (migração versionada já existe — `PRAGMA user_version`).
2. *(Alternativa)* Mover o banco para pasta protegida + excluir de backup (Quick Win 1). Reduz exfiltração por backup, **não** protege contra root/malware.
3. *(Mínima)* Cifrar apenas os campos sensíveis (`person_name`, `customer.phone/email`) com AES-GCM via `flutter_secure_storage` (chave no Keystore). Custo baixo, cobre PII mas não valores.

**Exemplo (SQLCipher, caminho recomendado):**

```dart
// pubspec: sqlcipher_flutter_libs: ^0.7.0  (build hooks — mesmo modelo do sqlite3 3.x)
import 'package:sqlite3/sqlite3.dart';
import '../security/secure_storage_service.dart';

Future<Database> openEncryptedDb(String path, SecureStorageService secure) async {
  // Chave mestra de 32 bytes gerada uma vez e guardada no Keystore/Keychain.
  var key = await secure.read('db_key');
  if (key == null) {
    final rng = Random.secure();
    key = base64UrlEncode(List<int>.generate(32, (_) => rng.nextInt(256)));
    await secure.write('db_key', key);
  }
  final db = sqlite3.open(path);
  db.execute("PRAGMA key = '$key';"); // SQLCipher deriva AES-256 da chave
  db.execute('PRAGMA cipher_memory_security = ON;');
  db.execute('PRAGMA foreign_keys = ON;');
  return db;
}
```

**Validação:** `flutter test` (novo teste: abrir DB cifrado, inserir venda, fechar, reabrir → dado presente e ilegível num `hexdump` do arquivo); `sqlite3 file.db` no terminal sem chave → `file is not a database`.

### V2 — Certificate pinning (Média)

**Evidência:** nenhum `badCertificateCallback`/`SecurityContext`/pinning no projeto; o `TimeoutRetryHttpClient` apenas delega ao `http.Client` (confia na cadeia do SO).

**Cenário:** em rede comprometida com CA user-installed (proxy corporativo, malware, Wi-Fi hostil), um MITM ativo lê o JWT (access/refresh) e todo o tráfego financeiro.

**Correção implementada (18/08):** ancoragem por cadeia no **intermediário WE1** (Google Trust Services) — não no leaf. O leaf do Supabase rotaciona (atual expira set/2026) sem quebrar o app; o WE1 é estável até 2028. Implementação:

- `lib/core/network/cert_pinning.dart` — API comum (`buildPinnedHttpClient()`, `buildBogusPinnedHttpClient()` para testes negativos); importa a impl de IO/Web por condicional;
- `cert_pinning_io.dart` — `SecurityContext(withTrustedRoots: false)` + `setTrustedCertificatesBytes` com o PEM do WE1 embutido (const): o client passa a confiar **apenas** na cadeia que chai até o WE1. MITM com CA user-installed → `HandshakeException` antes de qualquer HTTP (fail-closed);
- `cert_pinning_stub.dart` — web: fallback para a cadeia do SO (limitação documentada, igual à do secure storage na web — o pin real vale para Android/iOS/desktop);
- `supabase_bootstrap.dart` — o client pinado vira o `inner` do `TimeoutRetryHttpClient` (timeout + retry preservados).

**Validação (E2E no dispositivo real, 18/08):** `integration_test/cert_pinning_live_test.dart` conecta ao Supabase REAL com o client pinado — o handshake TLS valida contra o WE1 e a chamada HTTP chega ao servidor (status 401 do GoTrue sem token prova que o TLS passou); com a âncora falsa o handshake é **rejeitado** (`HandshakeException`). `cert_pinning_test.dart` (unit) valida que o PEM embutido parseia e bate com o fingerprint esperado.

> Operação: quando o Supabase rotacionar o intermediário, o WE1 embutido deve ser atualizado em PR junto com o PEM (o teste unit falha se o PEM for corrompido/trocado sem atualizar o fingerprint esperado).

**Validação:** teste com um proxy MITM (mitmproxy) com CA próprio → handshake recusado; com certificado legítimo → tráfego flui; `flutter analyze` limpo.

### V3 — MFA/Biometria (Média)

**Evidência:** `signInWithPassword` sem MFA; nenhum pacote de biometria; GoTrue tem MFA TOTP nativo (configuração externa — necessita validação).

**Correção:** habilitar MFA TOTP no Supabase (Authentication → MFA) + usar `local_auth` para desbloqueio por biometria no login em vez de digitar senha toda vez. O `flutter_secure_storage` já suporta `BiometricAuth` no iOS/Android.

```dart
// local_auth: ^2.x — gate biométrico antes de revelar a sessão restaurada
final auth = LocalAuthentication();
final ok = await auth.authenticate(
  localizedReason: 'Desbloqueie o Dumbhanengue com sua digital/Face ID',
  options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
);
if (!ok) return; // permanece na tela de login
```

**Validação:** teste manual em dispositivo com biometria configurada; teste de widget com `LocalAuthentication` mockado.

### V4 — Root/Jailbreak detection (Média)

**Correção:** pacote `root_detector` (ou `jailbreak_detection`) + detecção de debugger (`Debugger.isDebuggerAttached` via `dart:developer` é limitado — usar `Platform.isIOS/Android` + checagens de caminhos de root).

```dart
// root_detector: ^0.5.0
final isRooted = await RootDetector.detectRootAccess();
final isDebug = await RootDetector.detectDebugger();
if (isRooted || isDebug) {
  // Decisão de produto: bloquear, degradar (modo somente leitura) ou avisar.
  await CrashReporting.capture(StateError('root/debug'), StackTrace.current,
      hint: 'Dispositivo comprometido');
}
```

> Decisão de produto necessária: **bloquear** (seguro, UX dura) vs **avisar** (UX suave, risco residual). Para um POS de balcão, avisar + degradar é comum.

---

## 7. Hardening Android

| Item | Estado atual | Recomendação |
|---|---|---|
| `android:allowBackup` | `false` ✓ | Manter |
| `dataExtractionRules` | Exclui tudo ✓ | Manter |
| R8/minify + shrinkResources | Ativos ✓ (`build.gradle.kts`) | Manter |
| Ofuscação Dart | `--obfuscate --split-debug-info` (release.yml/ipa.yml) ✓ | Manter; iOS lane do Fastfile **não** ofusca (ver §9) |
| `usesCleartextTraffic` | Não definido (default = bloqueado em targetSdk 28+) ✓ | Manter (não habilitar cleartext) |
| Network Security Config | Não existe | Adicionar para pinning + bloquear tráfego user-CA em produção se desejado |
| Exported components | Só `MainActivity` (launcher + deep link) | Ok; o deep link aceita o scheme — validar host (V8) |
| Permissões | Só CAMERA ✓ (INTERNET via plugins + debug/profile) | Manter; auditar plugins que puxam permissões |
| Screenshot/recents | **Não protegido** (`FLAG_SECURE` ausente) | Avaliar `FLAG_SECURE` para telas financeiras (trade-off: impede captura legítima de suporte) |
| `FLAG_SECURE` | Ausente | Decisão de produto: aplicar nas telas de caixa/fiado |
| ProGuard rules | Padrão Flutter | Adicionar regras para manter classes do Sentry/Supabase se aparecerem no crash mapping |

---

## 8. Hardening iOS

| Item | Estado atual | Recomendação |
|---|---|---|
| ATS | Sem exceções (HTTPS obrigatório) ✓ | Manter |
| Keychain | Sessão + PKCE via `flutter_secure_storage` ✓ | Configurar `KeychainAccessibility.first_unlock_this_device` |
| `NSFaceIDUsageDescription` | Ausente | Adicionar se habilitar biometria (V3) |
| Backup | Arquivos locais **excluídos do backup iOS** (V9, corrigido 18/08) — DB + fotos marcados `NSURLIsExcludedFromBackupKey`; Android já exclui tudo | Rotação: validar no device real (iCloud) que o DB não aparece no backup |
| `UIFileSharingEnabled` | Não definido (off por padrão) ✓ | Manter off |
| Deep links | `CFBundleURLTypes` custom scheme | Considerar Universal Links (associar domínio) para eliminar conflito de scheme |
| Bitcode | `ENABLE_BITCODE = NO` ✓ | Manter (padrão atual) |
| Min. deployment | 13.0 | Ok |

---

## 9. Hardening Flutter/Dart

1. **Ofuscação consistente:** o lane `fastlane ios beta` (`flutter build ios --release`) **não** passa `--obfuscate --split-debug-info`, mas `ipa.yml` passa. Alinhar: adicionar `--obfuscate --split-debug-info=build/symbols` no Fastfile iOS.
2. **Logs:** `debugPrint` usado em `CrashReporting.capture` (só em `kDebugMode` — correto) e `AppDatabase` (só no catch de abertura). Sem logs de tokens/senhas. ✓
3. **Secrets:** anon key/URL/DSN embutidos por design (públicos); service role key ausente do client ✓. `env/prod.env` gitignored ✓; `env/dev.env` commitado com valores públicos (documentado) — aceitável, mas recomenda-se mover para secrets do CI.
4. **Validação de input:** formulários validam (email, senha forte no cadastro); RPCs revalidam no servidor ✓.
5. **`changePassword`:** reautentica com a senha atual antes de `updateUser` — mitigação correta contra sessão roubada trocando senha. ✓
6. **Sem `toString()` de entidades com dados sensíveis em logs** (freezed gera `toString` com campos — verificar que não é logado). Recomendação: revisar `debugPrint`/Sentry para não capturar payloads de `pending_ops`.

---

## 10. Hardening de APIs/Backend (Supabase)

| Área | Estado | Recomendação |
|---|---|---|
| RLS | Ativado em todas as tabelas, por tenant+loja, com `is_my_store`/`is_manager_of_store` ✓ | Reexecutar `sql_check_live.sh` após qualquer mudança |
| `SECURITY DEFINER` + `search_path` | Fixado em `public`/`extensions` ✓ | Manter; nunca `search_path` default |
| Anti-forja | Triggers forçam `user_id=auth.uid()` e `store_id` válido ✓ | Manter |
| Idempotência | Todas as RPCs de dinheiro idempotentes por id ✓ | Manter |
| TOCTOU | `lock_products_or_raise` + `FOR UPDATE` + advisory locks ✓ | Manter |
| Total = Σ itens | Validado em process_sale/process_purchase ✓ | Manter |
| Mass assignment | Triggers sobrescrevem `user_id`/`store_id`; `update_tenant_settings` só toca 2 colunas ✓ | Manter |
| Super admin | Tabela `super_admins` + RLS sem políticas + REVOKE ✓ | Manter; `promote_super_admin.sql` é manual/auditável |
| Audit log | Só decisões admin | Estender a operações de dinheiro (V13) |
| Rate limiting | **Não verificável do repo** (V7) | Validar no dashboard: GoTrue (sign-in/reset) tem limites por IP; RPCs de negócio podem precisar de `pg_net`/limites de aplicação |
| Email confirmation | **Não verificável do repo** | Validar se `require_email_confirmation` está ON em produção (crítico: sem ele, signup deixa conta ativa) |
| Storage buckets | Fotos: bucket público com escrita restrita à loja ✓ | Avaliar tornar leitura autenticada (produtos não precisam de CDN pública?) — trade-off com custo de CDN |
| Realtime | Só `store_employees` publicado ✓ | Manter mínimo |

---

## 11. Segurança de CI/CD e Supply Chain

| Item | Estado | Recomendação |
|---|---|---|
| `pubspec.lock` | Commitado ✓ | Manter |
| `flutter pub outdated` | Rodado no ciclo de auditoria anterior | Adicionar job periódico + `dependabot` |
| Ações do GitHub | Pinned por **tag** (`@v4`), não por SHA | Considerar pin por SHA (defesa contra supply chain) |
| Secrets | GitHub Secrets (keystore, Play, Apple, Supabase prod) ✓ | Manter; nunca em logs (verificar `set -x` ausente ✓) |
| Keystore | Base64 do secret → `key.properties` em runtime; `*.jks`/`key.properties` gitignored ✓ | Manter |
| Gate de cobertura | 45% ✓ | Subir progressivamente |
| Teste SQL/RLS no CI | `sql_check.sh` 12/12 em Postgres real ✓ | Excelente — manter |
| Artefatos | APK dev de validação + AAB prod + símbolos | Símbolos: mover para privado/expirar (V14) |
| Dependências | 189 entradas no lock, versões recentes (supabase_flutter 2.16, http 1.6, secure_storage 10.3, sentry 9.26, mobile_scanner 7.4) | Rodar `dependabot`/`flutter pub outdated` mensal |

---

## 12. Plano de Remediação por Prioridade

| Fase | Item | Esforço | Critério de saída |
|---|---|---|---|
| **Fase 1 (1–2 semanas)** | V1 SQLite cifrado (ou mover p/ pasta protegida + excluir backup) · V8/V12 validação de deep links · V9 backup iOS · V14 símbolos | ~2–3 dias | Testes verdes; `hexdump` do DB cifrado; deep link com host inválido rejeitado |
| **Fase 2 (2–4 semanas)** | V2 pinning SPKI (com 2 pins + rotação) · V5 senha temporária + troca no 1º login · V13 audit log de dinheiro | ~3–5 dias | MITM test bloqueado; fluxo de 1º login do funcionário testado |
| **Fase 3 (1–2 meses)** | V3 MFA/biometria · V4 root/debugger detection · `FLAG_SECURE` · `KeychainAccessibility` iOS · dependabot + pin por SHA | ~1 semana | Testes manuais em dispositivo rootado/JB; MFA habilitado e testado |
| **Contínuo** | Revalidar config externa do Supabase (email confirmation, rate limits, MFA) · `sql_check_live.sh` · `flutter pub outdated` mensal | — | Checklist abaixo verde |

---

## 13. Checklist Final de Segurança

### Armazenamento
- [ ] Tokens/sessão em Keychain/Keystore (nunca SharedPreferences) — **OK no código**
- [ ] Dados de negócio cifrados em repouso (SQLCipher) — **pendente (V1)**
- [ ] Backups Android desativados — **OK**
- [ ] Backups iOS excluídos — **OK (V9, 18/08)** — `NSURLIsExcludedFromBackupKey` via channel no DB + fotos; no-op fora do iOS

### Rede
- [ ] HTTPS obrigatório (sem cleartext) — **OK**
- [ ] Certificate pinning — **OK (V2, 18/08)** — `SecurityContext(withTrustedRoots: false)` + âncora WE1; fail-closed validado em device E2E
- [ ] Timeout/retry central — **OK**

### Autenticação/Autorização
- [ ] Senha forte no cadastro — **OK** (4 classes, ≥8)
- [ ] Reautenticação para trocar senha — **OK**
- [ ] MFA/biometria — **pendente (V3)**
- [ ] RLS por tenant+loja — **OK**
- [ ] Matriz de acesso no servidor (dono/gerente/funcionário) — **OK**
- [ ] Email confirmation validado em produção — **necessita validação**
- [ ] Rate limiting validado — **necessita validação**

### Código/Config
- [ ] Sem secrets privados no client — **OK** (só públicos por design)
- [ ] Sem logs de dados sensíveis — **OK** (rever Sentry para payloads)
- [ ] Ofuscação Dart no release — **parcial (falta iOS Fastfile)**
- [ ] R8/minify — **OK**
- [ ] `FLAG_SECURE` — **pendente (decisão)**

### CI/CD
- [ ] Lockfile commitado — **OK**
- [ ] Dependabot/pin por SHA — **pendente**
- [ ] Secrets em GitHub Secrets — **OK**
- [ ] sql_check no CI — **OK**

---

## 14. Testes a Executar Antes de Produção

1. **Dinâmico — MITM:** mitmproxy com CA próprio → handshake deve falhar após pinning (ou, hoje, deve falhar se a CA não estiver no trust store — verificar que **nenhum** cleartext é aceito).
2. **Estático — secrets:** `grep -r "service_role\|SUPABASE_SERVICE"` no APK extraído (`unzip -p app.apk` + `strings`) → nenhum secret privado.
3. **Armazenamento:** `adb backup` / iCloud → nenhum arquivo financeiro em backup (após V9); `hexdump` do DB → ilegível (após V1).
4. **Deep links:** `adb shell am start -a android.intent.action.VIEW -d "dumbhanengue://callback?code=..."` → fluxo correto; `dumbhanengue://evil` → rejeitado.
5. **IDOR/BOLA:** com JWT de um funcionário da loja A, tentar ler/gravar dados da loja B via PostgREST direto (fora do app) → RLS deve negar.
6. **RPC abuse:** chamar `process_sale` com total adulterado, estoque insuficiente, id duplicado → rejeitado/idempotente.
7. **Privilege escalation:** funcionário `employee` chama `process_purchase`/`close_cash_register`/`adjust_product_stock` → negado; `manager` → permitido.
8. **Root/JB:** instalar em dispositivo rootado → comportamento definido (após V4).
9. **Web:** verificar que o build web não vaza sessão em `localStorage` persistente além da sessão do browser; testar XSS básico na origem.
10. **Backup Play/App Store:** testar restore em dispositivo novo → app não restaura dados (offline) sem sync.

---

## 15. Riscos Residuais

| Risco | Nível | Mitigação |
|---|---|---|
| **Chave do SQLCipher no Keystore/Keychain do mesmo dispositivo** — root compromete as duas camadas | Médio | Aceitar (limite físico); avisar usuário em dispositivo rootado (V4) |
| **Pinning rompe em rotação de certificado do Supabase sem janela** | Médio | 2 pins + procedimento de rotação documentado; começar em report-only |
| **Funcionário com privilégio legítimo comete fraude** (registrar fiado falso, anular venda) | Médio | Audit log de operações de dinheiro (V13) + trilha `cancelled_at`/`decided_by` já existente |
| **Conta super admin comprometida** | Alto | MFA obrigatório para admin (V3), senha forte, rotação; acesso via `promote_super_admin.sql` auditável |
| **Email confirmation desativado em produção** | Alto se confirmado | **Validar imediatamente** no dashboard do Supabase (fora do repo) |
| **Web (localStorage)** | Médio | Documentar; restringir uso web a super admin; CSP no `index.html` |
| **Config do Supabase (rate limits, MFA, site_url)** | — | Revalidar no dashboard; registrar no `17-production-checklist.md` |

---

## Anexo A — Evidências coletadas (arquivos revisados)

- `lib/core/config/supabase_config.dart` (anon key pública por design; defaults dev)
- `lib/core/security/secure_storage_service.dart`, `secure_supabase_local_storage.dart` (sessão + PKCE no Keychain/Keystore; web = localStorage)
- `lib/core/network/supabase_bootstrap.dart` (guarda de release, HTTP client custom, authOptions)
- `lib/core/network/timeout_retry_http_client.dart` (timeout 20s, retry só GET/HEAD)
- `lib/core/network/deep_link_handler.dart` (sem validação de host/URI)
- `lib/core/database/app_database_io.dart` (SQLite em claro; migrações versionadas; outbox v2)
- `lib/data/datasources/auth/supabase_auth_remote_data_source.dart` (login/recovery/changePassword)
- `lib/presentation/screens/auth/auth_gate.dart` (fluxo de sessão/recovery/block de funcionário)
- `lib/presentation/screens/auth/login_screen.dart` (validação, 429 tratado)
- `lib/core/utils/password_policy.dart` (≥8, 4 classes no cadastro)
- `lib/core/observability/crash_reporting.dart` (Sentry, DSN público, beforeSend)
- `lib/data/services/offline_sync_service.dart` (outbox com payloads JSON)
- `android/app/src/main/AndroidManifest.xml` (backup off, deep link, CAMERA)
- `android/app/build.gradle.kts` (flavors, keystore, R8, guarda prod)
- `android/app/src/main/res/xml/data_extraction_rules.xml`
- `ios/Runner/Info.plist` (ATS sem exceções, deep link, permissões)
- `fastlane/Fastfile` (deploy Android com ofuscação; iOS lane sem ofuscação)
- `.github/workflows/{ci,release,ios,ipa}.yml` (secrets, artefatos, pinning por tag)
- `supabase/schema.sql` (RLS completo, RPCs idempotentes, triggers, audit log, super_admins, storage bucket)
- `env/dev.env`, `env/prod.env.example`, `.gitignore`, `android/key.properties.example`, `pubspec.lock` (189 deps)
- `docs/pt/AUDIT_REPORT.md`, `docs/pt/07-seguranca.md` (auditorias anteriores — continuidade)
