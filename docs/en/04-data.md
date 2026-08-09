# 04 — Data Layer

The `lib/data/` layer concretely implements what the domain declares. It contains:

- **Datasources** — local data sources (contracts + implementations), remote business sources (Supabase) and remote auth;
- **Repositories** — implementations of the domain contracts;
- **Unit of Work** — atomic transactions (SQLite);
- **Plan catalog** — the real price table injected at the composition root (no demo data).

---

## Structure

```text
lib/data/
├── datasources/
│   ├── auth/
│   │   ├── auth_remote_data_source.dart              # Remote auth contract
│   │   └── supabase_auth_remote_data_source.dart     # Supabase/gotrue implementation
│   ├── remote/
│   │   ├── supabase_datasource_helpers.dart          # Client + session user_id
│   │   ├── supabase_product_data_source.dart         # Products (Supabase)
│   │   ├── supabase_sale_data_source.dart            # Sales (nested insert sale + items)
│   │   ├── supabase_stock_lot_data_source.dart       # FIFO lots (Supabase)
│   │   ├── supabase_financial_transaction_data_source.dart  # Transactions (Supabase)
│   │   ├── supabase_debt_data_source.dart            # Debts/credit (Supabase)
│   │   ├── supabase_plan_data_source.dart            # Plans (Supabase)
│   │   ├── supabase_tenant_data_source.dart          # Tenants + approval (Supabase)
│   │   ├── supabase_store_data_source.dart           # Stores (Supabase)
│   │   ├── supabase_employee_data_source.dart        # Employees (Supabase)
│   │   └── supabase_plan_request_data_source.dart    # Upgrades (Supabase)
│   └── local/
│       ├── product_local_data_source.dart            # Contract
│       ├── product_local_data_source_impl.dart       # In-memory
│       ├── product_sqlite_data_source_impl.dart      # SQLite
│       ├── stock_lot_local_data_source.dart / _impl / _sqlite  # FIFO lots (contract + memory + SQLite)
│       ├── sale_local_data_source.dart / _impl / _sqlite
│       ├── financial_transaction_local_data_source.dart / _impl / _sqlite
│       ├── debt_local_data_source.dart / _impl / _sqlite
│       ├── plan_local_data_source.dart / _impl       # Contract + in-memory (Accounts)
│       ├── tenant_local_data_source.dart / _impl     # Tenants (Accounts)
│       ├── store_local_data_source.dart / _impl      # Stores (Accounts)
│       ├── employee_local_data_source.dart / _impl   # Employees (Accounts)
│       ├── plan_request_local_data_source.dart / _impl  # Upgrades (Accounts)
│       ├── sqlite_unit_of_work.dart                  # Real IUnitOfWork (transaction)
│       └── plan_catalog.dart                        # Plans (real catalog)
└── repositories/
    ├── product_repository_impl.dart
    ├── sale_repository_impl.dart
    ├── financial_transaction_repository_impl.dart
    ├── debt_repository_impl.dart
    ├── auth_repository_impl.dart
    ├── plan_repository_impl.dart / tenant_repository_impl.dart
    ├── store_repository_impl.dart / employee_repository_impl.dart
    └── plan_request_repository_impl.dart
```

---

## Two implementations, one contract

Each `XxxLocalDataSource` is an **interface**; there are two implementations:

| Contract | In-memory (`*_impl.dart`) | SQLite (`*_sqlite_impl.dart`) |
| -------- | ------------------------- | ----------------------------- |
| `ProductLocalDataSource` | `List<Product>` + seed | `products` table |
| `StockLotLocalDataSource` | `List<StockLot>` + seed | `stock_lots` table (FIFO order guaranteed in the query) |
| `SaleLocalDataSource` | `List<Sale>` + seed | `sales` + `sale_items` tables (single transaction) |
| `FinancialTransactionLocalDataSource` | `List<FinancialTransaction>` + seed | `financial_transactions` table |
| `DebtLocalDataSource` | `List<Debt>` + seed | `debts` table |

