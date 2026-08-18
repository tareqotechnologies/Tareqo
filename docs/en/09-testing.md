# 09 — Testing

The project has **test coverage in every layer**, following the testability that Clean Architecture provides. Tests run on the VM (no emulator) — including the SQLite ones.

---

## How to run

```bash
# All tests (440+ green — Aug 9)
flutter test

# A specific file
flutter test test/domain/usecases/process_sale_use_case_sqlite_test.dart

# With coverage report
flutter test --coverage
```

> **CI:** `.github/workflows/ci.yml` runs analyze → test+coverage (**45% gate**) → dev-flavor APK build → **`sql_check.sh`** against a real Postgres 16 service (the SQL/RLS/RPC harness — see below).

> **SQLite on the Windows VM:** the `package:sqlite3` loader automatically falls back to the system `winsqlite3.dll` (via `AppDatabase.configureLoader` — a defensive probe in `test/helpers/test_sqlite.dart`). No manual setup is required.

---

## Structure

```text
test/
├── core/
│ ├── database/app_database_test.dart # Schema, re-entrant transactions, migrations W4/W11
│ ├── utils/quantity_test.dart # Milli-units ↔ units (W11)
│ ├── utils/scale_barcode_test.dart # 20PPPPPWWWWW parser + PLU normalization (W11)
│ └── security/
│ ├── secure_storage_service_test.dart # In-memory backend
│ └── secure_supabase_local_storage_test.dart # Secure session + PKCE storage (S1, Aug 6)
├── data/
│ ├── datasources/local/
│ │ ├── product_sqlite_data_source_test.dart
│ │ ├── sale_sqlite_data_source_test.dart
│ │ ├── stock_lot_sqlite_data_source_test.dart # FIFO order + store scope (W11)
│ │ ├── purchase_sqlite_data_source_test.dart # Purchases with expiry/lot (W11)
│ │ ├── financial_transaction_sqlite_data_source_test.dart
│ │ ├── debt_sqlite_data_source_test.dart
│ │ └── sqlite_unit_of_work_test.dart
│ └── repositories/ # Repositories (with fakes/in-memory impls)
│ ├── product_repository_impl_test.dart
│ ├── sale_repository_impl_test.dart
│ ├── financial_transaction_repository_impl_test.dart
│ ├── debt_repository_impl_test.dart
│ └── auth_repository_impl_test.dart
├── domain/
│ ├── entities/ # financial_transaction_test, sale_test
│ └── usecases/
│ ├── add_debt_use_case_test.dart
│ ├── add_financial_transaction_use_case_test.dart
│ ├── get_cash_flow_use_case_test.dart
│ ├── get_pending_debts_use_case_test.dart
│ ├── get_settled_debts_use_case_test.dart
│ ├── product_use_cases_test.dart
│ ├── settle_debt_use_case_test.dart
│ ├── process_sale_use_case_test.dart # with fakes
│ ├── process_sale_use_case_sqlite_test.dart # with a real in-memory database
│ ├── fifo_stock_use_case_test.dart # FIFO lot decrease (W11)
│ └── add_purchase_use_case_test.dart # Stock-in with expiry (W11)
├── helpers/test_sqlite.dart # openTestDatabase(): sqlite in-memory + schema
├── presentation/
│ ├── controllers/expiry_alerts_provider_test.dart # Red/yellow alerts (W11)
│ └── screens/
│ ├── login_screen_test.dart
│ ├── app_shell_test.dart
│ ├── product_list_screen_test.dart
│ ├── new_sale_sheet_test.dart
│ ├── sales_screen_test.dart
│ ├── sale_detail_screen_test.dart
│ ├── financial_screen_test.dart
│ ├── add_debt_sheet_test.dart
│ └── debts_screen_test.dart
└── widget_test.dart # Dashboard end-to-end with overrides (test/ root)
```

---

## Strategy per layer

### Domain (use cases)

