# Audit Status & Pending Production Items (English)

> **Authoritative source:** the full production-readiness audit lives in Portuguese at [`../pt/AUDIT_REPORT.md`](../pt/AUDIT_REPORT.md) (the project's primary language). This chapter is the **English version of Update 6** (final session, part 3 — Aug 6, 2026), **Update 7** (Aug 7 — employee activation/deactivation + product creation matrix) **and Section 9** (pending production-checklist items). Numbers mirror the authoritative report: `381/381` tests, `sql_check.sh` **12/12**, `sql_check_live.sh` **14/14**, `schema.sql` 2,311 lines, 73 test files.

---

## Update 7 (Aug 7, 2026 — employee activation/deactivation + product creation matrix)

**Employee activation/deactivation:** the **owner** now activates/deactivates employees (switch in Stores → Employees tab, with confirmation). A deactivated employee loses access **immediately** through a two-layered block: the **app** shows the "Access suspended" screen in the AuthGate, and the **server** denies every operation — `is_my_store`/`is_manager_of_store` require an **active** link (`is_active = TRUE`), so RLS and RPC guards block even a modified client. Implementation: `store_employees.is_active` (DEFAULT TRUE — existing employees stay active) + `set_employee_active` RPC (SECURITY DEFINER, owner only, idempotent) + active-link requirement in both helpers — `schema.sql` + `supabase/upgrade.sql` (Part 19); `sql_check.sh` gained section [6b] (deactivate → `is_my_store` FALSE, reactivate → TRUE, non-owner rejected).

**Product creation matrix:** a regular **employee does not create products** (only lists/sells) — the "New product" FAB is hidden when `currentAccessLevelProvider == employee`; owner and manager keep it (server `products_insert` RLS unchanged).

**`flutter analyze` 0 issues · `flutter test` 381/381.**

---

## Update 6 (Aug 6, 2026 — final session, part 3: SQL consolidation + real-DB validation)

Delivered the **SQL consolidation** and **hard validation on real PostgreSQL**.

**(a) SQL consolidated to 4 files.** The 10 migration files (`002..011`) were merged into **one idempotent script `supabase/upgrade.sql`** (Parts 1–8 — DDL, RLS helpers, manager gate, audit log, employee account, W4 column migration, final cents RPCs). Fresh installs use `supabase/schema.sql` alone; existing databases apply `supabase/upgrade.sql` (re-runnable, no partial state when run in a single transaction with `-1`).

**(b) Real-DB validation (Docker Postgres 16, exact CI config — scram over TCP).** `scripts/sql_check.sh` now runs **12/12 steps**:

- **[1b]** `upgrade.sql` applied twice → **idempotency** confirmed
- **[10/10]** `get_dashboard_kpis` (W5) with value assertions
- **[11/11]** `get_cash_flow` / `get_sales_report` (H2) with value assertions
- **[12/12]** the W4 NUMERIC→cents migration with real data (25.50 → 2550, **no double-apply**)

This caught and fixed a **genuine W4 bug**: `SUM(bigint)` returns `numeric`, which breaks the BIGINT `RETURNS TABLE` of `get_dashboard_kpis` / `get_cash_flow` / `get_sales_report` at runtime — fixed with explicit `::bigint` casts in both `schema.sql` and `upgrade.sql`.

**(c) `scripts/sql_check_live.sh` extended to 14 read-only checks** — 9 money columns as BIGINT, zero fractional values, H2 RPCs present with `SECURITY DEFINER` + BIGINT returns — validated **14/14**; the stale `lock_products_or_raise` signature was fixed.

**(d) CI.** The `sql-check` jobs in `.github/workflows/ci.yml` + `.github/workflows/release.yml` run the full 12 steps on Postgres 16 (validated locally with the exact service-container config, scram/TCP; `timeout-minutes: 30`).

**`flutter analyze` 0 issues · `flutter test` 300/300.** *(Updated Aug 7: **381/381** — see Update 7.)*

---

## Final status of internal engineering (W4, H2, W10)

| Item | Status |
|---|---|
| **W4 — money in integer cents end-to-end** | ✓ Done — `*Cents` in domain, SQLite `INTEGER` + idempotent ×100 migration, Supabase `BIGINT` (+ W4 column migration, Part 7 of `upgrade.sql`), RPCs compare/sum in cents directly (no `ROUND(x*100)`), plan catalog in cents, `Money.parse` / `Formatters.currency(cents)` |
| **H2 — server-side aggregation + keyset pagination** | ✓ Done — `get_cash_flow` + `get_sales_report` RPCs (SECURITY DEFINER, `is_my_store`-scoped, BIGINT, day bucketing in device timezone; Parts 8.6–8.7 of `upgrade.sql`); `fetchAllKeyset` (stable `id` cursor, `pageSize` batches) replacing `.limit(1000)` on all 6 Supabase `getAll` |
| **W10 — sqlite3 3.x** | ✓ Done — `sqlite3` ^3.5.1 via build hooks/native assets; `sqlite3_flutter_libs` (EOL) removed; `dispose()` → `close()` |
| **SQL consolidation** | ✓ Done — 13 → 4 SQL files (`schema.sql` fresh install, `upgrade.sql` existing DBs, `promote_super_admin.sql` ops helper, `sqlcheck_stub.sql` smoke-test stub); **Sep 2026:** the 7 add-on/billing migration files were archived in `supabase/archived_migrations/` with their objects merged into `schema.sql` (Part 1.9) and `upgrade.sql` (Part 31) — a fresh install now needs ONE script |
| **Validation** | ✓ `sql_check.sh` **12/12** on real Postgres 16 (incl. idempotency + W4 migration with real data) · `sql_check_live.sh` **14/14** · CI runs the full suite in `ci.yml` + `release.yml` |

---

## Section 9 — Pending production checklist items

> Final status (Update 6, Aug 6): **all internal engineering work is complete** (W4, H2, W10, W1–W11, SQL consolidation) and validated on real PostgreSQL. **`upgrade.sql` was applied to the live project on Aug 6 (former item 1 ✓, removed from the list)** — what remains is only **external ops** (1–5) + **product/security items** (6–8) + optional long tail (9).

| # | Item (checklist) | Type | Status |
|---|---|---|---|
| 1 | Activate **Play App Signing** + register the upload-key SHA-256 (7.1 — external part of C1) | External (Play Console) | ○ |
| 2 | Verify **email confirmation ON** + enable **2FA on the super admin** (2.1/2.2 — H9) | External (Supabase dashboard) | ○ |
| 3 | `password_min_length = 8` in project settings (M7) | External (Supabase dashboard) | ○ |
| 4 | Google Play / Apple accounts + secrets in CI (7.9) | External | ○ |
| 5 | Privacy policy / ToS + backup policy (7.5/7.6) | Legal | ○ |
| 6 | **Billing** (W2) — deferred by product decision; plan limits are already DB-enforced | Product | ○ deferred |
| 7 | Tenant-creation rate limit + reCAPTCHA (H6) | Security | ○ |
| 8 | Employee invite flow (H7 — external part of C2) | Security/UX | ○ |
| 9 | Optional long tail: M3 (lazy tabs), M5 (remaining AppIds), M6 (gitleaks), M8 (low-stock per product), M12 (UUID v7); M2 (CSP, only if web ships) | Maintenance | ○ optional |

**Completed Aug 6 (removed from the list):** applying `supabase/upgrade.sql` to the live project (former item 1) — pooler eu-north-1, single transaction `-1`, PostgreSQL 17.6: 9 money columns → `bigint`, zero fractional values, `sql_check_live.sh` **14/14 PASS**, idempotency confirmed; backup `backup_pre_w4.sql` (gitignored); web E2E re-validated post-migration. Runbook: [chapter 16](16-migracao-w4-h2.md).

All remaining checklist items (1.1–1.18, 2.3–2.4, 4.1–4.2, 6.2, 7.1–7.8, 8.1–8.3, 9.1–9.2) are **✓**.

---

*Scope note: the original audit was read-only; fixes for C1/C3/C4/H3 were implemented in follow-up sessions (Aug 5, 2026) and W4/H2/W10 + the SQL consolidation in the final sessions (Aug 6, 2026). The live schema verification ran Aug 5 (read-only via pooler eu-north-1): the hardening layer was missing in production, `schema.sql` was applied in one transaction and re-verified 10/10. External items (email confirmation, Play App Signing activation, store console) must be verified in the Supabase dashboard and store consoles, not in code. Full details: [`../pt/AUDIT_REPORT.md`](../pt/AUDIT_REPORT.md).*
