# 05 — Presentation

The `lib/presentation/` layer contains everything the user sees and interacts with: **providers** (Riverpod state), **screens** (per module), shared **widgets** and **navigation**.

---

## State with Riverpod

### State architecture

- **"Bridge" providers** (e.g.: `getProductsUseCaseProvider`) read from GetIt and expose the use case as a provider — replaceable in tests via `overrideWith`/`overrideWithValue`.
- **AsyncNotifiers** (`AsyncNotifierProvider`) expose the state as **`AsyncValue`** (`loading` / `error` / `data`) — the screens react declaratively with `.when(...)`.

### Providers per module

| File | Providers/Notifiers |
| ---- | ------------------- |
| `auth_providers.dart` | `authRepositoryProvider`, `signIn/signUp/signOutUseCaseProvider`, **`authStateProvider`** (`StreamProvider<AppUser?>`) |
| `products_providers.dart` | `getProductsUseCaseProvider`, `addProductUseCaseProvider`, **`productsProvider`** (`AsyncNotifier<List<Product>>`) |
| `sales_providers.dart` | `salesRepositoryProvider`, `processSaleUseCaseProvider`, **`salesListProvider`** (sorted by date desc) |
| `finance_providers.dart` | `financeRepositoryProvider`, `getCashFlowUseCaseProvider`, `addTransactionUseCaseProvider`, `markTransactionAsPaidUseCaseProvider`, **`cashFlowPeriodProvider`** (enum `CashFlowPeriod`: today/week/month/all), **`cashFlowProvider`** (rebuilds when the period changes), **`transactionsProvider`** |
| `debts_providers.dart` | `debtsRepositoryProvider`, `getPendingDebtsUseCaseProvider`, `addDebtUseCaseProvider`, `getSettledDebtsUseCaseProvider`, `settleDebtUseCaseProvider`, **`pendingDebtsProvider`** (by due date), **`settledDebtsProvider`** (by `paidAt` desc) |
| `expiry_alerts_provider.dart` | `getStockLotsUseCaseProvider`, **`expiryAlertsProvider`** (`AsyncNotifier<List<ExpiryAlert>>`) — per-lot expiry alerts (W11) |
| `dashboard_providers.dart` | **`dashboardPeriodProvider`** (`CashFlowPeriod`, default `today`) — period pill of the Home; **`dashboardCashFlowProvider`** (cash balance scoped to that period); **`dashboardKpisProvider`** (RPC `get_dashboard_kpis` in Supabase mode, client-side fallback otherwise) |

**Relevant details:**

- `cashFlowProvider` computes the period as follows (all aligned to **start of day**):
 - `today` → start of today;
 - `week` → start of today − 7 days;
 - `month` → 1st day of the month;
 - `all` → `DateTime(2000)` until now.
- `authStateProvider`: without Supabase credentials, emits `Stream.value(null)` instead of accessing `Supabase.instance` (avoids `StateError`).
- All notifiers have `refresh()` (`invalidateSelf()` + `await future`).
- Lists are **copied before sorting** (entities/returned lists are immutable).

---

## Navigation

### `AuthGate` (authentication gate)

`lib/presentation/screens/auth/auth_gate.dart` decides the root screen:

```text
authStateProvider.when:
 loading → _SplashScreen (restoring persisted session)
 error → LoginScreen
 data → user == null ? LoginScreen : AppShell
```

### `AppShell` (adaptive shell)

`lib/presentation/screens/shell/app_shell.dart`:

- **Wide screens (≥ 880px, web/desktop):** `NavigationRail` on the left.
- **Narrow screens (mobile):** `NavigationBar` at the bottom.
- The 5 sections live in an **`IndexedStack`** (each tab preserves state: search, scroll, open forms).
- `shellIndexProvider` (`ShellIndexNotifier`) allows **switching tabs programmatically** — used by the module cards in the **Menu** tab.
- The **central FAB** opens the global action menu (New sale, Register expense, Add product, Register credit) — canvas V3 sheets.

### Sections (`AppSection`)

