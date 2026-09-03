import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/share/advanced_reports_pdf_exporter.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../controllers/products_providers.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';

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
      ),
      body: TabBarView(
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
      0,
      (sum, p) =>
          sum + (p.stockQuantity ~/ 1000) * (p.salePriceCents ~/ 100),
    );
    final lowStock =
        products.where((p) => (p.stockQuantity ~/ 1000) <= 10).length;
    final totalItems =
        products.fold<int>(0, (sum, p) => sum + (p.stockQuantity ~/ 1000));

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // KPIs
        Row(
          children: [
            Expanded(
              child: _KpiTile(
                label: 'Produtos',
                value: '$totalProducts',
                icon: Icons.inventory_2_outlined,
                color: ModuleColors.products,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _KpiTile(
                label: 'Estoque Baixo',
                value: '$lowStock',
                icon: Icons.warning_amber_rounded,
                color: ModuleColors.credit,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: _KpiTile(
                label: 'Total Itens',
                value: Formatters.compact(totalItems),
                icon: Icons.shopping_cart_outlined,
                color: ModuleColors.purchases,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _KpiTile(
                label: 'Valor Estoque',
                value: Formatters.currency(totalStockValue * 100),
                icon: Icons.attach_money,
                color: ModuleColors.reports,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // Top produtos
        AppCard(
          elevated: true,
          borderRadius: const BorderRadius.all(Radius.circular(18)),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: IconTone.darkBackground(ModuleColors.products),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.leaderboard_outlined,
                      size: 14,
                      color: IconTone.lightForeground(ModuleColors.products),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Produtos por Estoque',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      '${products.length}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
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
                for (final p in products.take(5)) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: p.stockQuantity ~/ 1000 <= 10
                                ? ModuleColors.credit
                                : ModuleColors.products,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            p.name,
                            style: theme.textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${p.stockQuantity ~/ 1000} ${p.unitLabel}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                            fontFeatures: const [
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton.secondary(
          expanded: true,
          label: 'Exportar Relatório (PDF)',
          icon: const Icon(Icons.download_outlined, size: 18),
          onPressed: () =>
              const AdvancedReportsPdfExporter().shareSalesReport(
            period: selectedPeriod,
            kpis: {
              'Produtos Ativos': '$totalProducts',
              'Estoque Baixo': '$lowStock',
              'Total Itens': '$totalItems',
              'Valor Estoque': Formatters.currency(totalStockValue * 100),
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
        // KPIs
        Row(
          children: [
            Expanded(
              child: _KpiTile(
                label: 'Receitas',
                value: '0,00',
                icon: Icons.arrow_downward_rounded,
                color: IconTone.green,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _KpiTile(
                label: 'Despesas',
                value: '0,00',
                icon: Icons.arrow_upward_rounded,
                color: IconTone.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        _KpiTile(
          label: 'Lucro Líquido',
          value: '0,00',
          icon: Icons.account_balance_wallet_outlined,
          color: ModuleColors.reports,
          fullWidth: true,
        ),
        const SizedBox(height: AppSpacing.lg),

        // Gráfico placeholder
        AppCard(
          elevated: true,
          borderRadius: const BorderRadius.all(Radius.circular(18)),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: IconTone.darkBackground(ModuleColors.reports),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.show_chart_rounded,
                      size: 14,
                      color:
                          IconTone.lightForeground(ModuleColors.reports),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Fluxo de Caixa',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 140,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.show_chart,
                        size: 32,
                        color: scheme.onSurfaceVariant
                            .withValues(alpha: 0.25),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Gráfico de fluxo de caixa',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton.secondary(
          expanded: true,
          label: 'Exportar Financeiro (PDF)',
          icon: const Icon(Icons.download_outlined, size: 18),
          onPressed: () =>
              const AdvancedReportsPdfExporter().shareFinancialReport(
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
    final lowStock =
        products.where((p) => (p.stockQuantity ~/ 1000) <= 10).length;
    final totalStockValue = products.fold<int>(
      0,
      (sum, p) =>
          sum + (p.stockQuantity ~/ 1000) * (p.salePriceCents ~/ 100),
    );
    final outOfStock =
        products.where((p) => (p.stockQuantity ~/ 1000) == 0).length;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // KPIs
        Row(
          children: [
            Expanded(
              child: _KpiTile(
                label: 'Produtos',
                value: '$totalProducts',
                icon: Icons.inventory_2_outlined,
                color: ModuleColors.products,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _KpiTile(
                label: 'Estoque Baixo',
                value: '$lowStock',
                icon: Icons.warning_amber_rounded,
                color: ModuleColors.credit,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: _KpiTile(
                label: 'Valor em Estoque',
                value: Formatters.currency(totalStockValue * 100),
                icon: Icons.attach_money,
                color: ModuleColors.purchases,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _KpiTile(
                label: 'Sem Estoque',
                value: '$outOfStock',
                icon: Icons.inventory_2,
                color: IconTone.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // Lista de estoque baixo
        AppCard(
          elevated: true,
          borderRadius: const BorderRadius.all(Radius.circular(18)),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: IconTone.darkBackground(ModuleColors.credit),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      size: 14,
                      color:
                          IconTone.lightForeground(ModuleColors.credit),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Estoque Baixo',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (lowStock > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: ModuleColors.credit.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        '$lowStock',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: ModuleColors.credit,
                          fontWeight: FontWeight.w500,
                          fontFeatures: const [
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (lowStock == 0)
                Text(
                  'Todos os produtos com estoque adequado',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                )
              else
                for (final p in products
                    .where((p) => (p.stockQuantity ~/ 1000) <= 10)
                    .take(5)) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 6,
                          color: ModuleColors.credit,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            p.name,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${p.stockQuantity ~/ 1000} ${p.unitLabel}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: ModuleColors.credit,
                            fontWeight: FontWeight.w500,
                            fontFeatures: const [
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton.secondary(
          expanded: true,
          label: 'Exportar Estoque (PDF)',
          icon: const Icon(Icons.download_outlined, size: 18),
          onPressed: () =>
              const AdvancedReportsPdfExporter().shareStockReport(
            period: selectedPeriod,
            kpis: {
              'Total Produtos': '$totalProducts',
              'Estoque Baixo': '$lowStock',
              'Valor em Estoque':
                  Formatters.currency(totalStockValue * 100),
              'Sem Estoque': '$outOfStock',
            },
          ),
        ),
      ],
    );
  }
}

// ─── Componentes compartilhados ─────────────────────────────────────────

/// KPI tile compacto — ícone tingido (IconTone) + label + valor.
///
/// Segue o padrão do dashboard: fundo `surfaceContainerHighest`,
/// ícone em container circular escuro, label em `bodySmall`,
/// valor em `labelMedium` com cor do módulo.
class _KpiTile extends StatelessWidget {
  const _KpiTile({
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
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: AppRadius.lgAll,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: IconTone.darkBackground(color),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 14,
                color: IconTone.lightForeground(color),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    value,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: color,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chip de período minimalista — mesmo padrão do dashboard.
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selected,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
      itemBuilder: (ctx) => periods
          .map(
            (p) => CheckedPopupMenuItem(
              value: p,
              checked: p == selected,
              child: Text(p),
            ),
          )
          .toList(),
    );
  }
}
