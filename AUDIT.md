# TAREQO - Gestão Empresarial - Code Audit & Improvement Plan

**Status**: Initial analysis complete — no code modifications performed
**Project**: TAREQO (Flutter, Clean Architecture, Riverpod 3)
**Date**: November 3, 2026
**Sole Author**: Principal Flutter Engineer & Technical Director

---

## 1. Project Structure & Architecture

### 1.1 Folder Organization
```
lib/
├── core/                 # Shared infrastructure & cross-cutting concerns
│   ├── config/           # App flavor, settings, Supabase config
│   ├── constants/        # Empty (reserved)
│   ├── database/         # AppDatabase (SQLite), stubs
│   ├── di/               # Service Locator (GetIt) bootstrap
│   ├── errors/           # Error handling base
│   ├── i18n/             # Localization (ARB files, intl)
│   ├── network/          # HTTP client with cert pinning, timeout/retry
│   ├── observability/    # Sentry crash reporting
│   ├── platform/         # Backup exclusion, platform specifics
│   ├── security/         # Biometrics, MFA, secure storage
│   ├── share/            # PDF exporters (invoice, quotation, receipt, reports)
│   ├── theme/            # AppTheme, colors, tokens, typography
│   └── ui/               # Custom painters, haptics
│   └── utils/            # Formatters, period utils, quantity, money, clock
├── data/                 # Data layer (repositories, datasources, models)
│   ├── datasources/      # Remote (Supabase), Local (SQLite)
│   ├── models/           # Generated models (freezed + json_serializable)
│   ├── repositories/     # Repository implementations
│   └── services/         # Business logic services (addon expiry, offline sync)
├── domain/               # Domain layer (entities, use cases, repositories)
│   ├── entities/         # Pure Dart models (freezed)
│   ├── repositories/     # Repository interfaces
│   └── usecases/         # Use case classes
└── presentation/         # UI layer
    ├── controllers/      # Riverpod providers/notifiers
    ├── routes/           # Route definitions (empty .gitkeep)
    ├── screens/          # ~70+ screens organized by feature
    └── widgets/          # Comprehensive custom widget library
```

### 1.2 Key Architectural Decisions
- **Clean Architecture**: Separation into domain/data/presentation layers
- **Riverpod 3**: State management via providers/notifiers (≈30+ providers)
- **GetIt (Service Locator)**: Dependency injection at app bootstrap
- **Freezed + json_serializable**: Immutable entities and serialization
- **Supabase + SQLite**: Hybrid backend (real-time database + local persistence)
- **Material 3 + Dark-first**: Design system prioritizing dark mode

---

## 2. Screens, Routes, Dialogs, Forms, Menus

### 2.1 Screen Count: ~75+ screens across these feature areas:

| Feature Area | Screens (count) |
|---|---|
| **Auth** | 8 (login, MFA, passwords, auth gate) |
| **Dashboard** | 1 (main overview screen) |
| **Sales** | 3 (list, new sale sheet, detail) |
| **Financial** | 1 (cash flow) + sheets |
| **Products** | 1 (list) + add/sheets |
| **Customers** | 1 (list) + add/sheets |
| **Credit/Debts** | 1 (debts list) + add sheet |
| **Admin** | 12 (dashboard, addons, audit, invoices, messages, plans, tenants, thin theme) |
| **Auth Gates & Onboarding** | 6 (onboarding pending/rejected, security settings) |
| **Support/Help** | 2 (doc reader, support screen) |
| **Add-ons** | 5 (marketplace, expiry, revenue, employee management, payment reconciliation, custom invoice, store transfers, quotations) |
| **Production** | 1 (production screen) |
| **Reports** | 1 (advanced reports) |
| **Purchases** | 1 (purchases screen) |
| **Store Transfers** | 1 (screen) |
| **Quotations** | 1 (screen) |
| **Invoice Templates** | part of providers |

