# TAREQO ERP — Production Readiness Checklist

> Origin: E2E production audit (Aug 4, 2026). Base facts: `flutter analyze` clean · **381 tests green** (Aug 7) · Flutter 3.44.6 / Dart 3.12.2.
> Status legend: ✓ done (merged/verified) · ◐ in progress · ○ queued · ● blocked/needs external resource · ? needs verification outside the repo.

---

## 1. Data integrity & money path (CRITICAL)

| # | Item | Status | Notes |
|---|------|--------|-------|
| 1.1 | Atomic sale processing on Supabase (RPC `process_sale` + `SupabaseSaleProcessor`) | ✓ | Single DB transaction: sale+items, stock lock/dec, cash entry. Schema + wiring + tests. Live E2E **22/22 PASS (Aug 5)** + `sql_check.sh` now EXECUTES the RPC (6.2). |
| 1.1b | Atomic purchase processing on Supabase (RPC `process_purchase` + `SupabasePurchaseProcessor`) | ✓ | Mirrors sale path; shared `lock_products_or_raise` helper keeps both RPCs in sync. |
| 1.1c | Atomic debt registration on Supabase (`register_debt` RPC) | ✓ | Debt + linked pending entry in one DB transaction (composite path keeps deliberate lenient semantics on SQLite). Live E2E **22/22 PASS (Aug 5)**: `register_debt` + `settle_debt` on live project. |
| 1.1c2 | Atomic debt settlement on Supabase (`settle_debt` RPC) | ✓ | C4 audit: `settle_debt` RPC (SECURITY DEFINER, idempotent, store/tenant-scoped) + `SettleDebtUseCase` delegation via `IDebtAtomicProcessor.settle`. Schema applied to live project (7.8). |
| 1.1d | Idempotency in RPCs (retry-safe) | ✓ | `process_sale`/`process_purchase`/`register_debt` return early when the id already exists (id = idempotency key). |
| 1.2 | Super-admin role hardened (DB table/claims, not email string) | ✓ | C3 audit: `public.super_admins` table + `is_super_admin()` SECURITY DEFINER RPC (schema.sql) + client RPC check (`isSuperAdminProvider`). Schema applied to live project (7.8); verify email confirmation is ON in dashboard (2.1). |
| 1.3 | Employee access to business data (RLS by store_employees) | ✓ | Store-scoped RLS `is_my_store()` aplicado a todas as tabelas de negócio (C2, Aug 5) — funcionário vê/grava dados da própria loja; dono cobre todas. |
| 1.4 | Plan-limit enforcement in DB (triggers on stores / store_employees) | ✓ | `enforce_store_limit` / `enforce_employee_limit` added to `schema.sql`; applied to live project (7.8). |
| 1.4b | **Access-level matrix (Aug 6):** compras são nível GERENCIAL — dono ou gerente registram/lêem compras; funcionário comum não (nem mesmo via PostgREST direto) | ✓ | Helper `is_manager_of_store` + guarda do `process_purchase` + políticas RLS de `purchases`/`purchase_items` no `schema.sql` e no `supabase/upgrade.sql` (Parte 4); UI oculta Compras/Relatórios (funcionário) e Lojas (não-dono) via `currentAccessLevelProvider`; regressão [8/8] no `sql_check.sh` (funcionário bloqueado, gerente autorizado). |
| 1.4c | **Employee activation + product creation (Aug 7):** dono ativa/desativa funcionários (desativado perde o acesso na hora, app e servidor); funcionário comum NÃO cria produto — só vende | ✓ | `store_employees.is_active` (DEFAULT TRUE) + RPC `set_employee_active` (só dono) + `is_my_store`/`is_manager_of_store` exigindo vínculo ATIVO — `schema.sql` e `supabase/upgrade.sql` **Parte 19**; AuthGate mostra "Acesso suspenso" para desativados; FAB "Novo produto" oculto para `currentAccessLevelProvider == employee` (dono/gerente mantêm); `sql_check.sh` seção [6b] (desativa → `is_my_store` FALSE, reativa → TRUE, não-dono rejeitado); testes 381/381. |
| 1.5 | Atomic stock decrement on Supabase (no lost updates) | ✓ | Solved inside `process_sale`/`process_purchase` RPCs (`FOR UPDATE` + guarded UPDATE). |
| 1.7 | Money as integer cents (replace double/REAL) | ✓ | **W4 (Aug 6 — sessão final):** migração integral para **centavos inteiros** — domínio (`*Cents`), SQLite (`INTEGER` + migração ×100 idempotente por afinidade de coluna), Supabase (`BIGINT` + migração ×100 com guarda — Parte 7 do `supabase/upgrade.sql`), RPCs comparando em centavos (sem `ROUND(x*100)`), catálogo de planos em centavos, UI (`Money.parse`/`Formatters.currency(cents)`). 381/381 testes verdes. |
| 1.10 | Collision-free IDs | ✓ | `AppIds.newId()` (timestamp + entropy) replaces all `microsecondsSinceEpoch` IDs. |
| 1.16 | `SettleDebtUseCase` inside `IUnitOfWork` (SQLite atomicity) | ✓ | Debt settlement + cash entry roll back together on SQLite. |
| 1.17 | **Critical (Aug 5):** operator-precedence bug in atomic RPCs — `'t' || p->>'id'` parses as `('t' || p)->>'id'` (`||` and `->>` share precedence), becoming jsonb concat → `22P02 Token "t" is invalid` on every sale/debt/purchase insert in Supabase mode | ✓ | Fixed with parentheses `'t' || (p->>'id')` (ids + descriptions in `process_sale`/`register_debt`/`process_purchase`), re-applied to live (7.8), E2E re-run **22/22**; `sql_check.sh` [4/4] executes the RPCs so it cannot regress silently. |
| 1.18 | **Aug 6:** `settle_debt` carimba a DATA DE REALIZAÇÃO (`date = now()`) na pendência vinculada — mesmo semântica do `markAsPaid` local (SQLite). Antes, o modo SaaS mantinha a data do REGISTRO da pendência e o fluxo de caixa reconhecia o recebimento no período errado | ✓ | `schema.sql` + `supabase/upgrade.sql` (Parte 8.3, idempotente) + assert de data no `sql_check.sh`. |

