# TAREQO ERP — Production Readiness Checklist (English)

> Origin: E2E production audit (Aug 4, 2026). Base facts: `flutter analyze` clean · **381 tests green** (Aug 7) · Flutter 3.44.6 / Dart 3.12.2.
> Status legend: ✓ done (merged/verified) · ◐ in progress · ○ queued · ● blocked/needs external resource · ? needs verification outside the repo.
>
> Authoritative (Portuguese): [`../pt/PRODUCTION_CHECKLIST.md`](../pt/PRODUCTION_CHECKLIST.md) · audit details: [15-audit-status.md](15-audit-status.md) · migration runbooks: W4+H2 [16-migracao-w4-h2.md](16-migracao-w4-h2.md) · W11 (FIFO lots + weight sales) [18-migracao-w11.md](18-migracao-w11.md)

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
| 1.3 | Employee access to business data (RLS by store_employees) | ✓ | Store-scoped RLS `is_my_store()` applied to all business tables (C2, Aug 5) — employees see/write their own store's data; the owner covers all. |
| 1.4 | Plan-limit enforcement in DB (triggers on stores / store_employees) | ✓ | `enforce_store_limit` / `enforce_employee_limit` added to `schema.sql`; applied to live project (7.8). |
| 1.4b | **Access-level matrix (Aug 6):** purchases are MANAGER-level — owner or manager record/read purchases; a regular employee cannot (not even via direct PostgREST) | ✓ | Helper `is_manager_of_store` + `process_purchase` guard + `purchases`/`purchase_items` RLS policies in `schema.sql` and `supabase/upgrade.sql` (Part 4); UI hides Purchases/Reports (employee) and Stores (non-owner) via `currentAccessLevelProvider`; regression [8/8] in `sql_check.sh` (employee blocked, manager authorized). |
| 1.4c | **Employee activation + product creation (Aug 7):** the owner activates/deactivates employees (a deactivated employee loses access immediately, app and server); a regular employee does NOT create products — only sells | ✓ | `store_employees.is_active` (DEFAULT TRUE) + `set_employee_active` RPC (owner only) + `is_my_store`/`is_manager_of_store` requiring an ACTIVE link — `schema.sql` and `supabase/upgrade.sql` **Part 19**; AuthGate shows "Access suspended" for deactivated accounts; the "New product" FAB is hidden when `currentAccessLevelProvider == employee` (owner/manager keep it); `sql_check.sh` section [6b] (deactivate → `is_my_store` FALSE, reactivate → TRUE, non-owner rejected); tests 381/381. |
| 1.5 | Atomic stock decrement on Supabase (no lost updates) | ✓ | Solved inside `process_sale`/`process_purchase` RPCs (`FOR UPDATE` + guarded UPDATE). |
| 1.7 | Money as integer cents (replace double/REAL) | ✓ | **W4 (Aug 6 — final session):** full migration to **integer cents** — domain (`*Cents`), SQLite (`INTEGER` + idempotent ×100 migration by column affinity), Supabase (`BIGINT` + guarded ×100 migration — Part 7 of `supabase/upgrade.sql`), RPCs comparing in cents (no `ROUND(x*100)`), plan catalog in cents, UI (`Money.parse`/`Formatters.currency(cents)`). 381/381 tests green. |
| 1.10 | Collision-free IDs | ✓ | `AppIds.newId()` (timestamp + entropy) replaces all `microsecondsSinceEpoch` IDs. |
| 1.16 | `SettleDebtUseCase` inside `IUnitOfWork` (SQLite atomicity) | ✓ | Debt settlement + cash entry roll back together on SQLite. |
| 1.17 | **Critical (Aug 5):** operator-precedence bug in atomic RPCs — `'t' || p->>'id'` parses as `('t' || p)->>'id'` (`||` and `->>` share precedence), becoming jsonb concat → `22P02 Token "t" is invalid` on every sale/debt/purchase insert in Supabase mode | ✓ | Fixed with parentheses `'t' || (p->>'id')` (ids + descriptions in `process_sale`/`register_debt`/`process_purchase`), re-applied to live (7.8), E2E re-run **22/22**; `sql_check.sh` [4/4] executes the RPCs so it cannot regress silently. |
| 1.18 | **Aug 6:** `settle_debt` stamps the REALIZATION DATE (`date = now()`) on the linked pending entry — same semantics as the local `markAsPaid` (SQLite). Before, SaaS mode kept the entry's REGISTRATION date and cash flow recognized the receipt in the wrong period | ✓ | `schema.sql` + `supabase/upgrade.sql` (Part 8.3, idempotent) + date assertion in `sql_check.sh`. |

