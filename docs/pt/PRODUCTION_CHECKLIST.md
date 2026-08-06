# Dumbhanengue ERP — Production Readiness Checklist

> Origin: E2E production audit (Aug 4, 2026). Base facts: `flutter analyze` clean · 175 tests green · Flutter 3.44.6 / Dart 3.12.2.
> Status legend: ✅ done (merged/verified) · 🔄 in progress · ⏳ queued · 🔴 blocked/needs external resource · ❓ needs verification outside the repo.

---

## 1. Data integrity & money path (CRITICAL)

| # | Item | Status | Notes |
|---|------|--------|-------|
| 1.1 | Atomic sale processing on Supabase (RPC `process_sale` + `SupabaseSaleProcessor`) | ✅ | Single DB transaction: sale+items, stock lock/dec, cash entry. Schema + wiring + tests. Live E2E **22/22 PASS (Aug 5)** + `sql_check.sh` now EXECUTES the RPC (6.2). |
| 1.1b | Atomic purchase processing on Supabase (RPC `process_purchase` + `SupabasePurchaseProcessor`) | ✅ | Mirrors sale path; shared `lock_products_or_raise` helper keeps both RPCs in sync. |
| 1.1c | Atomic debt registration on Supabase (`register_debt` RPC) | ✅ | Debt + linked pending entry in one DB transaction (composite path keeps deliberate lenient semantics on SQLite). Live E2E **22/22 PASS (Aug 5)**: `register_debt` + `settle_debt` on live project. |
| 1.1c2 | Atomic debt settlement on Supabase (`settle_debt` RPC) | ✅ | C4 audit: `settle_debt` RPC (SECURITY DEFINER, idempotent, store/tenant-scoped) + `SettleDebtUseCase` delegation via `IDebtAtomicProcessor.settle`. Schema applied to live project (7.8). |
| 1.1d | Idempotency in RPCs (retry-safe) | ✅ | `process_sale`/`process_purchase`/`register_debt` return early when the id already exists (id = idempotency key). |
| 1.2 | Super-admin role hardened (DB table/claims, not email string) | ✅ | C3 audit: `public.super_admins` table + `is_super_admin()` SECURITY DEFINER RPC (schema.sql) + client RPC check (`isSuperAdminProvider`). Schema applied to live project (7.8); verify email confirmation is ON in dashboard (2.1). |
| 1.3 | Employee access to business data (RLS by store_employees) | ✅ | Store-scoped RLS `is_my_store()` aplicado a todas as tabelas de negócio (C2, Aug 5) — funcionário vê/grava dados da própria loja; dono cobre todas. |
| 1.4 | Plan-limit enforcement in DB (triggers on stores / store_employees) | ✅ | `enforce_store_limit` / `enforce_employee_limit` added to `schema.sql`; applied to live project (7.8). |
| 1.4b | **Access-level matrix (Aug 6):** compras são nível GERENCIAL — dono ou gerente registram/lêem compras; funcionário comum não (nem mesmo via PostgREST direto) | ✅ | Helper `is_manager_of_store` + guarda do `process_purchase` + políticas RLS de `purchases`/`purchase_items` no `schema.sql` e na migração `007_manager_purchase_gate.sql`; UI oculta Compras/Relatórios (funcionário) e Lojas (não-dono) via `currentAccessLevelProvider`; regressão [8/8] no `sql_check.sh` (funcionário bloqueado, gerente autorizado). |
| 1.5 | Atomic stock decrement on Supabase (no lost updates) | ✅ | Solved inside `process_sale`/`process_purchase` RPCs (`FOR UPDATE` + guarded UPDATE). |
| 1.7 | Money as integer cents (replace double/REAL) | 🔄 | Migração integral segue ⏳; mitigação H1 aplicada: helper `Money` (soma/multiplicação em centavos) em todos os acúmulos de use cases + somas da UI (dashboard, customers, carrinho). |
| 1.10 | Collision-free IDs | ✅ | `AppIds.newId()` (timestamp + entropy) replaces all `microsecondsSinceEpoch` IDs. |
| 1.16 | `SettleDebtUseCase` inside `IUnitOfWork` (SQLite atomicity) | ✅ | Debt settlement + cash entry roll back together on SQLite. |
| 1.17 | **Critical (Aug 5):** operator-precedence bug in atomic RPCs — `'t' || p->>'id'` parses as `('t' || p)->>'id'` (`||` and `->>` share precedence), becoming jsonb concat → `22P02 Token "t" is invalid` on every sale/debt/purchase insert in Supabase mode | ✅ | Fixed with parentheses `'t' || (p->>'id')` (ids + descriptions in `process_sale`/`register_debt`/`process_purchase`), re-applied to live (7.8), E2E re-run **22/22**; `sql_check.sh` [4/4] executes the RPCs so it cannot regress silently. |
| 1.18 | **Aug 6:** `settle_debt` carimba a DATA DE REALIZAÇÃO (`date = now()`) na pendência vinculada — mesmo semântica do `markAsPaid` local (SQLite). Antes, o modo SaaS mantinha a data do REGISTRO da pendência e o fluxo de caixa reconhecia o recebimento no período errado | ✅ | `schema.sql` + `migrations/004_settle_debt_realization_date.sql` (idempotente) + assert de data no `sql_check.sh`. |

