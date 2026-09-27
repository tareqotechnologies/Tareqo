# 26 — Notification migration: `body_params` (Part 33) on the Production Supabase (runbook)

> **Goal:** apply **Part 33 — notifications: `body_params`** to the production
> project (`bcyolmheltzlddfwgqcq`), following the same conventions as runbooks
> 15 (W4/H2), 16 (W11), 17 (cash closing), 20 (MFA aal2), 24 (product type) and
> 25 (production).
>
> What this apply brings (idempotent):
> 1. **`body_params` column (JSONB)** on `invoice_notifications` — the body's
>    interpolation parameters (period, amount, currency, days, add-on, dates) so
>    the UI reconstructs the message **localised** at display time. The persisted
>    `body` stays in PT as a fallback; `NULL` = legacy notification (shows `body`).
> 2. **Column comment** (`COMMENT ON COLUMN`) documenting the contract.
>
> **No hard compatibility window:** the migration is **purely additive** (one new
> column; no existing data is read, changed or reclassified) and idempotent.
> ⚠️ The NEW app **selects the column** — against an unmigrated database PostgREST
> fails with `42703`. **Publish the app after the migration.**
>
> Portuguese (authoritative): [`../pt/26-migracao-notificacoes-body-params.md`](../pt/26-migracao-notificacoes-body-params.md)

---

## Application record

| Date | Project | Status |
|------|---------|--------|
| 2026-09-27 | **DEV** — `dotklbpqmlnhcdifiukd` | ✅ Part 33 applied (`invoice_notifications.body_params` present) |
| — | **PRODUCTION** — `bcyolmheltzlddfwgqcq` | ⏳ pending — REST diagnosis (2026-09-27): column absent; project essentially empty (1 store, 0 products/sales/purchases) |

> **Dev vs. production:** `env/dev.env` → `dotklbpqmlnhcdifiukd` (**DEV**) and
> `env/prod.env` → `bcyolmheltzlddfwgqcq` (**PRODUCTION**). The examples below use
> the **production** ref; for DEV use `env/db.env` (`SUPABASE_DB_URL`).

Set the URL (replace `PASSWORD` and the region):

```bash
export SUPABASE_DB_URL='postgresql://postgres.bcyolmheltzlddfwgqcq:PASSWORD@aws-0-<region>.pooler.supabase.com:6543/postgres?sslmode=require'
```

## Step 0 — Prerequisites

- Dashboard + the **database password** (Settings → Database); the direct host is
  IPv6-only → use the **pooler**.
- `psql`, Docker (`postgres:16`) **or** Python with `psycopg2`/`psycopg3`
  (`scripts/sql_check_live.sh` has a Python fallback).
- ⚠️ **NEVER** run `scripts/sql_check.sh` against the live database (it runs
  `DROP SCHEMA public CASCADE`). Live verification is only
  `scripts/sql_check_live.sh`.

## Step 1 — Backup (mandatory)

Dashboard → Database → **Backups** → "Create a backup" (or PITR), or `pg_dump`
(port **5432** of the pooler).

## Step 2 — Pre-flight (read-only)

```sql
-- Expected BEFORE the migration: 0 rows.
SELECT column_name, data_type FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'invoice_notifications'
  AND column_name = 'body_params';
```

## Step 3 — Apply

**Option A — standalone script (recommended):**

```bash
psql "$SUPABASE_DB_URL" -X -v ON_ERROR_STOP=1 -1 \
  -f supabase/add_notification_body_params_2026_09_27.sql
```

**Option B — full `upgrade.sql`** (if the database is behind by more than one
part; Part 33 is the `body_params` section):

```bash
psql "$SUPABASE_DB_URL" -X -v ON_ERROR_STOP=1 -1 -f supabase/upgrade.sql
```

Both use `-1` = single transaction: if anything fails, everything is rolled back.
Re-running is safe (idempotent).

## Step 4 — Verification (read-only)

```sql
SELECT column_name, data_type FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'invoice_notifications'
  AND column_name = 'body_params';
-- Expected: body_params | jsonb
```

**REST probe** (with the owner session):

```bash
curl -s "$SUPABASE_URL/rest/v1/invoice_notifications?select=id,body_params&limit=1" \
  -H "apikey: $SUPABASE_ANON_KEY" -H "Authorization: Bearer $OWNER_ACCESS_TOKEN"
```

- Expected: `200` (empty list or notifications). Before the migration: **`42703`**
  (`column invoice_notifications.body_params does not exist`).

## Rollback

```sql
ALTER TABLE public.invoice_notifications DROP COLUMN IF EXISTS body_params;
```

> Destructive — the column is additive and does not change existing data.
> Reverting is only needed if the new app will NOT be published.

---

## Final checklist

| # | Item | Verification |
|---|------|--------------|
| 1 | Backup done | Step 1 backup |
| 2 | Pre-flight | column absent before (Step 2) |
| 3 | Script applied | no errors (single transaction) |
| 4 | Column present | `body_params` of type `jsonb` (Step 4) |
| 5 | REST probe | `select=id,body_params` returns `200` |
| 6 | Re-run has no effect | idempotency (`ADD COLUMN IF NOT EXISTS`) |