| Index | Section | Icon | Screen |
| ----- | ------- | ---- | ------ |
| 0 | Home | `space_dashboard` | `DashboardScreen` |
| 1 | Products | `inventory_2` | `ProductListScreen` |
| 2 | Sales | `point_of_sale` | `SalesScreen` |
| 3 | Finance | `account_balance_wallet` | `FinancialScreen` |
| 4 | Credit | `receipt_long` | `DebtsScreen` |
| 5 | Customers | `people` | `CustomersScreen` |

> **Purchases** and **Reports** are pushed screens (`Navigator.push`) from the **Menu** tab's **"Modules"** section — keeping the nav bar at 4 tabs. The Menu tab also hosts **Products / Credit / Customers** (tab switch), **Stores** (owner only) and the **Sign out** tile.

---

## Screens

### 1. `DashboardScreen` (Home)

Canvas V3 "day view" — the Home tab has no avatar (sign out lives in the **Menu** tab):

- **Header:** date *above* the greeting ("Segunda, 17 ago") → "Olá, {name}"; to the right, the **period pill** (`Hoje ▾`: today / week / month / all — `dashboardPeriodProvider` scopes the Vendas/Caixa metrics); below, the dark-green **store chip** (`StoreSwitcher`, white storefront icon + name; with 2+ stores it opens the quick switcher);
- **3 compact metric cards** (no icons, reference layout):
 - **Vendas** — sales of the period selected in the pill with the **delta vs the previous period** as colored subtext (green `+N%` / red `-N%`);
 - **Caixa** — period-scoped cash balance (`dashboardCashFlowProvider`); negative balance renders the value in red; subtext = currency code (`MZN`);
 - **A receber** — pending credit total with the **fiado count** subtext in Black 70 (e.g. `4 fiados`);
- **Activity feed** ("Atividade de hoje" + event count on the right) in a single card with tinted circular icons and an anchor value/badge on the right:
 - **Sales** (green `north_east` icon, `+value` in green) — tap opens `SaleDetailScreen`;
 - **Stock entries** (grey box icon, `+qty` in white) — purchases of today, one row per item;
 - **Fiado payments** (neutral `payments` icon inside a **dashed circle**, `+value` in green) — settled debts paid today;
 - **Expenses** (red `south_west` icon, `-value` in red) — paid expenses of today;
 - **Low-stock** (ink warning icon + solid neutral **"Alerta"** pill) — active products with `stockQuantity < 5` units (`Quantity.lowStockThresholdUnits`);
 - **Expiry (W11)** via `expiryAlertsProvider`: **red** for **expired** lots with stock, **yellow** for lots expiring in **< 30 days** (`expiryWarningDays`), sorted by urgency (expired first);
- **Pending sync banner** (SaaS outbox) when the offline queue is non-empty, with a "Sync" action;
- KPI load error shows a compact inline warning with retry (`InlineErrorCard`) instead of fake zeros.

> **Sign out** lives in the **Menu** tab; the Home header has no avatar. The Home has **no quick actions and no module cards** — those live in the central FAB and the **Menu** tab (same module grid and access matrix).

### 2. `ProductListScreen` (Products)

- Local search (name and description), pull-to-refresh, "New product" FAB;
- Cards with purchase/sale price and stock chip (yellow if `< 5` units = `< 5000` milli-units);
- Registration via **`_AddProductSheet`** (bottom sheet): name, description, prices, stock, **scale barcode/PLU** (optional), **"Sold by weight"** switch (`vendaPorFracao` — enables fractions) and **sale unit** (`kg`/`un`) — catches `InvalidPriceException` and shows the message;
- Stock shown with **fraction and unit** for weight-based products (e.g., `1.75 kg`).
- `EmptyState` for empty list and for search without results.

### 3. `SalesScreen` + `NewSaleSheet` + `SaleDetailScreen` (Sales)

