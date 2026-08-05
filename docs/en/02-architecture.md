# 02 — Architecture

## Summary

Dumbhanengue follows **Clean Architecture** in three layers, all inside `lib/`:

```text
lib/
├── main.dart                    # Bootstrap: initializes Supabase + GetIt + ProviderScope
├── app.dart                     # Root widget (MaterialApp, theme, AuthGate)
├── core/                        # Cross-cutting concerns (belong to no layer)
│   ├── config/                  # Configuration (Supabase URL/anon key via --dart-define)
│   ├── database/                # SQLite facade (conditional import io × stub)
│   ├── di/                      # Service Locator (GetIt) — central dependency registry
│   ├── errors/                  # Failure hierarchy (ServerFailure, NetworkFailure, CacheFailure)
│   ├── network/                 # Supabase bootstrap
│   ├── security/                # Secure storage (Keychain/Keystore)
│   ├── theme/                   # Material 3 theme (AppTheme, AppColors)
│   └── utils/                   # Generic helpers (pt-BR Formatters)
├── domain/                      # CORE: pure business rules, no external dependencies
│   ├── entities/                # Immutable entities (Freezed): Product, Sale, SaleItem, Debt, FinancialTransaction, AppUser
│   ├── repositories/            # Abstract contracts (IProductRepository, ISaleRepository, ...)
│   └── usecases/                # Use cases — orchestrate the business rules
├── data/                        # Concrete implementations of what the domain defines
│   ├── datasources/
│   │   ├── auth/                # AuthRemoteDataSource (Supabase)
│   │   └── local/               # Contracts + in-memory and SQLite impls (product, sale, financial_transaction, debt) + unit of work + seed
│   ├── models/                  # Serializable DTOs (reserved)
│   └── repositories/            # Implementations of the domain contracts (ProductRepositoryImpl, ...)
└── presentation/                # Everything the user sees and interacts with
    ├── controllers/             # Riverpod providers/notifiers (auth, products, sales, finance, debts)
    ├── screens/                 # Screens per module (auth, shell, dashboard, products, sales, financial, credit)
    └── widgets/                 # Shared widgets (KpiCard, EmptyState, StatusChip, AppSheet, ...)
```

---

## The dependency rule (the heart of the architecture)

Dependencies always point **inward**:

```text
presentation → domain   (the UI only knows abstractions: entities, use cases, contracts)
data         → domain   (implements the domain contracts)
core         → nothing  (serves all layers)
domain       → nothing  (does not know Flutter, Dio, SQLite, Riverpod, GetIt...)
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

The `presentation` layer knows **only abstractions** — `Product`, `GetProductsUseCase`, `IProductRepository` — never datasources, SQL, Dio or concrete implementations.

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

1. `Dio`, `SecureStorageService` and `IAuthRepository`;
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

- **`app_database_io.dart`** — opens `dumbhanengue.db`, creates the schema, seeds the demo, exposes re-entrant transactions;
- **`app_database_stub.dart`** — `openAppDatabase()` always returns `false` (web falls back to in-memory).

> ⚠️ **Keep the signatures of `openAppDatabase()` and `registerDatasources()` in sync** between the two files (there is a comment about this in the code).

---

## Error pattern: `Failure`

`lib/core/errors/failure.dart` defines a **sealed** hierarchy:

- `Failure(message)` — base;
- `ServerFailure` — HTTP error (4xx/5xx);
- `NetworkFailure` — connectivity;
- `CacheFailure` — local persistence.

The layers convert infrastructure exceptions into `Failure` before exposing them to the UI, keeping layers decoupled. (The **domain** exceptions — `InvalidSaleException`, `InsufficientStockException`, etc. — are thrown by use cases and caught by the screens; see [Domain](03-domain.md).)

---

## Related documents

- [Domain](03-domain.md) — entities, contracts and use cases.
- [Data layer](04-data.md) — datasources, SQLite and Unit of Work.
- [Presentation](05-presentation.md) — providers, screens and widgets.
