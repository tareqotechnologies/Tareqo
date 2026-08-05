# Architecture Decisions — Dumbhanengue ERP

> This document records the **"why"** behind the main technical decisions of Dumbhanengue ERP: every architecture, modeling and security choice is justified here. For the overview and the full catalog, see documents [01-overview](01-overview.md) through [11-multitenancy](11-multitenancy.md).

---

## Why Clean Architecture?

We adopted Clean Architecture for Dumbhanengue because an ERP is, by nature, a long-lived system with complex, constantly evolving business rules: modules such as inventory, sales, purchases, finance and reports need to be developed, tested and replaced independently, without changes in one module causing side effects in others.

By splitting the code into three layers — **domain** (entities, repository contracts and use cases, free from any framework dependency), **data** (concrete implementations of remote and local data sources, such as Supabase and SQLite) and **presentation** (screens, widgets and state via Riverpod) — the architecture keeps the business rules at the center of the system, independent of infrastructure details. This brings four direct gains:

1. **Testability** — use cases can be tested with mocks, without a server or database;
2. **Replaceability** — the data source can migrate from a REST API to a local database without touching the domain;
3. **Maintainability** — each developer works on isolated modules with clear contracts between layers;
4. **Team scalability** — domain interfaces act as "contracts" that enable parallel work.

### How each folder is used

```
lib/
├── main.dart                    # Bootstrap: ProviderScope (Riverpod) + GetIt
├── app.dart                     # Root widget (MaterialApp, theme, tenant locale/currency)
│
├── core/                        # Cross-cutting concerns (belong to no layer)
│   ├── config/                  # Configuration (Supabase, tenant preferences)
│   ├── database/                # SQLite opening, schema and transactions (Unit of Work)
│   ├── di/                      # Service Locator (GetIt) — central dependency registry
│   ├── i18n/                    # Translation keys and localization helpers
│   ├── security/                # Secure storage (Keychain/Keystore)
│   ├── theme/                   # Material 3 app theme
│   └── utils/                   # Generic helpers (currency/date formatting, ids...)
│
├── domain/                      # CORE: pure business rules, no external dependencies
│   ├── entities/                # Immutable entities (Product, Sale, Tenant...) via Freezed
│   ├── repositories/            # Abstract persistence contracts (e.g. IProductRepository)
│   └── usecases/                # Use cases — orchestrate the business rules
│
├── data/                        # Concrete implementations of what the domain defines
│   ├── datasources/
│   │   ├── remote/              # Remote data sources (Supabase/REST)
│   │   └── local/               # Local data sources (SQLite, in-memory)
│   ├── models/                  # Serializable DTOs — only when the API format diverges from the domain
│   ├── repositories/            # Implementations of the domain interfaces
│   └── services/                # Integration services (employee accounts, atomic processors)
│
└── presentation/                # Everything the user sees and interacts with
    ├── controllers/             # State: Riverpod providers/notifiers
    ├── screens/                 # Screens per module (auth, dashboard, products, sales, finance...)
    └── widgets/                 # Shared widgets (KpiCard, EmptyState, StatusChip, AppSheet...)
```

> **Dependency Rule:** the dependency flow always points inward. `presentation → domain` (via contracts), `data → domain` (implements contracts), and `domain` knows nothing about the other layers.

## Why contracts (abstract interfaces) in the domain?

In the domain, `IProductRepository` is declared as an **abstract interface** — only the method signatures (`getAll`, `add`) — **not** as a concrete class. Because:

1. **Dependency Inversion (DIP):** the domain cannot know infrastructure details. The concrete class (e.g. `ProductRepositoryImpl`, using SQLite or Supabase) lives in the `data` layer and *implements* the contract. Business rules depend on an abstraction, never on an implementation.
2. **Decoupling and replaceability:** the data source can switch from a REST API to a local database (or vice versa) without changing a single line of the domain or the UI — just create another class implementing the same contract.
3. **Testability:** in use-case tests we inject a *mock/fake* of `IProductRepository` (no server, no database), isolating the business logic and keeping tests fast and deterministic.
4. **Integration contract:** the interface works as an agreement between layers/teams — `data` knows exactly what to implement, `presentation` knows exactly what to consume, enabling parallel work.

Unlike inheritance (where a concrete class "is a" contract), the interface declares only **what** the system needs, leaving the **how** to the data layer.

