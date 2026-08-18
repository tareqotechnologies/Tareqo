# 08 — Business Flows

This document explains how the use cases combine into the real flows of the system: **sale** (including its **cancellation**), **credit ("fiado")**, **cash flow**, **stock** and **daily cash closing (Z-report)** — and the business decisions behind each one.

---

## 1. Sale processing (atomic flow)

> **Two execution paths, one contract.** On **SQLite/in-memory** the flow below runs inside an **`IUnitOfWork`** (single transaction). On **Supabase**, `ProcessSaleUseCase` delegates the whole operation to the **`process_sale` RPC** (`SECURITY DEFINER`) — sale + items + stock lock/decrement + cash entry in **one DB transaction** on the server, with idempotency on the sale id and the same validation (stock, total in cents). The local description below is the business contract; the RPC mirrors it (see `supabase/schema.sql` §1.11). The same applies to purchases (`process_purchase`), debt registration (`register_debt`) and settlement (`settle_debt`).

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

### Sale cancellation (reversal — `cancel_sale`)

`CancelSaleUseCase` **undoes** a recorded sale: it returns the stock to the exact lots, reverses the cash and marks the sale as **cancelled** in the history (it stays visible with a "Cancelled" badge, but leaves reports, KPIs and the day summary). It is a **managerial** operation (owner/manager) — regular employees cannot cancel.

```text
SaleDetailScreen (detail of an ACTIVE sale + owner/manager user)
 │ confirmation (AlertDialog shows the sale amount)
 ▼
CancelSaleUseCase
 │
 ├─ SUPABASE MODE (ISaleCancellationProcessor → cancel_sale RPC, ONE transaction):
 │ ├─ immediate delegation (no client-side validation) — the server
 │ │ validates existence + idempotence: is_manager_of_store guard
 │ │ (employees CANNOT cancel — the server is the authority, even if a
 │ │ tampered client bypasses the UI)
 │ ├─ reads and LOCKS the sale FOR UPDATE (store-scoped); missing or
 │ │ already cancelled → no-op (never throws SaleNotFoundException)
 │ ├─ returns the stock to the EXACT lots consumed (sale_lot_consumption):
 │ │ └─ per lot (FOR UPDATE): current_quantity += returned
 │ │ and the product stock_quantity += returned — the
 │ │ `stock = Σ lots` invariant never breaks
 │ ├─ cash reversal: EXPENSE for the sale amount, category Sales, status
 │ │ paid, description "Sale reversal — <method>" — the pair
 │ │ (original income + reversal) closes the cash at ZERO
 │ └─ marks the sale: status = 'cancelled', cancelled_at = now()
 │
 └─ LOCAL MODE (SQLite/in-memory, inside an IUnitOfWork):
 ├─ validation: getById → else SaleNotFoundException; already
 │ cancelled → return (idempotent no-op)
 ├─ FifoStockUseCase.restoreLot for each LotConsumption
 ├─ markCancelled(saleId, storeId)
 └─ add FinancialTransaction(expense, "Sale reversal — …", category Sales)
 ▼
Cancelled sale → UI: "Cancelled" badge, total struck through, stays in history
 └─ LEAVES reports, KPIs and the day summary (status != 'active' is filtered)
 └─ invalidates salesListProvider, productsProvider, transactionsProvider,
 cashFlowProvider and dashboardKpisProvider (screens reload)
```

### Cancellation business decisions