- **Contract fakes** (`IProductRepository`, `ISaleRepository`, `IDebtRepository`, `IFinancialTransactionRepository`, `IUnitOfWork`) — no server, no database;
- Covers every domain exception (`InvalidPriceException`, `InsufficientStockException`, `InvalidPeriodException`, `DebtNotFoundException`, settlement idempotence...);
- **`process_sale_use_case_sqlite_test.dart`** tests the real flow with `openTestDatabase()` (in-memory database with the app schema) — validating atomicity (rollback on failure) and integrity;
- **`fifo_stock_use_case_test.dart`** covers the **FIFO decrease** (nearest-expiry lot first, surplus passing to the next lot, no expiry → by entry date), `increase` creating lots and the **stock pre-validation before any mutation** (no partial decrease).

### Data (SQLite datasources/repositories)

- `test/helpers/test_sqlite.dart`:
 ```dart
 Database openTestDatabase() {
 AppDatabase.configureLoader();
 final db = sqlite3.openInMemory();
 db.execute('PRAGMA foreign_keys = ON;');
 AppDatabase.createSchema(db);
 return db;
 }
 ```
- Test SQL, row mapping (enums by name, dates as epoch millis, bool 0/1), schema `CHECK`s and `SqliteUnitOfWork` (BEGIN/COMMIT/ROLLBACK, FIFO queue);
- `stock_lot_sqlite_data_source_test.dart` validates the **query FIFO order** (expiry ASC → entry ASC), the per-store scope and the atomic `current_quantity` update; `quantity_test.dart` and `scale_barcode_test.dart` cover the milli-unit math and the `20PPPPPWWWWW` parser (incl. PLU normalization).

### Presentation (screens)

- **Overridden providers** via `ProviderScope(overrides: [...])` — without touching GetIt or datasources;
- Example (`test/widget_test.dart`): simulates an active session (`authStateProvider.overrideWith(Stream.value(AppUser(...)))`), use case fakes and verifies KPIs + shell navigation;
- Pattern: `await tester.pumpAndSettle()` + `expect(find.text(...), findsOneWidget)`;
- `expiry_alerts_provider_test.dart` validates the alert classification (expired = red, < 30 days = yellow) and the urgency ordering.

---

## Patterns and conventions

| Pattern | Detail |
| ------- | ------ |
| Fakes via `implements` | `_Fake...` classes implement the domain interface (e.g.: `_FakeGetProductsUseCase implements GetProductsUseCase`) |
| Provider overrides | `productsProvider.overrideWithValue(...)`, `authStateProvider.overrideWith(...)` |
| Test database | SQLite **in-memory** (`sqlite3.openInMemory`) with the real schema, no seed |
| Atomicity | `ProcessSaleUseCase` tests validate full rollback when a step fails |
| Immutability | Datasources return immutable lists (tests verify copy/sorting behaviors) |

---

## SQL/RLS/RPC harness (`scripts/sql_check.sh`)

Runs `sqlcheck_stub.sql` (auth stubs) + `supabase/schema.sql` against a throwaway PostgreSQL, then as a **non-superuser** role (`app_user`, mirroring Supabase's `authenticated`):

1. schema applies cleanly;
2. super-admin role resolves via the `public.super_admins` table (C3 — never JWT email);
3. RLS isolates by `auth.uid()` with anti-forgery triggers;
4. employee access is scoped by **store** (`is_my_store`, C2);
5. the atomic money RPCs **execute for real** (`process_sale`, `register_debt`, `settle_debt`, `process_purchase`) with effects verified — including the **realization date** stamped on settlement (Aug 6), negative cases (insufficient stock) and the W11 additions: **FIFO lot decrease** (nearest expiry first), **lot creation on purchase** (with optional expiry) and the **`stock = Σ lots` invariant**.

Additionally, **`scripts/sql_check_live.sh`** is the **read-only** live verification (31 checks, 7 of them W11: columns, `stock_lots`/RLS/indexes, RPC bodies and the lots invariant) — used by the [W11 migration runbook](18-migracao-w11.md).

Run locally (Docker): `PGPASSWORD=... bash scripts/sql_check.sh [PGHOST] [PGUSER] [PGDATABASE]` (Warning: destructive — throwaway DB only).

---

## Related documents

- [Architecture](02-architecture.md) — why use cases are testable with mocks.
- [Developer guide](10-developer-guide.md) — commands and setup.
- [Business flows](08-business-flows.md) — what the sale/credit/cash tests validate.