## 2. Security

| # | Item | Status | Notes |
|---|------|--------|-------|
| 2.1 | Verify email confirmation is enabled in Supabase | ? | Dashboard check required. |
| 2.2 | Enable 2FA on super-admin account | ● | Dashboard / Supabase feature. |
| 2.3 | Audit log for admin decisions (approve/reject/plan edits) | ✓ | **H8 (Aug 6):** `audit_log` completa — DDL + triggers `trg_audit_*` (tenants/plan_requests/plans) + `get_audit_log` no `supabase/upgrade.sql` (Parte 5) + `decided_by` (S4, Aug 5). Consistente com o AUDIT_REPORT H8 ✓. |
| 2.4 | Remove dev Supabase URL/anon-key defaults; fail fast in release | ✓ | Fail-fast em release: `SupabaseBootstrap` lança se `SUPABASE_URL/SUPABASE_ANON_KEY` default embutidos em release NÃO-prod (S2, Aug 5; **ajustado Aug 9** — deployment é projeto Supabase ÚNICO `dotklbpqmlnhcdifiukd` compartilhado dev/prod; release `prod` com as credenciais do próprio projeto é legítimo; `main.dart` continua bloqueando release sem `--flavor prod`). Flavors dev/prod implementados (7.2, Aug 5). |
| 2.5 | Login hardening: strict email, min-8 password, confirm field, visibility toggle | ✓ | `login_screen.dart`. Senha de FUNCIONÁRIO alinhada ao mínimo 8 (M7, Aug 5). |
| 2.6 | AuthGate: explicit auth-stream error state (no silent login drop) | ✓ | `auth_gate.dart`. |
| 2.7 | Web CSP + metadata when web ships | ● | Metadata ✓ (Aug 5). CSP segue ● (só se web for alvo de release). |
| 2.8 | Crash reporting (Sentry/Crashlytics) | ✓ | Sentry integrado (`crash_reporting.dart`); DSN via `--dart-define=SENTRY_DSN`. Atualizado para sentry_flutter **9.26.0** (Aug 5) — o 8.14.2 quebrava o build de release (Kotlin 1.6 vs built-in 2.x). |
| 2.9 | Auth session em armazenamento SEGURO (Keychain/Keystore), não `shared_preferences` | ✓ | **S1 (Aug 6):** `SecureSupabaseLocalStorage` (sessão) + `SecureGotrueAsyncStorage` (code verifier PKCE) + `authOptions` no `SupabaseBootstrap` (nativo). O default do SDK gravava access/refresh tokens em XML em texto claro. Web mantém o default (flutter_secure_storage 10.x não suporta web — limitação documentada). Instalações existentes: 1 logout após a mudança (sessão migra para o Keychain/Keystore). |