| Decision | Why |
| -------- | --- |
| **Returns to the EXACT lots** | The lot consumption is recorded on the sale (`sale_lot_consumption`) — the cancellation returns each lot to its original quantity, **preserving expiry and cost** (no lot mixing) |
| **Reversal closes the cash at zero** | The original income (Sales, paid) + the reversal expense (Sales, paid) offset each other — the day's cash is not inflated by a cancelled sale |
| **Cancelled sale stays in history** | Audit trail: the record remains visible with the "Cancelled" badge and the cancellation moment (`cancelledAt`) |
| **Leaves reports/KPIs/day summary** | All aggregations filter `status = 'active'` (client-side and RPCs) — a cancelled sale never counts as revenue |
| **Idempotence** | Cancelling twice is a **no-op** — never creates a duplicate reversal nor returns stock twice (on Supabase, a missing or already-cancelled sale is also a no-op, no exception) |
| **Cancellation is managerial** | Like purchases and cash closing: `is_manager_of_store` on the server; `canCancelSalesProvider` in the app is UX guidance only |
| **Server is the authority on SaaS** | The client sends only `sale_id` + `store_id`; the RPC validates the session, the guard and runs the reversal in ONE transaction |

> **Verification:** `sql_check.sh` (17.x) runs `cancel_sale` as `app_user` and checks: lot/stock restored, `cancelled_at` filled, **second cancellation without duplicates**, the cancelled sale **out** of the KPI/report (delta in cents) and **employees rejected** when cancelling.

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
 │ ├─ pending → mark the SAME transaction as paid AND stamp the
 │ │ realization date (date = now — cash flow recognizes
 │ │ the money when it ENTERS, in both local and SaaS modes)
 │ └─ already paid → nothing (idempotent)
 └─ doesn't exist → record a new income (category "Fiado")
```

> On **Supabase** the whole settlement runs as the **`settle_debt` RPC** — one transaction, idempotent, scoped by store. Since Aug 6 it also stamps `date = now()` on the linked pending entry, matching the local SQLite `markAsPaid` semantics.

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

### 4.1 Product total (historical layer)

- **`UpdateProductStockUseCase`** is the port that mutates the product's **total** `stock_quantity`:
 - `ensureSufficientStock(productId, quantity)` — pre-validation without mutation;
 - `increase`/`decrease` — revalidate and persist the **absolute value**;
- **`IProductRepository.updateStock`** receives an **absolute value** (not a delta) — two layers of protection;
- **`CHECK (stock_quantity >= 0)`** in SQLite is the last line of defense;
- The UI blocks adding to the cart beyond stock (`soldOut`) and flags low stock (`< 5` units) on the dashboard and the listing.

### 4.2 FIFO lots and expiry (W11)

- Every **stock-in creates a `StockLot`** (initial/current quantity in **milli-units**, optional expiry, acquisition cost in cents). Purchases record an optional **expiry per item** (`purchase_items.expiry_date`) — it becomes the lot's expiry;
- The **POS decrease** consumes lots in FIFO order — nearest expiry first; without expiry, by entry date (`FifoStockUseCase` locally, `process_sale` on Supabase). The surplus passes to the next lot, and the sum of lots is **pre-validated before any mutation** (never a partial decrease);
- **Invariant:** `products.stock_quantity = Σ current_quantity of active lots` — verified by `sql_check.sh` (test) and by the read-only query in `sql_check_live.sh` (live);
- **Expiry alerts** on the dashboard: **red** for expired lots with stock, **yellow** for lots expiring in < 30 days (`expiryWarningDays`), sorted by urgency.

### 4.3 Weight-based sales (scales, W11)

- Products with `vendaPorFracao` accept **decimal quantities** in the POS (e.g., 1.75 kg) — quantities are **milli-units** (`1000` = 1 unit/kg), exact integer math in Dart and SQL;
- **Scale-label barcodes `20PPPPPWWWWW`** are intercepted in the POS: `ScaleBarcode` extracts the PLU (5 digits) and the weighed value, deriving the fraction as `value ÷ price` (never overcharges). Only interpreted as a scale code when the product exists and is `vendaPorFracao` — EAN-12 codes starting with `20` fall back to the normal lookup; PLUs are normalized (leading zeros).

---

## 5. Daily cash closing (Z-report)

`CloseCashRegisterUseCase` records the store's **day closing** with the **physical cash count** from the drawer. It is a **managerial** operation (owner/manager) — regular employees cannot close. The flow has two phases: the **preview** (read) and the **confirmation** (write).

> **Server-side preview (H2):** the day summary comes from the `get_cash_closing_summary` RPC (see [Architecture — Server-side aggregations](02-architecture.md)) — the app never lists the sales history to sum on the device. This section covers the **confirmation**.

```text
CashClosingSheet (Financial → Cash closing)
 │ 1. PREVIEW — cashClosingSummaryProvider → get_cash_closing_summary (server-side)
 │ └─ day total (all methods) · expected in the drawer (CASH only)
 │ · breakdown by method (JSONB) · already-registered closing (if any)
 │ 2. The user (owner/manager) types the PHYSICAL COUNT of the drawer
 │ └─ LIVE difference: matches / surplus / shortage (vs. the expected)
 ▼
