# 24 — Product structural type migration (`products.type`) on the Production Supabase (runbook)

> **Goal:** apply **Part 34 — product structural type (Phase 1)** to the
> production project (`bcyolmheltzlddfwgqcq`) using the consolidated
> `supabase/upgrade.sql` — same conventions as runbooks 15 (W4/H2), 16 (W11),
> 17 (cash closing), 18 (add-ons) and 20 (MFA aal2).
>
> What this apply brings (idempotent):
> 1. **`products.type` column** (`TEXT NOT NULL DEFAULT 'resale'`) — the
>    product's structural type by the NAME of the `ProductType` enum
>    (`rawMaterial`, `resale`, `manufactured`, `composite`, `packaging`);
> 2. **`DROP CONSTRAINT IF EXISTS products_type_check`** — clears an enum CHECK
>    that a previous version of the script may have created (it should not
>    exist; enum validation lives in the client/datasource);
> 3. **Column comment** (`COMMENT ON COLUMN`) documenting the values;
> 4. **`idx_products_store_type (store_id, type)` index** — keeps the
>    type filter constant in the catalogue listing.
>
> **No hard compatibility window:** the `'resale'` default means existing
> products were already purchasable and sellable and **keep working exactly
> the same** — no data is deleted or reclassified automatically. The old app
> neither selects nor sends the column (it relies on `DEFAULT 'resale'`); the
> new app (Phase 1) reads/writes the field. Publishing the app before or after
> the migration makes no difference.
>
> Portuguese (authoritative): [`../pt/24-migracao-tipo-produto.md`](../pt/24-migracao-tipo-produto.md)

---

## Application record

| Date | Project | Status |
|------|---------|--------|
| 2026-09-27 | **DEV** — `dotklbpqmlnhcdifiukd` | ✅ Part 34 applied: `products.type` column (TEXT NOT NULL DEFAULT `resale`) + `idx_products_store_type` index; `scripts/sql_check_live.sh` → checks 1–44 pass; the one-off backfill reclassified 1 product (`Oleo Maeva` → `rawMaterial`) |
| — | **PRODUCTION** — `bcyolmheltzlddfwgqcq` | ⏳ pending — REST diagnosis (2026-09-27): the `products.type` column already exists, but the index/CHECK are not observable over REST (confirm with check 43, which needs a `SUPABASE_DB_URL`). Project essentially empty (1 store, 0 products) |

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
- ⚠️ **Order of the parts:** check 44 is the **Phase 2** check (production,
  Part 35 — runbook 25). If you apply **only** Phase 1 (Part 34), check 43 will
  pass but **44 will fail** (production tables missing). The expected path is
  to apply both parts (34 and 35) — or accept 44 as the only pending one until
  Phase 2.
- **App built on the Phase 1 version** ready to publish (see Step 6) — only
  needed so the field shows up in the product form and so the role-based flows
  (purchases/POS) exist.

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
  --schema=public -f backup_pre_product_type.sql
```

## Step 2 — Pre-flight (read-only, SQL Editor)

**2.1 Do the column/index already exist?** (the migration is idempotent — this
only frames the scenario):

```sql
-- products.type column (expected: absent before the migration; if present,
-- with data_type=text / is_nullable=NO / column_default 'resale'):
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'products'
  AND column_name = 'type';

-- Type-filter index:
SELECT indexname FROM pg_indexes
WHERE schemaname = 'public' AND tablename = 'products'
  AND indexname = 'idx_products_store_type';

-- Accidental enum CHECK (expected: 0 rows):
SELECT conname FROM pg_constraint
WHERE conrelid = 'public.products'::regclass
  AND conname = 'products_type_check';
```

**2.2 Integrity sample** (write it down — the migration must not change any
row):

```sql
SELECT
  (SELECT count(*) FROM public.products)   AS products,
  (SELECT count(*) FROM public.sales)      AS sales,
  (SELECT count(*) FROM public.purchases)  AS purchases;