## 2. Security

| # | Item | Status | Notes |
|---|------|--------|-------|
| 2.1 | Verify email confirmation is enabled in Supabase | ❓ | Dashboard check required. |
| 2.2 | Enable 2FA on super-admin account | 🔴 | Dashboard / Supabase feature. |
| 2.3 | Audit log for admin decisions (approve/reject/plan edits) | 🔄 | `decided_by` (UUID) + trigger `set_decided_by` em tenants/plan_requests (S4, Aug 5). Tabela `audit_log` completa segue ⏳. |
| 2.4 | Remove dev Supabase URL/anon-key defaults; fail fast in release | ✅ | Fail-fast em release: `SupabaseBootstrap` lança se `SUPABASE_URL/SUPABASE_ANON_KEY` default embutidos (S2, Aug 5). Flavors dev/prod implementados (7.2, Aug 5). |
| 2.5 | Login hardening: strict email, min-8 password, confirm field, visibility toggle | ✅ | `login_screen.dart`. Senha de FUNCIONÁRIO alinhada ao mínimo 8 (M7, Aug 5). |
| 2.6 | AuthGate: explicit auth-stream error state (no silent login drop) | ✅ | `auth_gate.dart`. |
| 2.7 | Web CSP + metadata when web ships | 🔴 | Metadata ✅ (Aug 5). CSP segue 🔴 (só se web for alvo de release). |
| 2.8 | Crash reporting (Sentry/Crashlytics) | ✅ | Sentry integrado (`crash_reporting.dart`); DSN via `--dart-define=SENTRY_DSN`. Atualizado para sentry_flutter **9.26.0** (Aug 5) — o 8.14.2 quebrava o build de release (Kotlin 1.6 vs built-in 2.x). |
| 2.9 | Auth session em armazenamento SEGURO (Keychain/Keystore), não `shared_preferences` | ✅ | **S1 (Aug 6):** `SecureSupabaseLocalStorage` (sessão) + `SecureGotrueAsyncStorage` (code verifier PKCE) + `authOptions` no `SupabaseBootstrap` (nativo). O default do SDK gravava access/refresh tokens em XML em texto claro. Web mantém o default (flutter_secure_storage 10.x não suporta web — limitação documentada). Instalações existentes: 1 logout após a mudança (sessão migra para o Keychain/Keystore). |

## 3. Architecture & code quality

