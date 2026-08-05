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
| 1.3 | Employee access to business data (RLS by store_employees) | 🔴 | Product decision: share owner `user_id` vs. employee-scoped policies. |
| 1.4 | Plan-limit enforcement in DB (triggers on stores / store_employees) | ✅ | `enforce_store_limit` / `enforce_employee_limit` added to `schema.sql`; applied to live project (7.8). |
| 1.5 | Atomic stock decrement on Supabase (no lost updates) | ✅ | Solved inside `process_sale`/`process_purchase` RPCs (`FOR UPDATE` + guarded UPDATE). |
| 1.7 | Money as integer cents (replace double/REAL) | ⏳ | Large migration; queued after release blockers. |
| 1.10 | Collision-free IDs | ✅ | `AppIds.newId()` (timestamp + entropy) replaces all `microsecondsSinceEpoch` IDs. |
| 1.16 | `SettleDebtUseCase` inside `IUnitOfWork` (SQLite atomicity) | ✅ | Debt settlement + cash entry roll back together on SQLite. |
| 1.17 | **Critical (Aug 5):** operator-precedence bug in atomic RPCs — `'t' || p->>'id'` parses as `('t' || p)->>'id'` (`||` and `->>` share precedence), becoming jsonb concat → `22P02 Token "t" is invalid` on every sale/debt/purchase insert in Supabase mode | ✅ | Fixed with parentheses `'t' || (p->>'id')` (ids + descriptions in `process_sale`/`register_debt`/`process_purchase`), re-applied to live (7.8), E2E re-run **22/22**; `sql_check.sh` [4/4] executes the RPCs so it cannot regress silently. |

## 2. Security

| # | Item | Status | Notes |
|---|------|--------|-------|
| 2.1 | Verify email confirmation is enabled in Supabase | ❓ | Dashboard check required. |
| 2.2 | Enable 2FA on super-admin account | 🔴 | Dashboard / Supabase feature. |
| 2.3 | Audit log for admin decisions (approve/reject/plan edits) | ⏳ | Add `decided_by` + `audit_log` table. |
| 2.4 | Remove dev Supabase URL/anon-key defaults; fail fast in release | ⏳ | Requires flavors/dart-define strategy. |
| 2.5 | Login hardening: strict email, min-8 password, confirm field, visibility toggle | ✅ | `login_screen.dart`. |
| 2.6 | AuthGate: explicit auth-stream error state (no silent login drop) | ✅ | `auth_gate.dart`. |
| 2.7 | Web CSP + metadata when web ships | 🔴 | Only if web is a release target. |
| 2.8 | Crash reporting (Sentry/Crashlytics) | 🔴 | External service + credentials. |

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
| 6.2 | SQL/RLS test suite (Docker Postgres + `sqlcheck_stub.sql`) | ✅ | H3 audit: `scripts/sql_check.sh` (papel não-superusuário `app_user` para o RLS valer; schema apply + super admin + isolamento). Re-validado **Aug 5** pós-C3/C4. **Extendido com a seção [4/4] (Aug 5): EXECUTA `process_sale`/`register_debt`/`settle_debt` como `app_user` e verifica efeitos** (venda+item+estoque+caixa, dívida+pendência, quitação da MESMA pendência, negativo de estoque) — regressão do bug 1.17 (22P02). PASS local contra Postgres 16 (exit 0). |
| 6.3 | Widget tests: dashboard, customers, reports, purchases, admin, onboarding, auth_gate | 🔄 | `auth_gate_test.dart` ✅ — 5 testes: papel admin (banco) → AdminShell (incl. tenant pendente), sem papel → fluxo do tenant, falha transitória fail-open, deslogado → Login. Demais telas seguem no audit §7. |
| 6.4 | Integration tests (`integration_test/`) | 🔴 | None today. |
| 6.5 | Coverage threshold in CI | 🔄 | CI roda `flutter test --coverage` + resumo de %; definir a linha de base e fixar o gate. |
| 6.6 | New delegation tests for atomic processors (sale/purchase/debt) | ✅ | `process_sale_use_case_test.dart`, `add_purchase_use_case_test.dart`, `add_debt_use_case_test.dart`. |
| 6.7 | Unit test for collision-free `AppIds` | ✅ | `test/core/utils/ids_test.dart`. |

## 7. Production operations

| # | Item | Status | Notes |
|---|------|--------|-------|
| 7.1 | Real Android signing config (no debug keys) | ✅ | Keystore `android/app/upload-keystore.jks` gerado (alias `upload`, RSA 2048, válido até 2053) + `android/key.properties` preenchido (gitignored; PKCS12 = senha única store/key). Docs: `key.properties.example`, guia do dev (pt/en). FALTA (externo): publicar 1º AAB, ativar Play App Signing e registrar SHA-256 da upload key no console. |
| 7.2 | Flavors dev/prod + dart-define strategy | 🔴 | Tied to 2.4. |
| 7.3 | CI/CD (GitHub Actions: analyze → test → build) | ✅ | H3 audit: `.github/workflows/ci.yml` — analyze, test+coverage, build APK release, sql-check (Postgres service). |
| 7.4 | App icons, splash, branding, store metadata | 🔴 | Assets + store console. |
| 7.5 | Privacy policy / ToS | 🔴 | Legal. |
| 7.6 | Data backup/export | ⏳ | CSV export + Supabase backups. |
| 7.7 | Release build size budget (obfuscate, split-per-abi) | ⏳ | Add to build scripts. |
| 7.8 | `schema.sql` applied to live Supabase + read-only verification | ✅ | Aug 5, 2026: applied in ONE transaction (COMMIT) via pooler `aws-0-eu-north-1` (projeto `dotklbpqmlnhcdifiukd` — host direto é IPv6-only, usar o pooler). Achado pré-aplicação: apenas as 13 tabelas base — a camada de hardening C3/C4 NUNCA havia sido aplicada (is_super_admin antiga por e-mail; sem `settle_debt`, sem RPCs atômicos, sem triggers de limite). Pós-aplicação: 14 tabelas · 52 policies · 39 índices · 20 triggers · 17 funções · plans intactos (3, sem duplicatas). Re-verificação read-only **10/10 PASS** (`scripts/sql_check_live.sh`). |

## 8. Dependencies

| # | Item | Status | Notes |
|---|------|--------|-------|
| 8.1 | Remove `dio` | ✅ | Dead dependency removed. |
| 8.2 | Migrate `sqlite3` 2.9.0 → 3.x + `sqlite3_android` | ⏳ | `sqlite3_flutter_libs` is EOL (`0.6.0+eol`); plan migration + re-run Windows tests. |
| 8.3 | `dart pub upgrade` + re-verify 175 tests | ⏳ | After 8.2. |

## 9. Docs & housekeeping

| # | Item | Status | Notes |
|---|------|--------|-------|
| 9.1 | Update README/docs for removed `dio`/`Failure` and new RPC path | ⏳ | Docs currently reference both. |
| 9.2 | CHANGELOG + release process | ⏳ | Single commit today. |

---

## Immediate priorities (next working session)
1. **Keystore de release (7.1)** — gerar o upload keystore, preencher `android/key.properties` (gitignored) e ativar o Play App Signing.
2. **1.3** — employee RLS decision + implementation.
3. **9.1** — sync docs with today's changes (dio/Failure removal + RPC path + CI/signing).
4. **Dashboard** — verify email confirmation is ON + enable 2FA on the super-admin account (2.1/2.2).
5. **6.5** — medir a cobertura no CI e fixar o gate de limite.