-- No product should be reclassified: after the migration ALL rows are in
-- 'resale' (the default), with no UPDATE at all.
SELECT type, count(*) FROM public.products GROUP BY type ORDER BY type;
```

## Step 3 — Apply `supabase/upgrade.sql`

### Option A — psql via pooler, ONE transaction (recommended — project convention)

```bash
psql "$SUPABASE_DB_URL" -X -v ON_ERROR_STOP=1 -1 -f supabase/upgrade.sql
```

- `-1` = single transaction: if **any** part fails, **everything** is rolled
  back — no partial state.
- Part 34 is `ADD COLUMN IF NOT EXISTS` + `DROP CONSTRAINT IF EXISTS` +
  `COMMENT` + `CREATE INDEX IF NOT EXISTS` + `ANALYZE` — a no-op on the 2nd run.

### Option B — Dashboard SQL Editor

1. Open the **SQL Editor** in the project.
2. Paste the **full contents** of `supabase/upgrade.sql`.
3. Run it. On error the editor stops and shows the message; since the script
   is idempotent, fixing and re-running is safe.

### Option C — standalone script (only Part 34)

To apply **only** this migration (e.g. a database already on the previous
parts), run the dedicated script — same content as Part 34:

```bash
psql "$SUPABASE_DB_URL" -X -v ON_ERROR_STOP=1 -1 \
  -f supabase/add_product_type_2026_09_27.sql
```

## Step 4 — Post-migration verification (read-only)

**4.1 Run the live verification script** (read-only, now with **44 checks in
total** — Phase 1's is 43; 44 is the Phase 2/production one):

```bash
SUPABASE_DB_URL="$SUPABASE_DB_URL" bash scripts/sql_check_live.sh
```

- Expected (with Part 34 and Part 35 applied): **VERIFICATION COMPLETE — all
  checks passed**, including **43** — the `products.type` column
  `TEXT NOT NULL DEFAULT 'resale'` (no enum CHECK) + the
  `idx_products_store_type` index.
- Applying **only** Phase 1 makes **44 fail** (production tables missing) —
  apply Part 35 too via runbook 25.

**4.2 Manual check (SQL Editor):**

```sql
-- 1) Column with the right type/default:
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'products'
  AND column_name = 'type';
-- Expected: type | text | NO | 'resale'::text

-- 2) Index present:
SELECT indexdef FROM pg_indexes
WHERE schemaname = 'public' AND tablename = 'products'
  AND indexname = 'idx_products_store_type';
-- Expected: ... ON public.products (store_id, type)

-- 3) NO enum CHECK (the client validates; a future type must not be blocked
--    by the old constraint):
SELECT conname FROM pg_constraint
WHERE conrelid = 'public.products'::regclass AND contype = 'c'
  AND pg_get_constraintdef(oid) ILIKE '%type%';
-- Expected: 0 rows.
```

**4.3 Integrity check** — repeat 2.2: identical product/sales/purchase counts
and **all** products in `'resale'` (none reclassified by the migration).

**4.4 REST probe (the new app reads/writes the field):** with the anon key and
the owner session, a product `SELECT` already returns the column:

```bash
curl -s "$SUPABASE_URL/rest/v1/products?select=id,name,type&limit=1" \
  -H "apikey: $SUPABASE_ANON_KEY" -H "Authorization: Bearer $OWNER_ACCESS_TOKEN"
```

- Expected: an item with `"type":"resale"`. On a database without the
  migration, PostgREST returns **`42703` (column products.type does not
  exist)** — proof the column exists.

## Step 5 — Idempotency (optional; confirms a re-run does not duplicate)

Repeat Step 3 and then check:

```sql
-- Still exactly ONE type column:
SELECT count(*) AS type_columns
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'products'
  AND column_name = 'type';
-- Expected: 1.

-- Still exactly ONE idx_products_store_type index:
SELECT count(*) AS indexes
FROM pg_indexes
WHERE schemaname = 'public' AND tablename = 'products'
  AND indexname = 'idx_products_store_type';
