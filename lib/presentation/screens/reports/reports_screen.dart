import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/app_card.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/observability/crash_reporting.dart';
import '../../../core/share/report_exporter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/quantity.dart';
import '../../../domain/entities/store.dart';
import '../../../domain/usecases/get_sales_report_use_case.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../controllers/account_providers.dart';
import '../../controllers/auth_providers.dart';
import '../../controllers/reports_providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../../core/theme/app_tokens.dart';
import '../../widgets/app_page.dart';
import '../../widgets/app_segmented_button.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/inline_error_card.dart';
import '../../widgets/kpi_card.dart';
import '../../widgets/premium_decor.dart';
import '../../widgets/section_header.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/store_scoped_content.dart';

/// Tela de relatórios — lucro bruto, margem, produtos mais vendidos e
/// vendas por dia, com seletor de período.
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(reportPeriodProvider);
    final reportAsync = ref.watch(salesReportProvider);
    final l10n = context.l10n;

    final report = reportAsync.value;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Nome da loja ativa — vai no cabeçalho do arquivo exportado (CSV/PDF).
    final user = ref.watch(authStateProvider).value;
    final tenant = user == null
        ? null
        : ref.watch(myTenantProvider(user.id)).value;
    final activeStoreId = user == null
        ? null
        : ref.watch(activeStoreIdProvider(user.id));
    final stores = tenant == null
        ? const <Store>[]
        : ref.watch(storesProvider(tenant.id)).value ?? const <Store>[];
    final storeName =
        stores.where((s) => s.id == activeStoreId).firstOrNull?.name ?? '';

    return AppPage(
      title: l10n.reportsTitle,
      useSafeArea: false,
      // Exportação do relatório (CSV/PDF) — só com dados carregados; o
      // relatório é o que está na tela (período selecionado + loja ativa).
      // `!reportAsync.hasError`: em erro o `.value` do Riverpod devolve o
      // ÚLTIMO valor (o report vazio do build inicial) — sem o gate, o
      // menu apareceria mesmo na tela de erro.
      actions: [
        if (report != null && !reportAsync.hasError)
          PopupMenuButton<_ExportFormat>(
            tooltip: l10n.reportsExport,
            icon: const Icon(Icons.ios_share, size: AppSizes.iconMd),
            onSelected: (format) => _exportReport(
              context,
              ref,
              format,
              report,
              storeName: storeName,
              periodLabel: period.label(l10n),
              l10n: l10n,
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _ExportFormat.csv,
                height: AppSizes.tableRowHeight,
                child: Text(
                  l10n.reportsExportCsv,
                  style: AppTypography.bodyMedium.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
              ),
              PopupMenuItem(
                value: _ExportFormat.pdf,
                height: AppSizes.tableRowHeight,
                child: Text(
                  l10n.reportsExportPdf,
                  style: AppTypography.bodyMedium.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
      ],
      // A tela é empurrada por cima do AppShell (fora da casca): o seletor
      // de loja ativa é re-adicionado e o relatório reflete a loja
      // selecionada.
      body: StoreScopedContent(
        child: RefreshIndicator(
          // W8: puxar para atualizar — recarrega o relatório.
          onRefresh: () async {
            ref.invalidate(salesReportProvider);
            await Future<void>.delayed(const Duration(milliseconds: 300));
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              AppSpacing.pagePaddingForWidth(MediaQuery.sizeOf(context).width),
              AppSpacing.xs,
              AppSpacing.pagePaddingForWidth(MediaQuery.sizeOf(context).width),
              AppSpacing.xxl,
            ),
            children: [
              Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: AppSegmentedButton<ReportPeriod>(
                    segments: [
                      for (final value in ReportPeriod.values)
                        ButtonSegment(
                          value: value,
                          label: Text(value.label(l10n)),
                        ),
                    ],
                    selected: {period},
                    onSelectionChanged: (selection) => ref
                        .read(reportPeriodProvider.notifier)
                        .select(selection.first),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Erro: em vez de uma linha de KPIs com "R\$ 0,00"/"0.0%"
              // (zeros falsos), mostra o aviso compacto com retry — mesmo
              // padrão do Dashboard e do Financeiro. Com dados em cache
              // (stale) após um refresh falho, a última leitura é mantida.
              if (reportAsync.hasError)
                InlineErrorCard(
                  message: l10n.reportsLoadError,
                  onRetry: () => ref.invalidate(salesReportProvider),
                )
              else
                _KpiRow(
                  children: [
                    KpiCard(
                      label: l10n.reportsRevenue,
                      amountCents: report?.totalRevenueCents ?? 0,
                      icon: Icons.point_of_sale_outlined,
                      loading: reportAsync.isLoading,
                      borderRadius: AppRadius.lgAll,
                    ),
                    KpiCard(
                      label: l10n.reportsProfit,
                      amountCents: report?.totalProfitCents ?? 0,
                      icon: Icons.trending_up,
                      iconBackground: theme.income.withValues(alpha: 0.14),
                      iconColor: theme.income,
                      loading: reportAsync.isLoading,
                      borderRadius: AppRadius.lgAll,
                    ),
                    KpiCard(
                      label: l10n.reportsMargin,
                      value: '${(report?.margin ?? 0).toStringAsFixed(1)}%',
                      icon: Icons.percent,
                      iconBackground: theme.warning.withValues(alpha: 0.14),
                      iconColor: theme.warning,
                      loading: reportAsync.isLoading,
                      borderRadius: AppRadius.lgAll,
                    ),
                  ],
                ),
              const SizedBox(height: AppSpacing.xl),
              SectionHeader(title: l10n.reportsBestSellers),
              const SizedBox(height: AppSpacing.sm),
              reportAsync.when(
                loading: () => Skeleton(
                  child: Column(
                    children: List.generate(
                      4,
                      (_) => const Padding(
                        padding: EdgeInsets.only(bottom: AppSpacing.xs),
                        child: SkeletonBlock(height: 56, radius: AppRadius.md),
                      ),
                    ),
                  ),
                ),
                error: (error, _) => ErrorView(
                  message: l10n.reportsLoadError,
                  details: error.toString(),
                  onRetry: () => ref.invalidate(salesReportProvider),
                ),
                data: (data) {
                  if (data.bestSellers.isEmpty) {
                    return EmptyState(
                      icon: Icons.bar_chart_outlined,
                      title: l10n.reportsEmptyTitle,
                      subtitle: l10n.reportsEmptySubtitle,
                    );
                  }
                  return Column(
                    children: [
                      for (var i = 0; i < data.bestSellers.length; i++) ...[
                        _BestSellerRow(
                          rank: i + 1,
                          name: data.bestSellers[i].productName,
                          quantity: data.bestSellers[i].quantity,
                          revenue: data.bestSellers[i].revenueCents,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xl),
              SectionHeader(title: l10n.reportsSalesPerDay),
              const SizedBox(height: AppSpacing.sm),
              reportAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
                data: (data) {
                  if (data.perDay.isEmpty) return const SizedBox.shrink();
                  return AppCard(
                    elevated: true,
                    borderRadius: AppRadius.lgAll,
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (var i = 0; i < data.perDay.length; i++) ...[
                          if (i > 0)
                            Divider(
                              height: 1,
                              indent: AppSpacing.md,
                              endIndent: AppSpacing.md,
                              color: PremiumDecor.hairline(scheme),
                            ),
                          _DailyRow(
                            day: data.perDay[i].day,
                            total: data.perDay[i].totalCents,
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Formato de exportação escolhido no menu.
enum _ExportFormat { csv, pdf }

/// Linha de KPIs responsiva: três cartões lado a lado em escala normal e
/// empilhados em escalas de texto grandes — em 2.0× o rótulo de meia
/// largura quebrava no meio da palavra (ex.: "Margem").
class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final stacked = MediaQuery.textScalerOf(context).scale(14) >= 22;
    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            children[i],
          ],
        ],
      );
    }
    return Row(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(child: children[i]),
        ],
      ],
    );
  }
}

/// Exporta o relatório atual ([report]) em CSV ou PDF via share sheet.
///
/// Os rótulos do arquivo são localizados ([l10n]); o nome da loja ativa e o
/// período selecionado vão no cabeçalho. Falhas (rede/share) mostram a
/// mensagem de erro e caem no CrashReporting — sem derrubar a tela.
Future<void> _exportReport(
  BuildContext context,
  WidgetRef ref,
  _ExportFormat format,
  SalesReport report, {
  required String storeName,
  required String periodLabel,
  required AppLocalizations l10n,
}) async {
  final labels = ReportExportLabels(
    title: l10n.reportsExportTitle,
    store: l10n.reportsExportStore,
    period: l10n.reportsExportPeriod,
    generatedAt: l10n.reportsExportGeneratedAt,
    summary: l10n.reportsExportSummary,
    revenueKpi: l10n.reportsRevenue,
    profitKpi: l10n.reportsProfit,
    marginKpi: l10n.reportsMargin,
    bestSellers: l10n.reportsBestSellers,
    rank: l10n.reportsExportRank,
    product: l10n.reportsExportProduct,
    quantity: l10n.reportsExportQuantity,
    revenue: l10n.reportsExportRevenue,
    perDay: l10n.reportsSalesPerDay,
    day: l10n.reportsExportDay,
    total: l10n.reportsExportTotal,
    units: l10n.commonUnits,
    fileNameBase: l10n.reportsExportFileName,
  );

  final exporter = ref.read(reportExporterProvider);
  final generatedAt = DateTime.now();
  try {
    if (format == _ExportFormat.csv) {
      await exporter.shareCsv(
        report: report,
        labels: labels,
        storeName: storeName,
        periodLabel: periodLabel,
        generatedAt: generatedAt,
      );
    } else {
      await exporter.sharePdf(
        report: report,
        labels: labels,
        storeName: storeName,
        periodLabel: periodLabel,
        generatedAt: generatedAt,
      );
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.reportsExportDone)));
  } catch (error, stackTrace) {
    CrashReporting.capture(
      error,
      stackTrace,
      hint: 'Erro ao exportar relatório',
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.reportsExportError)));
  }
}

/// Linha de produto mais vendido: posição, nome, quantidade e receita.
class _BestSellerRow extends StatelessWidget {
  const _BestSellerRow({
    required this.rank,
    required this.name,
    required this.quantity,
    required this.revenue,
  });

  final int rank;
  final String name;
  final int quantity;
  final int revenue;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    // AppCard premium: raio lg do design system, superfície elevada.
    return AppCard(
      elevated: true,
      borderRadius: AppRadius.lgAll,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          CircleAvatar(
            radius: AppSpacing.md,
            backgroundColor: scheme.primaryContainer,
            child: Text(
              '$rank',
              style: AppTypography.labelMedium.copyWith(
                color: scheme.onPrimaryContainer,
                // Ranks (1..N) na coluna de posição — alinhados.
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nome COMPLETO do vendedor — quebra em linhas quando
                // necessário (nada de truncar nomes nos cards).
                Text(
                  name,
                  style: AppTypography.labelLarge.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.micro),
                Text(
                  l10n.reportsRevenueLabel(Formatters.currency(revenue)),
                  style: AppTypography.bodySmall.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          StatusChip(
            // W11: quantidade em MILÉSIMOS — exibe em unidades.
            label:
                '${Quantity.format(quantity, language: Formatters.currentLanguage)} ${l10n.commonUnits}',
            // Texto do chip sobre o próprio tint a 14%: `primary` no escuro
            // (#6B4AB3) rendia 1.97:1 — a quantidade é um dado neutro e usa
            // o tom de texto secundário (AA em claro e escuro).
            color: scheme.onSurfaceVariant,
            icon: Icons.shopping_bag_outlined,
          ),
        ],
      ),
    );
  }
}

/// Linha de vendas por dia.
class _DailyRow extends StatelessWidget {
  const _DailyRow({required this.day, required this.total});

  final DateTime day;
  final int total;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    // Dia da semana ajuda a leitura comparativa da série (ex.: "05/09 · Sex")
    // — reusa as chaves weekday* existentes; o modelo não tem contagem de
    // vendas por dia, então a linha continua dia + valor.
    final weekday = switch (day.weekday) {
      DateTime.monday => l10n.weekdayMonday,
      DateTime.tuesday => l10n.weekdayTuesday,
      DateTime.wednesday => l10n.weekdayWednesday,
      DateTime.thursday => l10n.weekdayThursday,
      DateTime.friday => l10n.weekdayFriday,
      DateTime.saturday => l10n.weekdaySaturday,
      _ => l10n.weekdaySunday,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${Formatters.day(day)} · $weekday',
              style: AppTypography.bodySmall.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            Formatters.currency(total),
            style: AppTypography.amountInRow(scheme.onSurface),
          ),
        ],
      ),
    );
  }
}