## Why does price validation live in the Use Case (not the UI)?

`AddProductUseCase` validates that `salePrice >= purchasePrice` before persisting. This rule was deliberately placed in the use case — **not** on the registration screen:

1. **Business rules belong to the domain.** The UI is only presentation. If the validation lived on the screen, every client (mobile, web, desktop) would need to reimplement it — and any rule change would require changing every screen.
2. **Centralization and consistency.** Every entry point (form, import, future API) goes through the same use case. It prevents an invalid product from entering the system through a route that didn't validate.
3. **Data integrity.** Validation happens as close to the data as possible, ensuring the system state never contains a product whose sale price is lower than its purchase price — regardless of where the data came from.
4. **Testability.** The rule is tested in isolation with unit tests (use case + repository fake), without UI or widgets — fast and deterministic.
5. **Cross-platform reuse.** The same use case serves the Flutter UI, migration scripts and a future REST API.

In practice, the UI stays **thin**: it only catches the exception thrown by the use case and shows the message to the user.

## Why start with an in-memory list and then migrate to SQLite?

`ProductRepositoryImpl` started with an in-memory datasource — a deliberate choice:

1. **Business rules first.** Without database setup, migrations or drivers, we validated the architecture and domain logic before investing in infrastructure.
2. **Fast end-to-end iteration.** UI → use case → repository → datasource worked from day one, demonstrating the full ERP flow.
3. **No premature commitment.** We only decide between SQLite, Hive, drift or an API when we know the real requirements (queries, concurrency, sync) — avoiding premature commitment to a technology.
4. **Deterministic tests.** In-memory data keeps tests fast, predictable and environment-independent.

The SQLite migration was completed following **Dependency Inversion**: `*SqliteDataSourceImpl` implementations were created for **the same contracts** (parameterized SQL with `package:sqlite3`), and the `ServiceLocator` swapped the registrations — **no changes in domain, use cases, repositories or UI**.

```dart
// lib/core/di/service_locator.dart — active persistence
final database = await AppDatabase.openAppDatabase();
if (database != null) {
  _registerSqlitePersistence(database);   // SQLite (native platforms)
} else {
  _registerInMemoryPersistence();         // fallback: web / native lib failure
}
```

Implementation details:

- **`lib/core/database/app_database.dart`** — opens `dumbhanengue.db` in `getApplicationDocumentsDirectory()`, creates the schema (`CREATE TABLE IF NOT EXISTS` with non-negativity `CHECK`s as a final safeguard), seeds demo data on first run and exposes `runInTransaction` (BEGIN/COMMIT/ROLLBACK) for atomic writes (e.g. sale + items).
- **Sales** are persisted in normalized tables (`sales` + `sale_items`) in a **single transaction**.
- **Enums** are persisted by name; **dates** as epoch millis; **booleans** as 0/1.
- **Web**: the native sqlite3 does not run in the browser (`dart:ffi` does not exist there), so `AppDatabase` uses a **conditional import** and the app falls back to the in-memory datasources (same contracts — the UI stays identical).
- **Tests**: on the Windows VM, `package:sqlite3` itself falls back to the system `winsqlite3.dll`, so tests run without manual setup.

## Why Riverpod for state management?

The presentation layer uses **Riverpod** (`Notifier`/`FutureProvider`/`StreamProvider`) to manage state:

1. **Declarative reactivity.** The screen declares what to watch (`ref.watch(productsProvider)`) and Riverpod rebuilds only the affected widgets — no manual `setState`, `InheritedWidget` or hand-rolled streams.
2. **Built-in AsyncValue.** Async providers expose state as `AsyncValue` (`loading` / `error` / `data`), making loading/error/retry handling declarative and consistent across screens.
3. **Typed provider composition.** Providers can depend on other providers, forming a typed graph with controlled scope via `ProviderScope` and *auto-dispose* when desired.
4. **Testability.** In tests, just override the providers (`overrideWithValue`/`overrideWith`) — without touching GetIt or datasources.

### How Riverpod talks to the domain without violating the dependency rule

The dependency flow always points **inward**:

```
ProductListScreen (widget)
      ↓ ref.watch
productsProvider (provider)
      ↓ ref.read
getProductsUseCaseProvider → GetProductsUseCase (domain)
      ↓
IProductRepository (domain contract)
      ↓ (implementation injected via GetIt at bootstrap)
ProductRepositoryImpl → ProductLocalDataSource (data layer)
```

