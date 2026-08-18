# 03 — Domain

The `lib/domain/` layer is the **core** of the system: pure business rules, with no dependencies on Flutter, Dio, SQLite or Riverpod. It contains:

- **Entities** — immutable objects (`Freezed`);
- **Repository contracts** — abstract interfaces;
- **Use cases** — business rule orchestration;
- **Domain exceptions** — business errors thrown by use cases.

---

## Entities

All entities are `@freezed` classes (immutable, with `copyWith`, `==`/`hashCode` and JSON serialization via `fromJson`/`toJson` — see `build.yaml` with `explicit_to_json: true`).

> **Phase 2 of multi-tenancy:** the business entities (`Product`, `Sale`, `FinancialTransaction`, `Debt`, `Customer`, `Purchase`) carry **`storeId`** — the store they belong to (default `'st1'`). Repository `getAll` calls require `storeId`, so every read/write is scoped by the active store. See [Multi-tenancy](11-multitenancy.md#store-scoping-phase-2--implemented).

### `Product`

| Field | Type | Notes |
| ----- | ---- | ----- |
| `id` | `String` | Primary key (generated with `AppIds.newId('p')` — timestamp + entropy, collision-free) |
| `storeId` | `String` | The store it belongs to (default `'st1'` — Phase 2) |
| `name` | `String` | Required |
| `description` | `String` | Default `''` |
| `purchasePrice` | `int` | Purchase price in **cents** (W4) |
| `salePrice` | `int` | Sale price in **cents** (W4) |
| `stockQuantity` | `int` | Default `0` — in **milli-units** (W11: 1000 = 1 unit/kg) |
| `code` | `String?` | Scale-label barcode/PLU (W11, optional, 5 digits) |
| `vendaPorFracao` | `bool` | Default `false` — sold by weight (fractions allowed) |
| `unitLabel` | `String` | Default `'un'` — sale unit (`kg`/`un`) |

**Associated business rule:** `salePrice >= purchasePrice` — validated in `AddProductUseCase`.

### `StockLot` (W11 — FIFO lots)

| Field | Type | Notes |
| ----- | ---- | ----- |
| `id` | `String` | `AppIds.newId('lot')` (collision-free) |
| `storeId` | `String` | The lot's store (default `'st1'` — Phase 2) |
| `productId` | `String` | Product the lot belongs to |
| `entryDate` | `DateTime` | Stock-in date |
| `expiryDate` | `DateTime?` | Expiry (optional — `null` = FIFO by entry date) |
| `initialQuantity` | `int` | Original quantity in **milli-units** (W11) |
| `currentQuantity` | `int` | Remaining quantity in **milli-units** (W11) |
| `costPriceCents` | `int` | Acquisition cost per unit, in **cents** |

> **Invariant:** `products.stock_quantity` is always the sum of the active lots' `currentQuantity` — guaranteed since the W11 migration (an initial `lot-mig-…` lot is created for every product with stock).

### `Sale` + `SaleItem`

```dart
enum PaymentMethod {
 cash('Dinheiro'), debitCard('Cartão de débito'),
 creditCard('Cartão de crédito'), mPesa('M-Pesa'), eMola('E-Mola'),
 transfer('Transferência');
}
```

| `Sale` | Type | Notes |
| ------ | ---- | ----- |
| `id` | `String` | `AppIds.newId('s')` (collision-free) |
| `storeId` | `String` | The sale's store (default `'st1'` — Phase 2) |
| `items` | `List<SaleItem>` | Snapshot of the sold items |
| `totalAmount` | `int` | Sum of items at the time of sale, in **cents** (W4) |
| `paymentMethod` | `PaymentMethod` | Payment method |
| `dateTime` | `DateTime` | Time of sale |

| `SaleItem` | Type | Notes |
| ---------- | ---- | ----- |
| `productId` | `String` | Traceability only |
| `productName` | `String` | **Snapshot** of the name at the time of sale |
| `quantity` | `int` | Quantity |
| `unitPrice` | `int` | **Snapshot** of the price at the time of sale, in **cents** (W4) |

> **Why snapshots?** Future price/name changes in the catalog cannot corrupt history: reports and audits use the value charged **at the time**, not the current one. See [Business flows](08-business-flows.md).

### `Debt` ("fiado"/credit)

| Field | Type | Notes |
| ----- | ---- | ----- |
| `id` | `String` | `AppIds.newId('d')` (collision-free) |
| `storeId` | `String` | The debt's store (default `'st1'` — Phase 2) |
| `personName` | `String` | Customer (or supplier) name |
| `amount` | `int` | `@Assert('amount >= 0')` — in **cents** (W4) |
| `dueDate` | `DateTime` | Due date |
| `isCustomerDebt` | `bool` | `true` = receivable (customer); `false` = payable (supplier) |
| `isPaid` | `bool` | Default `false` — settled or not |
| `paidAt` | `DateTime?` | Settlement date (feeds the settlement history) |

### `FinancialTransaction`

```dart
enum TransactionType { income('Entrada'), expense('Saída') }
enum TransactionStatus { paid('Pago'), pending('Pendente') }
```

| Field | Type | Notes |
| ----- | ---- | ----- |
| `id` | `String` | `AppIds.newId('t')` (collision-free) |
| `storeId` | `String` | The movement's store (default `'st1'` — Phase 2) |
| `description` | `String` | E.g.: "Venda M-Pesa", "Aluguel da loja" |
| `amount` | `int` | **Always a positive magnitude** (in **cents**, W4); direction comes from `type` |
| `type` | `TransactionType` | Income or expense |
| `category` | `String` | E.g.: "Vendas", "Contas", "Compras", "Fiado" |
| `date` | `DateTime` | Movement date (receipt date in the case of a settlement) |
| `status` | `TransactionStatus` | Default `paid`; `pending` = "credit"/pending entry |
| `debtId` | `String?` | Link to the `Debt` that originated the pending entry |

> **Separate entity from `Sale`?** Yes, deliberately: not every income comes from a sale (capital contributions, interest) and not every expense is merchandise (rent, electricity, salaries). `Sale` = operational event (items/stock); `FinancialTransaction` = money movement (direction/category). See [Business flows](08-business-flows.md).

### `AppUser` (authenticated user)

| Field | Type | Notes |
| ----- | ---- | ----- |
| `id` | `String` | Supabase UID (or placeholder before email confirmation) |
| `email` | `String` | |
| `fullName` | `String` | Default `''` — comes from `user_metadata.full_name` |

> Abstracts the Supabase/gotrue `User`: the domain and UI never depend on the authentication provider.

---

## Repository contracts (interfaces)

They live in `lib/domain/repositories/`. They declare **what** the system needs, never **how**.

| Contract | Methods |
| -------- | ------- |
| `IProductRepository` | `getAll(storeId)`, `getById(id)`, `add(product)`, `updateStock(id, newQuantity)` |
| `ISaleRepository` | `registerSale(sale)`, `getAll(storeId)` |
| `IDebtRepository` | `getAll(storeId)`, `add(debt)`, `markAsPaid(id)` |
| `IFinancialTransactionRepository` | `getByPeriod(storeId, start, end)`, `getAll(storeId)`, `add(transaction)`, `markAsPaid(id)` |
| `ICustomerRepository` | `getAll(storeId)`, `add(customer)` |
| `IPurchaseRepository` | `getAll(storeId)`, `add(purchase)` |
| `IStockLotRepository` | `getByStore(storeId)`, `getByProduct(storeId, productId)`, `add(lot)`, `updateQuantity(lotId, storeId, newQuantity)` |
| `IAuthRepository` | `signUp(...)`, `signIn(...)`, `signOut()`, `authStateChanges` (Stream) |
| `IUnitOfWork` | `run<T>(action)` — runs an action in an atomic transaction |

> The read methods (`getAll`/`getByPeriod`) take a required **`storeId`**: the business modules are scoped by the active store (Phase 2).

Rules documented in the contracts:
- `IDebtRepository.markAsPaid` — **must not be called directly from the UI**; the settlement goes through `SettleDebtUseCase` (which also records the cash income).
- `IFinancialTransactionRepository.markAsPaid` — the **date becomes the receipt date** (cash realization happens when the money comes in).
- `IProductRepository.updateStock` — receives an **absolute value**; non-negativity validation is the domain's responsibility (use cases).

---

## Use case catalog

### Products

| Use case | Behavior |
| -------- | -------- |
| `GetProductsUseCase` | `getAll(storeId)` of the repository. |
| `AddProductUseCase` | Validates `salePrice >= purchasePrice`; throws `InvalidPriceException` (nothing is persisted) before `add`. |
| `UpdateProductStockUseCase` | **The only entry point for mutating stock.** `ensureSufficientStock(productId, qty)` (pre-validation without mutation) and `decrease(productId, qty)` (revalidates and persists the **absolute value** `stock − qty`). Throws `ProductNotFoundException` / `InsufficientStockException`. |

### Stock (FIFO, W11)

| Use case | Behavior |
| -------- | -------- |
| `FifoStockUseCase` | **FIFO decrease:** pre-validates the sum of active lots **before** any mutation (`InsufficientStockException`), then consumes lots ordered by `expiry ASC → entryDate ASC → id` (nearest expiry first; the surplus passes to the next lot). `increase` creates a new lot (stock-in) **after** validating the product exists — no orphan lots. |
| `GetStockLotsUseCase` | `getByStore(storeId)` / `getByProduct(...)` of the repository — feeds the expiry alerts. |

### Sales

| Use case | Behavior |
| -------- | -------- |
| `ProcessSaleUseCase` | Complete atomic flow (see [Business flows](08-business-flows.md#sale-processing)): validates the sale → pre-validates stock → records the sale → deducts stock → cash income, all inside `IUnitOfWork`. Throws `InvalidSaleException`, `InsufficientStockException`, `ProductNotFoundException`. |

### Finance

| Use case | Behavior |
| -------- | -------- |
| `AddFinancialTransactionUseCase` | Validates `amount > 0` (`InvalidAmountException`); then `add`. |
| `GetCashFlowUseCase` | Returns `CashFlow(income, expense, balance)` for `[start, end]`, considering **only `paid` transactions** (realized cash). Throws `InvalidPeriodException` if `start > end`. |
| `MarkTransactionAsPaidUseCase` | Marks a pending transaction as paid (the "Receive" button). |

### Credit ("fiado")

| Use case | Behavior |
| -------- | -------- |
| `GetPendingDebtsUseCase` | Filters `isCustomerDebt == true && !isPaid` (customer receivables). |
| `GetSettledDebtsUseCase` | Filters `isCustomerDebt == true && isPaid` (settlement history). |
| `AddDebtUseCase` | Validates `amount > 0` (`InvalidDebtAmountException`); records the debt **and** creates the **linked financial pending entry** (`debtId`): pending income for customers, pending expense for suppliers. If the pending entry fails after the debt, throws `PendingEntryRegistrationException` (the UI does **not** suggest retrying — it would duplicate the credit). |
| `SettleDebtUseCase` | Settles the debt (marks `isPaid` + `paidAt`) and records the **cash income** ("Fiado" category). If a linked pending entry exists, marks the **same** transaction as paid (no duplicate). **Idempotent** — an already settled debt does not generate a second income. Throws `DebtNotFoundException`. Deliberate order: settlement before income (never charge the customer twice). |

### Authentication

| Use case | Behavior |
| -------- | -------- |
| `SignUpUseCase` | Creates an account (email/password/name). |
| `SignInUseCase` | Authenticates with email/password. |
| `SignOutUseCase` | Ends the session. |

---

## Domain exceptions (catalog)

| Exception | Thrown by | When |
| --------- | --------- | ---- |
| `InvalidPriceException` | `AddProductUseCase` | Sale price < purchase price |
| `InvalidSaleException` | `ProcessSaleUseCase` | Sale without items or divergent total |
| `ProductNotFoundException` | `UpdateProductStockUseCase` | Product does not exist |
| `InsufficientStockException` | `UpdateProductStockUseCase` | Insufficient stock (with `available`/`requested`) |
| `InvalidAmountException` | `AddFinancialTransactionUseCase` | Amount ≤ 0 |
| `InvalidPeriodException` | `GetCashFlowUseCase` | Inverted period |
| `InvalidDebtAmountException` | `AddDebtUseCase` | Amount ≤ 0 |
| `PendingEntryRegistrationException` | `AddDebtUseCase` | Credit recorded, pending entry failed |
| `DebtNotFoundException` | `SettleDebtUseCase` | Debt does not exist |
| `InsufficientStockException` | `FifoStockUseCase.decrease` | Sum of active lots < requested quantity (pre-validation, no partial decrease) |

The screens catch these exceptions and show friendly messages; no infrastructure exception reaches the UI.

---

## Related documents

- [Architecture](02-architecture.md) — where the domain fits.
- [Business flows](08-business-flows.md) — how the use cases combine into real flows.
- [Testing](09-testing.md) — use cases tested with contract fakes.
