import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../domain/entities/store.dart';
import '../../../core/share/advanced_reports_pdf_exporter.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/quantity.dart';
import '../../../domain/usecases/get_cash_flow_use_case.dart';
import '../../../domain/usecases/get_sales_report_use_case.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../controllers/account_providers.dart';
import '../../controllers/auth_providers.dart';
import '../../controllers/finance_providers.dart';
import '../../controllers/products_providers.dart';
import '../../controllers/reports_providers.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_menu_option.dart';

/// Fluxo de caixa REAL do período seleccionado (entradas/saídas pagas),
/// via [GetCashFlowUseCase] — o tab financeiro usava zeros fixos antes.
final advancedReportCashFlowProvider =
    FutureProvider.family<CashFlow, (String, String)>((ref, key) {
      final (storeId, periodKey) = key;
      final (start, end) = _periodRange(periodKey, DateTime.now());
      return ref
          .watch(getCashFlowUseCaseProvider)
          .call(storeId: storeId, start: start, end: end);
    });

/// Relatório de VENDAS do período (faturamento, lucro bruto, top 5) — via
/// [GetSalesReportUseCase] (RPC `get_sales_report` no modo Supabase).
final advancedSalesReportProvider =
    FutureProvider.family<SalesReport, (String, String)>((ref, key) {
      final (storeId, periodKey) = key;
      final (start, end) = _periodRange(periodKey, DateTime.now());
      return ref
          .watch(getSalesReportUseCaseProvider)
          .call(storeId: storeId, start: start, end: end);
    });

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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        // Título em bodyLarge (17/w400) — o AppBar de 56px com o chip de
        // período à direita truncava até o título 3 (20) em
        // 'Relatórios Avançad…' em telas estreitas; 17px cabe com folga
        // e mantém a hierarquia (o chip de período é o elemento primário).
        title: Text(
          l10n.reportsAdvancedTitle,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
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

/// Nome do negócio para PDFs de relatórios: LOJA REAL primeiro, fallback
/// localizado só quando não há loja/tenant (nunca "My Business" fixo).
String? _activeStoreName(WidgetRef ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return null;
  final tenant = ref.watch(myTenantProvider(user.id)).value;
  if (tenant == null) return null;
  final stores = ref.watch(storesProvider(tenant.id)).value ?? const <Store>[];
  if (stores.isEmpty) return null;
  final storeId = ref.watch(activeStoreIdProvider(user.id));
  return stores.where((s) => s.id == storeId).firstOrNull?.name ??
      stores.first.name;
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

    final user = ref.watch(authStateProvider).value;
    final storeId = user == null
        ? null
        : ref.watch(activeStoreIdProvider(user.id));
    final reportAsync = storeId == null
        ? null
        : ref.watch(advancedSalesReportProvider((storeId, selectedPeriod)));
    final report = reportAsync?.value;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // Erro real (rede/banco) com retry — nunca silencia falha (mesmo
        // padrão do tab Financeiro).
        if (storeId != null && (reportAsync?.hasError ?? false))
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                Icon(Icons.error_outline, size: 16, color: scheme.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.reportsLoadError,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.error,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => ref.invalidate(
                    advancedSalesReportProvider((storeId, selectedPeriod)),
                  ),
                  child: Text(l10n.commonRetry),
                ),
              ],
            ),
          ),
        // Loading real enquanto o servidor agrega as vendas.
        if (reportAsync?.isLoading ?? false)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        // KPIs de VENDAS do período (reais — RPC get_sales_report, em
        // centavos). A aba mostrava KPIs de ESTOQUE (duplicados com o tab
        // Estoque) — o operador abria "Vendas" e via inventário.
        Row(
          children: [
            Expanded(
              child: _KpiTile(
                label: l10n.reportsRevenue,
                value: report != null
                    ? Formatters.currency(report.totalRevenueCents)
                    : '—',
                icon: Icons.arrow_downward_rounded,
                color: IconTone.green,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _KpiTile(
                label: l10n.reportsProfit,
                value: report != null
                    ? Formatters.currency(report.totalProfitCents)
                    : '—',
                icon: Icons.savings_outlined,
                color: ModuleColors.products,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        _KpiTile(
          label: l10n.reportsMargin,
          value: report != null ? '${report.margin.toStringAsFixed(1)}%' : '—',
          icon: Icons.percent_rounded,
          color: ModuleColors.reports,
          fullWidth: true,
        ),
        const SizedBox(height: AppSpacing.lg),

        // Mais vendidos do período (top 5 por quantidade) — mesmo padrão
        // visual da tela de Relatórios (_BestSellerRow simplificado).
        AppCard(
          elevated: true,
          borderRadius: const BorderRadius.all(Radius.circular(AppRadius.lg)),
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
                      l10n.reportsBestSellers,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (report != null && report.bestSellers.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        '${report.bestSellers.length}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (report == null)
                const SizedBox.shrink()
              else if (report.bestSellers.isEmpty)
                Text(
                  l10n.reportsNoSalesData,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                )
              else
                for (final (index, best) in report.bestSellers.indexed) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${index + 1}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onPrimaryContainer,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            // Nome COMPLETO — quebra quando necessário.
                            best.productName,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              Formatters.currency(best.revenueCents),
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            // W11: quantidade em milésimos → unidades.
                            Text(
                              Quantity.format(
                                best.quantity,
                                language: Formatters.currentLanguage,
                              ),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
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
          onPressed: () => const AdvancedReportsPdfExporter().shareSalesReport(
            title: context.l10n.reportsTabSales,
            period: selectedPeriod,
            businessName: _activeStoreName(ref) ?? l10n.businessFallbackName,
            generatedOnLabel: context.l10n.pdfGeneratedOn('{date}'),
            indicatorsLabel: context.l10n.pdfIndicators,
            noDataLabel: context.l10n.reportsNoSalesData,
            footerLabel: context.l10n.pdfFooter('{date}'),
            kpis: {
              l10n.reportsRevenue: Formatters.currency(
                report?.totalRevenueCents ?? 0,
              ),
              l10n.reportsProfit: Formatters.currency(
                report?.totalProfitCents ?? 0,
              ),
              l10n.reportsMargin: report != null
                  ? '${report.margin.toStringAsFixed(1)}%'
                  : '0,0%',
            },
          ),
        ),
      ],
    );
  }
}

// ─── Financeiro ─────────────────────────────────────────────────────────

class _FinancialReportTab extends ConsumerWidget {
  const _FinancialReportTab({required this.selectedPeriod});

  final String selectedPeriod;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    final user = ref.watch(authStateProvider).value;
    final storeId = user == null
        ? null
        : ref.watch(activeStoreIdProvider(user.id));
    final cashFlowAsync = storeId == null
        ? null
        : ref.watch(advancedReportCashFlowProvider((storeId, selectedPeriod)));
    final cashFlow = cashFlowAsync?.value;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // Erro real (rede/banco) com retry — nunca silencia falha.
        if (storeId != null && (cashFlowAsync?.hasError ?? false))
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                Icon(Icons.error_outline, size: 16, color: scheme.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.reportsLoadError,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.error,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => ref.invalidate(
                    advancedReportCashFlowProvider((storeId, selectedPeriod)),
                  ),
                  child: Text(l10n.commonRetry),
                ),
              ],
            ),
          ),
        // Loading real enquanto busca o fluxo de caixa.
        if (cashFlowAsync?.isLoading ?? false)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        // KPIs (reais — fluxo de caixa do período, em centavos).
        Row(
          children: [
            Expanded(
              child: _KpiTile(
                label: l10n.reportsKpiRevenue,
                value: cashFlow != null
                    ? Formatters.currency(cashFlow.incomeCents)
                    : '—',
                icon: Icons.arrow_downward_rounded,
                color: IconTone.green,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _KpiTile(
                label: l10n.reportsKpiExpenses,
                value: cashFlow != null
                    ? Formatters.currency(cashFlow.expenseCents)
                    : '—',
                icon: Icons.arrow_upward_rounded,
                color: IconTone.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        _KpiTile(
          label: l10n.reportsKpiNetProfit,
          value: cashFlow != null
              ? Formatters.currency(cashFlow.balanceCents)
              : '—',
          icon: Icons.account_balance_wallet_outlined,
          color: ModuleColors.reports,
          fullWidth: true,
        ),
        const SizedBox(height: AppSpacing.lg),

        // Comparativo de fluxo de caixa do período (dados reais).
        AppCard(
          elevated: true,
          borderRadius: const BorderRadius.all(Radius.circular(AppRadius.lg)),
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
                      color: IconTone.lightForeground(ModuleColors.reports),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    l10n.reportsCashFlow,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              // Comparativo REAL do período: barras proporcionais com os
              // valores de entradas/saídas (antes: gráfico placeholder).
              if (cashFlow == null)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.show_chart,
                        size: 32,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.25),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.reportsCashFlowChart,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              else
                _CashFlowBars(
                  cashFlow: cashFlow,
                  theme: theme,
                  scheme: scheme,
                  l10n: l10n,
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
                businessName:
                    _activeStoreName(ref) ?? l10n.businessFallbackName,
                generatedOnLabel: context.l10n.pdfGeneratedOn('{date}'),
                indicatorsLabel: context.l10n.pdfIndicators,
                noDataLabel: context.l10n.reportsNoSalesData,
                footerLabel: context.l10n.pdfFooter('{date}'),
                kpis: {
                  l10n.reportsKpiRevenue: Formatters.currency(
                    cashFlow?.incomeCents ?? 0,
                  ),
                  l10n.reportsKpiExpenses: Formatters.currency(
                    cashFlow?.expenseCents ?? 0,
                  ),
                  l10n.reportsKpiNetProfit: Formatters.currency(
                    cashFlow?.balanceCents ?? 0,
                  ),
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
    final lowStock = products
        .where((p) => (p.stockQuantity ~/ 1000) <= 10)
        .length;
    // Valor de estoque em CENTAVOS — exacto (antes truncava quantidade e
    // preço para inteiros: 2,7 un × 15,99 saía 2 × 15 = MT 30,00 em vez
    // de ≈ MT 43,17).
    final totalStockValueCents = products.fold<int>(
      0,
      (sum, p) => sum + ((p.stockQuantity * p.salePriceCents) ~/ 1000),
    );
    final outOfStock = products
        .where((p) => (p.stockQuantity ~/ 1000) == 0)
        .length;

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
                value: Formatters.currency(totalStockValueCents),
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
          borderRadius: const BorderRadius.all(Radius.circular(AppRadius.lg)),
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
                      color: IconTone.lightForeground(ModuleColors.credit),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      l10n.reportsKpiLowStock,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (lowStock > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: ModuleColors.credit.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        '$lowStock',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: ModuleColors.credit,
                          fontWeight: FontWeight.w500,
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
                  ),
                )
              else
                for (final p
                    in products
                        .where((p) => (p.stockQuantity ~/ 1000) <= 10)
                        .take(5)) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Row(
                      children: [
                        Icon(Icons.circle, size: 6, color: ModuleColors.credit),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            // Nome COMPLETO — quebra quando necessário.
                            p.name,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                        Text(
                          '${p.stockQuantity ~/ 1000} ${p.unitLabel}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: ModuleColors.credit,
                            fontWeight: FontWeight.w500,
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
          onPressed: () => const AdvancedReportsPdfExporter().shareStockReport(
            title: context.l10n.reportsTabStock,
            period: selectedPeriod,
            businessName: _activeStoreName(ref) ?? l10n.businessFallbackName,
            generatedOnLabel: context.l10n.pdfGeneratedOn('{date}'),
            indicatorsLabel: context.l10n.pdfIndicators,
            noDataLabel: context.l10n.reportsNoSalesData,
            footerLabel: context.l10n.pdfFooter('{date}'),
            kpis: {
              l10n.reportsKpiTotalProducts: '$totalProducts',
              l10n.reportsKpiLowStock: '$lowStock',
              l10n.reportsKpiStockValue: Formatters.currency(
                totalStockValueCents,
              ),
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
                    ),
                  ),
                  const SizedBox(height: 1),
                  // Valor COMPLETO — FittedBox encolhe em vez de truncar
                  // (mesmo padrão dos KPIs do dashboard).
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: color,
                        letterSpacing: -0.2,
                      ),
                    ),
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
    final l10n = context.l10n;
    final periods = <String, String>{
      'Hoje': l10n.periodToday,
      'Esta Semana': l10n.periodWeek,
      'Este Mês': l10n.periodMonth,
      'Este Ano': l10n.reportsPeriodYear,
    };

    // Mesma pílula minimalista do dashboard ("Hoje ▾"): texto + chevron
    // fino, menu via AppMenuOption (44px, bodySmall, chapado).
    return AppMenuOption<String>(
      label: periods[selected] ?? selected,
      options: [
        for (final entry in periods.entries)
          AppMenuOptionItem(
            value: entry.key,
            label: entry.value,
            checked: entry.key == selected,
          ),
      ],
      onSelected: onChanged,
    );
  }
}

/// Janela [start, end] do período seleccionado no chip de relatórios
/// avançados (chaves internas do `_PeriodChip` — não user-facing).
(DateTime, DateTime) _periodRange(String periodKey, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  switch (periodKey) {
    case 'Hoje':
      return (today, now);
    case 'Esta Semana':
      final weekStart = today.subtract(Duration(days: today.weekday - 1));
      return (weekStart, now);
    case 'Este Mês':
      return (DateTime(now.year, now.month), now);
    default: // 'Este Ano' (ou chave desconhecida)
      return (DateTime(now.year), now);
  }
}

/// Barras comparativas REAIS (entradas vs saídas) do fluxo de caixa do
/// período — substitui o antigo gráfico placeholder.
class _CashFlowBars extends StatelessWidget {
  const _CashFlowBars({
    required this.cashFlow,
    required this.theme,
    required this.scheme,
    required this.l10n,
  });

  final CashFlow cashFlow;
  final ThemeData theme;
  final ColorScheme scheme;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final maxCents = cashFlow.incomeCents > cashFlow.expenseCents
        ? cashFlow.incomeCents
        : cashFlow.expenseCents;

    Widget bar({
      required String label,
      required int cents,
      required Color color,
    }) {
      final fraction = maxCents == 0 ? 0.0 : (cents / maxCents).clamp(0.0, 1.0);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                Formatters.currency(cents),
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              width: double.infinity,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: fraction,
                child: ColoredBox(color: color),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        bar(
          label: l10n.reportsKpiRevenue,
          cents: cashFlow.incomeCents,
          color: IconTone.green,
        ),
        const SizedBox(height: AppSpacing.md),
        bar(
          label: l10n.reportsKpiExpenses,
          cents: cashFlow.expenseCents,
          color: IconTone.red,
        ),
      ],
    );
  }
}
