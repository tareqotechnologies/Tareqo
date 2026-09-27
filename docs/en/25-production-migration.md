# 25 — Recipe (bill of materials) + production migration (`recipes`/`production_orders`) on the Production Supabase (runbook)

> **Goal:** apply **Part 35 — production: recipe (BOM) + orders (Phase 2)** to the
> production project (`bcyolmheltzlddfwgqcq`) using the consolidated
> `supabase/upgrade.sql` — same conventions as runbooks 15 (W4/H2), 16 (W11),
> 17 (cash closing), 20 (MFA aal2) and 24 (product type/Phase 1).
>
> What this apply brings (idempotent):
> 1. **4 new per-store tables**: `recipes` (the recipe/BOM — UNIQUE
>    `(store_id, product_id)`), `recipe_items` (components, FK CASCADE,
>    UNIQUE `(recipe_id, product_id)`), `production_orders` (history, with a
>    cost snapshot) and `production_order_items` (components consumed per
>    order, UNIQUE `(production_id, product_id)`);
> 2. **RLS** `ENABLE` on the 4 tables + **manager policies** (`is_manager_of_store`;
>    INSERT/UPDATE require `mfa_ok()`) — production is **managerial**, like
>    purchases;
> 3. **4 indexes** (`recipes(store_id)`, `recipe_items(recipe_id)`,
>    `production_orders(store_id, date_time DESC)`,
>    `production_order_items(production_id)`);
> 4. **RPC `process_production(p_order jsonb, p_items jsonb)`**
>    `SECURITY DEFINER` — consumes the components in FIFO order and creates the
>    finished product's lot **in ONE transaction** + `GRANT EXECUTE … TO authenticated`.
>
> **No hard compatibility window:** the migration is **purely additive** (new
> tables, no existing data is read, changed or reclassified). The old app simply
> has no Production module; the new app (Phase 2) reads/writes the tables.
> Publishing the app before or after the migration makes no difference — without
> the module, production simply does not exist.
>
> Portuguese (authoritative): [`../pt/25-migracao-producao.md`](../pt/25-migracao-producao.md)

---

## Application record

| Date | Project | Status |
|------|---------|--------|
| 2026-09-27 | **DEV** — `dotklbpqmlnhcdifiukd` | ✅ Part 35 applied: `recipes`/`recipe_items`/`production_orders`/`production_order_items` + RLS + `process_production` RPC; `scripts/sql_check_live.sh` → check 44 passes |
| — | **PRODUCTION** — `bcyolmheltzlddfwgqcq` | ⏳ pending — REST diagnosis (2026-09-27): missing Part 35 (4 production tables + `process_production` RPC) and also Part 33 (`invoice_notifications.body_params`); project essentially empty (1 store, 0 products/sales/purchases) |

> **Dev vs. production:** `env/dev.env` → `dotklbpqmlnhcdifiukd` (**DEV**) and
> `env/prod.env` → `bcyolmheltzlddfwgqcq` (**PRODUCTION**). The examples below
> use the **production** ref; for DEV use `env/db.env` (`SUPABASE_DB_URL`). The
> pooler host (`aws-0-<region>...`) must be the target project's (Dashboard →
> Settings → Database).

---

## Step 0 — Prerequisites

- Access to the project Dashboard + the **database password**
  (Settings → Database → Connection string).
- The project's direct host is **IPv6-only** → use the **pooler**
  `aws-0-eu-north-1.pooler.supabase.com`.
- Local `psql` **or** Docker (`postgres:16` ships `psql`).
- Warning: **NEVER** run `scripts/sql_check.sh` against the live database — it
  runs `DROP SCHEMA public CASCADE`. The live verification is only
  `scripts/sql_check_live.sh` (read-only, checks 1–44).
- **App built on the Phase 2 version** ready to publish (see Step 6) — only
  needed so the Production module shows up in the menu.
- **Dependency on the earlier phases:** the `products.type` column (Phase 1,
  Part 34) must exist — production uses `isProducible`
  (`manufactured`/`composite`) and costs by the component's `purchase_price`.
  If you have not applied it yet, run runbook 24 too.

Set the URL (replace `PASSWORD`):

