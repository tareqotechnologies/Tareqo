import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../widgets/pulse_badge.dart';
import '../../../domain/entities/financial_transaction.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/fade_indexed_stack.dart';
import '../../widgets/store_scoped_content.dart';
import '../credit/add_debt_sheet.dart';
import '../credit/debts_screen.dart';
import '../customers/customers_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../dashboard/notifications_screen.dart';
import '../financial/add_transaction_sheet.dart';
import '../financial/financial_screen.dart';
import '../../controllers/customers_providers.dart';
import '../../controllers/dashboard_providers.dart';
import '../../controllers/addon_expiry_provider.dart';
import '../../controllers/notification_providers.dart';
import '../../controllers/products_providers.dart';
import '../products/product_form_sheets.dart';
import '../products/product_list_screen.dart';
import '../sales/new_sale_sheet.dart';
import '../sales/sales_screen.dart';
import 'menu_screen.dart';

/// Seções principais do ERP, na ordem da navegação.
enum AppSection {
  dashboard,
  sales,
  financial,
  menu,
  products,
  credit,
  customers,
}

/// Índice da seção ativa — permite que qualquer tela troque de aba
/// programaticamente.
final shellIndexProvider = NotifierProvider<ShellIndexNotifier, int>(
  ShellIndexNotifier.new,
);

class ShellIndexNotifier extends Notifier<int> {
  @override
  int build() => AppSection.dashboard.index;

  void goTo(AppSection section) => state = section.index;
}

/// Casca de navegação V4 — rail em telas largas, barra inferior em mobile,
/// FAB central para acções rápidas e transições suaves entre abas.
class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  static const List<Widget> _sections = [
    DashboardScreen(),
    SalesScreen(),
    FinancialScreen(),
    MenuScreen(),
    ProductListScreen(),
    DebtsScreen(),
    CustomersScreen(),
  ];

  /// As 4 abas da barra/rail, na ordem de [AppSection]: Home, Vendas,
  /// Financeiro, Menu. As seções acessadas pelo Menu (Produtos, Crédito,
  /// Clientes) NÃO têm destino próprio — o destaque cai no Menu (o hub que
  /// as abriga), e o índice nunca estoura o tamanho da barra.
  static const int _tabCount = 4;

  /// Índice de seção → índice da barra: seções 0..3 mapeiam direto; as
  /// demais (>= 4) destacam a aba Menu (índice 3).
  static int _barIndex(int sectionIndex) =>
      sectionIndex < _tabCount ? sectionIndex : AppSection.menu.index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(shellIndexProvider);
    final wide =
        MediaQuery.sizeOf(context).width >=
        880; // Trigger add-on expiry check when tenant is known.
    ref.watch(addonExpiryCheckProvider);

    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final destinations = [
      (Icons.home_outlined, Icons.home_rounded, l10n.appNavHome),
      (Icons.receipt_long_outlined, Icons.receipt_long, l10n.appNavSales),
      (
        Icons.account_balance_wallet_outlined,
        Icons.account_balance_wallet,
        l10n.appNavWallet,
      ),
      (Icons.grid_view_outlined, Icons.grid_view_rounded, l10n.appNavMenu),
    ];

    void onSelect(int value) =>
        ref.read(shellIndexProvider.notifier).goTo(AppSection.values[value]);

    void openActionMenu() {
      showAppSheet<void>(context, builder: (_) => const _ActionMenuSheet());
    }

    final content = StoreScopedContent(
      child: FadeIndexedStack(index: index, children: _sections),
    ); // Contagem de notificações não lidas para o badge.
    final unreadCount = ref.watch(unreadNotificationsCountProvider).value ?? 0;

    // Hierarquia de voltar: em qualquer seção ≠ Home, o botão voltar do
    // sistema devolve ao Dashboard em vez de fechar o app (o Menu abre
    // Produtos/Crédito/Clientes no IndexedStack — sem rota para pop). Na
    // Home o comportamento nativo é preservado (voltar fecha o app).
    final atHome = index == AppSection.dashboard.index;

    return PopScope<Object?>(
      canPop: atHome,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        ref.read(shellIndexProvider.notifier).goTo(AppSection.dashboard);
      },
      child: Scaffold(
      appBar: AppBar(
        toolbarHeight: 48,
        title: Text(
          'TAREQO',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        titleSpacing: 16,
        actions: [
          // Badge de notificações com pulso
          PulseBadge(
            count: unreadCount,
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined, size: 20),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const NotificationsScreen(),
                  ),
                );
              },
              tooltip: l10n.notificationTitle,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: wide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _barIndex(index),
                  onDestinationSelected: onSelect,
                  labelType: NavigationRailLabelType.all,
                  leading: const Padding(
                    padding: EdgeInsets.only(
                      top: AppSpacing.md,
                      bottom: AppSpacing.sm,
                    ),
                  ),
                  destinations: [
                    for (final (icon, selected, label) in destinations)
                      NavigationRailDestination(
                        icon: Icon(icon),
                        selectedIcon: Icon(selected),
                        label: _NavLabel(text: label),
                      ),
                  ],
                ),
                VerticalDivider(width: 1, color: scheme.outlineVariant),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppSizes.contentMaxWidth,
                      ),
                      child: content,
                    ),
                  ),
                ),
              ],
            )
          : content,
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _barIndex(index),
              onDestinationSelected: onSelect,
              destinations: [
                for (final (icon, selected, label) in destinations)
                  NavigationDestination(
                    icon: Icon(icon),
                    selectedIcon: Icon(selected),
                    label: label,
                  ),
              ],
            ),
      // Seções que já trazem o seu próprio FAB: ocultamos o FAB do shell
      // para evitar duplicação visual (Sales, Financial, Products, Customers).
      floatingActionButton: _hasOwnFab(index)
          ? null
          : FloatingActionButton(
              heroTag: 'fab-shell',
              onPressed: openActionMenu,
              tooltip: l10n.fabMenuTitle,
              child: const Icon(Icons.add_rounded, size: 28),
            ),
      ),
    );
  }
}

