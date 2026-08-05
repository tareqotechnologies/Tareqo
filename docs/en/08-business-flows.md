# 08 — Business Flows

This document explains how the use cases combine into the real flows of the system: **sale**, **credit ("fiado")**, **cash flow** and **stock** — and the business decisions behind each one.

---

## 1. Sale processing (atomic flow)

The `ProcessSaleUseCase` integrates **Sales + Stock + Finance** with a deliberate operation order, all inside an **`IUnitOfWork`** (a single transaction — either everything is written, or nothing):

```text
1. Sale validation
   ├─ rejects a sale without items
   └─ rejects a total that diverges from Σ(quantity × unit price)
      └─ comparison in CENTS ((x * 100).round()) — avoids false
         positives from double precision (e.g.: 2 × 9.9 + 9.9)

2. Stock pre-validation (NO mutation)
   └─ for each item: UpdateProductStockUseCase.ensureSufficientStock
      └─ if missing → InsufficientStockException → rollback, nothing written

3. Sale recording (ISaleRepository.registerSale)
   └─ SQLite: sales + sale_items tables in the same transaction

4. Stock deduction (per item)
   └─ UpdateProductStockUseCase.decrease — revalidates internally
      (defense against direct calls) and persists the ABSOLUTE VALUE
      (stock − quantity) via IProductRepository.updateStock

5. Cash income
   └─ FinancialTransaction(income, category "Vendas", status paid)
```

### Guarantees

| Guarantee | How |
| --------- | --- |
| **Atomicity** | `IUnitOfWork` → `BEGIN IMMEDIATE` / `COMMIT` / `ROLLBACK` (SQLite); no-op in-memory (web) |
| **Stock never negative** | `UpdateProductStockUseCase` is the only mutation port; revalidates first; repository receives an absolute value; `CHECK (stock_quantity >= 0)` as the last line of defense |
| **No "orphan" sale** | Stock pre-validation happens before any write |
| **No TOCTOU window** | `BEGIN IMMEDIATE` acquires the write lock **before** pre-validation; FIFO queue serializes concurrent transactions in the same process |
| **No invalid nested transaction** | `AppDatabase` keeps a re-entrant depth counter (nested calls join the outer one) |

### Price snapshots

Each `SaleItem` keeps `productName` and `unitPrice` **at the time of sale** (plus `productId` for traceability). This preserves:

- historical price (future reports show the amount charged at the time);
- fiscal/accounting integrity (the total never changes retroactively);
- the real transaction context even after renaming/discontinuing products.

---

## 2. The "credit" cycle ("fiado")

### Registration (`AddDebtUseCase`)

1. Validates `amount > 0` (`InvalidDebtAmountException`);
2. Records the **debt** (`IDebtRepository.add`) — the source of truth for receivables/payables;
3. Creates the **linked financial pending entry** (`debtId`):
   - customer (`isCustomerDebt: true`) → **pending income** (receivable);
   - supplier (`isCustomerDebt: false`) → **pending expense** (payable).

> If the pending entry fails **after** the debt, it throws `PendingEntryRegistrationException` — the UI informs that the credit was recorded and asks to check Finance (never "try again", which would duplicate the credit).

### Settlement (`SettleDebtUseCase`)

```text
1. Find the debt (otherwise → DebtNotFoundException)
2. Idempotence: if already settled, return (never duplicates cash income)
3. Mark the debt as paid (isPaid = true, paidAt = now)
4. Cash income:
   ├─ linked pending entry exists (debtId)?
   │    ├─ pending → mark the SAME transaction as paid
   │    └─ already paid → nothing (idempotent)
   └─ doesn't exist → record a new income (category "Fiado")
```

**Deliberate order:** the settlement happens **before** the income. If something fails in the middle, the worst case is a settled debt without a cash movement (understated books) — never the reverse, which would allow **charging the customer twice**.

### Visualization

- `GetPendingDebtsUseCase` → customer receivables not yet settled ("Pending" tab);
- `GetSettledDebtsUseCase` → customer receivables already settled ("Settled" tab, history with `paidAt`).

### Impact on working capital

Receivables are **tied-up capital** (the merchandise left, but the money hasn't come back). The structure enables: knowing how much is sitting with customers, planning purchases without depending on credit, prioritizing collections by due date, and calculating the financial cycle.

---

## 3. Cash flow (realized cash)

`GetCashFlowUseCase` computes `CashFlow(income, expense, balance)` for a period `[start, end]`, considering **only `paid` transactions**:

```text
balance = Σ(paid income) − Σ(paid expenses)
```

- A credit sale (pending income) **only counts when received**;
- Pending payables also don't leave the cash;
- When a pending entry is received (`MarkTransactionAsPaidUseCase` / credit settlement), the **date becomes the receipt date** — cash realization happens when the money comes in.

### Why is `FinancialTransaction` separate from `Sale`?

| | `Sale` | `FinancialTransaction` |
| - | ------ | ---------------------- |
| Nature | **Operational** event (items, stock, payment) | **Money** movement (direction, category, amount) |
| Examples | sale with items | sale, rent, electricity, salaries, taxes, contributions, credit |
| Role | operational reports (margin, average ticket) | cash flow, pending entries, reconciliation |

Separating them avoids empty fields and incoherent rules (expenses have no item/stock) and gives each model a single responsibility.

---

## 4. Stock control

- **`UpdateProductStockUseCase`** is the **only entry point** for mutating stock:
  - `ensureSufficientStock(productId, quantity)` — pre-validation without mutation;
  - `decrease(productId, quantity)` — revalidates and persists the **absolute value**;
- **`IProductRepository.updateStock`** receives an **absolute value** (not a delta) — two layers of protection;
- **`CHECK (stock_quantity >= 0)`** in SQLite is the last line of defense;
- The UI blocks adding to the cart beyond stock (`soldOut`) and flags low stock (`< 5` units) on the dashboard and the listing.

---

## Related documents

- [Domain](03-domain.md) — use cases and exceptions in detail.
- [Data layer](04-data.md) — Unit of Work, schema and re-entrant transactions.
- [Presentation](05-presentation.md) — how the screens consume these flows.