| # | Item | Status | Notes |
|---|------|--------|-------|
| 3.1 | Remove dead `dio` dependency + registration | ✅ | `pubspec.yaml` + `service_locator.dart`. |
| 3.2 | Remove unused `Failure` hierarchy | ✅ | `lib/core/errors/failure.dart` deleted (domain exceptions remain). |
| 3.3 | Rename `*LocalDataSource` contracts (misleading for Supabase impls) | ⏳ | Cosmetic; docs acknowledge. Low priority. |
| 3.4 | Map-based product lookup in sale/purchase sheets | ✅ | `new_sale_sheet.dart`, `add_purchase_sheet.dart`. |

## 4. Performance & scalability

| # | Item | Status | Notes |
|---|------|--------|-------|
| 4.1 | Pagination (.range/.limit) on all Supabase `getAll` | ⏳ | High impact at 10k+ rows. |
| 4.2 | Server-side aggregation RPCs for KPIs/reports/cash flow | ⏳ | Replaces client-side full-table sums. |
| 4.3 | `SettleDebtUseCase` targeted lookups (WHERE id/debt_id) | 🔄 | Supabase now delegates to the targeted `settle_debt` RPC (C4); composite path (SQLite/memória) still O(all debts + all transactions). |
| 4.4 | Defer SQLite open/seed off the main isolate | ⏳ | Startup frame. |
| 4.5 | Offline cache + sync queue (local-first) | 🔴 | Strategic; biggest UX win for target market. |

## 5. Business / SaaS

| # | Item | Status | Notes |
|---|------|--------|-------|
| 5.1 | Reject plan downgrade below current usage (DB trigger) | ⏳ | Extends §1.4 trigger work. |
| 5.2 | Payments/billing integration | 🔴 | External service (Stripe/Mercado Pago). |
| 5.3 | Self-service upgrade/downgrade | 🔴 | Depends on 5.2. |
| 5.4 | Delete/void/edit flows (products, customers, sales), stock adjustments | ⏳ | Merchants need these daily. |

## 6. Testing

| # | Item | Status | Notes |
|---|------|--------|-------|
| 6.1 | Supabase datasource contract tests | ⏳ | Money path has zero automated coverage today. |
| 6.2 | SQL/RLS test suite (Docker Postgres + `sqlcheck_stub.sql`) | ✅ | H3 audit: `scripts/sql_check.sh` (papel não-superusuário `app_user` para o RLS valer; schema apply + super admin + isolamento). Re-validado **Aug 5** pós-C3/C4. **Extendido com a seção [4/4] (Aug 5): EXECUTA `process_sale`/`register_debt`/`settle_debt` como `app_user` e verifica efeitos** (venda+item+estoque+caixa, dívida+pendência, quitação da MESMA pendência, negativo de estoque) — regressão do bug 1.17 (22P02). **Aug 6:** assert de DATA DE REALIZAÇÃO pós-`settle_debt` (1.18). PASS local contra Postgres 16 (exit 0). |
| 6.3 | Widget tests: dashboard, customers, reports, purchases, admin, onboarding, auth_gate | 🔄 | `auth_gate_test.dart` ✅ — 5 testes: papel admin (banco) → AdminShell (incl. tenant pendente), sem papel → fluxo do tenant, falha transitória fail-open, deslogado → Login. Demais telas seguem no audit §7. |
| 6.4 | Integration tests (`integration_test/`) | 🔴 | None today. |
| 6.5 | Coverage threshold in CI | ✅ | Gate ativo (Aug 5): `flutter test --coverage` falha abaixo de **45%** no CI. |
| 6.6 | New delegation tests for atomic processors (sale/purchase/debt) | ✅ | `process_sale_use_case_test.dart`, `add_purchase_use_case_test.dart`, `add_debt_use_case_test.dart`. |
| 6.7 | Unit test for collision-free `AppIds` | ✅ | `test/core/utils/ids_test.dart`. |

## 7. Production operations

