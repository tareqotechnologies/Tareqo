# 18 — W11 Migration on the Production Supabase (runbook)

> **Goal:** apply **Part 22** of `supabase/upgrade.sql` to the production
> project (`dotklbpqmlnhcdifiukd`) — brings the EXISTING database to the W11
> state: **FIFO stock lots + expiry tracking** and **weight/scale sales**,
> with ALL quantities converted from whole units to **MILLESIMALS** (×1000).
>
> What Part 22 does (idempotent — same conventions as Parts 7/8):
> 1. **22.1** — new columns on `products` (`code`/PLU, `venda_por_fracao`,
> `unit_label`) and `purchase_items.expiry_date` (optional expiry per item);
> 2. **22.2** — `stock_lots` table (a lot = goods receipt: expiry, initial/
> current quantity, acquisition cost) + FIFO indexes;
> 3. **22.3** — **×1000** migration of ALL quantities (products, sale items
> and purchase items) + **initial-lot backfill** for every product with
> stock (the `stock = Σ lots` invariant holds from day one);
> 4. **22.4** — RLS + policies + triggers on `stock_lots`;
> 5. **22.5/22.6/22.7** — RPCs recreated: `process_sale` with **FIFO
> consumption** of lots, `process_purchase` **creating lots** on receipt,
> `get_sales_report` with millesimal math.
>
> The script is **100% idempotent** and was validated against real Postgres
> 16 (Docker, exact CI config): the full `sql_check.sh` is green (including
> re-applying `upgrade.sql` twice with no double multiplication and the
> `25.50 → 2550` + `5 → 5000` migration with no side effects). Safe to
> re-run as many times as needed.
>
> **Warning:** IMPORTANT — read before applying:** Part 22.3 multiplies **existing
> quantities by 1000** (5 units → 5000 millesimals). After it, **no legacy
> client** (pre-W11 app versions) must write data — the new app version
> must be published in the same window (see Step 6).
>
> Portuguese (authoritative): [`../pt/16-migracao-w11.md`](../pt/16-migracao-w11.md)

---

## Step 0 — Prerequisites

- Access to the project Dashboard + **database password**
 (Settings → Database → Connection string).
- The project's direct host is **IPv6-only** → use the **pooler**
 `aws-0-eu-north-1.pooler.supabase.com`.
- Local `psql` **or** Docker (`postgres:16` ships `psql`).
- Warning: **NEVER** run `scripts/sql_check.sh` against the live database — it
 does `DROP SCHEMA public CASCADE`. Live verification is only via
 `scripts/sql_check_live.sh` (read-only).
- **App built on the W11 version** ready to publish (see Step 6).

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
 --schema=public -f backup_pre_w11.sql
```

## Step 2 — Pre-flight (read-only, SQL Editor)

**2.1 Was W11 already applied?** If the `stock_lots` table already exists,
the migration has run → skip to Step 4 (and check Step 6):

```sql
SELECT to_regclass('public.stock_lots') AS stock_lots_already_exists;
-- Expected: NULL (not applied) or public.stock_lots (already applied).
```

**2.2 Sample of current quantities** (to confirm the ×1000 afterwards — note
some values):

```sql
SELECT id, name, stock_quantity FROM public.products
ORDER BY created_at DESC LIMIT 5;
```

**2.3 Row counts** (to confirm afterwards that nothing disappeared):

```sql
SELECT 'products' t, count(*) FROM public.products UNION ALL
SELECT 'sales', count(*) FROM public.sales UNION ALL
SELECT 'sale_items', count(*) FROM public.sale_items UNION ALL
SELECT 'purchases', count(*) FROM public.purchases UNION ALL
SELECT 'purchase_items', count(*) FROM public.purchase_items;
```

## Step 3 — Apply `supabase/upgrade.sql`

### Option A — psql via pooler, ONE transaction (recommended — project convention) ✓

```bash
psql "$SUPABASE_DB_URL" -X -v ON_ERROR_STOP=1 -1 -f supabase/upgrade.sql
```

- `-1` = single transaction: if **any** part fails, **everything** is rolled
 back — no partial state.
- Expected: no errors (Part 22 only emits "already exists" NOTICEs on
 columns/tables already created — normal, that is idempotency working).
- The ×1000 migration + backfill runs **only when `stock_lots` is empty**
 (Part 22.3 guard) — re-running the script is a no-op.

### Option B — Dashboard SQL Editor

1. Open the **SQL Editor** in the project.
2. Paste the **full contents** of `supabase/upgrade.sql`.
3. Run. The editor executes the script as a single batch; on error it stops
 and shows the message. Because the script is idempotent, fixing and
 re-running is safe.

## Step 4 — Post-migration verification (read-only)

**4.1 Run the live verification script** (read-only; at the time of W11 it
was **31 checks** — the script has since grown to 35, with the new 32–35
cash-closing checks (32–34 plus the server-side preview 35) adding on
without affecting these):

```bash
SUPABASE_DB_URL="$SUPABASE_DB_URL" bash scripts/sql_check_live.sh
```

- Expected: **VERIFICAÇÃO CONCLUÍDA — todos os checks passaram**, including
 the 7 new W11 checks (25–31):
 - 25 — `products.code` / `venda_por_fracao` / `unit_label` columns;
 - 26 — `purchase_items.expiry_date`;
 - 27 — `stock_lots` table + RLS ON + FIFO index;
 - 28 — `process_sale` with FIFO lot consumption in millesimals;
 - 29 — `process_purchase` creating lots;
 - 30 — `get_sales_report` with millesimal math;
 - 31 — **`stock = Σ active lots` invariant** (reports how many products
 have stock different from the sum of their lots — expected `0` right
 after the migration).

**4.2 Manual check (SQL Editor):**

```sql
-- 1) Quantities migrated to MILLESIMALS? (5 units → 5000)
SELECT id, name, stock_quantity FROM public.products
ORDER BY created_at DESC LIMIT 5;
-- Compare with the Step 2.2 sample: values must be ×1000.