**Who chooses which one?** The `ServiceLocator`, by precedence:

```dart
if (SupabaseConfig.isConfigured) {
  _registerSupabaseDatasources();            // remote: SaaS, per-tenant RLS
} else if (await AppDatabase.openAppDatabase()) {
  AppDatabase.registerDatasources(instance); // SQLite (native)
} else {
  _registerInMemoryDatasources();            // in-memory (web/fallback)
}
```

> With `SupabaseConfig.isConfigured = true` (default, embedded credentials), the **remote datasources** are active. To use local persistence, run with `--dart-define=SUPABASE_URL= --dart-define=SUPABASE_ANON_KEY=` (empty → `isConfigured = false`).

> Parity convention: the in-memory listing sorts by name case-insensitively and SQLite uses `ORDER BY name COLLATE NOCASE` — the UI behaves the same across all three sources.

---

## Remote datasources (Supabase)

They implement **the same contracts** (`ProductLocalDataSource`, `SaleLocalDataSource`, `FinancialTransactionLocalDataSource`, `DebtLocalDataSource`) with the backend on Supabase's Postgres — the domain, use cases and UI don't change.

- **Tenant/store isolation:** every INSERT writes `user_id` (from the session — `requireCurrentUserId()`); **RLS** (`auth.uid() = user_id` **OR** `public.is_my_store(store_id)`) filters in the database, and the `set_tenant_user_id()` + `set_record_store_id()` **triggers** in the schema enforce both values on the server (forgery-proof);
- **Enums** persisted by name; **dates** as TIMESTAMPTZ (ISO 8601); **booleans** as BOOLEAN;
- **Atomic money flows:** the sale/purchase use cases **delegate to `SECURITY DEFINER` RPCs** (`process_sale`, `process_purchase`, `register_debt`, `settle_debt`) that run the whole operation in **one DB transaction** (sale + items + **FIFO stock lots** + cash, or debt + pending entry, or settlement + resolution) with idempotency keys and `FOR UPDATE` stock locking. `process_sale` consumes lots in FIFO order; `process_purchase` **creates the lots** of the entry (with optional expiry). The PostgREST nested insert (sale + items in one request) remains as the fallback `add` for the contract;
- **Unit of Work:** no-op in Supabase mode (each REST call is its own transaction) — that is why the atomic RPCs exist;
- **No session:** the datasources throw `StateError` — data screens are only reachable after sign-in (`AuthGate`).

The schema (tables, RLS, policies, indexes, triggers, functions and seed) lives in [`supabase/schema.sql`](../../supabase/schema.sql), validated by `scripts/sql_check.sh` against PostgreSQL 16 (see [Testing](09-testing.md)).

---

## SQLite persistence

### Where the database lives

- File: **`dumbhanengue.db`** in `getApplicationDocumentsDirectory()` (via `path_provider`).
- `PRAGMA foreign_keys = ON` on open.
- On web SQLite **does not run** (`dart:ffi` does not exist) → conditional import to `app_database_stub.dart` → in-memory. In tests on the Windows VM, `package:sqlite3` falls back to the system `winsqlite3.dll` (see `test/helpers/test_sqlite.dart`).

### Database schema

Since W4, money is **INTEGER cents**; since W11, quantities are **INTEGER milli-units** (1000 = 1 unit/kg) — same philosophy as cents, no floating point in money or quantity.