### 2.2 Navigation Structure
- **AppShell**: Hybrid navigation (NavigationRail on wide screens, NavigationBar on mobile)
- **Bottom nav**: 4 tabs (Dashboard, Sales, Financial, Menu)
- **NavigationRail**: Same 4 destinations + persistent content area
- **FAB**: Central "+" action; context-sensitive (credit → add debt, others have own FAB)
- **PopScope**: Back button behavior — non-Dashboard sections navigate to Dashboard instead of closing app
- **AuthGate**: 3-step gate (session → MFA → tenant/admin) with 3-second timeouts
- **Route system**: Index-based (AppSection enum + shellIndexProvider), not declarative routes

### 2.3 Forms & Formsheets
- **AppSheet** (custom bottom sheet): Unified sheet pattern with SheetHeader, SheetSection, save/cancel actions
- **Common form patterns**: Label + TextField (AppTextField), validator, helperText, errorText
- **Specialized sheets**: NewSaleSheet, AddProductSheet, AddCustomerSheet, AddDebtSheet, CashClosingSheet, AddTransactionSheet, SetNewPasswordScreen, ForgotPasswordSheet, MFAVerificationSheet
- **Form validation**: Email regex, password strength, confirmation matching, rate limiting (429)

### 2.4 Menus & Navigation Components
- **AppMenuOption / AppMenuOptionItem**: Material-like option lists with checkboxes
- **NavigationRailDestination**: Icon + label pairs for wide screens
- **PinnedHeader**: Sticky header in scrollable lists
- **SalesSummaryHeader**: Summary area above sales list
- **PeriodFilter / PaymentFilter**: Dropdown filters applied globally

---

## 3. State Management & Navigation

### 3.1 State Management (Riverpod 3)
**Provider Count**: ~35+ providers across these notifier types:

| Notifier | Purpose |
|---|---|
| `ShellIndexNotifier` | Current navigation tab index |
| `DashboardPeriodNotifier` / `CashFlowPeriodPeriodNotifier` | Period selection |
| `AuthStateProvider` / `authStateProvider` | User session state |
| `TenantSettingsProvider` | Currency + language preference |
| `ProductsProvider` / `productsProvider` | Product list state |
| `SalesListProvider` / `salesListProvider` | Sales list with pagination |
| `DashboardKpisProvider` / `dashboardKpisProvider` | KPI aggregation (server-side RPC) |
| `DashboardCashFlowProvider` / `dashboardCashFlowProvider` | Cash flow data |
| `FinanceProviders` | Financial transaction state |
| `DebtProviders` | Debt/fiado management |
| `ExpiryAlertsProvider` | Product validity alerts |
| `NotificationProviders` / `notification_providers` | Unread count |
| `AddonExpiryProvider` | Periodic add-on deactivation |
| `InvoiceTemplateNotifier` | Invoice template config |
| `ReportPeriodNotifier` / `reportPeriodNotifier` | Report period selection |
| `StockTransfersNotifier` | Stock transfer list |
| `EmployeesPollingProvider` | Employee real-time link polling |
| `MyTenantProvider` | Current tenant resolution |
| `IsSuperAdminProvider` | Admin role check |
| `UnreadNotificationsCountProvider` | Notification badge count |
| `CanCloseCashRegisterProvider` | Cash register close permission |

**Patterns Observed**:
- `StateProvider<bool>` for simple flags
- `NotifierProvider<int>` for integer indexes
- `StateNotifierProvider` for complex state (limited — most use `Notifier`)
- `futures` watched for async loading with `hasError` checks
- `ref.read(xxx.notifier).refresh()` pattern for manual refresh
- `ref.invalidate(xxx)` for cache invalidation

### 3.2 Navigation
- **Index-based**: `AppSection` enum → `shellIndexProvider` → `AppShell`
- **No auto_routes or go_router**: Custom implementation using `FadeIndexedStack` + `NavigationRail/NavigationBar`
- **PopScope**: Overrides back button behavior for non-dashboard sections
- **PageTransitionsTheme**: Android (zoom), iOS/macOS (Cupertino swipe), Desktop (zoom)
- **Deep links**: Handled via `DeepLinkHandler.init()` in AuthGate

---

## 4. ThemeData, Cores, Fonts, Icons, Styles

### 4.1 Color System (Material 3, Dark-first)
**Primary Color**: `AppColors.petrol` (`#10282A`) — used as seed for ColorScheme

