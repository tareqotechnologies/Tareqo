import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../widgets/pulse_badge.dart';
import '../../../domain/entities/financial_transaction.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/premium_decor.dart';
import '../../widgets/fade_indexed_stack.dart';
import '../../widgets/store_scoped_content.dart';
import '../../widgets/sync_pending_banner.dart';
import '../credit/add_debt_sheet.dart';
import '../credit/debts_screen.dart';
import '../customers/customers_screen.dart';
import '../dashboard/dashboard_screen.dart';
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
import '../../navigation/app_routes.dart';
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

  /// Seções que vivem dentro do hub Menu (U-08): a barra destaca Menu,
  /// mas a AppBar mostra a secção real para o utilizador saber onde está.
  static bool _isMenuSubsection(int sectionIndex) => sectionIndex >= _tabCount;

  static String _subsectionLabel(AppLocalizations l10n, int sectionIndex) {
    return switch (AppSection.values[sectionIndex]) {
      AppSection.products => l10n.appNavProducts,
      AppSection.credit => l10n.appNavCredit,
      AppSection.customers => l10n.appNavCustomers,
      _ => l10n.appNavMenu,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(shellIndexProvider);
    // Rail persistente a partir do corte de sidebar (token único — o mesmo
    // 880 usado pelo shell do admin). Below it, barra inferior + FAB.
    final wide = MediaQuery.sizeOf(context).width >= AppBreakpoints.sidebarRail;
    // Trigger add-on expiry check when tenant is known.
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

    final isSubsection = _isMenuSubsection(index);
    final sectionLabel = isSubsection ? _subsectionLabel(l10n, index) : null;

    // Pendências do outbox offline ACIMA das seções: estado global do
    // caminho de dinheiro (vendas/movimentações/fiado enfileirados sem
    // conexão), visível em todas as abas — não só no Dashboard.
    final content = Column(
      children: [
        const SyncPendingBanner(),
        Expanded(
          child: StoreScopedContent(
            child: FadeIndexedStack(index: index, children: _sections),
          ),
        ),
      ],
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
          // Altura do tema (U-15) — sem override local de 52.
          // Marca: monograma em gradiente + wordmark espaçado.
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    // Marca sólida na cor de ação oficial — sem gradiente e
                    // sem brilho (anti-padrões do design system).
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    'T',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.onPrimary,
                      fontWeight: FontWeight.w600,
                      height: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Marca + secção numa ÚNICA linha ("TAREQO · Produtos"):
              // a AppBar tem 56 dp fixos e uma coluna de dois textos
              // estouraria com escala de texto 2.0. Nas subsecções do Menu
              // o utilizador continua a saber onde está.
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'TAREQO',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.6,
                      ),
                    ),
                    if (sectionLabel != null) ...[
                      Text(
                        ' · ',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          sectionLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          titleSpacing: AppSpacing.md,
          actions: [
            // Badge de notificações com pulso
            PulseBadge(
              count: unreadCount,
              child: IconButton(
                icon: const Icon(Icons.notifications_outlined, size: 20),
                onPressed: () =>
                    AppNavigator.push(context, AppRoutes.notifications),
                tooltip: l10n.notificationTitle,
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: wide
            ? Row(
                children: [
                  // SafeArea só no fundo: em paisagem o gesto do sistema
                  // deixaria a base do rail sem superfície; o ColoredBox
                  // mantém o fundo contínuo até à borda do ecrã.
                  ColoredBox(
                    color: scheme.surface,
                    child: SafeArea(
                      top: false,
                      child: NavigationRail(
                        selectedIndex: _barIndex(index),
                        onDestinationSelected: onSelect,
                        labelType: NavigationRailLabelType.all,
                        destinations: [
                          for (final (icon, selected, label) in destinations)
                            NavigationRailDestination(
                              icon: Icon(icon),
                              selectedIcon: Icon(selected),
                              label: _NavLabel(text: label),
                            ),
                        ],
                      ),
                    ),
                  ),
                  VerticalDivider(
                    width: 1,
                    color: PremiumDecor.hairline(scheme),
                  ),
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
        // Barra inferior flutuante (cápsula): mesma NavigationBar e mesmos
        // destinos — só o invólucro muda (margem, raio 28, borda de cabelo
        // e sombra neutra). O SafeArea fica POR FORA para a área segura do
        // sistema não ser somada dentro da cápsula.
        bottomNavigationBar: wide
            ? null
            : SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.xxs,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: AppRadius.xxlAll,
                      border: Border.all(color: PremiumDecor.hairline(scheme)),
                      // Sombra que sobe do fundo do ecrã (a barra é uma
                      // superfície elevada sobre o conteúdo, não um cartão).
                      boxShadow: PremiumDecor.upwardShadow(scheme),
                    ),
                    child: ClipRRect(
                      borderRadius: AppRadius.xxlAll,
                      child: NavigationBar(
                        // Altura do tema (U-16) — sem override de 70.
                        height: AppSizes.navBarHeight,
                        backgroundColor: Colors.transparent,
                        surfaceTintColor: Colors.transparent,
                        elevation: 0,
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
                    ),
                  ),
                ),
              ),
        // Seções que já trazem o seu próprio FAB: ocultamos o FAB do shell
        // para evitar duplicação visual (Sales, Financial, Products, Customers).
        // Na seção Crédito, o FAB pula o menu e abre DIRETO o "Registrar
        // fiado" (AddDebtSheet) — é a única ação que faz sentido ali.
        floatingActionButton: _hasOwnFab(index)
            ? null
            : FloatingActionButton(
                heroTag: 'fab-shell',
                onPressed: AppSection.values[index] == AppSection.credit
                    ? () => showAppSheet<void>(
                        context,
                        builder: (_) => const AddDebtSheet(),
                      )
                    : openActionMenu,
                tooltip: AppSection.values[index] == AppSection.credit
                    ? l10n.debtsAddDebt
                    : l10n.fabMenuTitle,
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
          Text(
            l10n.fabMenuSubtitle,
            style: AppTypography.bodySmall.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
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
          AppButton.secondary(onPressed: close, label: l10n.fabMenuCancel),
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
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Material(
        color: Color.alphaBlend(
          scheme.surfaceContainerHighest.withValues(alpha: 0.55),
          scheme.surface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
          side: BorderSide(color: PremiumDecor.hairline(scheme)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          // A11y (U-19): tile custom anuncia "botão" + título/hint num ÚNICO
          // nó — excludeSemantics evita repetir os textos do filho.
          child: Semantics(
            button: true,
            excludeSemantics: true,
            label: title,
            hint: hint,
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
                      border: Border.all(color: color.withValues(alpha: 0.25)),
                    ),
                    child: Icon(
                      icon,
                      size: AppSizes.iconMd,
                      color: IconTone.lightForeground(color),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTypography.labelLarge.copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.micro),
                        Text(
                          hint,
                          style: AppTypography.bodySmall.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: AppSizes.iconMd,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
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