## 3. Architecture & code quality

| # | Item | Status | Notes |
|---|------|--------|-------|
| 3.1 | Remove dead `dio` dependency + registration | ✓ | `pubspec.yaml` + `service_locator.dart`. |
| 3.2 | Remove unused `Failure` hierarchy | ✓ | `lib/core/errors/failure.dart` deleted (domain exceptions remain). |
| 3.3 | Rename `*LocalDataSource` contracts (misleading for Supabase impls) | ○ | Cosmetic; docs acknowledge. Low priority. |
| 3.4 | Map-based product lookup in sale/purchase sheets | ✓ | `new_sale_sheet.dart`, `add_purchase_sheet.dart`. |

## 4. Performance & scalability

| # | Item | Status | Notes |
|---|------|--------|-------|
| 4.1 | Pagination (.range/.limit) on all Supabase `getAll` | ✓ | **H2 (Aug 6 — sessão final):** paginação **keyset** no `getAll` dos 6 datasources remotos (produtos, vendas, caixa, fiado, compras, clientes) — helper `fetchAllKeyset` (lotes de `pageSize` pelo `id` como cursor estável, `gt(id, último)` na página seguinte) substitui o `.limit(1000)` único que truncava lojas com 10k+ linhas; ordenação de exibição preservada (produtos re-ordenam por nome no datasource; os demais nos providers). |
| 4.2 | Server-side aggregation RPCs for KPIs/reports/cash flow | ✓ | **W5 (Aug 6):** RPC `get_dashboard_kpis` + provider com fallback local + migração `009`. **H2 (Aug 6 — sessão final):** novas RPCs `get_cash_flow` (entradas/saídas PAID do período) e `get_sales_report` (faturamento, lucro bruto, top 5 vendidos e vendas por dia no fuso do dispositivo) — `SECURITY DEFINER` com guarda `is_my_store`, valores em BIGINT (centavos). `GetCashFlowUseCase`/`GetSalesReportUseCase` ganharam `serverRepository` opcional (`SupabaseCashFlowRepository`/`SupabaseSalesReportRepository`, registrados só no modo SaaS); local/testes continuam somando client-side. Consolidado em `supabase/upgrade.sql` (Partes 8.6–8.7) + passo **[11/11]** no `sql_check.sh`. |
| 4.3 | `SettleDebtUseCase` targeted lookups (WHERE id/debt_id) | ◐ | Supabase now delegates to the targeted `settle_debt` RPC (C4); composite path (SQLite/memória) still O(all debts + all transactions). |
| 4.4 | Defer SQLite open off the main isolate | ○ | Startup frame. |
| 4.5 | Offline cache + sync queue (local-first) | ● | Strategic; biggest UX win for target market. |