The `presentation` knows **only domain abstractions** — entity, use case and contract — never datasources, SQLite or concrete implementations. GetIt only delivers instances; the provider graph decides the dependencies. That is why swapping persistence or the repository implementation **does not change a single line of the presentation**.

## Why does a sale store the price at sale time (snapshot)?

Each `SaleItem` stores `productName` and `unitPrice` **at the sale date**, in addition to `productId`. Referencing only the product would not be enough:

1. **Historical price variation.** Product prices change (promotions, adjustments, inflation). If the sale referenced only the product, a future report would show the **current** price, not the one charged at the time — distorting revenue, margins and taxes.
2. **Fiscal and accounting integrity.** A sale is a legal record: the total charged cannot change retroactively because of a change in the price table. Storing `totalAmount` + the frozen items guarantees this.
3. **Reports and audit.** Historical analysis ("how many pens did I sell in March?", "what was the margin in that period?") requires the price in effect on the sale date.
4. **Catalog evolution.** Products are renamed, discontinued or have their id reused. The snapshot (name + price) preserves the real transaction context.
5. **Industry standard.** It is the classic ERP/POS behavior: *line items* are the "photograph" of the item at the instant of sale, with a reference (`productId`) only for traceability.

**Conclusion:** we keep `productId` for traceability, but the displayed and summed values (`unitPrice`, `totalAmount`) are the ones from the sale moment — history is never corrupted by future catalog changes.

## How to guarantee stock never goes negative (ProcessSaleUseCase)

`ProcessSaleUseCase` integrates Sales, Stock and Finance with a **deliberate operation order** to guarantee integrity:

1. **Sale validation** — rejects a sale without items and a total diverging from `Σ(quantity × unit price)`, **persisting nothing**;
2. **Stock pre-validation** — before any mutation, checks that **all** sale items have sufficient stock. If any is missing, it throws **without persisting anything** — there is never an "orphan" sale;
3. **Sale registration** — `ISaleRepository.registerSale`;
4. **Stock decrement** — for each item, a decrease that **re-validates stock internally** (defense against direct calls) before persisting the absolute value;
5. **Cash inflow** — registers the `FinancialTransaction` (category "Sales", `paid`).

Everything runs inside a **`IUnitOfWork`** (unit of work): sale + items, stock decrement and cash inflow are written in a **single SQLite transaction** — either everything is persisted, or nothing. `BEGIN IMMEDIATE` acquires the write lock **before** stock pre-validation, closing the concurrency window (TOCTOU). In memory (web) the unit of work is a no-op.

`UpdateProductStockUseCase` is the **only entry point** to mutate stock, and the repository receives an **absolute value** (not a delta) — two layers of protection: the use case never computes a negative stock and the repository only persists. The `CHECK (stock_quantity >= 0)` in the schema remains the final safeguard.

### How the layers communicate without coupling

`ProcessSaleUseCase` depends **only on abstractions**: the `ISaleRepository` contract and `UpdateProductStockUseCase` (which depends on the `IProductRepository` contract). None of them know about datasources or SQLite. Composition happens in the **wiring** (ServiceLocator/GetIt), never inside business rules.

## Why a financial entity separate from the sale?

`FinancialTransaction` (cash in/out) is a **financial** concept; `Sale` is an **operational** event. Separating them is deliberate:

1. **Not every inflow comes from a sale, nor every outflow is merchandise.** Loans, capital injections, interest and refunds are inflows; rent, utilities, salaries, taxes and maintenance are outflows that have **no item, stock or product attached**. Mixing them into `Sale` would force empty fields and incoherent rules.
2. **Fixed expenses have their own nature.** They are periodic, recurring and categorizable. A dedicated entity (`description`, `category`, `date`) lets you answer *"how much did I spend on electricity this year?"* without contaminating the sales model.
3. **Real cash flow.** The correct balance = **inflows (sales + others) − outflows (fixed + variable)**. With a single financial entity, `GetCashFlowUseCase` aggregates everything over a period — `Sale` keeps serving operational reports.
4. **Single responsibility.** `Sale` = operation (items, stock, payment); `FinancialTransaction` = money (direction, category, value). Each evolves with its own requirements without breaking the other.
5. **Audit and traceability.** Every movement has its own identity, category and date, making reconciliation and category reports easy.