```bash
export SUPABASE_DB_URL='postgresql://postgres.bcyolmheltzlddfwgqcq:PASSWORD@aws-0-eu-north-1.pooler.supabase.com:6543/postgres?sslmode=require'
```

## Step 1 — Backup (mandatory)

- **Quick option:** Dashboard → Database → **Backups** → "Create a backup"
  (or enable PITR).
- **CLI option** (port **5432** *session* pooler, suitable for `pg_dump`):

```bash
pg_dump "postgresql://postgres.bcyolmheltzlddfwgqcq:PASSWORD@aws-0-eu-north-1.pooler.supabase.com:5432/postgres?sslmode=require" \
  --schema=public -f backup_pre_production.sql
```

## Step 2 — Pre-flight (read-only, SQL Editor)

**2.1 Do the tables/RPC already exist?** (the migration is idempotent — this
only frames the scenario; expected: absent BEFORE the migration):

```sql
-- The 4 production tables (expected: 0 rows before).
SELECT tablename FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('recipes','recipe_items','production_orders','production_order_items')
ORDER BY tablename;

-- The atomic RPC (expected: 0 rows before).
SELECT proname FROM pg_proc
WHERE proname = 'process_production';
```

**2.2 Integrity sample** (write it down — the migration must not change any
row):

```sql
SELECT
  (SELECT count(*) FROM public.products)   AS products,
  (SELECT count(*) FROM public.sales)      AS sales,
  (SELECT count(*) FROM public.purchases)  AS purchases,
  (SELECT count(*) FROM public.stock_lots WHERE current_quantity > 0) AS active_lots;
```

**2.3 Is Phase 1 applied?** (cost/production depend on `products.type`):

```sql
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'products'
  AND column_name = 'type';
-- Expected: type | text | 'resale'::text  (otherwise run runbook 24 first)
```

## Step 3 — Apply `supabase/upgrade.sql`

### Option A — psql via pooler, ONE transaction (recommended — project convention)

```bash
psql "$SUPABASE_DB_URL" -X -v ON_ERROR_STOP=1 -1 -f supabase/upgrade.sql
```

- `-1` = single transaction: if **any** part fails, **everything** is rolled
  back — no partial state.
- Part 35 is `CREATE TABLE/INDEX IF NOT EXISTS` + `DROP POLICY IF EXISTS` +
  `CREATE OR REPLACE FUNCTION` + `GRANT` — a no-op on the 2nd run.

### Option B — Dashboard SQL Editor

1. Open the **SQL Editor** in the project.
2. Paste the **full contents** of `supabase/upgrade.sql`.
3. Run it. On error the editor stops and shows the message; since the script
   is idempotent, fixing and re-running is safe.

### Option C — standalone script (only Part 35)

To apply **only** this migration (e.g. a database already on the previous
parts), run the dedicated script — same content as Part 35:

```bash
psql "$SUPABASE_DB_URL" -X -v ON_ERROR_STOP=1 -1 \
  -f supabase/add_production_2026_09_27.sql
```

## Step 4 — Post-migration verification (read-only)

**4.1 Run the live verification script** (read-only, now with **44 checks** —
the new one is 44):

```bash
SUPABASE_DB_URL="$SUPABASE_DB_URL" bash scripts/sql_check_live.sh
```

- Expected: **VERIFICATION COMPLETE — all checks passed**, including **44** —
  the 4 tables exist, with RLS active on all 4, and
  `process_production(jsonb,jsonb)` is `SECURITY DEFINER` with `EXECUTE` for
  `authenticated`.

**4.2 Manual check (SQL Editor):**

```sql
-- 1) The 4 tables + RLS active (expected: 4 rows, rls = true):
SELECT c.relname, c.relrowsecurity AS rls
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND c.relname IN ('recipes','recipe_items','production_orders','production_order_items')
ORDER BY c.relname;

-- 2) Manager policies on the tables (expected: 16 policies — SELECT/INSERT/
--    UPDATE/DELETE per table):
SELECT tablename, count(*) AS policies
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('recipes','recipe_items','production_orders','production_order_items')
GROUP BY tablename ORDER BY tablename;

-- 3) RPC SECURITY DEFINER + EXECUTE for authenticated:
SELECT p.proname, p.prosecdef,
       has_function_privilege('authenticated',
         'public.process_production(jsonb,jsonb)', 'EXECUTE') AS exec_ok
FROM pg_proc p
WHERE p.proname = 'process_production';
-- Expected: process_production | true | true
```