/// Seções que trazem o seu próprio FAB — o shell não adiciona um
/// segundo para evitar duplicação visual.
bool _hasOwnFab(int sectionIndex) {
  const ownFabSections = {
    AppSection.sales,
    AppSection.financial,
    AppSection.products,
    AppSection.customers,
  };
  return ownFabSections.contains(AppSection.values[sectionIndex]);
}

/// Menu global de acções (FAB central).
class _ActionMenuSheet extends ConsumerWidget {
  const _ActionMenuSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    Future<void> close() async => Navigator.of(context).pop();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(title: l10n.fabMenuTitle),
          Text(l10n.fabMenuSubtitle, style: theme.textTheme.bodySmall),
          const SizedBox(height: AppSpacing.md),
          _ActionTile(
            icon: Icons.add_shopping_cart_rounded,
            title: l10n.fabMenuNewSale,
            hint: l10n.fabMenuNewSaleHint,
            color: theme.accent,
            onTap: () {
              close();
              showAppSheet<void>(
                context,
                builder: (_) => const NewSaleSheet(),
                fullscreen: true,
              );
            },
          ),
          _ActionTile(
            icon: Icons.remove_circle_outline_rounded,
            title: l10n.fabMenuExpense,
            hint: l10n.fabMenuExpenseHint,
            color: theme.expense,
            onTap: () {
              close();
              showAppSheet<void>(
                context,
                builder: (_) => const AddTransactionSheet(
                  initialType: TransactionType.expense,
                ),
              );
            },
          ),
          _ActionTile(
            icon: Icons.inventory_2_outlined,
            title: l10n.fabMenuAddProduct,
            hint: l10n.fabMenuAddProductHint,
            color: theme.colorScheme.onSurface,
            onTap: () async {
              close();
              await showAppSheet<void>(
                context,
                builder: (_) => const AddProductSheet(),
              );
              ref.invalidate(productsProvider);
              ref.invalidate(dashboardKpisProvider);
            },
          ),
          _ActionTile(
            icon: Icons.person_add_alt_1_outlined,
            title: l10n.fabMenuAddCustomer,
            hint: l10n.fabMenuAddCustomerHint,
            color: theme.colorScheme.primary,
            onTap: () async {
              close();
              await showAppSheet<void>(
                context,
                builder: (_) => const AddCustomerSheet(),
              );
              ref.invalidate(customersProvider);
            },
          ),
          _ActionTile(
            icon: Icons.credit_card_outlined,
            title: l10n.fabMenuAddDebt,
            hint: l10n.fabMenuAddDebtHint,
            color: theme.warning,
            onTap: () {
              close();
              showAppSheet<void>(context, builder: (_) => const AddDebtSheet());
            },
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(onPressed: close, child: Text(l10n.fabMenuCancel)),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.hint,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String hint;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: AppRadius.lgAll,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: AppSizes.avatarSm,
                  height: AppSizes.avatarSm,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: IconTone.darkBackground(color),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: IconTone.lightForeground(color),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleSmall),
                      const SizedBox(height: 2),
                      Text(hint, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavLabel extends StatelessWidget {
  const _NavLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return FittedBox(fit: BoxFit.scaleDown, child: Text(text, maxLines: 1));
  }
}