- **List:** cards with item count, payment method, day and total; tapping opens the **detail**;
- **`NewSaleSheet`** (cart):
 - Searches and adds products with **steppers** (+/−) limited to stock (`soldOut` disables); weight-based products use **0.1 steps** and open a **decimal quantity dialog** (e.g., `1.75` kg);
 - **Barcode field** (USB keyboard-style scanners trigger the lookup on `onSubmitted`) + **camera reading** via `BarcodeScanSheet` (`mobile_scanner`, where supported);
 - Intercepts the **scale-label pattern `20PPPPPWWWWW`** (`ScaleBarcode`): extracts the PLU, derives the fraction from the weighing (value ÷ price — never overcharges) and only treats it as a scale code when the product is `vendaPorFracao` — EAN-12 codes starting with `20` fall back to the normal lookup; PLUs are normalized (leading zeros: `123` ≡ `00123`);
 - Payment method via `ChoiceChip`s (`PaymentMethod.values`);
 - Confirms via **`ProcessSaleUseCase`** → records the sale + **FIFO stock deduction (lots)** + cash income;
 - Catches `InsufficientStockException` (shows the product and available amount) and `ProductNotFoundException`;
 - After success, invalidates `productsProvider`, `salesListProvider`, `transactionsProvider`, `cashFlowProvider`, `expiryAlertsProvider`;
- **`SaleDetailScreen`:** summary (id, date, payment, total), items with `quantity × price` and subtotal, and the note "Preços congelados no momento da venda" (prices frozen at the time of sale).

### 4. `FinancialScreen` + `AddTransactionSheet` (Finance)

- **SegmentedButton** of period (`CashFlowPeriod`);
- 3 KPIs: **Income**, **Expenses**, **Balance** (semantic green/red colors);
- **Transactions** list: directional icon, description, category + day, signed value (+/−) and color;
- Pending entries (income with `pending` status) show a "Pendente" chip + **"Receber" (Receive)** button (confirmation dialog → `MarkTransactionAsPaidUseCase` → invalidates cash/transactions);
- **`AddTransactionSheet`:** Income/Expense type (SegmentedButton), description, category (default "Vendas"/"Despesas"), amount and the **"Pendente (fiado)"** switch — catches `InvalidAmountException`.

### 5b. `CustomersScreen` (Customers)

- Local search (name, phone, email), pull-to-refresh and "New customer" FAB;
- Cards with avatar (initial), name, contacts and the customer's **pending credit chip** (sum of debts linked via `Debt.customerId`);
- Registration via **`_AddCustomerSheet`**: name (required), optional phone and email — catches `InvalidCustomerException`;
- **Credit integration:** `AddDebtSheet` lets you **link** the debt to a customer (chips) — `personName` becomes the name snapshot and `customerId` keeps the link.

### 5c. `PurchasesScreen` + `AddPurchaseSheet` (Purchases)

- Purchases list (supplier, item count, day and total);
- **`AddPurchaseSheet`**: supplier, product search with steppers and total (purchase price); weight-based products accept **decimal fractions** and each item can get an **expiry date** (optional — feeds the lot created for the entry) → **`ProcessPurchaseUseCase`** records the purchase, **increases stock creating lots** and records the **cash expense** ("Compras" category); catches `ProductNotFoundException`;
- After success, invalidates purchases, products, transactions, cash and expiry alerts.

### 5d. `ReportsScreen` (Reports)

- Period selector (`ReportPeriod`: Today / 7 days / This month / All);
- KPIs: **Revenue**, **Gross profit** and **Margin %**;
- **Best sellers** (top 5 by quantity, with revenue) and **sales per day** — computed by `GetSalesReportUseCase` from sales (snapshots) and the current catalog.

### 5. `DebtsScreen` + `AddDebtSheet` (Credit)

- **Tabs:** "Pendentes" (Pending) and "Quitadas" (Settled) (local `_DebtView` SegmentedButton);
- **Pending:** "Total a receber" (Total receivable) summary card (neutral) + debt list with initial avatar, due-date chip (`Atrasada` red / `Vence hoje` yellow / `Em N dias` green) and **"Quitar dívida" (Settle debt)** button (confirmation dialog → `SettleDebtUseCase` → invalidates credit, history, cash and balance);
- **Settled:** "Total quitado" (Total settled) summary card (green) + history with `paidAt` ("Quitada em 25/07/2026");
- **`AddDebtSheet`:** customer name, amount, due date (DatePicker) → `AddDebtUseCase` (records the debt + linked financial pending entry); catches `InvalidDebtAmountException` and handles `PendingEntryRegistrationException` specially (informs that the credit was recorded and asks to check Finance — without suggesting a retry).