CloseCashRegisterUseCase
 ├─ validates countedCashCents >= 0 → else InvalidCashCountException
 │
 ├─ SUPABASE MODE (ICashClosingProcessor → close_cash_register RPC, ONE transaction):
 │ ├─ is_manager_of_store guard — employees CANNOT close (the server is the
 │ │ authority, even if a tampered client bypasses the UI)
 │ ├─ validates the session and the non-negative count ON THE SERVER
 │ ├─ computes ON THE SERVER (the client NEVER sends computed values):
 │ │ └─ expected = Σ ACTIVE CASH sales on [p_day, p_day+1)
 │ │ · total = Σ active sales (all methods)
 │ │ · breakdown = jsonb_object_agg by method (Z report)
 │ └─ UPSERT into cash_closings (UNIQUE store_id + closing_date):
 │ re-closing the day UPDATES the physical count, no duplicates
 │ └─ returns the registered closing (JSONB) → UI shows the result
 │
 └─ LOCAL MODE (SQLite/in-memory):
 └─ aggregateCashClosingDay (SAME criteria as the RPC: active only,
 cancelled out) → ICashClosingRepository.save (UPSERT per store + day)
 ▼
Closing persisted → UI shows the result (on SaaS, the displayed values are the
 RPC's RETURN — the server is the authority)
 └─ invalidates cashClosingSummaryProvider + cashClosingHistoryProvider
 (preview and history are re-fetched with the new closing)
```

### Business decisions

| Decision | Why |
| -------- | --- |
| **Expected = cash only** | Card/M-Pesa/E-Mola/transfer **do not pass through the physical drawer** — the expected compares only what should be in cash |
| **Count never negative** | The owner may close with an **empty** drawer, but never with a negative value (typo) — validated on the client **and** the server |
| **Cancelled sales stay out** | The reversal (`cancel_sale`) already adjusted the cash — including cancelled sales would inflate the closing (same criteria as reports and KPIs) |
| **UPSERT per store + day** | Re-closing the day (e.g., a mistyped count) **updates** the count and the snapshots, without creating a duplicate row |
| **Closing is managerial** | Like purchases and reversal: `is_manager_of_store` on the server — the in-app access matrix (`canCloseCashRegisterProvider`) is UX guidance only |
| **Server computes, client only sends the count** | `p_store_id`, `p_day` (start of the local day in UTC) and `p_counted_cash_cents` — no computed total leaves the device |
| **Single preview/confirmation criteria** | `aggregateCashClosingDay` (local) mirrors exactly what the RPC computes — the preview and the closing never diverge |

> **Verification:** `sql_check.sh` (19.1–19.6) executes `close_cash_register`/`get_cash_closing_summary` as `app_user` and checks values (total, expected, breakdown, UPSERT without duplicates, employee rejected when closing); `sql_check_live.sh` (35/35) validates the RPC live; contract tests cover the payload and mapping (`cash_closing_supabase_data_source_test.dart`) and the use case (`close_cash_register_use_case_test.dart`).

---

## Related documents

- [Domain](03-domain.md) — use cases and exceptions in detail.
- [Data layer](04-data.md) — Unit of Work, schema and re-entrant transactions.
- [Presentation](05-presentation.md) — how the screens consume these flows.