-- Expected: 1.
```

## Step 6 — Publish the app (Phase 1) and reclassify products

The migration changes nothing on its own (default `'resale'`):

1. **Publish the app version with Phase 1.** Existing products stay
   purchasable and sellable exactly as before.
2. **Reclassify product by product** (Products → edit → "Product type"):
   raw materials, manufactured, composite and packaging get the right role.
   It is best to start with the items that will leave the default lists:
   - **raw material/packaging** stop appearing in the POS;
   - **manufactured/composite** stop appearing in Purchases.
3. **Check the flows:** in the POS the catalogue shows only sellable roles
   (`isSellable`); in Purchases only purchasable ones (`isPurchasable`). If a
   role ends up with no items, the empty state explains why instead of saying
   "no products".
4. **Optional backfill by SQL** (only if you know the categories — the app
   never reclassifies anything on its own):

```sql
-- Example: everything in 'resale' with "FARINHA" (flour) in the name becomes a raw material.
UPDATE public.products SET type = 'rawMaterial'
WHERE type = 'resale' AND upper(name) LIKE '%FARINHA%';
```

> The `UPDATE` above is **manual and explicit** — the migration never runs it.

**Automatic backfill (recommended for large catalogues):** the one-off helper
`tool/backfill_product_types.dart` generalises the `LIKE` above with an ordered
keyword table (`lib/domain/services/product_type_classifier.dart`):

```bash
# 1) Dry-run on DEV (nothing is written) — review the plan:
dart run tool/backfill_product_types.dart

# 2) Apply on DEV (only rows still on 'resale'):
dart run tool/backfill_product_types.dart --apply

# 3) On PRODUCTION: dry-run, review, and only then --apply:
dart run tool/backfill_product_types.dart --prod
dart run tool/backfill_product_types.dart --prod --apply
```

- **Dry-run by default**: nothing is written without `--apply`.
- **Never undoes** an existing classification — by default it only looks at
  products on `resale` (use `--include-classified` to reapply the rules to
  all).
- Restrict to one store with `--store <id>`.
- Uses the **owner session** (RLS watches) and the gitignored credentials
  (`env/dev.env`/`env/test_accounts.env`; `--prod` uses `env/prod.env`).
- The matched rule shows up in the report (`(rule: farinha)`) — review it
  before `--apply`. Classification is heuristic: products with ambiguous
  names should be fixed in the UI afterwards.

## Rollback (only if needed)

> The migration is **additive** (column with a default, a comment and an
> index) and idempotent. Reverting simply means NOT publishing the new app;
> the data stays valid. To truly remove it:
>
> 1. **There is no data to undo:** no product was reclassified automatically
>    (only MANUAL reclassifications made in Step 6.4/the app).
> 2. Drop the column (destructive — only if the new app will NOT be published
>    and no product was reclassified):
>    `ALTER TABLE public.products DROP COLUMN IF EXISTS type;`
>    `DROP INDEX IF EXISTS public.idx_products_store_type;`
> 3. For the manual reclassifications, revert the `UPDATE`s you ran by hand
>    (or restore the Step 1 backup).

---

## Final checklist

| # | Item | Verification |
|---|------|--------------|
| 1 | Backup done | file `backup_pre_product_type.sql` exists |
| 2 | Pre-flight | column/index/CHECK catalogued (2.1); counts and `type` distribution written down (2.2) |
| 3 | `upgrade.sql` applied | no errors (single transaction) — or the standalone script in Step 3C |
| 4 | `sql_check_live.sh` | ✓ checks 1–43 (product type: 43). Check 44 (production) only passes with Part 35 (runbook 25) |
| 5 | No enum CHECK | 0 `type` constraints (4.2.3) |
| 6 | Data intact | identical counts and all products on `resale` (4.3) |
| 7 | REST probe | product returns `"type":"resale"` (4.4) |
| 8 | Re-run has no effect | idempotency confirmed (Step 5) |
| 9 | Phase 1 app published | "Product type" field visible in the form |
| 10 | Reclassification (optional) | owner/manager classifies product by product; POS/Purchases filter by role |
