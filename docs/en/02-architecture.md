# 02 — Architecture

## Summary

Dumbhanengue follows **Clean Architecture** in three layers, all inside `lib/`:

```text
lib/
├── main.dart # Bootstrap: initializes Supabase + GetIt + ProviderScope
├── app.dart # Root widget (MaterialApp, theme, AuthGate)
├── core/ # Cross-cutting concerns (belong to no layer)
│ ├── config/ # Configuration (Supabase URL/anon key via --dart-define)
│ ├── database/ # SQLite facade (conditional import io × stub)
│ ├── di/ # Service Locator (GetIt) — central dependency registry
│ ├── errors/ # (empty — domain exceptions replace the old Failure hierarchy)
│ ├── i18n/ # L10n helpers + transaction description strings
│ ├── observability/ # Crash reporting (Sentry) — CrashReporting
│ ├── network/ # Supabase bootstrap + secure session storage wiring
│ ├── security/ # Secure storage (Keychain/Keystore) + SecureSupabaseLocalStorage
│ ├── theme/ # Material 3 theme (AppTheme, AppColors)
│ └── utils/ # Generic helpers (pt-BR Formatters)
├── domain/ # CORE: pure business rules, no external dependencies
│ ├── entities/ # Immutable entities (Freezed): Product, Sale, SaleItem, Debt, FinancialTransaction, AppUser
│ ├── repositories/ # Abstract contracts (IProductRepository, ISaleRepository, ...)
│ └── usecases/ # Use cases — orchestrate the business rules
├── data/ # Concrete implementations of what the domain defines
│ ├── datasources/
│ │ ├── auth/ # AuthRemoteDataSource (Supabase)
│ │ └── local/ # Contracts + in-memory and SQLite impls (product, sale, financial_transaction, debt) + unit of work + plan catalog
│ ├── models/ # Serializable DTOs (reserved)
│ └── repositories/ # Implementations of the domain contracts (ProductRepositoryImpl, ...)
└── presentation/ # Everything the user sees and interacts with
 ├── controllers/ # Riverpod providers/notifiers (auth, products, sales, finance, debts)
 ├── screens/ # Screens per module (auth, shell, dashboard, products, sales, financial, credit)
 └── widgets/ # Shared widgets (KpiCard, EmptyState, StatusChip, AppSheet, ...)
```

---

## The dependency rule (the heart of the architecture)

Dependencies always point **inward**:

```text
presentation → domain (the UI only knows abstractions: entities, use cases, contracts)
data → domain (implements the domain contracts)
core → nothing (serves all layers)
domain → nothing (does not know Flutter, SQLite, Riverpod, GetIt...)
```

- **The domain imports no other layer.** Entities, contracts and use cases are pure Dart (with Freezed annotations for immutability and serialization).
- **Inversion happens at the wiring:** who decides *which* concrete implementations feed the contracts is the **ServiceLocator** (GetIt) at bootstrap. Switching SQLite for in-memory (or for a REST API in the future) **does not change a single line** of the domain or presentation.

### Real example: how a screen reaches the data

```text
ProductListScreen (widget)
 ↓ ref.watch
productsProvider (AsyncNotifier)
 ↓ ref.read
getProductsUseCaseProvider → GetProductsUseCase (domain)
 ↓
IProductRepository (domain contract)
 ↓ (implementation injected via GetIt)
ProductRepositoryImpl → ProductLocalDataSource (data layer)
 ↓ (SQLite on native / in-memory on web)
dumbhanengue.db database
```

The `presentation` layer knows **only abstractions** — `Product`, `GetProductsUseCase`, `IProductRepository` — never datasources, SQL or concrete implementations.

---

## Why Clean Architecture in this project?

1. **Testability:** use cases are tested with contract fakes — no server, no database, fast and deterministic.
2. **Replaceability:** persistence already migrated from in-memory → SQLite by changing **a single registration** in the ServiceLocator; a future REST API would follow the same path.
3. **Maintainability:** every layer has a clear contract; developers work in isolated modules.
4. **Team scalability:** domain interfaces act as "contracts" that enable parallel work (data and presentation against the same domain).

---

## Important structural decisions

### Contracts as interfaces (DIP)

`IProductRepository` is an **abstract interface** — only signatures (`getAll`, `getById`, `add`, `updateStock`). The concrete implementation (`ProductRepositoryImpl`, using SQLite or in-memory) lives in the `data` layer. The domain depends on the abstraction, never on the implementation.

### GetIt as Service Locator (composition root)

`lib/core/di/service_locator.dart` registers **everything** in `ServiceLocator.initialize()`:

1. `SecureStorageService`, `IAuthRepository` and `EmployeeAccountService`;
2. **Conditional persistence:**
 - `AppDatabase.openAppDatabase()` returns `true` (native) → registers **SQLite** datasources + `SqliteUnitOfWork`;
 - `false` (web or native library failure) → registers **in-memory** datasources + no-op unit of work.
3. Repositories and use cases (identical in both scenarios, since they depend only on contracts).

```dart
if (await AppDatabase.openAppDatabase()) {
 AppDatabase.registerDatasources(instance);
} else {
 _registerInMemoryDatasources();
}
_registerRepositoriesAndUseCases();
```

### Riverpod + GetIt together

**GetIt** delivers the instances (concrete dependencies); **Riverpod** defines the reactive state graph. The bridge is made by simple providers:

```dart
final getProductsUseCaseProvider = Provider<GetProductsUseCase>(
 (ref) => ServiceLocator.instance<GetProductsUseCase>(),
);
```