**Light Theme**:
- `primary`: `AppColors.slate` (`#3D4D55`) — text white 8.8:1 contrast
- `onPrimary`: `Colors.white`
- `surface`: `Colors.white` / `AppColors.scaffoldLight`
- `onSurface`: `AppColors.onSurfaceLight`
- `error`: `Color(0xFFDC2626)`

**Dark Theme**:
- `primary`: `AppColors.warmBeige` (`#D3C3B9`) — text black soft 10.6:1 contrast
- `surface`: `AppColors.surfaceDark`
- `onSurface`: `Color(0xFFFAFAFA)`
- `terracotta`: `AppColors.terracotta` — reserved accent (FAB, links, cursor)

**Status Colors** (`AppStatusColors` extension):
- `income`, `expense`, `warning`, `accent` — theme extensions for visual consistency

**Module Colors** (`ModuleColors`):
- `products`: `#10282A` (petrol)
- `customers`: `#3D4D55` (slate)
- `credit`: `#B58863` (terracotta)
- `purchases`: `#A79E9C` (gray warm)
- `reports`: `#2E6E75` (petrol médio)
- `stores`: `#223A41` (petroleum-ardósia)
- `production`: `#5A4632` (terra queimada)

### 4.2 Typography (Inter Variable Font)
**Font Family**: `Inter` variable (`Inter-Variable.ttf`) with optical size axis (`opsz`)

**Text Theme Scale** (Apple HIG / SF Pro calibrated):
| Role | Size | Weight | Usage |
|---|---|---|---|
| `displaySmall` | 34 | w300 | Large title, welcome screens |
| `headlineMedium` | 28 | w300 | Page section headers |
| `headlineSmall` | 24 | w600 | KPIs/totals |
| `titleLarge` | 22 | w600 | Cards, modals, AppBar |
| `titleMedium` | 20 | w600 | Subtitles |
| `titleSmall` | 14 | w600 | Line highlight, chips |
| `bodyLarge` | 17 | w400 | Highlighted body |
| `bodyMedium` | 15 | w400 | Body text |
| `bodySmall` | 13 | w400 | Table cells, captions |
| `labelLarge` | 14 | w600 | Actions |
| `labelMedium` | 12 | w600 | Labels |
| `labelSmall` | 11 | w500 | Captions, badges |

**Features**: `tabularFigures` enabled globally; `fontVariations: [opsz, 32]`/`[opsz, 24]`

### 4.3 Widget Library (Custom V4 Components)
Key widgets (all with design system consistency):

- **AppButton**: primary/secondary/danger variants with pressScale animation
- **AppCard**: elevated/fill, border, focus ring for accessibility
- **AppTextField**: minimalist, filled, outlined, with prefix/suffix icons
- **EmptyState**: icon + title + subtitle + action (primary/outlined)
- **ErrorView**: center-aligned error with retry button
- **InlineEmpty**: inline empty state message
- **PulseBadge**: notification badge with pulse animation
- **StatusChip**: status indicator chip
- **KPICard**: key performance indicator card
- **SaleCard / SalesCard**: sale list card with border radius handling
- **SalesSummaryHeader**: summary above sales list
- **PeriodPill**: period selector ("Hoje ▾")
- **BalanceHero**: hero cash/sales/receivables card
- **ActivityFeed / ActivityRow**: today's activity feed
- **SheetScaleIn**: sheet entrance animation (scale 0.92 + fade)
- **SheetHeader / SheetSection**: unified sheet header + grouped fields
- **SalesSummaryHeader**: summary header above sales list
- **DashedCirclePainter**: dotted border around circular icons (thermal receipt pattern)
- **FocusRing**: visible focus ring for keyboard navigation
- **AppPage**: page scaffold with app bar, actions, FAB
- **AppSheet**: modal bottom sheet with standardized appearance
- **Skeleton**: loading skeleton (various block shapes)

### 4.4 Asset & Icon System
- **Branding icon**: `assets/branding/icon_official.png` (blue square + arc + "D" white + blue dot)
- **Splash logo**: `assets/branding/splash_logo.png`
- **App icons**: Generated via `flutter_launcher_icons` from `icon_legacy.png`
- **Font icons**: Material Cupertino icons (`^1.0.8`)
- **Custom icons**: Generated via `tool/generate_icons_test.dart` + `tool/apply_official_icon.py`