## 2. Security

| # | Item | Status | Notes |
|---|------|--------|-------|
| 2.1 | Verify email confirmation is enabled in Supabase | ? | Dashboard check required. |
| 2.2 | Enable 2FA on super-admin account | ● | Dashboard / Supabase feature. |
| 2.3 | Audit log for admin decisions (approve/reject/plan edits) | ✓ | **H8 (Aug 6):** full `audit_log` — DDL + triggers `trg_audit_*` (tenants/plan_requests/plans) + `get_audit_log` in `supabase/upgrade.sql` (Part 5) + `decided_by` (S4, Aug 5). Consistent with AUDIT_REPORT H8 ✓. |
| 2.4 | Remove dev Supabase URL/anon-key defaults; fail fast in release | ✓ | Fail-fast in release: `SupabaseBootstrap` throws if `SUPABASE_URL/SUPABASE_ANON_KEY` defaults are embedded in a NON-prod release (S2, Aug 5; **adjusted Aug 9** — deployment is a SINGLE Supabase project `dotklbpqmlnhcdifiukd` shared by dev/prod; a `prod` release with the project's own credentials is legitimate; `main.dart` still blocks releases without `--flavor prod`). dev/prod flavors implemented (7.2, Aug 5). |
| 2.5 | Login hardening: strict email, min-8 password, confirm field, visibility toggle | ✓ | `login_screen.dart`. EMPLOYEE password aligned to the 8-char minimum (M7, Aug 5). |
| 2.6 | AuthGate: explicit auth-stream error state (no silent login drop) | ✓ | `auth_gate.dart`. |
| 2.7 | Web CSP + metadata when web ships | ● | Metadata ✓ (Aug 5). CSP stays ● (only if web is a release target). |
| 2.8 | Crash reporting (Sentry/Crashlytics) | ✓ | Sentry integrated (`crash_reporting.dart`); DSN via `--dart-define=SENTRY_DSN`. Updated to sentry_flutter **9.26.0** (Aug 5) — 8.14.2 broke the release build (Kotlin 1.6 vs built-in 2.x). |
| 2.9 | Auth session in SECURE storage (Keychain/Keystore), not `shared_preferences` | ✓ | **S1 (Aug 6):** `SecureSupabaseLocalStorage` (session) + `SecureGotrueAsyncStorage` (PKCE code verifier) + `authOptions` in `SupabaseBootstrap` (native). The SDK default wrote access/refresh tokens in plaintext XML. Web keeps the default (flutter_secure_storage 10.x doesn't support web — documented limitation). Existing installs: 1 logout after the change (session migrates to Keychain/Keystore). |

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
| 4.1 | Pagination (.range/.limit) on all Supabase `getAll` | ✓ | **H2 (Aug 6 — final session):** **keyset** pagination on the `getAll` of the 6 remote datasources (products, sales, cash, credit, purchases, customers) — `fetchAllKeyset` helper (batches of `pageSize` keyed by the stable `id` cursor, `gt(id, last)` on the next page) replaces the single `.limit(1000)` that truncated stores with 10k+ rows; display order preserved (products re-sort by name in the datasource; the rest in the providers). |
| 4.2 | Server-side aggregation RPCs for KPIs/reports/cash flow | ✓ | **W5 (Aug 6):** `get_dashboard_kpis` RPC + provider with local fallback + migration `009`. **H2 (Aug 6 — final session):** new `get_cash_flow` (PAID entries in the period) and `get_sales_report` (revenue, gross profit, top 5 sellers and sales per day in the device timezone) — `SECURITY DEFINER` with `is_my_store` guard, BIGINT (cents) values. `GetCashFlowUseCase`/`GetSalesReportUseCase` gained an optional `serverRepository` (`SupabaseCashFlowRepository`/`SupabaseSalesReportRepository`, registered only in SaaS mode); local/tests keep client-side aggregation. Consolidated in `supabase/upgrade.sql` (Parts 8.6–8.7) + step **[11/11]** in `sql_check.sh`. |
| 4.3 | `SettleDebtUseCase` targeted lookups (WHERE id/debt_id) | ◐ | Supabase now delegates to the targeted `settle_debt` RPC (C4); composite path (SQLite/memory) still O(all debts + all transactions). |
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
| 6.1 | Supabase datasource contract tests | ◐ | The **money path has automated coverage via `sql_check.sh` (16/16, incl. W11: FIFO lots, purchases creating lots and the `stock = Σ lots` invariant)**, which EXECUTES `process_sale`/`register_debt`/`settle_debt`/`get_dashboard_kpis`/`get_cash_flow`/`get_sales_report` as `app_user` and verifies effects + values. Dart unit contract tests for the remote datasources remain (○). |
| 6.2 | SQL/RLS test suite (Docker Postgres + `sqlcheck_stub.sql`) | ✓ | H3 audit: `scripts/sql_check.sh` (non-superuser `app_user` role so RLS actually applies; schema apply + super admin + isolation). Re-validated **Aug 5** after C3/C4. **Extended with section [4/4] (Aug 5): EXECUTES `process_sale`/`register_debt`/`settle_debt` as `app_user` and verifies effects** (sale+item+stock+cash, debt+pending entry, settlement of the SAME pending entry, negative stock) — regression for bug 1.17 (22P02). **Aug 6:** REALIZATION-DATE assertion after `settle_debt` (1.18) + step **[10/10]** `get_dashboard_kpis` (baseline + delta after `process_sale`). **Final session (Aug 6):** steps **[1b]** (upgrade.sql applied 2× — idempotency), **[11/11]** (`get_cash_flow`/`get_sales_report` — H2) and **[12/12]** (W4 NUMERIC→cents migration with real data 25.50→2550, no double-apply). Run in CI (`sql-check` jobs of `ci.yml` + `release.yml`, Postgres 16, scram over TCP) — **12/12 green**. **Aug 9 (W11):** extended with the **FIFO lot decrease** in sales (nearest expiry first, surplus to the next lot), **purchases creating lots** (with optional expiry) and the **`stock = Σ lots` invariant** — **16/16 green**. |
| 6.3 | Widget tests: dashboard, customers, reports, purchases, admin, onboarding, auth_gate | ◐ | `auth_gate_test.dart` ✓ — 5 tests: admin role (DB) → AdminShell (incl. pending tenant), no role → tenant flow, transient failure fail-open, signed-out → Login. Other screens follow in audit §7. |
| 6.4 | Integration tests (`integration_test/`) | ✓ | `integration_test/access_levels_web_test.dart` (browser E2E of the owner/manager/employee access gating against the real Supabase, via `test_driver/`) — run with `flutter drive --no-dds --driver=test_driver/integration_test.dart --target=integration_test/access_levels_web_test.dart -d chrome --dart-define-from-file=env/dev.env` + `TEST_*` defines (chromedriver on port 4444; `--no-dds` works around the dwds AppConnectionException bug on Windows). **Re-validated Aug 6 post W4/H2 migration: PASS** (owner → everything; manager → purchases/reports without stores; employee → operations only). **+ `integration_test/cash_closing_summary_live_test.dart`** (E2E of the REAL payload of the `get_cash_closing_summary` RPC against Supabase: captures the exact `{p_store_id, p_day}` payload with the local day in UTC via an observation seam and forwards it to the real server — proves acceptance, coherent server-side aggregation (total = Σ by method; expected = cash only), the app's registered chain, and the `is_my_store` guard) — run with `flutter drive --no-dds --driver=test_driver/integration_test.dart --target=integration_test/cash_closing_summary_live_test.dart -d chrome --dart-define-from-file=env/dev.env` + `--dart-define=TEST_OWNER_EMAIL=... --dart-define=TEST_OWNER_PASSWORD=...`. |
| 6.5 | Coverage threshold in CI | ✓ | Active gate (Aug 5): `flutter test --coverage` fails below **45%** in CI. |
| 6.6 | New delegation tests for atomic processors (sale/purchase/debt) | ✓ | `process_sale_use_case_test.dart`, `add_purchase_use_case_test.dart`, `add_debt_use_case_test.dart`. |
| 6.7 | Unit test for collision-free `AppIds` | ✓ | `test/core/utils/ids_test.dart`. |
| 6.8 | Accessibility: 2.0 text-scale test + named UI constants | ✓ | W8 (Aug 6): `test/presentation/screens/accessibility_text_scale_test.dart` (login usable at max font scale) + `lowStockThreshold` on the dashboard (M8). |

## 7. Production operations

| # | Item | Status | Notes |
|---|------|--------|-------|
| 7.1 | Real Android signing config (no debug keys) | ✓ | Keystore `android/app/upload-keystore.jks` generated (alias `upload`, RSA 2048, valid until 2053) + `android/key.properties` filled in (gitignored; PKCS12 = single store/key password). Docs: `key.properties.example`, developer guide (pt/en). MISSING (external): publish the 1st AAB, activate Play App Signing and register the upload-key SHA-256 in the console. |
| 7.2 | Flavors dev/prod + dart-define strategy | ✓ | `dev` flavor (applicationIdSuffix `.dev`, label "TAREQO" — no visible suffix in the name) and `prod` in `build.gradle.kts`; mandatory defines via `--dart-define-from-file` (`env/dev.env`, `env/prod.env.example`); release guards: `main.dart` requires the `prod` flavor (`FLUTTER_APP_FLAVOR` is injected by the framework from `--flavor` — reserved define), `SupabaseBootstrap` rejects embedded dev defaults (S2), and Gradle fails `prodRelease` without a keystore (Aug 5). |
| 7.3 | CI/CD (GitHub Actions: analyze → test → build) | ✓ | `.github/workflows/ci.yml` — analyze, test+coverage, release APK build (dev flavor + `env/dev.env`), sql-check (Postgres service). Release: `.github/workflows/release.yml` (tag `v*` → Fastlane: signed prod AAB → Internal testing upload, Aug 5). |
| 7.4 | App icons, splash, branding, store metadata | ◐ | **Icons ✓ (W7, Aug 6):** Android adaptive (mipmap-anydpi-v26 + drawables), full iOS (21 images), web (favicon + manifest); sources in `assets/branding/` + generator `tool/generate_icons_test.dart`; template defaults removed. **Redesign v3 (Aug 8):** official dark "bag + D" source image (`assets/branding/dumbhanenge_logo.png`) — generator rewritten to process it (legacy/fg 62%/mono by chrome luminance) + dark `adaptive_icon_background` `#19191A`; natives regenerated. **Dark splash ✓ (Aug 8):** in-app (`_SplashScreen` + bundled `splash_logo.png`), native Android (launch_background + values-v31 for Android 12+) and iOS (storyboard + LaunchImage); web dark loading splash in `index.html`. **Official icon ✓ (v4.2, Aug 8):** source `assets/branding/icon_official.png` — user-provided design: **3D blue bag (sky-blue→indigo gradient) with white "D" and grommets**, white bg; **edge flood-fill keying** (preserves the enclosed "D"/grommets, removes bg+shadow) + white `adaptive_icon_background` `#FFFFFF`; mono by luminance 60; natives regenerated. Store metadata (consoles) remain external ●. |
| 7.5 | Privacy policy / ToS | ● | Legal. |
| 7.6 | Data backup/export | ○ | CSV export + Supabase backups. **DB backup flow exercised Aug 6** (pg_dump via pooler 5432 → `backup_pre_w4.sql`, gitignored) before the W4/H2 migration (7.8b). |
| 7.7 | Release build size budget (obfuscate, split-per-abi) | ○ | Add to build scripts. |
| 7.8 | `schema.sql` applied to live Supabase + read-only verification | ✓ | Aug 5, 2026: applied in ONE transaction (COMMIT) via pooler `aws-0-eu-north-1` (project `dotklbpqmlnhcdifiukd` — direct host is IPv6-only, use the pooler). Pre-apply finding: only the 13 base tables — the C3/C4 hardening layer had NEVER been applied (old email-based `is_super_admin`; no `settle_debt`, no atomic RPCs, no limit triggers). Post-apply: 14 tables · 52 policies · 39 indexes · 20 triggers · 17 functions · plans intact (3, no duplicates). Read-only re-verification **10/10 PASS** (`scripts/sql_check_live.sh`). |
| 7.8b | **`upgrade.sql` applied to live (W4 cents + H2 RPCs)** + read-only verification | ✓ | **Aug 6, 2026:** applied in ONE transaction (`-1`) via pooler `aws-0-eu-north-1` (PostgreSQL **17.6**): 9 money columns → `BIGINT` (cents), zero fractional values, H2 RPCs (`get_cash_flow`/`get_sales_report`/`get_dashboard_kpis`) active; `sql_check_live.sh` **14/14 PASS**; idempotency confirmed (re-apply without effect). Backup `backup_pre_w4.sql` (gitignored). **Runbook: [`docs/en/16-migracao-w4-h2.md`](16-migracao-w4-h2.md) (chapter 16)**. |
| 7.8c | **`upgrade.sql` Part 22 applied to live (W11: FIFO lots + weight sales, quantities ×1000)** + read-only verification | ○ | Pending: apply Part 22 of `supabase/upgrade.sql` (millesimal migration + lot backfill + FIFO RPCs) in ONE transaction, then `sql_check_live.sh` (now **31 checks**, incl. W11 25–31) + publish the W11 app in the same window (no legacy clients writing mixed scales). Post-migration invariant: `stock = Σ active lots` (check 31). **Runbook: [`docs/pt/16-migracao-w11.md`](../pt/16-migracao-w11.md) (cap 16)** / [18-migracao-w11.md](18-migracao-w11.md). |
| 7.9 | iOS pipeline (TestFlight) | ✓ | W1 (Aug 6): `ios/Podfile` + `ios_testflight` lane in the Fastfile + `.github/workflows/ios.yml` (macOS runner: analyze → test → build+sign iOS → TestFlight; secrets `ASC_KEY_ID`/`ASC_ISSUER_ID`/`ASC_KEY_BASE64`). Missing external: Apple account + certs in the repo secrets. |
| 7.10 | Go-live guide (ops) | ✓ | W3 (Aug 6): `docs/{pt,en}/14-go-live-ops.md` — CI secrets (`KEYSTORE_BASE64` + passwords, `PLAY_*`), keystore base64 export, Play Console checklist (Play App Signing, 2FA, email confirmation), TestFlight steps. |

## 8. Dependencies

| # | Item | Status | Notes |
|---|------|--------|-------|
| 8.1 | Remove `dio` | ✓ | Dead dependency removed. |
| 8.2 | Migrate `sqlite3` 2.9.0 → 3.x + `sqlite3_android` | ✓ | **W10 (Aug 6 — final session):** `sqlite3` **2.9.0 → ^3.5.1** — since 3.0.0 the package uses **build hooks (native assets)** and compiles/packages SQLite for Android/iOS/desktop; removed `sqlite3_flutter_libs` (EOL) and the manual loader (`open.overrideFor`/`DynamicLibrary`), `dispose()` → `close()`. No `sqlite3_android` needed (the hook covers Android). |
| 8.3 | `dart pub upgrade` + re-verify 175 tests | ✓ | **Aug 6 (final session):** after W10, `dart pub get` + full suite **300/300 tests green** + `flutter analyze` 0 issues. **Aug 7:** suite **381/381** (employee activation/deactivation + owner/manager product creation). |

## 9. Docs & housekeeping

| # | Item | Status | Notes |
|---|------|--------|-------|
| 9.1 | Update README/docs for removed `dio`/`Failure` and new RPC path | ✓ | Docs synced in the Aug 5/6 audits (en/pt): architecture without `Failure`, atomic RPCs, server-side KPIs, flavors, Android+iOS pipelines, guide 14 (go-live). |
| 9.2 | CHANGELOG + release process | ✓ | `CHANGELOG.md` created (Aug 6) with the full history (Aug 4/5/6 audits, features, fixes). |

---

## Immediate priorities (next working session)
1. **External (store blockers):** activate Play App Signing + register the upload-key SHA-256 (7.1); verify email confirmation ON + 2FA in the Supabase dashboard (2.1/2.2); Google Play/Apple accounts + CI secrets (7.9); privacy policy/ToS (7.5).
2. **W2** — billing (deferred by product decision; limits are already server-enforced).
3. ✓ **Apply `supabase/upgrade.sql` to the live Supabase + `sql_check_live.sh` 14/14** — **DONE Aug 6** (pooler eu-north-1, single transaction `-1`, PostgreSQL 17.6): 9 money columns → `bigint`, zero fractional values, **14/14 PASS**, idempotency confirmed; backup `backup_pre_w4.sql` (gitignored). Runbook: `docs/en/16-migracao-w4-h2.md`. *All internal items (W4, H2, W10, SQL consolidation, live apply) are done — only external (1) and W2 (2) remain.*
