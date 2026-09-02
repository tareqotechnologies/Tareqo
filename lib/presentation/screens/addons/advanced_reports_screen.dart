import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/share/advanced_reports_pdf_exporter.dart';
import '../../../core/theme/app_tokens.dart';
import '../../controllers/products_providers.dart';
import '../../widgets/app_button.dart';

/// Ecra de relatórios avançados — dashboards, filtros e exportação.
class AdvancedReportsScreen extends ConsumerStatefulWidget {
  const AdvancedReportsScreen({super.key});

  @override
  ConsumerState<AdvancedReportsScreen> createState() =>
      _AdvancedReportsScreenState();
}

class _AdvancedReportsScreenState extends ConsumerState<AdvancedReportsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String _selectedPeriod = 'Este Mês';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        titleSpacing: AppSpacing.lg,
        title: Text(
          'Relatórios Avançados',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w500,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          // Filtro de período
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: _PeriodChip(
              selected: _selectedPeriod,
              onChanged: (v) => setState(() => _selectedPeriod = v),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Vendas'),
            Tab(text: 'Financeiro'),
            Tab(text: 'Estoque'),
          ],
        ),
      ),        body: TabBarView(
        controller: _tabController,
        children: [
          _SalesReportTab(selectedPeriod: _selectedPeriod),
          _FinancialReportTab(selectedPeriod: _selectedPeriod),
          _StockReportTab(selectedPeriod: _selectedPeriod),
        ],
      ),
    );
  }
}

// ─── Vendas ─────────────────────────────────────────────────────────────

class _SalesReportTab extends ConsumerWidget {
  const _SalesReportTab({required this.selectedPeriod});

  final String selectedPeriod;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final products = ref.watch(productsProvider).value ?? [];
    final totalProducts = products.length;
    final totalStockValue = products.fold<int>(
        0, (sum, p) => sum + (p.stockQuantity ~/ 1000) * (p.salePriceCents ~/ 100));
    final lowStock = products.where((p) => (p.stockQuantity ~/ 1000) <= 10).length;
    final totalItems = products.fold<int>(0, (sum, p) => sum + (p.stockQuantity ~/ 1000));

    String formatMoney(int v) => '${v.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')},00 MT';

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                label: 'Produtos Ativos',
                value: '$totalProducts',
                icon: Icons.trending_up,
                color: const Color(0xFF16A34A),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _KpiCard(
                label: 'Estoque Baixo',
                value: '$lowStock',
                icon: Icons.warning_amber,
                color: const Color(0xFFF59E0B),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                label: 'Total Itens',
                value: '$totalItems',
                icon: Icons.shopping_cart_outlined,
                color: const Color(0xFF7C3AED),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _KpiCard(
                label: 'Valor Estoque',
                value: formatMoney(totalStockValue),
                icon: Icons.attach_money,
                color: const Color(0xFF3B82F6),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        // Top produtos por estoque
        Material(
          color: scheme.surfaceContainerLow,
          borderRadius: AppRadius.lgAll,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Produtos por Estoque',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (products.isEmpty)
                  Text(
                    'Sem produtos cadastrados',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  )
                else
                  ...products.take(5).map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            p.name,
                            style: theme.textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${p.stockQuantity ~/ 1000} ${p.unitLabel}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton.secondary(
          expanded: true,
          label: 'Exportar Relatório (PDF)',
          icon: const Icon(Icons.download_outlined, size: 18),
          onPressed: () => const AdvancedReportsPdfExporter().shareSalesReport(
            period: selectedPeriod,
            kpis: {
              'Produtos Ativos': '$totalProducts',
              'Estoque Baixo': '$lowStock',
              'Total Itens': '$totalItems',
              'Valor Estoque': formatMoney(totalStockValue),
            },
          ),
        ),
      ],
    );
  }
}

// ─── Financeiro ─────────────────────────────────────────────────────────

class _FinancialReportTab extends StatelessWidget {
  const _FinancialReportTab({required this.selectedPeriod});