### 4.5 Known Theme Issues
- `always_use_package_imports` excluded by design convention (relative imports used)
- Font weight mapping: `FontWeight.w600` maps to eixo `wght` ~400-500 in Inter variable
- No `green` in official theme (terracotta `#B58863` used as "green" in prior versions — now `ModuleColors.green = #B58863` retained as semantic warm accent)
- `OutlineInputBorder` radius consistency: `AppRadius.mdAll` (12) used everywhere

---

## 5. Services, Repositories, Models, HTTP Integrations

### 5.1 Core Services (≈15 services)
| Service | Purpose |
|---|---|
| `AddOnExpiryService` | Periodic check → deactivate expired add-ons |
| `OfflineSyncService` | Outbox pattern for offline-capable transactions |
| `BiometricService` | Fingerprint/face authentication |
| `MFAService` | TOTP-based multi-factor authentication |
| `SecureStorageService` | Encrypted storage (Keychain/AzureKeyVault) |
| `CertPinning` / `PinnedRetryHTTPClient` | Certificate-pinned HTTP with retry |
| `TimeoutRetryHTTPClient` | Timeout + retry on idempotent reads |
| `CrashReporting` (Sentry) | Error tracking (9.30.0) |
| `DeepLinkHandler` | OAuth PKCE + email callback (`tareqo://callback`) |

### 5.2 Repository Pattern (≈40 repositories)
**Remote (Supabase)**: `Supabase*DataSourceImpl` + `*RepositoryImpl`
- `AuthRepositoryImpl`, `CustomerRepositoryImpl`, `ProductRepositoryImpl`
- `InvoiceRepositoryImpl`, `QuotationRepositoryImpl`, `DebtRepositoryImpl`
- `SaleRepositoryImpl`, `PurchaseRepositoryImpl`, `PlanRepositoryImpl`
- `EmployeeRepositoryImpl`, `TenantRepositoryImpl`
- `AdminRepositoryImpl`, `AdminMessageRepositoryImpl`

**Local (SQLite)**: `*SqliteDataSourceImpl`
- `ProductSqliteDataSourceImpl`, `DebtSqliteDataSourceImpl`
- `PurchaseSqliteDataSourceImpl`, `QuotationSqliteDataSourceImpl`
- `SaleSqliteDataSourceImpl`, `StockLotSqliteDataSourceImpl`
- `CustomerSqliteDataSourceImpl`, `ProductionSqliteDataSourceImpl`

**Hybrid Repositories**: Combine remote + local (e.g., `ProductRepositoryImpl` uses both Supabase + SQLite)

### 5.3 HTTP Client
- **Centralized**: `http: ^1.6.0` with `PinnedRetryHTTPClient`
- **Features**: Timeout, retry of idempotent reads, cert pinning
- **Interceptor**: Error translation (PostgrestException → domain errors)
- **Base URL**: Supabase project URL (environment-configured)

### 5.4 PDF Exporters (6 exporters)
| Exporter | Content |
|---|---|
| `InvoicePDFExporter` | Individual invoice generation |
| `QuotationPDFExporter` | Quotation/proposal generation |
| `AdvancedReportsPDFExporter` | Full reports with charts/analysis |
| `ReceiptPDFExporter` / `receipt_sharer` | Receipt generation + share |
| `DocumentPDFScaffold` | PDF document scaffold base |

### 5.5 Code Generation
- **Build Runner**: `build_runner: ^2.15.1` — run after freezed/json changes
- **Freezed**: `>=3.2.5 <3.2.6` — immutable entities
- **Json_serializable**: `^6.14.1` — serialization annotations

---

## 6. Loading, Error, Empty & Connectivity States

### 6.1 Loading States
- **AsyncValue patterns**: `when loading: ..., error: ..., data: ...` across all screens
- **Skeleton loaders**: `Skeleton` + `SkeletonBlock` widgets for list loading
- **Progress indicators**: `ProgressIndicatorTheme` with theme-aware colors
- **Specific loading**: `_CountUpText` animates to final value; `_CountUpText` shows "—" during loading

