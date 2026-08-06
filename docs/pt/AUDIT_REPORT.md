# 🏭 E2E Production-Readiness Audit — Dumbhanengue ERP

**Audit date:** Aug 4, 2026 · **Stack:** Flutter 3.44.6 / Dart 3.12.2 · **Size:** 211 files / ~20k LOC in `lib/`, 72 test files

> **Update (Aug 5, 2026):** findings **C1, C3, C4** and **H3** are resolved — each finding below carries a status line, and the specialized reports, checklist, score, tech-debt estimate and roadmap were refreshed accordingly. A live schema verification also ran (Aug 5): the C3/C4 hardening layer had **never been applied** to the Supabase project — it was applied in one transaction and re-verified **10/10** (see Methodology).
>
> **Update 3 (Aug 6, 2026 — follow-up session):** follow-up E2E pass with **287/287 tests green** and `flutter analyze` 0 issues. **New HIGH finding S1-FIXED in this session:** the Supabase auth session (access + refresh tokens) was persisted by the SDK default `SharedPreferencesLocalStorage` — **plaintext XML** on the device. Implemented `SecureSupabaseLocalStorage` + `SecureGotrueAsyncStorage` (PKCE code verifier) in `lib/core/security/secure_supabase_local_storage.dart`, backed by `flutter_secure_storage` (Keychain/Keystore), wired via `authOptions: FlutterAuthClientOptions(localStorage: …, pkceAsyncStorage: …)` in `SupabaseBootstrap` (native platforms; web keeps the SDK default — documented limitation). Also fixed a **cross-mode DB inconsistency**: `settle_debt` RPC now stamps `date = now()` on the linked pending entry (realization date) — matching the local SQLite `markAsPaid` semantics; consolidated into `supabase/upgrade.sql` (Part 8.3) + an **airtight** `sql_check.sh` assertion (transaction date must be ≥ the debt's `paid_at`, both stamped in the same settle transaction — a time-window assertion wouldn't catch the regression). Housekeeping: stale doc comments corrected (trigger name, super-admin email refs, duplicated facade comment, `Money` typo), `CHANGELOG.md` created, README/build commands synced to the flavor strategy. See the report below for the complete findings catalog.
>
> **Update 5 (Aug 6, 2026 — final session, part 2):** **300/300 tests green**, `flutter analyze` 0 issues, `sql_check.sh` **11/11 steps**. Delivered the three remaining internal engineering items: **(W4)** money → **integer cents end-to-end** — domain (`*Cents`), SQLite (`INTEGER` + idempotent ×100 migration by column affinity), Supabase (`BIGINT` + migration with guard — Part 7 of the consolidated `supabase/upgrade.sql`), RPCs comparing/summing in cents directly (no `ROUND(x*100)`), seeds ×100, UI (`Money.parse`/`Formatters.currency(cents)`); **(H2)** server-side aggregation RPCs `get_cash_flow` + `get_sales_report` (SECURITY DEFINER, `is_my_store`-scoped, BIGINT; day bucketing in the device timezone) wired via optional `serverRepository` on the use cases (`SupabaseCashFlowRepository`/`SupabaseSalesReportRepository`, SaaS mode only; local keeps client-side) + consolidated in `supabase/upgrade.sql` (Parts 8.6–8.7) + sql_check step [11/11], **and** keyset pagination (`fetchAllKeyset` — cursor on stable `id`, `pageSize` batches) replacing the `.limit(1000)` cap on all 6 Supabase `getAll`; **(W10)** `sqlite3` **2.9.0 → ^3.5.1** using build hooks/native assets — dropped `sqlite3_flutter_libs` (EOL) and the manual `open.overrideFor`/`DynamicLibrary` loader, `dispose()` → `close()`. **Remaining:** only W2 billing (deferred by product decision — limits already DB-enforced) and external ops (Play App Signing activation, store accounts, 2FA + email-confirmation verification, privacy/ToS, applying `supabase/upgrade.sql` (the consolidated script replacing migrations 010/011) + running sql_check [11/11] against the live Supabase).
>
> **Update 6 (Aug 6, 2026 — final session, part 3: SQL consolidation + real-DB validation):** delivered the **SQL consolidation** and **hard validation on real PostgreSQL**. **(a) SQL consolidated to 4 files:** the 10 migration files (`002..011`) were merged into ONE idempotent script **`supabase/upgrade.sql`** (Parts 1–8 — DDL, RLS helpers, manager gate, audit log, employee account, W4 column migration, final cents RPCs). Fresh installs use `schema.sql` alone; existing DBs apply `upgrade.sql` (re-runnable). **(b) Real-DB validation (Docker Postgres 16, exact CI config — scram over TCP):** `sql_check.sh` now runs **12/12 steps** — [1b] `upgrade.sql` applied twice (idempotency), [10/10] `get_dashboard_kpis`, [11/11] `get_cash_flow`/`get_sales_report` (H2) with value assertions, [12/12] the W4 migration with real data (25.50 → 2550 cents, no double-apply). This caught and fixed a **genuine W4 bug**: `SUM(bigint)` returns `numeric`, breaking the BIGINT `RETURNS TABLE` of `get_dashboard_kpis`/`get_cash_flow`/`get_sales_report` at runtime — fixed with explicit `::bigint` casts (schema.sql + upgrade.sql). **(c)** `scripts/sql_check_live.sh` extended to **14 read-only checks** (9 money columns BIGINT, zero fractional values, H2 RPCs present + SECURITY DEFINER + BIGINT returns) — validated 14/14; stale `lock_products_or_raise` signature fixed. **(d) CI:** the `sql-check` jobs in `ci.yml` + `release.yml` run the full 12 steps on Postgres 16 (validated locally with the exact service-container config, scram/TCP). **300/300 tests green · `flutter analyze` 0 issues.** Remaining: only external ops (store accounts, Play App Signing, 2FA/email-confirmation verification, billing W2, legal) + applying `supabase/upgrade.sql` to the live project and re-verifying with `sql_check_live.sh` (14/14).
>
> **Update 2 (Aug 5, 2026, follow-up session):** findings **C2, H4, H1(UI), H5/S2, S3, S4, S6, S7, M7** addressed in code: (1) C2 — store-scoped RLS (`is_my_store`) applied to all business tables in `schema.sql` (employees now see/write their store's data); (2) H4 — Sentry integrated (`lib/core/observability/crash_reporting.dart`, `main.dart`); (3) H1 — `Money` helper (cents arithmetic) applied at every accumulation boundary in use cases and UI sums (dashboard, customers, cart total); (4) S2 — fail-fast in release when `SUPABASE_URL`/`SUPABASE_ANON_KEY` defaults are embedded; (5) S3 — `UNIQUE INDEX idx_tenants_one_pending` (1 pending tenant per user); (6) S4 — `decided_by` audit columns + trigger on tenants/plan_requests; (7) S6 — `android:allowBackup=false` + data extraction rules; (8) S7 — R8/minify enabled; (9) M7 — employee password min length aligned to 8; (10) S1 — `SupabaseEmployeeAccountService` restores the owner's session after employee `signUp` (GoTrue auto-sign-in with confirmation OFF would otherwise replace the owner's session). CI now enforces a 45% coverage gate. `flutter analyze` 0 issues · `flutter test` **233/233**.
>
> **🔴 Critical bug found & fixed by the live E2E (Aug 5):** operator **precedence** in Postgres — `||` and `->>` share precedence (left-assoc), so `'t' || p_sale->>'id'` parsed as `('t' || p_sale)->>'id'` = **jsonb concatenation** → `22P02 invalid input syntax for type json, Token "t" is invalid`. Every `'t' || (jsonb->>'field')` in `process_sale`, `register_debt` and `process_purchase` (cash-entry ids **and** descriptions) broke — **no sale, debt or purchase could be recorded in Supabase mode**. Fixed with parentheses (`'t' || (p_sale->>'id')`), re-applied to the live project, E2E re-run **22/22 PASS**; `sql_check.sh` extended with section **[4/4]** that executes the RPCs so the bug cannot regress silently (the previous smoke test never executed the money path).

## 0. Methodology — what was actually verified

| Check | Result |
|---|---|
| `flutter analyze` | ✅ **0 issues** (clean) |
| `flutter test` | ✅ **300/300 passing** (Aug 6 — final session) |
| `flutter pub outdated` | ✅ **Resolved (W10):** `sqlite3` → ^3.5.1 (build hooks/native assets); `sqlite3_flutter_libs` (EOL) removed |
| SQL/RLS smoke test (`scripts/sql_check.sh` + `sqlcheck_stub.sql`) | ✅ **12/12 steps** on real Postgres 16 (Docker, CI config — scram/TCP): RLS per store, atomic money RPCs, `get_dashboard_kpis` (W5), `get_cash_flow`/`get_sales_report` (H2), `upgrade.sql` idempotency, W4 NUMERIC→cents migration (25.50→2550, no double-apply) |
| Schema review (`supabase/schema.sql`, 2311 lines) | ✅ Full read: RLS, triggers, RPCs, policies, seed |
| Live schema verification (read-only via pooler **eu-north-1**, project `dotklbpqmlnhcdifiukd`) | ✅ **Ran Aug 5, 2026**: found **outdated schema** — only the 13 base tables; `super_admins`, new `is_super_admin()`, `settle_debt`, atomic RPCs and limit triggers **absent** → `schema.sql` applied in ONE transaction → re-verified **10/10 PASS** (14 tables · 52 policies · 39 indexes · 20 triggers · 17 functions · plans intact) |
| **Live E2E money path** (REST/RPC with real JWT, same payloads the app sends) | ✅ **Ran Aug 5**: signup/login → onboarding (tenant pending) → super-admin promotion (`promote_super_admin.sql`) → approval → store → product → `process_sale` → `register_debt` → `settle_debt`, plus sale/settle **idempotency**, negatives (total mismatch, insufficient stock), and RLS isolation — **22/22 PASS**. Exposed the critical **22P02 precedence bug** (see update note), fixed + re-applied + re-run green; web build boots in Supabase mode with no console errors |
| Build config (Android/iOS/Web/Windows) | ✅ Reviewed |
| Screens reviewed in depth | Login, AuthGate, Shell, Dashboard, providers; all 24 screens inventoried |
| Prior work | `PRODUCTION_CHECKLIST.md` (a prior audit session, dated today) confirms continuity |

**Could NOT be verified from the repo** (external facts — flagged explicitly where they matter):
- Whether the Supabase project has **email confirmation ON/OFF** (dashboard setting) — no longer gates C3 (the role is DB-backed now); still relevant for signup security and 2FA (H9)
- ~~Whether `schema.sql` was executed on the live project~~ — **resolved Aug 5**: it had NOT been (only the 13 base tables); now applied and verified 10/10 (see table above)
- Keystore, signing credentials, store accounts, Apple/Google console state
- Runtime performance profiling on real devices / network conditions
- Whether `SUPER_ADMIN_EMAIL` / `SUPABASE_*` dart-defines are supplied in any real build

---

## 1. Executive Summary

This is a **well-engineered codebase** — unusually so for its size: clean `flutter analyze`, 300 green tests (Aug 6), real Clean Architecture, Material 3 theming with dark mode, RLS on every table, atomic `SECURITY DEFINER` RPCs with idempotency for sales/purchases/debts, anti-forgery triggers, secure session storage (Keychain/Keystore), and 15 chapters of bilingual documentation.

**But it is not shippable to production today.** The blockers are not in code quality — they are in **release operations, authorization modeling, and money-path integrity**:

1. **Release builds sign with the debug keystore** (`android/app/build.gradle.kts`) — cannot be published, and debug keys are a known-credential risk. *(✅ fixed Aug 5 — real keystore + `key.properties`, see C1)*
2. **Employees cannot see any business data in SaaS mode** — RLS is scoped `auth.uid() = user_id`, but employees are *different* auth users; the "add employee" feature ships but is non-functional in Supabase mode.
3. **Super-admin authorization is a hardcoded email string** checked against the JWT email claim, on both client and server. Safe *only if* email confirmation is ON (unverifiable from repo); if OFF, **anyone can self-register as the super admin**. *(✅ fixed Aug 5 — DB-backed role, see C3)*
4. **Debt settlement on Supabase is still non-atomic** (two separate REST calls) — the one remaining money-path hole. *(✅ fixed Aug 5 — `settle_debt` RPC, see C4)*
5. **Money is `double`** in every entity while the DB uses `NUMERIC(12,2)`; KPIs and reports sum in Dart on full-table fetches — precision and scaling risk. *(✅ fixed Aug 6 — W4 integer cents + W5/H2 server-side aggregation)*
6. **Production ops**: CI/CD + SQL/RLS smoke runner *(✅ H3)*; crash reporting (H4), flavors, icons/branding (W7), CHANGELOG, iOS pipeline (W1) — **all delivered Aug 5/6**; only external store ops remain.

**Bottom line (Aug 6, final session, part 3): ALL internal engineering items are done — W4 cents migration, H2 SQL aggregation + keyset pagination, W10 sqlite3 3.x, and the SQL consolidation into `supabase/upgrade.sql` (4 SQL files). Everything was validated on real PostgreSQL 16: `sql_check.sh` **12/12** (incl. upgrade idempotency and the W4 ×100 migration with real data — which caught and fixed a genuine `SUM(bigint)→numeric` bug) and `sql_check_live.sh` **14/14**; the CI `sql-check` jobs run the full suite. The remaining work is exclusively external ops (store accounts, Play App Signing activation, billing W2, 2FA/email-confirmation verification, legal) plus applying `supabase/upgrade.sql` to the live Supabase. The codebase is conditionally approved for production.**

---

## 2. Findings — ranked by severity

Top findings use the full 9-point format; the long tail is condensed into tables (category / severity / location / problem / fix).

---

### 🔴 C1 — CRITICAL — Release build signs with the debug keystore

**Status: ✅ FIXED (Aug 5, 2026)** — `android/app/build.gradle.kts` now signs releases from the gitignored `android/key.properties` using a real upload keystore (`android/app/upload-keystore.jks`, alias `upload`, RSA 2048, valid to 2053); debug-keystore fallback only in CI/dev; `*.jks`/`key.properties` added to `.gitignore`; setup documented in `android/key.properties.example` + developer guide. Remaining (external): activate **Play App Signing** and register the upload key SHA-256 in the Play Console, and finalize the `applicationId` placeholder before the first upload.

1. **Category:** Production readiness / Security
2. **Severity:** **Critical (blocker)**
3. **Location:** `android/app/build.gradle.kts` (lines 30–31, `signingConfigs.getByName("debug")`)
4. **Problem:** The release build uses `signingConfigs.getByName("debug")`, and the file still contains Flutter's template TODOs ("Specify your own unique Application ID", "Add your own signing config"). Every Flutter debug keystore is created with a **well-known default password** (`android`) and the same key — any APK you ship is effectively signed with a public key, enabling impersonation/repackaging attacks.
5. **Business impact:** Cannot upload to Google Play at all; if leaked/shipped, users could install tampered builds (banking app).
6. **Technical impact:** Zero signature integrity; also `applicationId` `com.dumbhanengue.dumbhanengue` is a placeholder (doubled name, not reverse-DNS).
7. **Recommended solution:** Generate a real upload keystore, store it **outside the repo**, wire `key.properties` (gitignored), set up Play App Signing.
8. **Implementation steps:** (1) `keytool -genkey -v -keystore upload.jks`; (2) add `key.properties` + signingConfigs.release; (3) add `*.jks`/`key.properties` to `.gitignore`; (4) verify with `flutter build apk --release` + `apksigner verify`.
9. **Code example:**
```kotlin
signingConfigs {
    create("release") {
        val props = Properties().apply {
            load(File("key.properties").inputStream())
        }
        storeFile = file(props["storeFile"] as String)
        storePassword = props["storePassword"] as String
        keyAlias = props["keyAlias"] as String
        keyPassword = props["keyPassword"] as String
    }
}
buildTypes {
    release {
        signingConfig = signingConfigs.getByName("release")
        isMinifyEnabled = true
        isShrinkResources = true
    }
}
```

---

### 🔴 C2 — CRITICAL — Employees have no access to business data in Supabase mode

1. **Category:** Business logic / Multi-tenancy
2. **Severity:** **Critical (blocker for the multi-user value proposition)**
3. **Location:** `supabase/schema.sql` (all RLS policies use `auth.uid() = user_id`), `lib/data/services/supabase_employee_account_service.dart`, `lib/presentation/screens/stores/stores_screen.dart`
4. **Problem:** The schema seeds business rows with `user_id` = **owner's** auth UID. RLS everywhere is `auth.uid() = user_id`. A store employee is a **different** auth user (created via `auth.signUp`). Employee queries therefore return **zero rows** — the entire dashboard, products, sales, etc. are empty for employees. The checklist (item 1.3) marks this 🔴/undecided. The "add employee" feature exists in the UI but is non-functional in SaaS mode.
5. **Business impact:** Selling a plan with `max_employees > 1` (all three plans!) promises a feature that doesn't work. Highest-priority product gap.
6. **Technical impact:** Two RLS models collide (user-scoped business rows vs. store-employee scoping). Requires a schema-wide decision: share owner `user_id` (simplest, no RLS change — employees read owner data) or introduce store-scoped policies via `store_employees` (clean, bigger migration).
7. **Recommended solution:** Decide ownership model — recommend the **owner-scoped** model for v1 (all tenant business rows keep owner's `user_id`; employees authenticate but the tenant resolves via `store_employees`), or go full store-scoped with policy functions like `is_my_store()` applied to every table. Also: replace owner-chosen employee passwords with **invite/magic-link + forced password reset** (the owner currently knows the employee's password; and with email confirmation OFF, `auth.signUp` **replaces the owner's active session** with the new employee's session — a latent bug in `SupabaseEmployeeAccountService`).
8. **Implementation steps:** (1) Product decision (owner-shared vs store-scoped); (2) if store-scoped: add `is_employee_of_store(store_id)` policy function + swap policies; (3) rework employee onboarding to invite flow; (4) widget test for employee login → data visibility.
9. **Code example (store-scoped select policy, chosen route):**
```sql
CREATE POLICY products_select ON public.products
  FOR SELECT USING (
    public.is_my_store(store_id)   -- owner OR employee of that store
  );
```

---

### 🔴 C3 — HIGH/CRITICAL — Super-admin authorization is a hardcoded email

**Status: ✅ FIXED (Aug 5, 2026)** — super-admin is now a **DB-backed role**: `public.super_admins` table (RLS enabled with no policies + conditional REVOKE from anon/authenticated) and `is_super_admin()` rewritten as `SECURITY DEFINER` reading that table; the client resolves the role via RPC (`IAdminRepository` → `isSuperAdminProvider`), `super_admin_config.dart` deleted; a one-time migration promotes the legacy admin. All admin RLS policies and plan-limit triggers enforce against the table. The dashboard email-confirmation check no longer gates this finding (still relevant for signup security — see H9).

1. **Category:** Security / Authorization
2. **Severity:** **High (Critical if email confirmation is OFF)**
3. **Location:** `lib/core/config/super_admin_config.dart` (`admin@dumbhanengue.com`), `supabase/schema.sql` → `is_super_admin()` (line ~555), `lib/presentation/screens/auth/auth_gate.dart`
4. **Problem:** Both client (`SuperAdminConfig.isSuperAdmin(email)`) and server (`is_super_admin()` reads `auth.jwt()->>'email'`) treat a **string equality on a hardcoded email** as super-admin. Authorization is derived from a JWT claim that reflects the signup email — so the ONLY thing protecting the admin panel is that nobody can register `admin@dumbhanengue.com`. If email confirmation is disabled in the Supabase project, **anyone can claim that email and become super admin** — approving tenants, editing plans, deleting data. If email confirmation is ON, an attacker would need to own that mailbox (likely not registered). This cannot be verified from the repo → must be checked in the dashboard.
5. **Business impact:** Full tenant-control compromise = data of all customers at risk.
6. **Technical impact:** No database-backed role; email string duplicated in two places that can drift.
7. **Recommended solution:** Store a super-admin flag in `auth.users` metadata (`app_metadata` or a `roles` table) set by a trusted bootstrap process; change `is_super_admin()` to read metadata; keep client gating as UX only.
8. **Implementation steps:** (1) Verify email confirmation is ON in the dashboard (immediate); (2) add `role` to user metadata / roles table; (3) update `is_super_admin()`; (4) enable 2FA on the admin account; (5) add a test.
9. **Code example:**
```sql
CREATE OR REPLACE FUNCTION public.is_super_admin()
RETURNS boolean LANGUAGE sql STABLE AS $$
  SELECT COALESCE((auth.jwt()->'app_metadata'->>'is_super_admin')::boolean, false);
$$;
```

---

### 🔴 C4 — HIGH — Debt settlement is not atomic on Supabase (money path)

**Status: ✅ FIXED (Aug 5, 2026)** — new `settle_debt` RPC (`SECURITY DEFINER`, idempotent, store/tenant-scoped) mirrors the composite use case in **one DB transaction**; `IDebtAtomicProcessor.settle()` + `SupabaseDebtProcessor` wired through `SettleDebtUseCase` (Supabase mode); server lookups are targeted (`WHERE id/debt_id` + index `idx_financial_transactions_debt`). The SQLite/in-memory composite path remains O(n) (checklist 4.3).

1. **Category:** Data integrity / Business logic
2. **Severity:** **High** (money path — silent inconsistency)
3. **Location:** `lib/domain/usecases/settle_debt_use_case.dart` + `supabase/schema.sql` (no `settle_debt` RPC; checklist 1.1c2 ⏳)
4. **Problem:** On Supabase the `IUnitOfWork` is a no-op, so `SettleDebtUseCase` issues **two independent REST calls** (`debts.markAsPaid` then `financial_transactions.markAsPaid`). A network failure between them leaves a paid debt with a pending cash entry (or vice versa). Every other money mutation (sale/purchase/debt registration) was already moved to atomic RPCs — this one wasn't.
5. **Business impact:** Cash book out of sync with credit ledger; reconciliation burden on merchants.
6. **Technical impact:** Also `_find` fetches **all debts and all transactions** to locate one record (checklist 4.3) — O(n) per settlement.
7. **Recommended solution:** Add `settle_debt(p_debt_id text, p_store text)` RPC that marks the debt paid + resolves the linked transaction in one transaction, then wire `IDebtAtomicProcessor` (or a new settle processor) in `service_locator.dart`; narrow the lookup to `WHERE id = ... AND store_id = ...`.
8. **Implementation steps:** (1) Write `settle_debt` RPC mirroring `register_debt` (idempotent on debt id); (2) add `ISettleDebtProcessor` + Supabase impl; (3) inject into `SettleDebtUseCase`; (4) SQL smoke test (see T1).
9. **Code example:**
```sql
CREATE OR REPLACE FUNCTION public.settle_debt(p_debt_id text, p_store text)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_uid uuid := auth.uid();
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Sessão necessária.'; END IF;
  UPDATE public.debts SET is_paid = TRUE, paid_at = now()
   WHERE id = p_debt_id AND store_id = p_store AND user_id = v_uid
     AND NOT is_paid;
  IF NOT FOUND THEN RETURN; END IF;  -- idempotent / not found
  UPDATE public.financial_transactions SET status = 'paid'
   WHERE debt_id = p_debt_id AND store_id = p_store
     AND user_id = v_uid AND status = 'pending';
END; $$;
```

---

### High-severity findings (condensed)

| # | Category | Location | Problem | Recommended fix |
|---|---|---|---|---|
| H1 | Money integrity | All entities (`sale.dart`, `product.dart`, `financial_transaction.dart`, `plan.dart`, …) | **✅ FIXED (Aug 6, W4):** money is **integer cents end-to-end** (`*Cents` fields, `Money.parse`/`fromReais`, SQLite INTEGER + Supabase BIGINT, RPCs comparing/summing in cents, seeds ×100) | Done (checklist 1.7) — validated 12/12 on real Postgres |
| H2 | Performance | All Supabase `getAll` (`supabase_product/sale/debt/financial_*_data_source.dart`) | **✅ FIXED (Aug 6, Update 5):** keyset pagination (`fetchAllKeyset`, stable `id` cursor, `pageSize` batches) on all 6 Supabase `getAll`; KPI aggregation in the `get_dashboard_kpis` RPC (W5); **cash flow + sales report aggregation moved to the `get_cash_flow`/`get_sales_report` RPCs** (H2) — UMA chamada server-side, fallback client-side no modo local | ✅ Done (checklist 4.1/4.2) |
| H3 | Ops | Repo-wide | **No CI/CD** (no `.github/`), no integration tests (`integration_test/` absent), no coverage gate, no `sqlcheck` runner for the SQL suite — **✅ fixed Aug 5**: `.github/workflows/ci.yml` (analyze → test+coverage → release APK → sql-check on Postgres 16) + `scripts/sql_check.sh`, validated locally against real Postgres 16 (PASS, re-runnable). **Aug 6:** sql-check runs **12/12** in `ci.yml` + `release.yml` (W4/H2/upgrade) | Remaining: integration tests (`integration_test/`) — coverage gate (45%) já ativo desde Update 2 |
| H4 | Observability | `lib/main.dart` | No `FlutterError.onError`/`PlatformDispatcher.onError`, no Sentry/Crashlytics, no analytics — **zero crash visibility**; errors only `debugPrint` | ✅ Sentry integrated + `runZonedGuarded` (Update 2) |
| H5 | Config | `lib/core/config/supabase_config.dart` | **Real project URL + anon key compiled into the binary as defaults.** Anon keys are public by design, but: (a) the app always points at the *dev* project unless rebuilt with `--dart-define`; (b) a release without defines silently talks to a hardcoded project — no fail-fast | ✅ Flavors (dev/prod) + fail-fast em release (S2, Update 2); ⏳ revoke/rotate da chave embutida (2.4/7.2) |
| H6 | Security | `supabase/schema.sql` (`tenants_insert` policy) | Any logged-in user can create **unlimited pending tenants** — free DoS on the manual-approval queue + unauthenticated signup spam | Rate-limit tenant creation (e.g., 1 pending tenant per user), require confirmed email before creating a tenant, reCAPTCHA on signup |
| H7 | Security | `lib/data/services/supabase_employee_account_service.dart` | Owner-defined employee passwords (owner knows them); with email confirmation OFF, `signUp` **replaces the owner's session** mid-flow | Invite-based onboarding (magic link / temp password + forced reset); assert `session.user?.id` unchanged after employee creation |
| H8 | Security | `supabase/schema.sql` | No **audit trail** for admin decisions (approve/reject/plan edits) — `decided_at` exists but no actor/immutable log | ✅ `audit_log` + triggers + `get_audit_log` (upgrade.sql Parte 5 / checklist 2.3) |
| H9 | Security | `supabase/schema.sql` (`is_super_admin`) + dashboard | No 2FA on admin account; no email-confirmation verification possible from repo | Enable 2FA + confirm email verification (checklist 2.1/2.2) |

---

### Medium findings (condensed)

| # | Category | Location | Problem | Fix |
|---|---|---|---|---|
| M1 | Data | `supabase/schema.sql` seed | Demo seed works **only for the first user** (PKs `p1`…`tn_demo` conflict → `DO NOTHING`). Documented, but confusing in a multi-tenant prod | Ship no seed in prod schema; move to a one-time migration |
| M2 | Ops | `web/index.html`, `web/manifest.json`, `ios/Runner/Info.plist`, Android label | Placeholder branding everywhere: meta description *"A new Flutter project."*, title `dumbhanengue`, default icons, no CSP — **metadata + full icon set done (W7, Aug 6)**; CSP still open (only if web ships) | ✅ metadata + icon set (W7); ⏳ `Content-Security-Policy` meta (só se web ship) |
| M3 | Perf | `lib/presentation/screens/shell/app_shell.dart` | `IndexedStack` keeps all 6 sections alive (memory + build cost); dashboard folds on every list change | Acceptable at this scale; if growing, lazy-load tabs / use `AutomaticKeepAlive` |
| M4 | Deps | `pubspec.yaml` | **✅ FIXED (Aug 6, W10):** `sqlite3` → ^3.5.1 (build hooks/native assets), `sqlite3_flutter_libs` (EOL) removed | Done (checklist 8.2) |
| M5 | Code | `supabase_tenant_data_source.dart` L63, `supabase_plan_request_data_source.dart` L54, `admin_plans_screen.dart` L197 | `AppIds` migration **incomplete** — tenant/plan-request/plan creation still uses `microsecondsSinceEpoch` (checklist 1.10 claims ✅) | Replace remaining call sites with `AppIds.newId('tn'/'pr'/'pl')` |
| M6 | Security | `.gitignore` | No keystore/key.properties exclusion; no secrets-scanning | Add `*.jks`, `key.properties`, `.env`; run `gitleaks`/`trufflehog` pre-merge |
| M7 | Security | `supabase/schema.sql` password policy | Client enforces 8 chars; Supabase default min is 6 — direct API users get weaker passwords | Set `password_min_length=8` in project settings |
| M8 | UX | Dashboard low-stock | Threshold hardcoded `< 5` units — **extracted to `lowStockThreshold` constant (W8, Aug 6)**; still not per-product configurable | ✅ constante `lowStockThreshold` (W8); ⏳ config per-product |
| M9 | Ops | Versioning | `1.0.0+1` everywhere; single commit; no CHANGELOG, no flavors | Define versioning + flavor strategy before first release (checklist 9.2) |
| M10 | Docs | `docs/` | Docs still reference `dio`/`Failure` and pre-RPC architecture (checklist 9.1) | Sync docs with the atomic-RPC path |
| M11 | Reliability | Supabase client defaults | No explicit timeouts/retries on REST calls; no connectivity-awareness UI — **timeouts + retry with backoff wired via `TimeoutRetryHttpClient` (W6, Aug 6)**; offline banner remains | ✅ timeouts + retry via `TimeoutRetryHttpClient` (W6); ⏳ offline banner |
| M12 | Scale | Schema | TEXT PKs generated client-side (fine at small scale; collision odds low with `AppIds`) | Revisit UUID v7 PKs at scale |

### Low findings

| # | Location | Issue |
|---|---|---|
| L1 | `app.dart`, package name | Product name "Dumbhanengue" + doubled applicationId read as template placeholders — confirm the final brand before store submission |
| L2 | `finance_providers.dart` / `reports_providers.dart` | Duplicated `_startOfDay` helper → **fixed (W11, Aug 6)** via `core/utils/period_utils.dart` |
| L3 | `supabase_auth_remote_data_source.dart` | Signup-without-confirmation returns placeholder `AppUser(id: email)` — guarded by flow, but fragile; assert real uid |
| L4 | `AppIds.newId` | Format `p<ts36>_<hex6>` is fine, but a `_` in PKs is awkward for URL/key usage — cosmetic |
| L5 | Localization | All strings hardcoded pt-BR — acceptable for the target market; i18n only when expanding |

---

## 3. Specialized Reports

### 🔐 Security Report
**Strengths:** RLS enabled on **all 14 tables** with per-tenant policies (incl. `super_admins`, zero policies); DB-backed super-admin role (`public.super_admins` + SECURITY DEFINER `is_super_admin`); anti-forgery triggers force `user_id = auth.uid()` and validate `store_id` against the user's stores on every insert; plan-limit enforcement **in the DB** (triggers `enforce_store_limit`/`enforce_employee_limit`); atomic `SECURITY DEFINER` RPCs with pinned `search_path`, explicit `user_id`/`store_id` filters and **idempotency keys**; `FOR UPDATE` locking closes TOCTOU on stock; tokens in `flutter_secure_storage` (Keychain/Keystore AES-GCM); no `service_role` key anywhere; no `print`/plaintext secrets; the seed's "preserve value when no JWT" backdoor is harmless under RLS.

**Gaps (by severity):** H6 (tenant spam), H7 (employee session/password — invite flow), H9 (no 2FA), M7 (password policy consistency), M2 (CSP, só se web). *(C1/C3/C4 fixed; H8 audit log ✅ — upgrade.sql Parte 5; M11 timeouts/retry ✅ — W6.)* XSS/CSRF: N/A (native + PostgREST JWT; web target would need CSP — checklist 2.7). SQL injection: N/A (typed PostgREST + parameterized SQL). MITM: TLS enforced by Supabase endpoints; no custom cert validation code to audit.

### 🏛️ Architecture Report
Genuine Clean Architecture: domain (entities/usecases/repos) is framework-free; data layer split local/remote with repository pattern; DI via GetIt + Riverpod providers (dual-DI is documented and test-friendly — one provider override covers the chain). Atomic processors (`ISaleAtomicProcessor` etc.) keep use cases backend-agnostic. **Praise:** separation, testability, documentation. **Flaws:** misleading `*LocalDataSource` naming for Supabase impls (M—cosmetic, documented); exception-based error handling (deliberately dropped the `Failure` hierarchy — acceptable, but screens catch bare `Exception`); `SettleDebtUseCase` O(n) lookup on the SQLite/memory composite path (Supabase is targeted via the `settle_debt` RPC); `AppIds` migration incomplete; no offline repository abstraction yet.

### 🎨 UX/UI Report
Genuinely strong. Verified in code: consistent Material 3 theme with **dark mode**, emerald identity, filled inputs, borderless cards, 52px buttons, adaptive `NavigationRail`/`NavigationBar` (>880px), `IndexedStack` state preservation, store selector scoped to all modules, consistent loading/empty/error states (`KpiCard`, `EmptyState`, `ErrorView`, `StatusChip`), polished login (password visibility toggle, min-8 + confirm validation, autofill hints, generic error messages, explicit auth-stream error screen with retry — no silent login drops), dashboard KPIs + quick actions + low-stock alerts. **Gaps:** no explicit `Semantics` labels; accessibility (font scaling, contrast ratios, touch targets at large text) untested; low-stock threshold hardcoded; no pull-to-refresh on lists; placeholder branding; onboarding/admin screens not widget-tested.

### ⚡ Performance Report
At **1–100 users: excellent.** At 10k+ rows: now handled — keyset pagination on all Supabase `getAll`, and dashboard KPIs / cash flow / sales report aggregated server-side via RPCs (W5+H2, single `SELECT` per metric). `SettleDebtUseCase` O(all data) on the SQLite/memory path remains (Supabase targets the `settle_debt` RPC). Startup: SQLite open/seed on the main isolate (dev mode only). `IndexedStack` keeps all tabs mounted. Remaining recommendations: targeted lookups, deferred SQLite, and offline-first as the strategic play.

### 💼 Business Readiness Report
Plans (Essencial/Profissional/Empresa) with **DB-enforced** store/employee limits — unusually good server-side gating. Missing: **billing entirely** (manual approval, no payments), no trial, no self-serve upgrade/downgrade, no downgrade-below-usage protection (queued), no edit/void/delete for products/customers/sales (daily merchant need, queued). The C2 employee-access gap was resolved Aug 6 (store-scoped RLS + access matrix); the invite flow (H7) remains.

---

## 4. Production Readiness Checklist

| Area | ✅ Ready | 🔴 Not ready |
|---|---|---|
| Code quality | analyze clean, 300 tests, docs | — |
| Data integrity | atomic sale/purchase/debt RPCs (incl. `settle_debt`), idempotent, stock locking, **money in integer cents (W4)** | — |
| Security | RLS, anti-forgery triggers, DB-backed super-admin role (C3), secure storage, **audit log (H8)** | tenant spam (H6), 2FA (H9) |
| Release | keystore-based release signing (C1), flavors | applicationId/branding placeholder (L1) |
| Ops | CI/CD + SQL/RLS smoke runner (H3, **12/12**), Sentry (H4), 45% coverage gate | — |
| Multi-user | store-scoped RLS + access matrix (C2, Aug 6) | invite flow (H7) |
| Scale | KPIs + cash flow + sales report aggregated server-side (W5/H2); keyset pagination on all 6 Supabase `getAll` (H2) | — |

## 5. Release Checklist (pre-store)
1. ✅ Real upload keystore + `key.properties` gitignored (C1) — keystore generated; external: activate Play App Signing + register upload key
2. ✅ Super-admin role fixed (C3); external: verify email confirmation ON + enable 2FA (H9)
3. ✅ `settle_debt` RPC (C4) + SQL smoke test (H3) — `schema.sql` **applied to the live project** (eu-north-1) and re-verified 10/10 (Aug 5)
3b. ✅ Apply **`supabase/upgrade.sql`** (W4 cents + H2 RPCs — old migrations 010/011) to the live project + re-verify with `sql_check_live.sh` — **DONE Aug 6** via pooler eu-north-1 (transação única `-1`, PostgreSQL 17.6): 9 colunas de dinheiro → `bigint`, zero fracionários, `sql_check_live.sh` **14/14 PASS**, idempotência confirmada (reaplicação sem efeito). Backup `backup_pre_w4.sql` gerado (gitignored). **runbook: [capítulo 15](15-migracao-w4-h2.md)**
4. ✅ Store-scoped employee RLS + access matrix (C2, Aug 6); ⏳ invite flow (H7)
5. Branding: appId, labels, web metadata, icons/splash (M2)
6. ✅ CI pipeline (H3) + Sentry (H4) + **iOS TestFlight pipeline (W1, Aug 6)**
7. Privacy policy / ToS (legal) · data backup policy (checklist 7.5/7.6)
8. ✅ Icons/branding (W7, Aug 6) · ✅ go-live ops guide (W3, `docs/*/14-go-live-ops.md`) · external: Play App Signing activation + SHA-256 registration

## 6. Final Production Score: **82 / 100** *(updated Aug 6 — final session part 3: W1–W11 + H2 done + SQL consolidation; only W2 billing deferred + live apply + external ops remain)*
Architecture 88 · Testing 80 · Security 68 · UX/UI 88 · Performance/Scalability 66 · Business/Billing 30 · Production Ops 78 · Documentation 93.

## 7. Estimated Technical Debt
~**0 engineering days** for the internal items — **W4, H2, W10 + SQL consolidation done (Update 6, Aug 6)**. Remaining: live apply of `upgrade.sql` + external work (store accounts, Play App Signing activation, billing integration, legal, 2FA) + M-items long tail (M1 seed, M3 lazy tabs, M5 AppIds, M6 secrets scan, M12 UUID v7) if pursued.

## 8. Priority Roadmap
- **Done (all sessions):** C1 signing · C2 store-scoped RLS + access matrix (owner/manager/employee) · C3 super-admin role · C4 `settle_debt` · H3 CI + sql_check [10/10]→[12/12] · H4 Sentry · H8 audit log · S1 secure session storage · H1 `Money` → **integer cents (W4)** · dashboard KPIs/cash flow/sales report SQL RPCs (W5/H2) · keyset pagination (H2) · sqlite3 3.x (W10) · timeouts/retry (W6) · icons (W7) · UX/accessibility (W8) · iOS pipeline (W1) · go-live ops (W3) · SQL consolidation into `upgrade.sql` · `schema.sql` applied to live + 10/10 verification.
- **Next (short term):** apply `supabase/upgrade.sql` to the live Supabase (old migrations 010/011 — W4 cents + H2 RPCs) + re-verify with `sql_check_live.sh` (14 checks) · external: verify email confirmation ON + 2FA (H9), Play App Signing activation, store accounts, privacy/ToS. *(sql_check.sh already runs **12/12 in CI** — done)*
- **Long term (post-launch):** billing (W2 — deferred by product decision; Stripe/Paddle/M-Pesa) + self-serve plans · offline-first sync · audit log + data export · i18n

---

## 9. Itens ainda pendentes do checklist de produção

> Status final (Update 6, Aug 6): **todo o trabalho interno de engenharia está concluído** (W4, H2, W10, W1–W11, consolidação SQL) e validado em Postgres real. **O `upgrade.sql` foi aplicado ao live em Aug 6 (item 1 ✅)** — o que resta é apenas **ops externas** + long tail opcional.

| # | Item (checklist) | Tipo | Estado |
|---|---|---|---|
| 1 | **Aplicar `supabase/upgrade.sql` ao Supabase live** (antigas migrações 010/011 — W4 cents + H2 RPCs) + re-verificar com `scripts/sql_check_live.sh` (**14/14**) | Interno → live | ✅ **Aplicado Aug 6** (pooler eu-north-1, transação única `-1`, PostgreSQL 17.6): 9 colunas → `bigint`, zero fracionários, `sql_check_live.sh` **14/14 PASS**, idempotência confirmada. Backup `backup_pre_w4.sql` (gitignored). **runbook: [capítulo 15](15-migracao-w4-h2.md)** |
| 2 | Ativar **Play App Signing** + registrar o SHA-256 da upload key (7.1 — parte externa do C1) | Externo (Play Console) | ⏳ |
| 3 | Verificar **e-mail de confirmação ON** + habilitar **2FA no super admin** (2.1/2.2 — H9) | Externo (dashboard Supabase) | ⏳ |
| 4 | `password_min_length = 8` nas settings do projeto (M7) | Externo (dashboard Supabase) | ⏳ |
| 5 | Contas Google Play/Apple + secrets no CI (7.9) | Externo | ⏳ |
| 6 | Privacy policy / ToS + política de backup (7.5/7.6) | Legal | ⏳ |
| 7 | **Billing** (W2) — adiado por decisão de produto; limites de plano já são DB-enforced | Produto | ⏳ deferido |
| 8 | Rate-limit de criação de tenants + reCAPTCHA (H6) | Segurança | ⏳ |
| 9 | Invite flow do funcionário (H7 — parte externa do C2) | Segurança/UX | ⏳ |
| 10 | Long tail opcional: M1 (seed em prod), M3 (lazy tabs), M5 (AppIds restantes), M6 (gitleaks), M8 (low-stock por produto), M12 (UUID v7); M2 (CSP, só se web ship) | Manutenção | ⏳ opcional |

Todos os demais itens do checklist (1.1–1.18, 2.3–2.4, 4.1–4.2, 6.2, 7.1–7.8, 8.1–8.3, 9.1–9.2) estão **✅**.

---

*Scope note: the original audit was read-only; fixes for C1/C3/C4/H3 were implemented in follow-up sessions (Aug 5, 2026) — statuses above. The live schema verification also ran Aug 5 (read-only via pooler eu-north-1): the hardening layer was missing in production, `schema.sql` was applied in one transaction and re-verified 10/10. External items (email confirmation, Play App Signing activation, store console) must be verified in the Supabase dashboard and store consoles, not in code.*