**Summary:** the sale records *what happened* (items and stock); the financial transaction records *the money that came in or went out*. Two models, two responsibilities, one accurate cash flow.

## Credit control ("fiado") and working capital

Credit control answers the small merchant's most important question: **who owes me, how much and when does it mature?**

### Structure

- **`Debt` (credit/IOU)** — a payment promise record with `personName`, `amount`, `dueDate` and `isCustomerDebt`:
  - `isCustomerDebt: true` → **receivable** (the customer owes the merchant);
  - `isCustomerDebt: false` → **payable** (the merchant owes the supplier).
- **`GetPendingDebtsUseCase`** — filters and lists only what is **receivable from customers**, answering *"how much do I have to receive and from whom"* immediately.
- **`FinancialTransaction.status`** (`paid`/`pending`) — separates money **already in the cash** from mere **expected inflow**. When registering credit, `AddDebtUseCase` creates the linked pending transaction right away (`debtId`): a pending inflow for receivables and a pending outflow for payables. Pending transactions can also be created on the Finance screen ("Pendente (fiado)" toggle); when received, they are marked `paid` via the **"Receber"** (Receive) button (or by settling the credit) — realized cash counts the inflow on the **receipt date**.
- **`Debt.isPaid`** — settlement state: when the customer pays, `SettleDebtUseCase` marks the debt `isPaid: true`. If the debt has a **linked pending transaction**, the settlement marks the **same** transaction as paid; otherwise it registers the cash inflow. There is never a duplicate.

### Impact on working capital

Receivables are **tied-up capital**: the merchandise has left (and was paid to the supplier), but the money has not returned. With this structure, the merchant can:

1. **Know exactly how much is "idle" in customers' hands** — the sum of receivables — and compare it with what is in cash, avoiding an overestimated cash flow;
2. **Plan purchases without depending on credit** — if working capital is tied up, the merchant can delay purchases or negotiate terms with suppliers;
3. **Prioritize collections** — `dueDate` makes it possible to list what matures first and identify defaulters;
4. **Calculate the financial cycle** — the interval between buying (payable), selling (on credit) and receiving (receivable) defines how much working capital is needed to operate without interruptions.

## Why is authentication the first step of the SaaS model?

1. **Multi-tenant from day one.** Every merchant is a *tenant*: without login there is no way to separate each customer's data in the same database. Authentication provides the identity that isolates the data.
2. **Security enforced in the database (RLS).** Supabase uses the user's JWT in Postgres *Row Level Security*: the isolation rule (`auth.uid() = user_id`) is enforced by the database, not just the UI — even if a UI bug leaks data, the database filters it.
3. **Revenue model.** SaaS charges per subscription/plan; authentication identifies who pays, which plan and which limits apply.
4. **Onboarding and retention.** Sign up → login → personal data; a persistent session improves the experience and reduces daily friction.

### How the session stays active (session persistence)

1. **Secure storage.** `supabase_flutter` persists the session automatically: `flutter_secure_storage` (Android/iOS) and `localStorage` (web) — no extra code.
2. **Restore on boot.** On app open, the auth stream re-emits the saved session. The `AuthGate` reacts: restored session → straight to the dashboard, no new login.
3. **Automatic JWT renewal.** GoTrue renews the access token with the refresh token before it expires.
4. **Reactivity.** Login/logout emit events on the same stream; navigation and any session-dependent state react automatically.

The development project credentials are already embedded in `SupabaseConfig` (the anon key is public by design in Supabase — real security comes from RLS; **never** put the service role key in the client). To point at another project (e.g. production):

```bash
flutter run --dart-define=SUPABASE_URL=https://your-project.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJ...
```

### Tenant currency and language (presentation)

The owner chooses the **currency** (BRL, USD, EUR, MZN) and **language** (pt, en) during onboarding and can change them in **Stores → Settings**. Preferences live in the `tenants` table (`currency_code`, `language`) and propagate to the whole app: the `MaterialApp` locale and currency formatting (`Formatters`) follow the `tenantSettingsProvider` — employees inherit the owner's choice.

## Secure storage: why not use `shared_preferences` for sensitive data?

`SecureStorageService` encapsulates the **encrypted** persistence of access tokens, refresh tokens and API keys. `shared_preferences` is never used for this kind of data.

### Technical difference between regular and secure storage