### 6.2 Error States
- **ErrorView**: Center-aligned with icon, message, details, retry button
- **InlineErrorCard**: Compact error within content (dashboard KPIs)
- **Error handling layers**:
  - `AuthApiException`: rate limiting (429), generic API errors
  - `AuthWeakPasswordException`: weak password rejection
  - `AuthRetryableFetchException`: network/DNS errors
  - Generic `catch` → Sentry + snackbar
- **Connectivity**: `loginNoConnection` snackbar for network failures

### 6.3 Empty States
- **EmptyState**: Full-screen with icon, title, subtitle, primary action (e.g., "New Sale")
- **InlineEmpty**: Compact inline message within list/grid
- **Usage patterns**:
  - Lists with zero items → `EmptyState` or `InlineEmpty`
  - Filtered results with zero matches → `EmptyState` with clear filters action
  - Dashboard activity feed empty → `InlineEmpty`

### 6.4 Connectivity Awareness
- **No dedicated Connectivity service** in current implementation
- **Network errors** handled via catch blocks in auth/sign-in flows
- **No offline-first UI patterns** beyond `OfflineSyncService` outbox
- **Rate limiting** (429) → actionable snackbar vs generic "check credentials"

---

## 7. Usability, Consistency, Accessibility & Responsiveness Issues

### 7.1 Usability Findings
| Issue | Severity | Impact |
|---|---|---|
| **Timeout gates**: 3-second timeouts in AuthGate may trap users on slow networks | High | Users stuck on splash screen |
| **FAB duplication**: Some screens define own FAB + shell FAB logic attempts to prevent double FAB | Medium | Visual clutter if logic fails |
| **Period-based KPI recalculation**: Changing period animates from current value → new (600ms count-up) | Low | Minor UJ discrepancy during period switch |
| **Sheet handle consistency**: All sheets use same `_SheetHandle` (4px tall) | Low | Consistent across app |
| **Parallax effect**: Login screen header parallax at 0.5× speed | Low | Aesthetic, may cause motion reduction issues |

### 7.2 Accessibility (A11y) — Partially Addressed
| Feature | Status |
|---|---|
| **Text scaling**: `MediaQuery.textScaler.clamp(min: 1.0, max: 1.6)` in `TareqoApp` — ✅ | Good |
| **Focus ring**: `FocusRing` widget on `AppCard` when `onTap` provided — ✅ | Good |
| **Semantics**: `Semantics` widgets on `AppCard` hero metrics — ✅ | Good |
| **Label + value merging**: Semantics container merges label + value into single node — ✅ | Good |
| **Contrast**: WCAG-audited (petrol/slate in light, beige in dark) — ✅ | Good |
| **Color-only meaning**: Some status colors (green/red) not universally meaningful — ⚠️ | Medium |
| **Touch target**: `AppSizes.touchTarget = 48` — ✅ | Good |
| **Navigation back**: PopScope redirects non-Dashboard → Dashboard — ✅ | Good |
| **Screen reader sheet titles**: `SheetHeader` uses `FittedBox` scaleDown — ✅ | Good |

### 7.3 Responsiveness
| Screen Width | Layout |
|---|---|
| < 600px (mobile) | NavigationBar bottom + content area |
| 600px – 880px | Transition zone — both NavigationRail and NavigationBar attempted |
| > 880px (tablet/web) | NavigationRail left + VerticalDivider + content center |
| **Padding adaptation**: `AppSpacing.pagePaddingForWidth()` — ✅ | Good |
| **Content max width**: `AppSizes.contentMaxWidth = 1040` — ✅ | Good |

### 7.4 Visual Consistency
| Aspect | Status |
|---|---|
| **Rounded corners**: `AppRadius` constants everywhere — ✅ | Excellent |
| **Spacing**: `AppSpacing` grid (4px base) — ✅ | Excellent |
| **Elevations**: Consistent shadow usage (0, 1, 2, 4, 8) — ✅ | Excellent |
| **Borders**: `outlineVariant` for borders, `primary` for focus — ✅ | Excellent |
| **Ink ripples**: Standard `InkRipple.splashFactory` — ✅ | Good |
| **Shadow colors**: `Colors.black.withValues(alpha: 0.2)` standard — ✅ | Good |
| **Green usage**: `ModuleColors.green = #B58863` (terracota) — historical remnant — ⚠️ |