-- 2) W11 invariant: product stock = Σ active lots?
SELECT count(*) AS products_with_stock_out_of_lot_sum
FROM public.products p
WHERE p.stock_quantity > 0
 AND COALESCE((
 SELECT SUM(l.current_quantity) FROM public.stock_lots l
 WHERE l.product_id = p.id AND l.store_id = p.store_id
 AND l.current_quantity > 0
 ), 0) <> p.stock_quantity;
-- Expected: 0.

-- 3) Backfilled lots (no expiry — non-perishable products)?
SELECT count(*) AS initial_lots, count(*) FILTER (WHERE expiry_date IS NULL) AS no_expiry
FROM public.stock_lots;

-- 4) W11 RPCs live?
SELECT p.proname
FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
 AND p.proname IN ('process_sale','process_purchase','get_sales_report')
ORDER BY 1;
```

**4.3 Row counts** — compare with Step 2.3 (nothing should be missing).

## Step 5 — Idempotency (optional, confirms re-applying does not duplicate)

Repeat Step 3, then confirm there was **no** double multiplication:

```sql
-- A known product: e.g. 5 units must be 5000 (once only)
SELECT id, name, stock_quantity FROM public.products
ORDER BY created_at DESC LIMIT 3;
-- And the number of lots must NOT have doubled:
SELECT count(*) FROM public.stock_lots;
```

## Step 6 — Publish the W11 app (IMPORTANT — compatibility window)

The migration changes the **quantity contract** (units → millesimals) in the
database. To avoid mixing scales:

1. **Publish the W11 app version immediately after Step 3** — the new app
 is the only one that reads/writes quantities correctly.
2. Legacy clients still open may fail to write (quantity out of scale) —
 the migration is a **short maintenance window**: apply `upgrade.sql` and
 publish the app as soon as possible.
3. The W11 app stays **100% offline-compatible** (local SQLite migrates
 itself via the W11 migration in `AppDatabase`).

## Rollback (only if needed)

> **Warning:** There is no automatic rollback for Part 22.3 (×1000 + lots) — restore
> via the **backup** (Step 1). To revert: restore the database from
> `backup_pre_w11.sql` **and** publish the old app version.

---

## Final checklist

| # | Item | Verification |
|---|------|--------------|
| 1 | Backup done | `backup_pre_w11.sql` file exists |
| 2 | Pre-flight clean | `stock_lots` does not exist; quantity sample noted |
| 3 | `upgrade.sql` applied | no errors (single transaction) |
| 4 | `sql_check_live.sh` | ✓ all checks (incl. W11 25–31) |
| 5 | `stock = Σ active lots` invariant | `products_with_stock_out_of_lot_sum` = 0 |
| 6 | Re-apply without effect | idempotency confirmed (Step 5) |
| 7 | W11 app published | no legacy clients writing in the same window |
| 8 | App in Supabase mode | scale/weight POS and expiry alerts working |
