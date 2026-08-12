# 19 — Daily Cash Closing Migration on the Production Supabase (runbook)

> **Goal:** apply **Part 25** of `supabase/upgrade.sql` to the production
> project (`dotklbpqmlnhcdifiukd`) — enables the **daily cash closing
> (Z-report)** on the EXISTING database: the `cash_closings` table (one
> closing per store per day) + the `close_cash_register` RPC that computes
> the expected drawer amount SERVER-SIDE and persists the closing
> atomically.
>
> What Part 25 does (idempotent — same conventions as Parts 7/8/22):
> 1. **25.1** — `cash_closings` table (day snapshot: total sales, expected
>    drawer, counted cash, per-payment-method breakdown as JSONB) with a
>    **UNIQUE `(store_id, closing_date)`** — re-closing the same day UPDATES,
>    never duplicates;
> 2. **25.2** — RLS + policies: read for the store owner/employees; writes
>    through the RPC (INSERT for own store; UPDATE/DELETE only on own rows —
>    defense in depth);
> 3. **25.3** — `idx_cash_closings_store` index (store-scoped scans);
> 4. **25.4** — `user_id`/`store_id` triggers (same helpers as the schema);
> 5. **25.5** — `close_cash_register(text, timestamptz, bigint)` RPC,
>    `SECURITY DEFINER` with the **`is_manager_of_store`** guard (closing is
>    a MANAGERIAL operation — owner/manager only), server-side expected-cash
>    calculation (Σ ACTIVE **cash** sales of the day — card/M-Pesa/E-Mola/
>    transfer do not go through the physical drawer) and an UPSERT in ONE
>    transaction.
>> The same application also brings **Part 26**: the read-only
> `get_cash_closing_summary(text, timestamptz)` RPC — the Z-report PREVIEW
> aggregated SERVER-SIDE (same criteria as `close_cash_register`, guarded
> by `is_my_store`), so stores with large histories no longer load the
> sales onto the client (H2 scale, `get_cash_flow`/`get_sales_report`
> pattern).
>
> The script is **100% idempotent** and Part 25 follows the same conventions
> as Parts 7/8/22 (CREATE TABLE IF NOT EXISTS, DROP POLICY IF EXISTS +
> CREATE POLICY, DROP TRIGGER IF EXISTS + CREATE TRIGGER, CREATE OR REPLACE
> FUNCTION). Step **[18/18]** of `sql_check.sh` (which EXECUTES the RPC as
> `app_user` and verifies total, expected, per-method breakdown, UPSERT
> without duplicating, and employee rejection) runs in the **CI** (`sql-check`
> job, disposable Postgres 16) — the syntax was already validated locally
> (`bash -n`). Safe to re-run as many times as needed.
>
> ⚠️ **No hard compatibility window** (unlike W11): Part 25 only ADDS a
> table + RPC — no existing data is rewritten. The app must be on the
> version with the cash closing to USE the RPC, but legacy clients do not
> break while writing. Still, publish the new version together (Step 6) so
> the feature shows up.

---

## Step 0 — Prerequisites

- Access to the project Dashboard + **database password**
  (Settings → Database → Connection string).
- The project's direct host is **IPv6-only** → use the **pooler**
  `aws-0-eu-north-1.pooler.supabase.com`.
- Local `psql` **or** Docker (`postgres:16` ships `psql`).
- ⚠️ **NEVER** run `scripts/sql_check.sh` against the live database — it
  does `DROP SCHEMA public CASCADE`. Live verification is only
  `scripts/sql_check_live.sh` (read-only).
- **App built with the cash closing feature** ready to publish (see Step 6).

Set the URL (replace `SENHA`):

```bash
export SUPABASE_DB_URL='postgresql://postgres.dotklbpqmlnhcdifiukd:SENHA@aws-0-eu-north-1.pooler.supabase.com:6543/postgres?sslmode=require'
```

## Step 1 — Backup (mandatory)

- **Quick option:** Dashboard → Database → **Backups** → "Create a backup"
  (or enable PITR).
- **CLI option** (pooler **5432** *session* port, suitable for `pg_dump`):

```bash
pg_dump "postgresql://postgres.dotklbpqmlnhcdifiukd:SENHA@aws-0-eu-north-1.pooler.supabase.com:5432/postgres?sslmode=require" \
  --schema=public -f backup_pre_cash_closing.sql
```

## Step 2 — Pre-flight (read-only, SQL Editor)

**2.1 Was Part 25 already applied?** If the `cash_closings` table already
exists, the migration already ran → skip to Step 4 (and check Step 6):

```sql
SELECT to_regclass('public.cash_closings') AS cash_closings_exists;
-- Expected: NULL (not applied) or public.cash_closings (already applied).
```

**2.2 Existing closings?** (databases that may have rows from a manual RPC
test before this runbook):

```sql
SELECT count(*) AS existing_closings FROM public.cash_closings;
```

