import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
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
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.reportsAdvancedTitle,
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
          tabs: [
            Tab(text: l10n.reportsTabSales),
            Tab(text: l10n.reportsTabFinancial),
            Tab(text: l10n.reportsTabStock),
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
    final l10n = context.l10n;
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
                label: l10n.reportsKpiProducts,
                value: '$totalProducts',
                icon: Icons.inventory_2_outlined,
                color: ModuleColors.products,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _KpiTile(
                label: l10n.reportsKpiLowStock,
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
                label: l10n.reportsKpiTotalItems,
                value: Formatters.compact(totalItems),
                icon: Icons.shopping_cart_outlined,
                color: ModuleColors.purchases,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _KpiTile(
                label: l10n.reportsKpiStockValue,
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
                      l10n.reportsStockByQty,
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
                  l10n.reportsNoProducts,
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
          label: l10n.reportsExportSales,
          icon: const Icon(Icons.download_outlined, size: 18),
          onPressed: () =>
              const AdvancedReportsPdfExporter().shareSalesReport(
            title: context.l10n.reportsTabSales,
            period: selectedPeriod,
            businessName: l10n.businessFallbackName,
            generatedOnLabel: context.l10n.pdfGeneratedOn('{date}'),
            indicatorsLabel: context.l10n.pdfIndicators,
            noDataLabel: context.l10n.reportsNoSalesData,
            footerLabel: context.l10n.pdfFooter('{date}'),
            kpis: {
              l10n.reportsKpiProducts: '$totalProducts',
              l10n.reportsKpiLowStock: '$lowStock',
              l10n.reportsKpiTotalItems: '$totalItems',
              l10n.reportsKpiStockValue:
                  Formatters.currency(totalStockValue * 100),
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
    final l10n = context.l10n;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // KPIs
        Row(
          children: [
            Expanded(
              child: _KpiTile(
                label: l10n.reportsKpiRevenue,
                value: Formatters.currency(0),
                icon: Icons.arrow_downward_rounded,
                color: IconTone.green,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _KpiTile(
                label: l10n.reportsKpiExpenses,
                value: Formatters.currency(0),
                icon: Icons.arrow_upward_rounded,
                color: IconTone.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        _KpiTile(
          label: l10n.reportsKpiNetProfit,
          value: Formatters.currency(0),
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
                    l10n.reportsCashFlow,
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
                        l10n.reportsCashFlowChart,
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
          label: l10n.reportsExportFinancial,
          icon: const Icon(Icons.download_outlined, size: 18),
          onPressed: () =>
              const AdvancedReportsPdfExporter().shareFinancialReport(
            title: context.l10n.reportsTabFinancial,
            period: selectedPeriod,
            businessName: l10n.businessFallbackName,
            generatedOnLabel: context.l10n.pdfGeneratedOn('{date}'),
            indicatorsLabel: context.l10n.pdfIndicators,
            noDataLabel: context.l10n.reportsNoSalesData,
            footerLabel: context.l10n.pdfFooter('{date}'),
            kpis: {
              l10n.reportsKpiRevenue: Formatters.currency(0),
              l10n.reportsKpiExpenses: Formatters.currency(0),
              l10n.reportsKpiNetProfit: Formatters.currency(0),
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
    final l10n = context.l10n;
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
                label: l10n.reportsKpiProducts,
                value: '$totalProducts',
                icon: Icons.inventory_2_outlined,
                color: ModuleColors.products,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _KpiTile(
                label: l10n.reportsKpiLowStock,
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
                label: l10n.reportsKpiStockValue,
                value: Formatters.currency(totalStockValue * 100),
                icon: Icons.attach_money,
                color: ModuleColors.purchases,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _KpiTile(
                label: l10n.reportsKpiStockOut,
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
                      l10n.reportsKpiLowStock,
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
                  l10n.reportsStockHealthy,
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
          label: l10n.reportsExportStock,
          icon: const Icon(Icons.download_outlined, size: 18),
          onPressed: () =>
              const AdvancedReportsPdfExporter().shareStockReport(
            title: context.l10n.reportsTabStock,
            period: selectedPeriod,
            businessName: l10n.businessFallbackName,
            generatedOnLabel: context.l10n.pdfGeneratedOn('{date}'),
            indicatorsLabel: context.l10n.pdfIndicators,
            noDataLabel: context.l10n.reportsNoSalesData,
            footerLabel: context.l10n.pdfFooter('{date}'),
            kpis: {
              l10n.reportsKpiTotalProducts: '$totalProducts',
              l10n.reportsKpiLowStock: '$lowStock',
              l10n.reportsKpiStockValue:
                  Formatters.currency(totalStockValue * 100),
              l10n.reportsKpiStockOut: '$outOfStock',
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
    final l10n = context.l10n;
    final periods = <String, String>{
      'Hoje': l10n.periodToday,
      'Esta Semana': l10n.periodWeek,
      'Este Mês': l10n.periodMonth,
      'Este Ano': l10n.reportsPeriodYear,
    };

    return PopupMenuButton<String>(
      onSelected: onChanged,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              periods[selected] ?? selected,
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
      itemBuilder: (ctx) => periods.entries
          .map(
            (entry) => CheckedPopupMenuItem(
              value: entry.key,
              checked: entry.key == selected,
              child: Text(entry.value),
            ),
          )
          .toList(),
    );
  }
}