## 5. Business / SaaS

| # | Item | Status | Notes |
|---|------|--------|-------|
| 5.1 | Reject plan downgrade below current usage (DB trigger) | ○ | Extends §1.4 trigger work. |
| 5.2 | Payments/billing integration | ● | External service (Stripe/Mercado Pago). |
| 5.3 | Self-service upgrade/downgrade | ● | Depends on 5.2. |
| 5.4 | Delete/void/edit flows (products, customers, sales), stock adjustments | ○ | Merchants need these daily. |

## 6. Testing

| # | Item | Status | Notes |
|---|------|--------|-------|
| 6.1 | Supabase datasource contract tests | ◐ | O **money path tem cobertura automática via `sql_check.sh` (16/16, incl. W11: FIFO por lotes, compras criando lotes e a invariante `stock = Σ lotes`)**, que EXECUTA `process_sale`/`register_debt`/`settle_debt`/`get_dashboard_kpis`/`get_cash_flow`/`get_sales_report` como `app_user` e verifica efeitos + valores. Restam contract tests unitários Dart para os datasources remotos (○). |
| 6.2 | SQL/RLS test suite (Docker Postgres + `sqlcheck_stub.sql`) | ✓ | H3 audit: `scripts/sql_check.sh` (papel não-superusuário `app_user` para o RLS valer; schema apply + super admin + isolamento). Re-validado **Aug 5** pós-C3/C4. **Extendido com a seção [4/4] (Aug 5): EXECUTA `process_sale`/`register_debt`/`settle_debt` como `app_user` e verifica efeitos** (venda+item+estoque+caixa, dívida+pendência, quitação da MESMA pendência, negativo de estoque) — regressão do bug 1.17 (22P02). **Aug 6:** assert de DATA DE REALIZAÇÃO pós-`settle_debt` (1.18) + passo **[10/10]** `get_dashboard_kpis` (baseline + delta após `process_sale`). **Sessão final (Aug 6):** passos **[1b]** (upgrade.sql aplicado 2x — idempotência), **[11/11]** (`get_cash_flow`/`get_sales_report` — H2) e **[12/12]** (migração W4 NUMERIC→centavos com dado real 25.50→2550, sem dupla aplicação). Rodado no CI (jobs `sql-check` do `ci.yml` e `release.yml`, Postgres 16, scram via TCP) — **12/12 verdes**. **Aug 9 (W11):** estendido com a baixa **FIFO por lotes** na venda (validade mais próxima primeiro, excedente ao lote seguinte), **compra criando lotes** (com validade opcional) e a **invariante `stock = Σ lotes`** — **16/16 verdes**. |
| 6.3 | Widget tests: dashboard, customers, reports, purchases, admin, onboarding, auth_gate | ◐ | `auth_gate_test.dart` ✓ — 5 testes: papel admin (banco) → AdminShell (incl. tenant pendente), sem papel → fluxo do tenant, falha transitória fail-open, deslogado → Login. Demais telas seguem no audit §7. |
| 6.4 | Integration tests (`integration_test/`) | ✓ | `integration_test/access_levels_web_test.dart` (E2E browser do gating de acesso dono/gerente/funcionário contra o Supabase real, via `test_driver/`) — rodar com `flutter drive --no-dds --driver=test_driver/integration_test.dart --target=integration_test/access_levels_web_test.dart -d chrome --dart-define-from-file=env/dev.env` + defines `TEST_*` (chromedriver na porta 4444; `--no-dds` contorna o bug AppConnectionException do dwds no Windows). **Re-validado Aug 6 pós-migração W4/H2: PASS** (dono → tudo; gerente → compras/relatórios sem lojas; funcionário → só operação). **+ `integration_test/cash_closing_summary_live_test.dart`** (E2E do PAYLOAD REAL da RPC `get_cash_closing_summary` contra o Supabase: captura o payload exato `{p_store_id, p_day}` com o dia local em UTC via seam de observação e o encaminha ao servidor real — prova aceitação, agregação server-side coerente (total = Σ por forma; esperado = só dinheiro), a cadeia registrada do app e a guarda `is_my_store`) — rodar com `flutter drive --no-dds --driver=test_driver/integration_test.dart --target=integration_test/cash_closing_summary_live_test.dart -d chrome --dart-define-from-file=env/dev.env` + `--dart-define=TEST_OWNER_EMAIL=... --dart-define=TEST_OWNER_PASSWORD=...`. |
| 6.5 | Coverage threshold in CI | ✓ | Gate ativo (Aug 5): `flutter test --coverage` falha abaixo de **45%** no CI. |
| 6.6 | New delegation tests for atomic processors (sale/purchase/debt) | ✓ | `process_sale_use_case_test.dart`, `add_purchase_use_case_test.dart`, `add_debt_use_case_test.dart`. |
| 6.7 | Unit test for collision-free `AppIds` | ✓ | `test/core/utils/ids_test.dart`. |
| 6.8 | Acessibilidade: teste de escala de texto 2.0 + constantes nomeadas de UI | ✓ | W8 (Aug 6): `test/presentation/screens/accessibility_text_scale_test.dart` (login utilizável com fonte máxima) + `lowStockThreshold` no dashboard (M8). |

