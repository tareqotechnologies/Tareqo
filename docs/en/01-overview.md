# 01 — Overview

## What is Dumbhanengue ERP?

**Dumbhanengue ERP** is a business management system aimed at **small merchants**. It brings together the day-to-day operations of a store in a single app:

- **Inventory** — product registration and control with **FIFO lots and expiry** (purchase, sale, available quantity, expiry);
- **Sales** — sale registration with a cart, payment method and automatic stock deduction;
- **Finance** — cash flow (income × expenses), transactions and pending entries;
- **Credit ("fiado")** — tracking who owes the merchant, when it's due and the settlement history.

*Dumbhanengue* is the project's nickname; the product itself is a lean ERP focused on usability and simplicity.

---

## Product goals

1. **Answer the merchant's essential questions:**
 - "How much did I sell?" (total sales);
 - "How much cash do I have?" (cash flow balance);
 - "How much is owed to me on credit, and by whom?" (receivables);
 - "How much inventory do I have and what's running out?" (low stock).
2. **Avoid the "credit black hole":** turn granted credit into a visible, manageable number (who owes, how much, when it's due).
3. **Guarantee business integrity:** stock never negative, atomic sales, consistent cash register.
4. **Be a SaaS multi-tenant model:** per-store/merchant authentication (Supabase), prepared for RLS (Row Level Security).

---

## Features

### Implemented (v1.0.0)

| Module | Features |
| ------ | -------- |
| **Authentication** | Sign up and sign in with email/password (Supabase), persistent session restored on boot, sign out |
| **Home (Dashboard)** | KPIs (total sales, cash balance, credit receivables, inventory), quick actions, recent sales, low-stock alert |
| **Products** | Listing with local search, registration via bottom sheet (with price validation), **scale barcode/PLU and weight-based sales** (W11), pull-to-refresh, low-stock chip |
| **Stock (FIFO, W11)** | **Lots per stock-in** with quantity, expiry and acquisition cost; FIFO decrease at the POS (nearest expiry first); expiry alerts on the dashboard (**red** = expired, **yellow** = < 30 days) |
| **Sales** | Sales history, new sale cart (quantity steppers and **decimal fractions** for weight products), **scale-label barcode reading (`20PPPPPWWWWW`)**, 6 payment methods, sale detail with price snapshots |
| **Purchases** | Merchandise intake from suppliers: cart with steppers, **optional expiry per item** (creates the entry's lots), **increases stock** and records the cash expense ("Compras" category) |
| **Finance** | Cash flow by period (Today / 7 days / This month / All), income/expenses/balance, transaction registration, pending entries with "Receive" button |
| **Credit ("fiado")** | Total receivables, debts by due date (late chips), credit registration **optionally linked to a customer**, settlement with confirmation, settlement history tab |
| **Customers** | Registration (name, phone, email), search, pending credit total per customer on the card |
| **Reports** | Revenue, gross profit, margin %, best sellers (top 5) and sales per day, with a period selector |
| **Accounts (SaaS)** | Owner signs up, picks a plan and **waits for super admin approval (≤ 24h)**; once approved, creates **stores** and **employees** (with plan limits) and requests **plan upgrades** |
| **Super Admin** | Admin panel: approve/reject tenant requests, decide plan upgrades and create/edit plans (which limit each tenant's stores and employees) |
| **Multi-store (Phase 2)** | Per-**store** scoping (`store_id`) across products, sales, finance, credit, customers and purchases — each store with its own stock, cash and history — with an **active-store selector** at the top of every screen |

### Design highlights

- **Adaptive navigation:** `NavigationRail` on wide screens (web/desktop) and `NavigationBar` on narrow screens (mobile), with 6 tabs (Home, Products, Sales, Finance, Credit, Customers) and Purchases/Reports/Stores reachable from the dashboard ("Modules" section).
- **Role-based access:** the super admin enters the admin panel; an owner without approval sees waiting/reason screens until release; an approved owner operates the ERP and manages stores/employees.
- **Light and dark themes** (Material 3) with a single emerald-green accent.
- **pt-BR formatting:** currency (`R$ 1.234,56`), dates (`04/08/2026`) and relative days (`Hoje`, `Ontem`).
- **100% real data:** the app ships no demo data — every tenant starts empty and only records what the user creates.

---

## Target audience and platforms

- **End user:** small merchants (grocery stores, stationery shops, general stores, neighborhood shops) who need to control inventory, sales and credit.
- **Platforms:** Android, iOS, Windows, Linux, macOS and **Web** (with an in-memory persistence fallback).

---

## Stack and dependencies

| Package | Role | Layer |
| ------- | ---- | ----- |
| `flutter_riverpod` ^3.4.2 | Reactive state management (AsyncNotifier) | presentation |
| `get_it` ^9.2.1 | Dependency injection (Service Locator) | core |
| `freezed` 3.2.x + `json_serializable` | Immutable entities and JSON serialization (codegen) | domain/data |
| `supabase_flutter` ^2.16.0 | SaaS authentication and future backend (Postgres/RLS) | data |
| `flutter_secure_storage` ^10.3.1 | Encrypted persistence (Keychain/Keystore) | core |
| `sqlite3` + `sqlite3_flutter_libs` | Local relational persistence (parameterized SQL) | data |
| `mobile_scanner` | Camera barcode reading in the POS (scales/PLU, W11) | presentation |
| `path_provider` + `path` | Database file location | core/data |
| `sentry_flutter` ^9.26.0 | Crash reporting (Sentry, DSN via `--dart-define=SENTRY_DSN`) | core |
| `flutter_localizations` + `intl` | i18n (pt/en) and currency/date formatting | core |

> Dart SDK `^3.12.2` (recent Flutter 3.x).

---

## Current state and next steps

The app is fully functional end-to-end. With Supabase configured (default), the business modules **sync to Postgres per tenant and per store** — products, sales, finance, credit, customers and purchases — with RLS + isolation triggers (schema in `supabase/schema.sql`), and the **money flows (sale, purchase, debt, settlement) run as atomic `SECURITY DEFINER` RPCs** in a single DB transaction — including the **FIFO lot decrease** on sales and **lot creation** on purchases (W11). Without Supabase configured, persistence falls back to **SQLite (native)** or **in-memory (web)**.

Remaining roadmap:

1. Recurring fixed expenses (scheduling rent/electricity);
2. "Pay" action for pending expenses in Finance (today only income has "Receive");
3. Offline cache (local read + sync) for use without connection;
4. Server-side aggregation/pagination for large datasets (KPIs are client-side today, capped at 1000 rows per listing);
5. Billing/payments and self-serve plan changes.

---

## Related documents

- [Architecture](02-architecture.md) — how the code is organized.
- [Business flows](08-business-flows.md) — how sales, credit and cash work internally.
- [Multi-tenancy and Super Admin](11-multitenancy.md) — plans, access approval and store management.
- [Developer guide](10-developer-guide.md) — how to run and evolve the project.