| # | Item | Status | Notes |
|---|------|--------|-------|
| 7.1 | Real Android signing config (no debug keys) | ✅ | Keystore `android/app/upload-keystore.jks` gerado (alias `upload`, RSA 2048, válido até 2053) + `android/key.properties` preenchido (gitignored; PKCS12 = senha única store/key). Docs: `key.properties.example`, guia do dev (pt/en). FALTA (externo): publicar 1º AAB, ativar Play App Signing e registrar SHA-256 da upload key no console. |
| 7.2 | Flavors dev/prod + dart-define strategy | ✅ | Flavors `dev` (applicationIdSuffix `.dev`, label "Dumbhanengue Dev") e `prod` no `build.gradle.kts`; defines obrigatórios via `--dart-define-from-file` (`env/dev.env`, `env/prod.env.example`); guardas de release: `main.dart` exige flavor `prod` (`FLUTTER_APP_FLAVOR` é injetado pelo framework a partir do `--flavor` — define reservado), `SupabaseBootstrap` rejeita defaults de dev (S2) e o Gradle falha `prodRelease` sem keystore (Aug 5). |
| 7.3 | CI/CD (GitHub Actions: analyze → test → build) | ✅ | `.github/workflows/ci.yml` — analyze, test+coverage, build APK release (flavor dev + `env/dev.env`), sql-check (Postgres service). Release: `.github/workflows/release.yml` (tag `v*` → Fastlane: AAB prod assinado → upload Internal testing, Aug 5). |
| 7.4 | App icons, splash, branding, store metadata | 🔴 | Label Android capitalizado + web metadata ✅ (Aug 5). Ícones/splash/store seguem 🔴. |
| 7.5 | Privacy policy / ToS | 🔴 | Legal. |
| 7.6 | Data backup/export | ⏳ | CSV export + Supabase backups. |
| 7.7 | Release build size budget (obfuscate, split-per-abi) | ⏳ | Add to build scripts. |
| 7.8 | `schema.sql` applied to live Supabase + read-only verification | ✅ | Aug 5, 2026: applied in ONE transaction (COMMIT) via pooler `aws-0-eu-north-1` (projeto `dotklbpqmlnhcdifiukd` — host direto é IPv6-only, usar o pooler). Achado pré-aplicação: apenas as 13 tabelas base — a camada de hardening C3/C4 NUNCA havia sido aplicada (is_super_admin antiga por e-mail; sem `settle_debt`, sem RPCs atômicos, sem triggers de limite). Pós-aplicação: 14 tabelas · 52 policies · 39 índices · 20 triggers · 17 funções · plans intactos (3, sem duplicatas). Re-verificação read-only **10/10 PASS** (`scripts/sql_check_live.sh`). |

## 8. Dependencies

| # | Item | Status | Notes |
|---|------|--------|-------|
| 8.1 | Remove `dio` | ✅ | Dead dependency removed. |
| 8.2 | Migrate `sqlite3` 2.9.0 → 3.x + `sqlite3_android` | 🔄 | `sqlite3_flutter_libs` atualizado 0.5.27 → **0.6.0+eol** (Aug 5) — corrigiu build de release quebrado (a 0.5.27 era compilada contra android-32). Migração completa para `sqlite3_android` + `sqlite3` 3.x segue ⏳. |
| 8.3 | `dart pub upgrade` + re-verify 175 tests | ⏳ | After 8.2. |

## 9. Docs & housekeeping

| # | Item | Status | Notes |
|---|------|--------|-------|
| 9.1 | Update README/docs for removed `dio`/`Failure` and new RPC path | ⏳ | Docs currently reference both. |
| 9.2 | CHANGELOG + release process | ✅ | `CHANGELOG.md` criado (Aug 6) com o histórico completo (auditorias Aug 4/5/6, features, fixes). |

---

## Immediate priorities (next working session)
1. **Keystore de release (7.1)** — gerar o upload keystore, preencher `android/key.properties` (gitignored) e ativar o Play App Signing.
2. **1.3** — employee RLS decision + implementation.
3. **9.1** — sync docs with today's changes (dio/Failure removal + RPC path + CI/signing).
4. **Dashboard** — verify email confirmation is ON + enable 2FA on the super-admin account (2.1/2.2).
5. **6.5** — medir a cobertura no CI e fixar o gate de limite.