## 7. Production operations

| # | Item | Status | Notes |
|---|------|--------|-------|
| 7.1 | Real Android signing config (no debug keys) | ✓ | Keystore `android/app/upload-keystore.jks` gerado (alias `upload`, RSA 2048, válido até 2053) + `android/key.properties` preenchido (gitignored; PKCS12 = senha única store/key). Docs: `key.properties.example`, guia do dev (pt/en). FALTA (externo): publicar 1º AAB, ativar Play App Signing e registrar SHA-256 da upload key no console. |
| 7.2 | Flavors dev/prod + dart-define strategy | ✓ | Flavors `dev` (applicationIdSuffix `.dev`, label "TAREQO" — sem o sufixo no nome visível) e `prod` no `build.gradle.kts`; defines obrigatórios via `--dart-define-from-file` (`env/dev.env`, `env/prod.env.example`); guardas de release: `main.dart` exige flavor `prod` (`FLUTTER_APP_FLAVOR` é injetado pelo framework a partir do `--flavor` — define reservado), `SupabaseBootstrap` rejeita defaults de dev (S2) e o Gradle falha `prodRelease` sem keystore (Aug 5). |
| 7.3 | CI/CD (GitHub Actions: analyze → test → build) | ✓ | `.github/workflows/ci.yml` — analyze, test+coverage, build APK release (flavor dev + `env/dev.env`), sql-check (Postgres service). Release: `.github/workflows/release.yml` (tag `v*` → Fastlane: AAB prod assinado → upload Internal testing, Aug 5). |
| 7.4 | App icons, splash, branding, store metadata | ◐ | **Ícones ✓ (W7, Aug 6):** adaptativo Android (mipmap-anydpi-v26 + drawables), iOS completo (21 imagens), web (favicon + manifest); originais em `assets/branding/` + gerador `tool/generate_icons_test.dart`; ícones default do template removidos. **Redesign v3 (Aug 8):** imagem-fonte oficial dark "sacola + D" (`assets/branding/dumbhanenge_logo.png`) — gerador reescrito para processá-la (legacy/fg 62%/mono por luminância do cromado) + `adaptive_icon_background` dark `#19191A`; nativos regenerados. **Splash dark ✓ (Aug 8):** in-app (`_SplashScreen` + asset `splash_logo.png`), Android nativo (launch_background + valores-v31 p/ Android 12+) e iOS (storyboard + LaunchImage); web com splash de carregamento dark no `index.html`. **Ícone oficial ✓ (v4.2, Aug 8):** fonte `assets/branding/icon_official.png` — design enviado pelo usuário: **sacola azul 3D (gradiente azul-céu→índigo) com "D" branco e ilhós**, fundo branco; key por **flood-fill das bordas** (preserva o "D"/ilhós encerrados, remove fundo+sombra) + `adaptive_icon_background` branco `#FFFFFF`; mono por luminância 60; nativos regenerados. Store metadata (consoles) seguem externos ●. |
| 7.5 | Privacy policy / ToS | ● | Legal. |
| 7.6 | Data backup/export | ○ | CSV export + Supabase backups. **Fluxo de backup do DB exercitado Aug 6** (pg_dump via pooler 5432 → `backup_pre_w4.sql`, gitignored) antes da migração W4/H2 (7.8b). |
| 7.7 | Release build size budget (obfuscate, split-per-abi) | ○ | Add to build scripts. |
| 7.8 | `schema.sql` applied to live Supabase + read-only verification | ✓ | Aug 5, 2026: applied in ONE transaction (COMMIT) via pooler `aws-0-eu-north-1` (projeto `dotklbpqmlnhcdifiukd` — host direto é IPv6-only, usar o pooler). Achado pré-aplicação: apenas as 13 tabelas base — a camada de hardening C3/C4 NUNCA havia sido aplicada (is_super_admin antiga por e-mail; sem `settle_debt`, sem RPCs atômicos, sem triggers de limite). Pós-aplicação: 14 tabelas · 52 policies · 39 índices · 20 triggers · 17 funções · plans intactos (3, sem duplicatas). Re-verificação read-only **10/10 PASS** (`scripts/sql_check_live.sh`). |
| 7.8b | **`upgrade.sql` applied to live (W4 cents + H2 RPCs)** + read-only verification | ✓ | **Aug 6, 2026:** applied in ONE transaction (`-1`) via pooler `aws-0-eu-north-1` (PostgreSQL **17.6**): 9 colunas de dinheiro → `BIGINT` (centavos), zero valores fracionários, RPCs H2 (`get_cash_flow`/`get_sales_report`/`get_dashboard_kpis`) ativas; `sql_check_live.sh` **14/14 PASS**; idempotência confirmada (reaplicação sem efeito). Backup `backup_pre_w4.sql` (gitignored). **Runbook: [`docs/pt/15-migracao-w4-h2.md`](15-migracao-w4-h2.md) (cap 15)**. |
| 7.8c | **`upgrade.sql` Parte 22 aplicada no live (W11: lotes FIFO + vendas por peso, quantidades ×1000)** + verificação read-only | ✓ | **Verificada aplicada Aug 10, 2026** via `sql_check_live.sh` **35/35 PASS** (os checks W11 25–31 fazem parte do conjunto — incl. a invariante `stock = Σ lotes ativos`, check 31; a coluna `current_quantity` em milésimos e as RPCs FIFO estão presentes). Resta apenas PUBLICAR o app W11 (janela de compatibilidade: ver runbook). **Runbook: [`docs/pt/16-migracao-w11.md`](16-migracao-w11.md) (cap 16)**. |
| 7.8d | **`upgrade.sql` Parte 25+26 aplicada no live (fecho de caixa diário: cash_closings + close_cash_register + prévia get_cash_closing_summary)** + verificação read-only | ✓ | **Verificada aplicada Aug 10, 2026** — pré-flight (Passo 2 do runbook) já encontrou `cash_closings` presente (0 fechos); `sql_check_live.sh` **35/35 PASS** (checks 32–35 do fecho) + conferência manual (4.2/5): UNIQUE `(store_id, closing_date)` presente, RPCs `close_cash_register`/`get_cash_closing_summary` SECURITY DEFINER com `search_path=public, extensions`, 2 triggers (`user_id`/`store_id`), 4 policies, índice `idx_cash_closings_store`; **0 fechos** (a migração não insere dados) e tabelas de negócio intactas (20 vendas / 2 compras / 25 produtos). **Resta publicar o app com o Z-report (Passo 6 do runbook — externo).** **Runbook: [`docs/pt/17-migracao-fecho-caixa.md`](17-migracao-fecho-caixa.md) (cap 17)**. |
| 7.9 | Pipeline iOS (TestFlight) | ✓ | W1 (Aug 6): `ios/Podfile` + lane `ios_testflight` no Fastfile + `.github/workflows/ios.yml` (runner macOS: analyze → test → build+sign iOS → TestFlight; secrets `ASC_KEY_ID`/`ASC_ISSUER_ID`/`ASC_KEY_BASE64`). Falta externo: conta Apple + certs nos secrets do repo. |
| 7.10 | Guia de go-live (ops) | ✓ | W3 (Aug 6): `docs/{pt,en}/14-go-live-ops.md` — secrets do CI (`KEYSTORE_BASE64` + senhas, `PLAY_*`), export base64 do keystore, checklist Play Console (Play App Signing, 2FA, confirmação de e-mail), passos do TestFlight. |