  final String selectedPeriod;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                label: 'Receitas',
                value: '0,00 MT',
                icon: Icons.arrow_downward,
                color: const Color(0xFF16A34A),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _KpiCard(
                label: 'Despesas',
                value: '0,00 MT',
                icon: Icons.arrow_upward,
                color: const Color(0xFFDC2626),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        _KpiCard(
          label: 'Lucro Líquido',
          value: '0,00 MT',
          icon: Icons.account_balance_wallet_outlined,
          color: const Color(0xFF3B82F6),
          fullWidth: true,
        ),
        const SizedBox(height: AppSpacing.lg),
        Material(
          color: scheme.surfaceContainerLow,
          borderRadius: AppRadius.lgAll,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fluxo de Caixa',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: 160,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.show_chart,
                          size: 40,
                          color: scheme.onSurfaceVariant
                              .withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Gráfico de fluxo de caixa',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),        AppButton.secondary(
          expanded: true,
          label: 'Exportar Financeiro (PDF)',
          icon: const Icon(Icons.download_outlined, size: 18),
          onPressed: () => const AdvancedReportsPdfExporter().shareFinancialReport(
            period: selectedPeriod,
            kpis: {
              'Receitas': '0,00 MT',
              'Despesas': '0,00 MT',
              'Lucro Líquido': '0,00 MT',
            },
          ),
        ),
      ],
    );
  }
}




// ─── Estoque ────────────────────────────────────────────────────────────

class _StockReportTab extends ConsumerWidget {
  const _StockReportTab({required this.selectedPeriod});

  final String selectedPeriod;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final products = ref.watch(productsProvider).value ?? [];
    final totalProducts = products.length;
    final lowStock = products.where((p) => (p.stockQuantity ~/ 1000) <= 10).length;
    final totalStockValue = products.fold<int>(
        0, (sum, p) => sum + (p.stockQuantity ~/ 1000) * (p.salePriceCents ~/ 100));
    final outOfStock = products.where((p) => (p.stockQuantity ~/ 1000) == 0).length;

    String formatMoney(int v) => '${v.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')},00 MT';

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                label: 'Total Produtos',
                value: '$totalProducts',
                icon: Icons.inventory_2_outlined,
                color: const Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _KpiCard(
                label: 'Estoque Baixo',
                value: '$lowStock',
                icon: Icons.warning_amber,
                color: const Color(0xFFF59E0B),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                label: 'Valor em Estoque',
                value: formatMoney(totalStockValue),
                icon: Icons.attach_money,
                color: const Color(0xFF7C3AED),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _KpiCard(
                label: 'Sem Estoque',
                value: '$outOfStock',
                icon: Icons.event_busy,
                color: const Color(0xFFDC2626),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        // Lista de produtos com estoque baixo
        Material(
          color: scheme.surfaceContainerLow,
          borderRadius: AppRadius.lgAll,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Produtos com Estoque Baixo',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (lowStock == 0)
                  Text(
                    'Todos os produtos com estoque adequado',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  )
                else
                  ...products
                      .where((p) => (p.stockQuantity ~/ 1000) <= 10)
                      .take(5)
                      .map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber, size: 14, color: const Color(0xFFF59E0B)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            p.name,
                            style: theme.textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${p.stockQuantity ~/ 1000} ${p.unitLabel}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFFF59E0B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton.secondary(
          expanded: true,
          label: 'Exportar Estoque (PDF)',
          icon: const Icon(Icons.download_outlined, size: 18),
          onPressed: () => const AdvancedReportsPdfExporter().shareStockReport(
            period: selectedPeriod,
            kpis: {
              'Total Produtos': '$totalProducts',
              'Estoque Baixo': '$lowStock',
              'Valor em Estoque': formatMoney(totalStockValue),
              'Sem Estoque': '$outOfStock',
            },
          ),
        ),
      ],
    );
  }
}




// ─── Componentes compartilhados ─────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.fullWidth = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: AppRadius.lgAll,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final periods = ['Hoje', 'Esta Semana', 'Este Mês', 'Este Ano'];

    return PopupMenuButton<String>(
      onSelected: onChanged,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selected,
              style: theme.textTheme.labelMedium,
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
      itemBuilder: (ctx) => periods
          .map(
            (p) => PopupMenuItem(
              value: p,
              child: Text(p),
            ),
          )
          .toList(),
    );
  }
}