```sql
CREATE TABLE products (
  id TEXT PRIMARY KEY,
  store_id TEXT NOT NULL DEFAULT 'st1',  -- Phase 2: store scope
  name TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  purchase_price INTEGER NOT NULL CHECK (purchase_price >= 0),  -- cents (W4)
  sale_price INTEGER NOT NULL CHECK (sale_price >= 0),          -- cents (W4)
  stock_quantity INTEGER NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0),  -- milli-units (W11)
  code TEXT,                 -- scale-label barcode/PLU (W11, optional)
  venda_por_fracao INTEGER NOT NULL DEFAULT 0,  -- 0/1: sold by weight (W11)
  unit_label TEXT NOT NULL DEFAULT 'un'         -- kg | un (W11)
);

CREATE TABLE sales (
  id TEXT PRIMARY KEY,
  store_id TEXT NOT NULL DEFAULT 'st1',
  sale_number INTEGER NOT NULL DEFAULT 0,  -- sequential per store (S-00001)
  total_amount INTEGER NOT NULL CHECK (total_amount >= 0),  -- cents
  payment_method TEXT NOT NULL,          -- enum name (stable)
  date_time INTEGER NOT NULL             -- epoch millis
);

CREATE TABLE sale_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  sale_id TEXT NOT NULL REFERENCES sales(id) ON DELETE CASCADE,
  product_id TEXT NOT NULL,
  product_name TEXT NOT NULL,            -- snapshot
  quantity INTEGER NOT NULL CHECK (quantity > 0),    -- milli-units (W11)
  unit_price INTEGER NOT NULL CHECK (unit_price >= 0) -- cents
);
CREATE INDEX idx_sale_items_sale_id ON sale_items(sale_id);

CREATE TABLE financial_transactions (
  id TEXT PRIMARY KEY,
  store_id TEXT NOT NULL DEFAULT 'st1',
  description TEXT NOT NULL,
  amount INTEGER NOT NULL CHECK (amount >= 0),  -- cents
  type TEXT NOT NULL,                    -- income | expense
  category TEXT NOT NULL,
  date INTEGER NOT NULL,                 -- epoch millis
  status TEXT NOT NULL DEFAULT 'paid',   -- paid | pending
  debt_id TEXT                           -- link to debts (credit)
);

CREATE TABLE debts (
  id TEXT PRIMARY KEY,
  store_id TEXT NOT NULL DEFAULT 'st1',
  debt_number INTEGER NOT NULL DEFAULT 0,  -- sequential per store (D-00001)
  person_name TEXT NOT NULL,
  amount INTEGER NOT NULL CHECK (amount >= 0),  -- cents
  due_date INTEGER NOT NULL,             -- epoch millis
  is_customer_debt INTEGER NOT NULL,     -- 0/1
  is_paid INTEGER NOT NULL DEFAULT 0,    -- 0/1
  paid_at INTEGER,                       -- epoch millis (settlement date)
  customer_id TEXT                       -- link to customers (credit module)
);

CREATE TABLE customers (
  id TEXT PRIMARY KEY,
  store_id TEXT NOT NULL DEFAULT 'st1',
  name TEXT NOT NULL,
  phone TEXT NOT NULL DEFAULT '',
  email TEXT NOT NULL DEFAULT ''
);

CREATE TABLE purchases (
  id TEXT PRIMARY KEY,
  store_id TEXT NOT NULL DEFAULT 'st1',
  purchase_number INTEGER NOT NULL DEFAULT 0,  -- sequential per store (C-00001)
  supplier_name TEXT NOT NULL,
  total_amount INTEGER NOT NULL CHECK (total_amount >= 0),  -- cents
  payment_method TEXT NOT NULL DEFAULT 'cash',  -- supplier payment method
  date_time INTEGER NOT NULL
);

CREATE TABLE purchase_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  purchase_id TEXT NOT NULL REFERENCES purchases(id) ON DELETE CASCADE,
  product_id TEXT NOT NULL,
  product_name TEXT NOT NULL,
  quantity INTEGER NOT NULL CHECK (quantity > 0),    -- milli-units (W11)
  unit_price INTEGER NOT NULL CHECK (unit_price >= 0),  -- cents
  expiry_date INTEGER,             -- expiry of the lot created by this item (W11)
  UNIQUE (purchase_id, product_id)
);
CREATE INDEX idx_purchase_items_purchase_id ON purchase_items(purchase_id);

-- W11 — FIFO lots: every stock-in creates a lot; the POS decrease consumes
-- by expiry (nearest first) and, without expiry, by entry date.
CREATE TABLE stock_lots (
  id TEXT PRIMARY KEY,
  store_id TEXT NOT NULL DEFAULT 'st1',
  product_id TEXT NOT NULL,
  entry_date INTEGER NOT NULL,             -- epoch millis (stock-in date)
  expiry_date INTEGER,                     -- expiry (optional, NULL = none)
  initial_quantity INTEGER NOT NULL CHECK (initial_quantity >= 0),  -- milli-units
  current_quantity INTEGER NOT NULL CHECK (current_quantity >= 0),  -- milli-units
  cost_price INTEGER NOT NULL CHECK (cost_price >= 0)               -- cents
);
CREATE INDEX idx_stock_lots_product ON stock_lots(product_id, store_id);
CREATE INDEX idx_stock_lots_expiry ON stock_lots(expiry_date) WHERE current_quantity > 0;
```