---

## Shared widgets

| Widget | Purpose |
| ------ | ------- |
| `showAppSheet` + `AppSheetHeader` | Standard bottom sheet (28px corners, SafeArea, keyboard padding, title + close) |
| `KpiCard` | Indicator: colored icon, value (with `FittedBox` anti-overflow), label, caption, loading state ("—") |
| `StatusChip` | Status pill with translucent background and optional icon |
| `EmptyState` | Empty state: icon in a rounded box, title, subtitle, optional action |
| `ErrorView` | Error state: message + technical detail + "Try again" button |
| `SearchField` | Filled, rounded search field (no outline) |
| `SectionHeader` | Section title with optional action on the right |
| `BarcodeScanSheet` | Camera barcode reader (`mobile_scanner`) used in the POS (W11) |

---

## Theme (Material 3)

`lib/core/theme/app_theme.dart`:

- **Seed:** deep emerald green `#0E6B5A`; `ColorScheme.fromSeed` for light/dark;
- **Semantic colors (`AppColors`):** `income` green `#2E7D32`, `expense` red `#C62828`, `warning` neutral (Black 70 `#4E576A` light / White 60 `#BFC5D4` dark) — no orange;
- **Visual guidelines:** neutral surfaces, cards with subtle border without heavy shadow (`elevation: 0`), rounded corners (14–20px), **filled fields without outline**, `FilledButton`s 52px tall;
- **Navigation:** `NavigationBar` (68px height, `primaryContainer` indicator) and `NavigationRail` (`groupAlignment: -0.9`);
- **Typography:** modular scale (Apple HIG/SF Pro): **34** (Large Title — login/welcome) → **28** (page titles) → **24** (KPIs/totals) → **22** (cards/modals/AppBar) → **20** (subtitles/sections) → **17/15/14/13/12/11** (body large/body/line highlights/note/labels/caption); hierarchy by size + weight (w300 display, w400 body, w600+ values), **`tabularFigures`** on the numeric styles (MZN prices and kg/un quantities align digit by digit), and **three precision axes** like SF Pro: (1) **optical axis `opsz`** — Inter is variable (14–32) and titles ≥20px use the *Display* cut (opsz 24–32) while body stays on the *Text* cut; (2) **negative tracking** on titles (−0.15 to −0.6), neutral on body, slight positive on captions; (3) **line height** at the SF Pro ratio (~1.2 titles, ~1.4 body); the full decision (scale table, roles and golden rules) is in [chapter 12 — Architecture Decisions](12-architecture-decisions.md);
- **Floating snackbars** with inverted theme (dark on light theme and vice versa).

The theme is applied in `app.dart`:

```dart
MaterialApp(
 title: 'TAREQO ERP',
 debugShowCheckedModeBanner: false,
 theme: AppTheme.dark,
 darkTheme: AppTheme.dark,
 themeMode: ThemeMode.dark, // V3 — 100% dark
 home: const AuthGate(),
)
```

---

## pt-BR formatting (`Formatters`)

`lib/core/utils/formatters.dart`:

- `currency(int cents)` → `1.234,56` with the tenant's symbol (default `R$`, Mozambique tenants use `MZN`) — since W4, money is integer cents;
- `date(DateTime)` → `04/08/2026`;
- `shortDate(DateTime)` → `17 ago` (header date of the dashboard);
- `dateTime(DateTime)` → `04/08/2026 14:30`;
- `day(DateTime)` → `Hoje`, `Ontem` or `04/08`;
- `compact(double)` → `12,4k` (compact metric values);
- `signedAmount(int cents)` → `+500,00` / `-500,00` (feed amounts).

---

## Related documents

- [Architecture](02-architecture.md) — how the presentation talks to the domain.
- [Authentication](06-authentication.md) — `AuthGate` and the session flow.
- [Testing](09-testing.md) — screen tests with overridden providers.