**4.3 Integrity check** — repeat 2.2: identical product/sales/purchase/lot
counts (the migration does not touch existing rows).

**4.4 REST probe (the new app reads/writes the tables):** with the anon key and
the owner session, a `SELECT` on the new tables already responds (empty or with
recipes):

```bash
curl -s "$SUPABASE_URL/rest/v1/recipes?select=id,product_id,yield_quantity&limit=1" \
  -H "apikey: $SUPABASE_ANON_KEY" -H "Authorization: Bearer $OWNER_ACCESS_TOKEN"
```

- Expected: `[]` (no recipes) — on a database without the migration, PostgREST
  returns **`42P01` (relation "public.recipes" does not exist)**.

## Step 5 — Idempotency (optional; confirms a re-run does not duplicate)

Repeat Step 3 and then check:

```sql
-- Still exactly 4 production tables:
SELECT count(*) AS tables
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('recipes','recipe_items','production_orders','production_order_items');
-- Expected: 4.

-- Still exactly ONE process_production:
SELECT count(*) AS rpcs FROM pg_proc WHERE proname = 'process_production';
-- Expected: 1.
```

## Step 6 — Publish the app (Phase 2) and use production

The migration on its own changes nothing (new, empty tables):

1. **Publish the app version with Phase 2.** The **Production** module appears
   in the menu for owner/manager (gate `accessLevel != employee`).
2. **Build the recipes** (Production → New recipe): pick the **finished**
   product (only `manufactured`/`composite`), the base yield and the
   components/quantities. One recipe per finished product.
3. **Record production** (Production → Produce): enter the bases — the
   components are consumed FIFO and the finished lot is born with the cost
   calculated from the components' **current** purchase price.
4. **Check the flows:** the finished product becomes sellable in the POS
   (resale/manufactured/composite) and raw materials/packaging show up in
   Purchases.

> A production order **does not move cash** — the components were already paid
> for at purchase time; production only transforms stock.

## Rollback (only if needed)

> The migration is **purely additive** (new tables/indexes, a new RPC) and
> idempotent. Reverting simply means NOT publishing the new app; the existing
> data stays valid. To truly remove it:
>
> 1. **Recipes, orders and components written will be lost** (they are data NEW
>    to this phase — there was nothing before). Take the Step 1 backup first.
> 2. Drop the objects (destructive):
>    ```sql
>    DROP FUNCTION IF EXISTS public.process_production(jsonb, jsonb);
>    DROP TABLE IF EXISTS public.production_order_items;
>    DROP TABLE IF EXISTS public.production_orders;
>    DROP TABLE IF EXISTS public.recipe_items;
>    DROP TABLE IF EXISTS public.recipes;
>    ```
> 3. Do NOT revert the `products.type` column or the lots because of production:
>    they belong to Phases 1/W11 and stay valid without this module.

---

## Final checklist

| # | Item | Verification |
|---|------|--------------|
| 1 | Backup done | file `backup_pre_production.sql` exists |
| 2 | Pre-flight | 4 tables + RPC absent (2.1); counts written down (2.2); `products.type` present (2.3) |
| 3 | `upgrade.sql` applied | no errors (single transaction) — or the standalone script in Step 3C |
| 4 | `sql_check_live.sh` | ✓ all 44 checks (production: 44) |
| 5 | Tables + RLS | 4 tables with `relrowsecurity = true` (4.2.1) |
| 6 | Manager policies | 16 policies, INSERT/UPDATE with `mfa_ok()` (4.2.2) |
| 7 | Atomic RPC | `process_production` SECURITY DEFINER + EXECUTE to authenticated (4.2.3) |
| 8 | Data intact | identical product/sales/purchase/lot counts (4.3) |
| 9 | REST probe | `GET /rest/v1/recipes` responds `[]` (4.4) |
| 10 | Re-run has no effect | idempotency confirmed (Step 5) |
| 11 | Phase 2 app published | Production module visible to owner/manager |
| 12 | Recipes + production | owner/manager builds the recipe and produces; the finished lot is born with a cost |