**Serialization conventions:**

| Type | Persisted as |
| ---- | ------------ |
| Enum | **Name** (`payment_method`, `type`, `status`) — stable in serialization |
| `DateTime` | Epoch millis (`int`) |
| `bool` | `0`/`1` |
| Money | `INTEGER` — **cents** (W4) |
| Quantity | `INTEGER` — **milli-units** (W11: `1000` = 1 unit/kg) |

The `CHECK` constraints (`stock_quantity >= 0`, `amount >= 0`, `quantity > 0`) are the database's **last line of defense**; the business rules remain in the domain.

### Lightweight migrations (idempotent)

`AppDatabase.createSchema` applies `ALTER TABLE` for already existing databases:

1. **`debts.is_paid`** — added with `DEFAULT 0` (old debts remain pending);
2. **`financial_transactions.debt_id`** — added as `NULL` (old debts will settle via a new income, no duplicate);
3. **`debts.paid_at`** — added as `NULL` (already settled debts have no settlement date until a new settlement);
4. **`store_id`** on all 6 business tables (Phase 2) — added as `'st1'` + per-store indexes.
5. **`sales.sale_number`** — sequential per store (S-00001…), backfilled by date order; unique `(store_id, sale_number)`;
6. **`purchases.purchase_number`** — sequential per store (C-00001…), backfilled by date order; unique `(store_id, purchase_number)`;
7. **`debts.debt_number`** — sequential per store (D-00001…), backfilled by due date order; unique `(store_id, debt_number)`;
8. **`purchases.payment_method`** — supplier payment method (same enum as sales), added as `'cash'` (legacy purchases were immediate cash expenses);
9. **W11 (FIFO + expiry + milli-units)** — legacy databases get the `code`/`venda_por_fracao`/`unit_label` (products) and `expiry_date` (purchase_items) columns; **all quantities** (products, sale_items, purchase_items) are converted from whole units to **milli-units (×1000)**; and every product with stock gets an **initial lot** (`lot-mig-…`, no expiry, cost = purchase price) so the `stock = Σ lots` invariant holds from day one. Idempotent guard: presence of the `code` column (added only in this migration) — the ×1000 conversion never re-runs.

The numbering migrations run **after** the `store_id` migration (the backfills reference `store_id`). All of them use `PRAGMA table_info` to check the column first — **safe for re-execution** (new databases already create the columns in `CREATE TABLE`).

### No automatic seed

The database **never seeds demo data**: `AppDatabase.initialize` only creates the schema and migrates money to cents (W4) and quantities to milli-units (W11) — products, sales, cash, credit, customers and purchases start **empty** and only record real data created by the user.

---

## Unit of Work (atomic transactions)

### Contract (domain)

```dart
abstract interface class IUnitOfWork {
  Future<T> run<T>(Future<T> Function() action);
}
```

### SQLite implementation (`SqliteUnitOfWork`)

