# 10 — Developer Guide

Practical guide to run, test and evolve Dumbhanengue ERP.

---

## Prerequisites

- Flutter 3.x (Dart SDK `^3.12.2`);
- Chrome (to run on web);
- Windows/mobile/desktop for SQLite persistence; **web** uses in-memory (automatic fallback).

---

## Run the project

```bash
# Install dependencies
flutter pub get

# Generate code (Freezed + json_serializable) — required after creating/changing
# classes annotated with @freezed
dart run build_runner build --delete-conflicting-outputs

# Run on a device/emulator
flutter run

# Run on web (in-memory fallback)
flutter run -d chrome

# Tests
flutter test

# Static analysis
flutter analyze
```

### Point to another Supabase project (e.g.: production)

```bash
flutter run --dart-define=SUPABASE_URL=https://your-project.supabase.co \
            --dart-define=SUPABASE_ANON_KEY=eyJ...
```

> The `Dio` API base (`API_BASE_URL`) is configured the same way, with `http://localhost:3000/api` as default.

### Define the super admin

The super admin is identified by a **DB-backed role** — the `public.super_admins` table in Supabase (no more hardcoded email). To promote a user (project SQL Editor):

```sql
INSERT INTO public.super_admins (user_id)
SELECT id FROM auth.users WHERE email = 'admin@yourdomain.com'
ON CONFLICT (user_id) DO NOTHING;
```

> The app resolves the role via the `is_super_admin` RPC; the server-side RLS is the authority. Details in [Multi-tenancy and Super Admin](11-multitenancy.md).

### Active persistence (Supabase × local)

With Supabase configured (default — credentials embedded in `SupabaseConfig`), products, sales, finance and credit are written **remotely** per tenant (RLS — datasources in `lib/data/datasources/remote/`). To develop with local persistence (SQLite on native / in-memory on web), run with **empty** variables:

```bash
flutter run --dart-define=SUPABASE_URL= --dart-define=SUPABASE_ANON_KEY=
```

### Android release signing

Release signing reads `android/key.properties` (never versioned — see `.gitignore` and the documented template `android/key.properties.example`).