### 7.5 Duplicated Components & Reuse Opportunities
| Duplicated Pattern | Count / Location |
|---|---|
| **AppButton** usage: ~25+ instances across screens | `lib/presentation/widgets/app_button.dart` |
| **AppCard** usage: ~30+ instances | `lib/presentation/widgets/app_card.dart` |
| **AppTextField** usage: ~20+ instances | `lib/presentation/widgets/app_text_field.dart` |
| **EmptyState** usage: ~8 instances (different variants) | Various screens |
| **ErrorView** usage: ~5 instances | Sales, Financial, Dashboard |
| **PeriodFilterBar + PaymentFilterBar** | Sales screen only (could be shared) |
| **SheetHeader / SheetSection** | All sheets (well centralized) ✅ |
| **SalesSummaryHeader** | Sales-only (could generalize) |
| **AppMenuOption / AppMenuOptionItem** | Dashboard period pill + admin menus |
| **PinnedHeader** | Sales filters + potentially other lists |
| **CountUp / _CountUpText** | Dashboard hero + could generalize |
| **ActivityFeed / _ActivityRow** | Dashboard-only pattern |
| **StoreSwitcher** | Dashboard-only (could be top app bar action) |

**High-Reuse Components (already good)**:
- `AppButton`, `AppCard`, `AppTextField`, `EmptyState`, `ErrorView`
- `SheetHeader`, `SheetSection`, `SheetScaleIn`
- `AppPage`, `PulseBadge`, `StatusChip`

**Extraction Opportunities**:
- Generalize `SalesSummaryHeader` → generic `SummaryHeader`
- Generalize `PeriodFilterBar` + `PaymentFilterBar` → generic filter bar
- Generalize `ActivityFeed` → reusable list component
- Generalize `StoreSwitcher` → top-bar tenant selector
- Generalize `_CountUpText` → reusable animated value widget

---

## 8. Duplicate Components & Reuse Opportunities Summary

### 8.1 Confirmed Duplication
1. **Two FAB logic paths**: Shell `_hasOwnFab()` + individual screen FABs → coordination needed
2. **Period/payment filters**: Hardcoded in `SalesScreen` Wrap — not reusable outside sales
3. **Activity feed pattern**: Dashboard-specific — not abstracted
4. **Store switcher**: Dashboard-only, could be global app bar action
5. **Three empty state variants**: `EmptyState`, `InlineEmpty`, + inline within lists

### 8.2 Missing Abstractions
- No generic `FilterBar` component (period + payment hardcoded per feature)
- No generic `SectionHeader` for list sections
- No universal `LoadingPlaceholder` beyond `Skeleton`
- No `ErrorBoundary` widget (try/catch handled per-use)

### 8.3 Good Reuse Patterns
- PDF exporters shared across invoice/quotation/reports
- Sheet system (`AppSheet`, `SheetHeader`, `SheetSection`) consistent
- Button/text field/component library well-maintained
- Theme tokens fully centralized

---

## 📊 Existing Tests & Analysis Errors

### 8.1 Test Inventory
**Total test files**: ~312 detected (from repository stats)

**Test Areas**:
- `test/presentation/screens/` — screen-level widget tests (≈40 tests)
- `test/presentation/controllers/` — provider/notifier tests (≈20 tests)
- `test/presentation/goldens/` — golden tests (≈10 golden tests)
- `test/core/` — core layer tests (config, theme, i18n, network)
- `test/data/` — datasource/repository tests
- `test/domain/` — entity/use case tests
- `test/helpers/` — helper utilities

**Key test files read**:
- `test/presentation/screens/auth/login_screen_test.dart`
- `test/presentation/screens/dashboard/dashboard_screen_test.dart`
- `test/presentation/goldens/login_golden_test.dart`
- `test/presentation/goldens/design_system_golden_test.dart`

### 8.2 Analysis Issues (from `flutter analyze`)
Known exclusions in `analysis_options.yaml`:
- `build/**, android/**, ios/**, web/**, windows/**` — build artifacts excluded