## 8. Dependencies

| # | Item | Status | Notes |
|---|------|--------|-------|
| 8.1 | Remove `dio` | ✓ | Dead dependency removed. |
| 8.2 | Migrate `sqlite3` 2.9.0 → 3.x + `sqlite3_android` | ✓ | **W10 (Aug 6 — sessão final):** `sqlite3` **2.9.0 → ^3.5.1** — desde a 3.0.0 o pacote usa **build hooks (native assets)** e compila/empacota o SQLite para Android/iOS/desktop; removidos `sqlite3_flutter_libs` (EOL) e o loader manual (`open.overrideFor`/`DynamicLibrary`), `dispose()` → `close()`. Nenhum `sqlite3_android` é necessário (o hook cobre o Android). |
| 8.3 | `dart pub upgrade` + re-verify 175 tests | ✓ | **Aug 6 (sessão final):** após o W10, `dart pub get` + suíte completa **300/300 testes verdes** + `flutter analyze` 0 issues. **Aug 7:** suíte **381/381** (ativação/desativação de funcionários + criação de produtos dono/gerente). |

## 9. Docs & housekeeping

| # | Item | Status | Notes |
|---|------|--------|-------|
| 9.1 | Update README/docs for removed `dio`/`Failure` and new RPC path | ✓ | Docs sincronizados nas auditorias Aug 5/6 (en/pt): arquitetura sem `Failure`, RPCs atômicos, KPIs no servidor, flavors, pipelines Android+iOS, guia 14 (go-live). |
| 9.2 | CHANGELOG + release process | ✓ | `CHANGELOG.md` criado (Aug 6) com o histórico completo (auditorias Aug 4/5/6, features, fixes). |

---

## Immediate priorities (next working session)
1. **Externos (bloqueadores de loja):** ativar Play App Signing + registrar o SHA-256 da upload key (7.1); verificar e-mail de confirmação ON + 2FA no dashboard do Supabase (2.1/2.2); contas Google Play/Apple + secrets no CI (7.9); privacy policy/ToS (7.5).
2. **W2** — billing (adiado por decisão de produto; limites já no servidor).
3. ✓ **Aplicar o `supabase/upgrade.sql` ao Supabase live + `sql_check_live.sh` 14/14** — **FEITO Aug 6** (pooler eu-north-1, transação única `-1`, PostgreSQL 17.6): 9 colunas de dinheiro → `bigint`, zero fracionários, **14/14 PASS**, idempotência confirmada; backup `backup_pre_w4.sql` (gitignored). Runbook: `docs/pt/15-migracao-w4-h2.md`. **Aug 10: `sql_check_live.sh` 35/35 PASS** — confirma W11 (Parte 22) e fecho de caixa (Partes 25+26) também aplicados no live (7.8c/7.8d). *Todos os itens internos (W4, H2, W10, W11, fecho de caixa, consolidação SQL, aplicações no live) estão concluídos — restam só os externos (1) e W2 (2).*
