import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../widgets/store_scoped_content.dart';
import '../credit/debts_screen.dart';
import '../customers/customers_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../financial/financial_screen.dart';
import '../products/product_list_screen.dart';
import '../sales/sales_screen.dart';

/// Seções principais do ERP, na ordem da navegação.
enum AppSection { dashboard, products, sales, financial, credit, customers }

/// Índice da seção ativa — permite que qualquer tela (ex.: ações rápidas
/// do dashboard) troque de aba programaticamente.
final shellIndexProvider = NotifierProvider<ShellIndexNotifier, int>(
  ShellIndexNotifier.new,
);

class ShellIndexNotifier extends Notifier<int> {
  @override
  int build() => AppSection.dashboard.index;

  void goTo(AppSection section) => state = section.index;
}

/// Casca de navegação adaptativa: `NavigationRail` em telas largas
/// (web/desktop) e `NavigationBar` em telas estreitas (mobile).
///
/// As seções ficam num [IndexedStack] — cada aba preserva seu estado
/// (busca, scroll, formulários abertos).
class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  static const List<Widget> _sections = [
    DashboardScreen(),
    ProductListScreen(),
    SalesScreen(),
    FinancialScreen(),
    DebtsScreen(),
    CustomersScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(shellIndexProvider);
    final wide = MediaQuery.sizeOf(context).width >= 880;
    final l10n = context.l10n;

    final destinations = [
      (Icons.space_dashboard_outlined, Icons.space_dashboard, l10n.appNavHome),
      (Icons.inventory_2_outlined, Icons.inventory_2, l10n.appNavProducts),
      (Icons.point_of_sale_outlined, Icons.point_of_sale, l10n.appNavSales),
      (
        Icons.account_balance_wallet_outlined,
        Icons.account_balance_wallet,
        l10n.appNavFinancial,
      ),
      (Icons.receipt_long_outlined, Icons.receipt_long, l10n.appNavCredit),
      (Icons.people_outline, Icons.people, l10n.appNavCustomers),
    ];

    void onSelect(int value) =>
        ref.read(shellIndexProvider.notifier).goTo(AppSection.values[value]);

    // Seletor de loja ativa no topo de TODAS as telas (Fase 2 do
    // multi-tenancy): com mais de uma loja, o usuário troca a loja ativa
    // e todos os módulos (produtos, vendas, financeiro, fiado, clientes,
    // compras) reagem escopando pelos dados da loja selecionada.
    final content = StoreScopedContent(
      child: IndexedStack(index: index, children: _sections),
    );

    return Scaffold(
      body: wide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: index,
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
                // O NavigationRail já desenha a própria divisória à direita.
                // O conteúdo é centralizado com largura máxima: em monitores
                // largos (web/desktop) as telas não se esticam até a borda,
                // mantendo a leitura e a hierarquia visuais confortáveis.
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1040),
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
              selectedIndex: index,
              onDestinationSelected: onSelect,
              destinations: [
                for (final (icon, selected, label) in destinations)
                  // O label do NavigationBar é String e recebe o
                  // labelTextStyle compacto do tema (uma linha em telas
                  // estreitas — ver app_theme.dart).
                  NavigationDestination(
                    icon: Icon(icon),
                    selectedIcon: Icon(selected),
                    label: label,
                  ),
              ],
            ),
    );
  }
}

/// Rótulo de aba em uma ÚNICA linha: o [FittedBox] encolhe o texto em telas
/// estreitas em vez de quebrar (ex.: 'Customers' ocupava duas linhas no
/// NavigationBar mobile). A navegação em si não muda.
class _NavLabel extends StatelessWidget {
  const _NavLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(text, maxLines: 1),
    );
  }
}