**No active analysis errors visible** in the current config beyond the known `always_use_package_imports` convention exception.

### 8.3 Pre-existing Risks
- **Sentry Kotlin detection**: Benign but logged (`builtInKotlin=false` conditional)
- **Windows flavor detection**: Fallback to `APP_FLAVOR` env var
- **Cert pinning**: Must keep `pinned_retry_http_client` in sync with Supabase cert changes

---

## 🎯 Recommended Implementation Sequence (Phase 1)

### Priority 1 — Foundation & Polish (Weeks 1-2)
1. **Fix AuthGate timeouts** — increase from 3s or add connectivity check before showing login
2. **Audit contrast on all status colors** — verify WCAG AA/AAA across light/dark for all `AppStatusColors`
3. **Text scaling edge cases** — test with `textScaler` at 1.6× across all screens, especially tables and forms
4. **Remove `green` from `ModuleColors`** — replace with proper semantic color or document as intentional terracotta reuse
5. **Add `connectivity_plus`** + basic offline UI patterns (skeleton + retry)

### Priority 2 — Consistency & Reuse (Weeks 3-4)
6. **Extract generic FilterBar** from SalesScreen period/payment → reusable component
7. **Generalize ActivityFeed pattern** → reusable list section component
8. **Generalize StoreSwitcher** → top app bar tenant selector (replace dashboard-specific logic)
9. **Consolidate empty state variants** → standardize on `EmptyState` + `InlineEmpty` only
10. **Refactor duplicated FAB logic** — ensure single source of truth in `AppShell`

### Priority 3 — Accessibility & Visual Polish (Weeks 5-6)
11. **Full contrast audit** — run `flutter test` contrast checks on all color combinations
12. **Accessibility tree audit** — verify semantics merges work correctly with VoiceOver/TalkBack
13. **Table cell formatting** — ensure `bodySmall` (13/w400/tabular) used consistently for data cells
14. **iOS-style swipe-back** — verify `CupertinoPageTransitionsBuilder` works without navigatorKey issues
15. **Dark mode color recomputation** — verify all `AppStatusColors.light/dark` extensions interpolate correctly

### Priority 4 — Architecture Refinement (Weeks 7-8)
16. **Consider auto_routes or go_router** migration from index-based navigation
17. **Add ErrorBoundary widget** for centralized error handling
18. **Abstract generic LoadingPlaceholder** beyond `Skeleton` blocks
19. **Document ModuleColors intent** — clarify terracotta-as-green historical decision
20. **Add integration test scaffold** for critical user flows (auth → dashboard → key transaction)

---

## ⚠️ Risks & Mitigation

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| **AuthGate timeout on slow networks** | High | User experience degradation | Increase timeout, add connectivity check, show friendly error |
| **Terracotta/green color confusion** | Medium | Brand inconsistency | Document intent or rename `ModuleColors.green` |
| **Sentry false positives on Windows** | Low | Noise in error tracking | Monitor, update when sentry-dart migrates |
| **SQLite ↔ Supabase sync issues** | Medium | Data inconsistency | `OfflineSyncService` outbox pattern, periodic validation |
| **Text scaling breaks layouts** | Medium | UI regression | `clamp(min: 1.0, max: 1.6)` already in place, test thoroughly |
| **No dedicated connectivity service** | Medium | Poor offline UX | Add `connectivity_plus`, skeleton + retry patterns |
| **Analysis excludes too broad** | Low | Hidden lint issues | Gradually reduce exclusions, run `flutter analyze` on feature branches |

---

## ✅ Next Steps — Awaiting Authorization

**Do not modify code without explicit authorization.**

Once authorized, the recommended sequence is:

1. **Run `flutter analyze`** on a clean branch to establish baseline
2. **Apply Priority 1 fixes** (auth timeout, contrast, connectivity)
3. **Progress through priorities** as authorized, with `flutter test` and `flutter analyze` after each phase
4. **Generate AUDIT.md v2** after each priority group to track progress
5. **Final visual audit** against Apple Human Interface Guidelines benchmark before production release

---
*Generated by Codebuff AI — Principal Flutter Engineer & Technical Director analysis phase only. No code modifications performed.*