| Aspect | `shared_preferences` (regular) | `flutter_secure_storage` (secure) |
| ------ | ------------------------------ | --------------------------------- |
| **Physical location** | Plain-text preferences file (XML/JSON/plist) | **Keychain** (iOS/macOS) and **Android Keystore** |
| **Encryption** | None — the value is readable on disk | Encrypted data; on Android the key (AES-GCM) is generated and kept inside the Keystore, tied to the hardware |
| **Access** | Any process with file read permission | OS-protected: only the authenticated app accesses it; on iOS access may require biometrics |
| **Backup/extraction** | Plain values can be read from backups, root/JB or APK extraction | End-to-end encrypted; on iOS they live in the hardware secure enclave |
| **Ideal use case** | UI preferences (theme, language, filters) — nothing sensitive | Session tokens, refresh tokens, API keys, secrets |

### Why this is vital to protect the merchant's account

1. **The token is the password.** With the session token in hand, an attacker accesses the account as if they were the merchant. Storing that token in plain text turns a backup, a rooted device or an extracted APK into a gateway to the account and its financial data.
2. **Encryption is tied to the device.** On Android the master key lives in the **Android Keystore** (hardware-backed, TEE); on iOS in the **Keychain** with the secure enclave. Even if the data file is copied, without the hardware key the content is useless.
3. **High attack cost.** Stealing a protected token requires compromising the OS/hardware — infeasible at scale.
4. **User-conditional access (iOS).** The Keychain can require Face ID/Touch ID — one more barrier before any leak.

### How the service was designed

- **Abstracted backend** (`SecureStorageBackend`): the real implementation uses Keychain/Keystore via `flutter_secure_storage`; tests use an in-memory backend.
- **Centralized keys** in `SecureStorageKeys`: avoids typos and lets you audit exactly what is treated as sensitive.

### Responsibility boundary (important to avoid session duplication)

The **Supabase session** is already persisted internally by `supabase_flutter` in its own `flutter_secure_storage` instance. So `SecureStorageService` **must not** store those tokens — it exists for **application secrets**: third-party API keys, configuration secrets and credentials needed by the data/presentation layer. Keeping this boundary avoids two places writing the session.

### Platform caveat (technical precision)

- **Android/iOS (mobile):** hardware-backed — Android Keystore (AES-GCM, key in TEE) and Keychain with secure enclave. This is where critical data should live.
- **Windows:** DPAPI (tied to the OS user account) and **Linux:** libsecret. Reasonable protection, no dedicated enclave.
- **Web:** weaker — the web implementation keeps the encryption key in `localStorage` (not hardware-backed). **For critical secrets, prioritize mobile.**

## Initial dependencies

| Package | Role | Layer |
| ------- | ---- | ----- |
| `flutter_riverpod` | Reactive state management | presentation |
| `flutter_localizations` + `intl` | Internationalization (pt/en) and formatting | presentation/core |
| `freezed` + `json_serializable` | Immutable models and JSON serialization (code generation) | domain/data |
| `get_it` | Dependency injection (Service Locator) | core |
| `supabase_flutter` | SaaS authentication, database and realtime | data |
| `flutter_secure_storage` | Encrypted persistence of tokens and keys | core |
| `sqlite3` + `sqlite3_flutter_libs` | Relational local persistence | data |
| `path_provider` | Documents directory path | data/core |

### Code generation (Freezed)

Whenever you create or change a class annotated with `@freezed`, generate the files:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Presentation layer (summary)

The app has adaptive navigation (`AppShell` with `NavigationRail` on wide screens and `NavigationBar` on narrow screens) and functional modules:

1. **Home** — dashboard with KPIs (sales, cash balance by period, receivables, stock), quick actions, recent sales and a low-stock alert;
2. **Products** — search, listing with prices/stock and registration via bottom sheet;
3. **Sales** — history and the **new sale** flow (cart + payment method → stock decrement + cash inflow, atomically);
4. **Finance** — cash flow by period (today/7 days/month/all) with inflows, outflows and balance, transactions and receiving pending items;
5. **Credit ("fiado")** — total receivables, debts by due date, credit registration and **settlement** with a history of settlements;
6. **Stores** — tenant management: stores, employees, plan and **Settings** (owner language + currency);
7. **Purchases** — goods entry with stock update and cash outflow.

The visual is minimalist (Material 3): neutral surfaces, cards with subtle borders, rounded corners and localized currency formatting (`Formatters`).