- Runs `action()` inside **`BEGIN IMMEDIATE` → `COMMIT`/`ROLLBACK`**.
- `BEGIN IMMEDIATE` acquires the **write lock** at the start — closes the TOCTOU window between stock pre-validation and writing.
- **Internal FIFO queue:** serializes concurrent transactions in the same process (the connection does not accept nested transactions from different flows).

### Re-entrant transactions (`AppDatabase`)

SQLite **does not accept nested transactions**. That's why `AppDatabase` keeps a **depth counter** (`_transactionDepth`):

- outer call → issues the real `BEGIN IMMEDIATE` (increments to 1);
- nested calls (e.g.: `SaleSqliteDataSourceImpl.add` inside `ProcessSaleUseCase` via `runInTransaction`) → only increment the counter and **join** the outer transaction;
- `commit`/`rollback` are only issued when the counter returns to 0.

> ⚠️ **Global invariant:** the counter is static and assumes **a single connection** (Database singleton) and **one** `IUnitOfWork` per process — as the app registers. Do not open multiple concurrent transactional connections.

### In-memory implementation

`_DirectUnitOfWork` (in `service_locator.dart`) is a **no-op**: in-memory execution is already sequential — but **without atomicity guarantees** on a partial failure (in-memory writes practically never fail).

---

## Repositories (implementations)

They are **dumb ports**: they only delegate to the injected datasource.

| Implementation | Domain contract | Delegates to |
| ------------- | --------------- | ------------ |
| `ProductRepositoryImpl` | `IProductRepository` | `ProductLocalDataSource` |
| `SaleRepositoryImpl` | `ISaleRepository` | `SaleLocalDataSource` |
| `FinancialTransactionRepositoryImpl` | `IFinancialTransactionRepository` | `FinancialTransactionLocalDataSource` (the `getByPeriod` filter runs in Dart) |
| `DebtRepositoryImpl` | `IDebtRepository` | `DebtLocalDataSource` |
| `AuthRepositoryImpl` | `IAuthRepository` | `AuthRemoteDataSource` |

No repository knows whether the data comes from memory, SQLite or an API — switching persistence means switching **one registration in the ServiceLocator**.

---

## Remote datasource (authentication)

- `AuthRemoteDataSource` — contract (`signUp`, `signIn`, `signOut`, `authStateChanges`);
- `SupabaseAuthRemoteDataSourceImpl` — uses `Supabase.instance.client.auth` (gotrue) and **converts the Supabase `User` to the domain `AppUser`** here (the layers above never see gotrue).

Important detail: on `signUp`, if **email confirmation** is enabled, `response.user` may be `null` (account created, session not yet) → returns an `AppUser` with a **placeholder id** (`fallbackEmail`); the real session only arrives after confirmation.

---

## Accounts layer (multi-tenancy)

The Accounts datasources (plans, tenants, stores, employees and upgrades) follow the **same dual-implementation pattern**: contract + in-memory (`*_impl.dart`) in the local branch and a Supabase datasource (`remote/`) in the remote branch. In local dev, the composition root only injects the **real plan catalog**; tenant, stores, employees and upgrades start empty — the owner goes through onboarding and approval. Flow details in [Multi-tenancy and Super Admin](11-multitenancy.md).

---

## No demo data

The app **never seeds sample content** (neither locally nor in the production schema): the only injected data is the **real plan catalog** (`PlanCatalog`, mirrored in Part 2 of `schema.sql`). Products, sales, transactions, credit, customers and purchases start empty — the periods (Today/7 days/Month) only reflect real data. Existing databases that received the old seed can be cleaned with `supabase/cleanup_demo_data.sql`.

---

## Related documents

- [Architecture](02-architecture.md) — where the data layer fits.
- [Business flows](08-business-flows.md) — transactions in action (atomic sale).
- [Multi-tenancy and Super Admin](11-multitenancy.md) — plans, tenants, stores and employees in the database.
- [Developer guide](10-developer-guide.md) — how to run the SQLite tests.