- **Keystore:** `android/app/upload-keystore.jks` (already generated — alias `upload`, RSA 2048, valid until 2053);
- **`key.properties`:** already filled with the generated credentials (passwords live in the file — back it up in a password manager together with the `.jks`; losing both means you can't publish updates);
- **⚠️ PKCS12 (JDK 9+):** the store and the key share a SINGLE password — `storePassword` and `keyPassword` must be equal;
- **Without `key.properties`** (CI/dev): the release build falls back to the **debug** keystore — not publishable;
- **Play Console:** publish the first AAB with this key, enable *Play App Signing*, and register the upload key's SHA-256 fingerprint in *Setup → App integrity*;
- **CI:** the current pipeline does NOT sign releases (debug fallback). For publishable artifacts in CI, decode the keystore from a secret (instructions in `key.properties.example`).

To inspect the key:

```bash
keytool -list -v -keystore android/app/upload-keystore.jks -storepass YOUR_PASSWORD
```

---

## Development flow mental map

```text
New feature:
  1. Entity in the domain (freezed)      → lib/domain/entities/
  2. Repository contract                 → lib/domain/repositories/
  3. Use case + domain exceptions        → lib/domain/usecases/
  4. Implementation in data              → lib/data/datasources/ (in-memory + SQLite)
                                          lib/data/datasources/remote/ (Supabase)
                                          lib/data/repositories/
  5. Register in ServiceLocator          → lib/core/di/service_locator.dart
  6. Riverpod provider                   → lib/presentation/controllers/
  7. Screen/widget                       → lib/presentation/screens/ | widgets/
  8. Tests (domain → data → UI)          → test/
  9. `dart run build_runner build --delete-conflicting-outputs`
```

---

## Project conventions

### Architecture (non-negotiable)

- **Dependency rule:** `domain` doesn't import `data`, `presentation` or infrastructure `core`; dependencies always point inward;
- **Contracts as interfaces:** domain repositories and datasources are `abstract interface class`; implementations live in `data`;
- **Thin UI:** business rules in use cases; screens only catch domain exceptions and show messages;
- **GetIt only at the composition root:** who delivers instances is the `ServiceLocator`; providers bridge to Riverpod.

### Persistence

- **Always two implementations:** when creating a datasource, make the **in-memory** version (`*_impl.dart`) and the **SQLite** one (`*_sqlite_impl.dart`) implementing the same contract;
- **Parameterized SQL** (prepared statements) — never string concatenation;
- **Serialization:** enums by name, `DateTime` as epoch millis, `bool` as 0/1;
- **Transactions:** related multiple writes inside `IUnitOfWork` / `runInTransaction` (re-entrant);
- **Lightweight migrations:** idempotent `ALTER TABLE` in `AppDatabase.createSchema`, guarded by `PRAGMA table_info`;
- **⚠️ Keep the signatures in sync** between `app_database_io.dart` ↔ `app_database_stub.dart`.

### SQLite for new data

When adding tables/columns: create them in `createSchema` (with guard `CHECK`s), add an idempotent migration if needed, and extend the seed if the demo requires it.

### State (Riverpod)

- Async state → `AsyncNotifier`/`AsyncNotifierProvider` (AsyncValue: loading/error/data);
- "Bridge" providers for use cases via `ServiceLocator.instance<T>()`;
- `refresh()` = `invalidateSelf()` + `await future`;
- Reload dependent lists with `ref.invalidate(...)` after mutations (e.g.: sale → products, sales, transactions and cash).

### UI

- Material 3, theme via `AppTheme` (`AppColors` for semantics: income/expense/warning);
- pt-BR formatting via `Formatters` (currency, date, relative day);
- Form bottom sheets via `showAppSheet` + `AppSheetHeader`;
- Screen states: `EmptyState`, `ErrorView`, `KpiCard`, `StatusChip`, `SearchField`, `SectionHeader`.

### Tests

- Contract fakes in use cases; `openTestDatabase()` (in-memory SQLite) for data;
- Provider overrides in screen tests (`ProviderScope(overrides: [...])`);
- Every domain exception must have a test.

---

## Adding a new module (step by step)

Fictional example: **Suppliers** module.

1. **Domain:**
   - `Supplier` (freezed entity) in `lib/domain/entities/`;
   - `ISupplierRepository` in `lib/domain/repositories/`;
   - `GetSuppliersUseCase`, `AddSupplierUseCase` in `lib/domain/usecases/`;
2. **Data:**
   - `SupplierLocalDataSource` (contract) + `SupplierLocalDataSourceImpl` (in-memory) + `SupplierSqliteDataSourceImpl`;
   - `SupplierRepositoryImpl`;
   - `suppliers` table in `AppDatabase.createSchema` (+ migration if there's an old database);
3. **DI:** register the datasource (in both ServiceLocator branches), repository and use cases;
4. **Presentation:** `suppliers_providers.dart`, screen, registration sheet;
5. **Tests:** use case, SQLite datasource, screen;
6. `dart run build_runner build --delete-conflicting-outputs` and `flutter test`.

---

## Useful commands

| Command | Purpose |
| ------- | ------- |
| `flutter pub get` | Install dependencies |
| `dart run build_runner build --delete-conflicting-outputs` | Generate Freezed/JSON code |
| `flutter analyze` | Static analysis (lints) |
| `flutter test` | Run all tests |
| `flutter test test/<file>` | Run one test file |
| `flutter run -d chrome` | Run on web |
| `flutter run --dart-define=...` | Run with custom configuration |

---

## Related documents

- [Architecture](02-architecture.md) — structural rules.
- [Data layer](04-data.md) — schema and persistence conventions.
- [Multi-tenancy and Super Admin](11-multitenancy.md) — plans, tenant approval and roles.
- [Testing](09-testing.md) — how to test each layer.
