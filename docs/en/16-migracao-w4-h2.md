# 16 — W4 + H2 Migration on the Production Supabase (runbook)

> **Goal:** apply **`supabase/upgrade.sql`** to the production project
> (`dotklbpqmlnhcdifiukd`) — brings the EXISTING database to the current
> state: **Part 7** = W4 (money as integer cents: `NUMERIC` → `BIGINT`) and
> **Part 8** = H2 (RPCs `get_cash_flow` / `get_sales_report` + all other
> final functions). These used to be migrations `010`/`011`; today the
> consolidated script replaces **all** migrations `002..011`.
>
> The script is **100% idempotent** and was validated **12/12** on real
> Postgres 16 (Docker, exact CI config — scram/TCP), including the
> `25.50 → 2550` migration with no double-apply. Safe to re-run as many
> times as needed.
>
> 🇵🇹 Portuguese (authoritative): [`../pt/15-migracao-w4-h2.md`](../pt/15-migracao-w4-h2.md)

---

## Step 0 — Prerequisites

- Access to the project Dashboard + **database password**
  (Settings → Database → Connection string).
- The project's direct host is **IPv6-only** → use the **pooler**
  `aws-0-eu-north-1.pooler.supabase.com`.
- Local `psql` **or** Docker (`postgres:16` ships `psql`).
- ⚠️ **NEVER** run `scripts/sql_check.sh` against the live database — it
  does `DROP SCHEMA public CASCADE`. Live verification is only via
  `scripts/sql_check_live.sh` (read-only).

Set the URL (replace `SENHA`):

```bash
export SUPABASE_DB_URL='postgresql://postgres.dotklbpqmlnhcdifiukd:SENHA@aws-0-eu-north-1.pooler.supabase.com:6543/postgres?sslmode=require'
```

## Step 1 — Backup (mandatory)

- **Quick option:** Dashboard → Database → **Backups** → "Create a backup"
  (or enable PITR).
- **CLI option** (port **5432** *session* pooler, suitable for `pg_dump`):

```bash
pg_dump "postgresql://postgres.dotklbpqmlnhcdifiukd:SENHA@aws-0-eu-north-1.pooler.supabase.com:5432/postgres?sslmode=require" \
  --schema=public -f backup_pre_w4.sql
```

## Step 2 — Pre-flight (read-only, SQL Editor)

**2.1 Current types of the money columns** (if they already come back as
`bigint`, the migration was already applied → skip to Step 4):

```sql
SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND column_name IN ('purchase_price','sale_price','total_amount','unit_price','amount','price_monthly')
ORDER BY 1, 2;
```

**2.2 Duplicate pending tenants** — the S3 guard (Part 2 of `upgrade.sql`)
**aborts** the script if any exist. Check first:

```sql
SELECT owner_user_id, count(*)
FROM public.tenants
WHERE status = 'pending'
GROUP BY owner_user_id HAVING count(*) > 1;
```
→ If it returns rows: resolve the duplicates (keep the oldest, reject the
others) **before** applying.

**2.3 Row counts** (to confirm afterwards that nothing disappeared):

```sql
SELECT 'products' t, count(*) FROM public.products UNION ALL
SELECT 'sales', count(*) FROM public.sales UNION ALL
SELECT 'financial_transactions', count(*) FROM public.financial_transactions UNION ALL
SELECT 'debts', count(*) FROM public.debts;
```

## Step 3 — Apply `supabase/upgrade.sql`

### Option A — psql via pooler, ONE transaction (recommended — project convention) ✅

```bash
psql "$SUPABASE_DB_URL" -X -v ON_ERROR_STOP=1 -1 -f supabase/upgrade.sql
```

- `-1` = single transaction: if **any** part fails (e.g. the S3 guard),
  **everything** is rolled back — no partial state.
- Expected: no errors. If it aborts, the message shows the reason (e.g.
  pending duplicates); resolve and re-apply.

### Option B — Dashboard SQL Editor

1. Open the **SQL Editor** in the project.
2. Paste the **full contents** of `supabase/upgrade.sql`.
3. Run. The editor executes the script as a single batch; on error it
   stops and shows the message. Because the script is idempotent, fixing
   and re-running is safe.

## Step 4 — Post-migration verification (read-only)

**4.1 Run the live verification script** (read-only, 14 checks):

```bash
SUPABASE_DB_URL="$SUPABASE_DB_URL" bash scripts/sql_check_live.sh
```

- Expected: **VERIFICAÇÃO CONCLUÍDA — todos os checks passaram** (14/14),
  covering: 9 money columns as `BIGINT`, zero fractional values, H2 RPCs
  present (`get_cash_flow`/`get_sales_report`/`get_dashboard_kpis`) with
  `SECURITY DEFINER` + `BIGINT` returns.

**4.2 Manual check (SQL Editor):**

```sql
-- 1) Columns already in cents (bigint)?
SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND column_name IN ('purchase_price','sale_price','total_amount','unit_price','amount','price_monthly')
ORDER BY 1, 2;
-- Expected: data_type = bigint on all 9 columns.

-- 2) No fractional values left?
SELECT 'products' t, count(*) FROM public.products WHERE purchase_price % 1 <> 0 OR sale_price % 1 <> 0
UNION ALL SELECT 'sales', count(*) FROM public.sales WHERE total_amount % 1 <> 0
UNION ALL SELECT 'financial_transactions', count(*) FROM public.financial_transactions WHERE amount % 1 <> 0
UNION ALL SELECT 'debts', count(*) FROM public.debts WHERE amount % 1 <> 0;
-- Expected: all 0.

-- 3) H2 RPCs present?
SELECT p.proname, pg_get_function_identity_arguments(p.oid) args
FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND p.proname IN ('get_cash_flow','get_sales_report','get_dashboard_kpis')
ORDER BY 1;
```

**4.3 Row counts** — compare with Step 2.3 (nothing should be missing).

## Step 5 — Idempotency (optional, confirms re-applying does not duplicate)

Repeat Step 3, then confirm there was **no** double multiplication:

```sql
-- A known product: e.g. original price 25.50 must be 2550 (once only)
SELECT id, purchase_price, sale_price FROM public.products ORDER BY created_at LIMIT 3;
```

## Rollback (only if needed)

Restore the columns to `NUMERIC(12,2)` by dividing by 100 (the old
reais-based RPCs cease to exist — the app in Supabase mode would fall back
to client-side aggregation):

```sql
ALTER TABLE public.products ALTER COLUMN purchase_price TYPE NUMERIC(12,2) USING (purchase_price / 100.0);
ALTER TABLE public.products ALTER COLUMN sale_price     TYPE NUMERIC(12,2) USING (sale_price     / 100.0);
-- … repeat for sales.total_amount, sale_items.unit_price,
-- financial_transactions.amount, debts.amount, purchases.total_amount,
-- purchase_items.unit_price, plans.price_monthly
```

---

## Final checklist

| # | Item | Verification |
|---|------|--------------|
| 1 | Backup done | `backup_pre_w4.sql` file exists |
| 2 | Pre-flight clean | no pending duplicates; types `numeric` |
| 3 | `upgrade.sql` applied | no errors (single transaction) |
| 4 | `sql_check_live.sh` | ✅ 14/14 |
| 5 | Re-apply without effect | idempotency confirmed |
| 6 | App in Supabase mode | KPIs/reports/cash flow with correct values |