In **tests**, these providers are overridden with `overrideWithValue`/`overrideWith` — without touching GetIt or datasources.

### Conditional import for web (SQLite)

`dart:ffi` does not exist in the browser. `lib/core/database/app_database.dart` uses:

```dart
export 'app_database_stub.dart' if (dart.library.io) 'app_database_io.dart';
```

- **`app_database_io.dart`** — opens `dumbhanengue.db`, creates the schema, never seeds data (the DB starts empty), exposes re-entrant transactions;
- **`app_database_stub.dart`** — `openAppDatabase()` always returns `false` (web falls back to in-memory).

> **Warning:** **Keep the signatures of `openAppDatabase()` and `registerDatasources()` in sync** between the two files (there is a comment about this in the code).

---

## Server-side aggregations (H2): the Z-report preview

Since **H2** (scale), the app does not download the whole history to compute totals: heavy aggregations run **in Postgres** (`SECURITY DEFINER` RPCs) in **ONE call** — the device only receives the numbers. This pattern covers the cash flow (`get_cash_flow`), the sales report (`get_sales_report`), the dashboard KPIs (`get_dashboard_kpis`) and the **daily cash-closing preview (Z-report)** — `get_cash_closing_summary` — the focus of this section.

### The problem H2 solves

The Z-report preview needs the store's day summary: **total active sales**, the **expected cash in the drawer** (cash sales only) and the **breakdown by payment method**, plus the already-registered closing (if any). In local mode, `GetCashClosingSummaryUseCase` lists **all** sales and sums client-side (`aggregateCashClosingDay`). For stores with a large history (10k+ rows), that means downloading and processing everything on the device every time the screen opens — needless latency and memory.

### The flow in Supabase mode (H2)

```text
CashClosingSheet (Financial → Cash closing)
 │ ref.watch
 ▼
cashClosingSummaryProvider (Riverpod — FutureProvider.autoDispose)
 │ resolves active storeId + day = today
 ▼
GetCashClosingSummaryUseCase (domain)
 │ serverRepository != null (registered only in Supabase mode)
 ▼
SupabaseCashClosingSummaryRepository (data)
 │ ONE RPC call — the client never lists sales
 ▼
supabaseClient.rpc('get_cash_closing_summary', {p_store_id, p_day})
 │ PostgREST → Postgres
 ▼
get_cash_closing_summary (SECURITY DEFINER + is_my_store guard)
 ├─ Σ total of the day's ACTIVE sales (all methods)
 ├─ Σ expected in the drawer (only payment_method = 'cash')
 ├─ jsonb_object_agg by method → breakdown (JSONB)
 └─ already-registered closing in cash_closings (if any)
 │ returns JSONB
 ▼
CashClosingSummary (day, total, expected, breakdown, existing closing) → UI
```

### Architecture decisions

- **Aggregate where the data lives:** the RPC sums in the database (`SUM(total_amount)` with `status = 'active'` over the day window) — the network payload is **always small and constant**, regardless of history (H2 scale).
- **Guards on the server, not in the UI:** `SECURITY DEFINER` + `SET search_path` + the **`is_my_store(p_store_id)`** guard — the preview is readable by the store's owner **and employees**; the *confirmation* (closing) is managerial (`is_manager_of_store` in the `close_cash_register` RPC). Even a tampered client calling PostgREST directly is blocked.
- **The client sends only parameters:** `p_store_id` and `p_day` (start of the **local** day converted to UTC — same semantics as `close_cash_register`, window `[p_day, p_day + 1 day)`). No computed value leaves the device.
- **Same criteria, two places:** local mode uses `aggregateCashClosingDay` (client-side) with **exactly the same criteria** as the RPC (active sales only; cancelled ones stay out) — a single criteria shared with `CloseCashRegisterUseCase`, so the preview and the confirmation never diverge.
- **Optional injection (DIP):** `GetCashClosingSummaryUseCase` receives an optional `serverRepository` (`instance.isRegistered<ICashClosingSummaryRepository>()`). Supabase → `SupabaseCashClosingSummaryRepository` (RPC); local/tests → `null` (client-side fallback). The domain and the UI do not change between modes — only the ServiceLocator wiring does, like any persistence swap in this project.

> **Verification:** `sql_check.sh` (19.6) and `sql_check_live.sh` (35/35) validate the RPC against Postgres 16/17 (SECURITY DEFINER, guard, server-side aggregation); the E2E `integration_test/cash_closing_summary_live_test.dart` proves the **real payload** (`{p_store_id, p_day}` with the local day in UTC) against the real Supabase.

---

## Error pattern: domain exceptions + `CrashReporting`

The app does **not** use a `Failure` hierarchy. Business errors are **domain exceptions** (e.g. `InvalidSaleException`, `InsufficientStockException`) thrown by use cases and caught by the screens, which translate them into friendly messages. Unexpected errors (and any caught exception) are routed to **`CrashReporting.capture`** — `debugPrint` in debug, **Sentry** in release when `SENTRY_DSN` is present (see `lib/core/observability/crash_reporting.dart`).

---

## Related documents

- [Domain](03-domain.md) — entities, contracts and use cases.
- [Data layer](04-data.md) — datasources, SQLite and Unit of Work.
- [Presentation](05-presentation.md) — providers, screens and widgets.
- [Cash-closing migration runbook](19-migracao-cash-closing.md) — runbook of Part 25/26 (`cash_closings` table + `close_cash_register`/`get_cash_closing_summary` RPCs) applied live.