**2.3 Day sample** (to verify later that the server-side expected-cash
calculation matches today's cash sales — note the total of cash sales
today). ⚠️ The query uses `date_trunc('day', now())` in the SERVER timezone
(UTC on Supabase), while the RPC receives the client's LOCAL day start
converted to UTC — for MZN stores (UTC+2) the two "days" can diverge near
midnight. The sample is informational; the RPC is the authority:

```sql
SELECT COALESCE(SUM(total_amount), 0) AS cash_sales_today
FROM public.sales
WHERE status = 'active'
  AND payment_method = 'cash'
  AND date_time >= date_trunc('day', now())
  AND date_time < date_trunc('day', now()) + interval '1 day';
```

## Step 3 — Apply `supabase/upgrade.sql`

### Option A — psql via pooler, ONE transaction (recommended — project convention) ✅

```bash
psql "$SUPABASE_DB_URL" -X -v ON_ERROR_STOP=1 -1 -f supabase/upgrade.sql
```

- `-1` = single transaction: if **any** part fails, **everything** is
  rolled back — no partial state.
- Expected: no errors (Part 25 only emits "already exists" NOTICEs on
  already-created columns/tables — normal, that's idempotency at work).

### Option B — Dashboard SQL Editor

1. Open the **SQL Editor** in the project.
2. Paste the **full contents** of `supabase/upgrade.sql`.
3. Run it. The editor runs the script as a single batch; on error it stops
   and shows the message. Since the script is idempotent, fixing and
   re-running is safe.

## Step 4 — Post-migration verification (read-only)

**4.1 Run the live verification script** (read-only, now with **35 checks**, the
cash-closing ones being 32–34 plus the summary-preview check 35):

```bash
SUPABASE_DB_URL="$SUPABASE_DB_URL" bash scripts/sql_check_live.sh
```

- Expected: **VERIFICATION COMPLETE — all checks passed**, including:
  - 32 — `cash_closings` table + RLS ON + UNIQUE `(store_id, closing_date)`;
  - 33 — `close_cash_register` RPC `SECURITY DEFINER` + `is_manager_of_store`
    guard + server-side calculation over `sales`;
  - 34 — `user_id`/`store_id` triggers + `idx_cash_closings_store` index.

**4.2 Manual check (SQL Editor):**

```sql
-- 1) Table + uniqueness (must exist; one closing per store/day):
SELECT conname, pg_get_constraintdef(oid) AS def
FROM pg_constraint
WHERE conrelid = 'public.cash_closings'::regclass
  AND contype = 'u';

-- 2) RPC present + SECURITY DEFINER + fixed search_path:
SELECT p.proname, p.prosecdef, p.proconfig
FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public' AND p.proname = 'close_cash_register';

-- 3) The migration did NOT create any closings (it inserts no data):
SELECT count(*) AS closings_after_migration FROM public.cash_closings;
-- Expected: 0 (or the Step 2.2 count, unchanged).
```

**4.3 Business table row counts** — if noted in Step 2.3, verify nothing
changed (Part 25 does not touch existing data).

## Step 5 — Idempotency (optional, confirms re-applying does not duplicate)

Repeat Step 3 and verify the table still has a single set of objects:

```sql
-- Unique objects (no duplicates):
SELECT count(*) AS closing_triggers FROM pg_trigger
WHERE tgrelid = 'public.cash_closings'::regclass;
-- Expected: 2 (trg_cash_closings_user_id + trg_cash_closings_store_id).

SELECT count(*) AS closing_policies FROM pg_policies
WHERE schemaname = 'public' AND tablename = 'cash_closings';
-- Expected: 4 (select/insert/update/delete).
```

## Step 6 — Publish the app (Z-report)

Part 25 does not rewrite data, but the feature only shows in the new UI:

1. **Publish the app version with the cash closing** — button in Finance
   (owner/manager) → Z-report sheet with the physical cash count.
2. Legacy clients keep working (the RPC is additive); the feature simply
   does not appear until they update.
3. The new app stays **100% offline-compatible** (local SQLite already
   creates the `cash_closings` table on database open).

## Rollback (only if needed)

> Part 25 is **additive** (table + RPC — no existing data is rewritten). If
> you need to revert, simply **do not publish** the new app (the feature
> does not appear) and, if you want to drop the table, restore from the
> Step 1 backup. There is no destructive migration to undo.

---

## Final checklist

| # | Item | Verification |
|---|------|--------------|
| 1 | Backup made | `backup_pre_cash_closing.sql` exists |
| 2 | Pre-flight clean | `cash_closings` does not exist; sample noted |
| 3 | `upgrade.sql` applied | no errors (single transaction) |
| 4 | `sql_check_live.sh` | ✅ all 35 checks (closing 32–34 + server-side preview 35) |
| 5 | Per-store/day uniqueness | UNIQUE `(store_id, closing_date)` present |
| 6 | Re-apply without effect | idempotency confirmed (Step 5) |
| 7 | App published | version with cash closing published |
| 8 | Closing works | owner/manager close the register; employee blocked (server) |
