import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/app_card.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/observability/crash_reporting.dart';
import '../../../core/share/report_exporter.dart';
import '../../../core/theme/app_theme.dart';
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
import '../../widgets/inline_error_card.dart';
import '../../widgets/kpi_card.dart';
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

 return Scaffold(
 // AppBar estilo iOS large title — mesmo padrão das demais telas.
 appBar: AppBar(
 title: Text(
 l10n.reportsTitle,
 style: theme.textTheme.headlineSmall?.copyWith(
 fontWeight: FontWeight.w700,
 letterSpacing: -0.5,
 ),
 ),
 // Exportação do relatório (CSV/PDF) — só com dados carregados; o
 // relatório é o que está na tela (período selecionado + loja ativa).
 // `!reportAsync.hasError`: em erro o `.value` do Riverpod devolve o
 // ÚLTIMO valor (o report vazio do build inicial) — sem o gate, o
 // menu apareceria mesmo na tela de erro.
 actions: [
 if (report != null && !reportAsync.hasError)
 PopupMenuButton<_ExportFormat>(
 tooltip: l10n.reportsExport,
 icon: const Icon(Icons.ios_share),
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
 child: Text(l10n.reportsExportCsv),
 ),
 PopupMenuItem(
 value: _ExportFormat.pdf,
 child: Text(l10n.reportsExportPdf),
 ),
 ],
 ),
 ],
 ),
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
 padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
 children: [        Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: SegmentedButton<ReportPeriod>(
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                shape: const StadiumBorder(),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant,
                ),
                backgroundColor: Colors.transparent,
                selectedBackgroundColor:
                    theme.colorScheme.primaryContainer,
                selectedForegroundColor:
                    theme.colorScheme.onPrimaryContainer,
                foregroundColor: theme.colorScheme.onSurfaceVariant,
                textStyle: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
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
 const SizedBox(height: 16),
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
 Row(
 children: [
 Expanded(
 child: KpiCard(
 label: l10n.reportsRevenue,
 amountCents: report?.totalRevenueCents ?? 0,
 icon: Icons.point_of_sale_outlined,
 loading: reportAsync.isLoading,
 borderRadius: BorderRadius.circular(18),
 ),
 ),
 const SizedBox(width: 12),
 Expanded(
 child: KpiCard(
 label: l10n.reportsProfit,
 amountCents: report?.totalProfitCents ?? 0,
 icon: Icons.trending_up,
 iconBackground: theme.income.withValues(alpha: 0.14),
 iconColor: theme.income,
 loading: reportAsync.isLoading,
 borderRadius: BorderRadius.circular(18),
 ),
 ),
 const SizedBox(width: 12),
 Expanded(
 child: KpiCard(
 label: l10n.reportsMargin,
 value: '${(report?.margin ?? 0).toStringAsFixed(1)}%',
 icon: Icons.percent,
 iconBackground: theme.warning.withValues(alpha: 0.14),
 iconColor: theme.warning,
 loading: reportAsync.isLoading,
 borderRadius: BorderRadius.circular(18),
 ),
 ),
 ],
 ),
 const SizedBox(height: 24),
 SectionHeader(title: l10n.reportsBestSellers),
 const SizedBox(height: 12),
 reportAsync.when(
 loading: () => const Padding(
 padding: EdgeInsets.all(32),
 child: Center(child: CircularProgressIndicator()),
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
 const SizedBox(height: 8),
 ],
 ],
 );
 },
 ),
 const SizedBox(height: 24),
 SectionHeader(title: l10n.reportsSalesPerDay),
 const SizedBox(height: 12),
 reportAsync.when(
 loading: () => const SizedBox.shrink(),
 error: (_, _) => const SizedBox.shrink(),
 data: (data) {
 if (data.perDay.isEmpty) return const SizedBox.shrink();
 return AppCard(
 elevated: true,
 borderRadius: BorderRadius.circular(18),
 padding: EdgeInsets.zero,
 child: Column(
 children: [
 for (var i = 0; i < data.perDay.length; i++) ...[
 if (i > 0)
 const Divider(height: 1, indent: 14, endIndent: 14),
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
 final theme = Theme.of(context);
 final l10n = context.l10n;

 // AppCard premium (estilo Apple): cantos 18, superfície elevada.
 return AppCard(
 elevated: true,
 borderRadius: BorderRadius.circular(18),
 padding: const EdgeInsets.all(12),
 child: Row(
 children: [
 CircleAvatar(
 radius: 16,
 backgroundColor: theme.colorScheme.primaryContainer,
 child: Text(
 '$rank',
 style: TextStyle(
 color: theme.colorScheme.onPrimaryContainer,
 fontWeight: FontWeight.w700,
 // Ranks (1..N) na coluna de posição — alinhados.
 fontFeatures: [FontFeature.tabularFigures()],
 ),
 ),
 ),
 const SizedBox(width: 12),
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 // Nome COMPLETO do vendedor — quebra em linhas quando
 // necessário (nada de truncar nomes nos cards).
 Text(
 name,
 style: theme.textTheme.bodyMedium?.copyWith(
 fontWeight: FontWeight.w600,
 ),
 ),
 const SizedBox(height: 2),
 Text(
 l10n.reportsRevenueLabel(Formatters.currency(revenue)),
 style: theme.textTheme.bodySmall?.copyWith(
 color: theme.colorScheme.onSurfaceVariant,
 ),
 ),
 ],
 ),
 ),
 StatusChip(
 // W11: quantidade em MILÉSIMOS — exibe em unidades.
 label:
 '${Quantity.format(quantity, language: Formatters.currentLanguage)} ${l10n.commonUnits}',
 color: theme.colorScheme.primary,
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
 final theme = Theme.of(context);

 return Padding(
 padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
 child: Row(
 children: [
 Expanded(
 child: Text(
 Formatters.day(day),
 style: theme.textTheme.bodyMedium?.copyWith(
 fontWeight: FontWeight.w600,
 ),
 ),
 ),
 Text(Formatters.currency(total), style: theme.textTheme.titleMedium),
 ],
 ),
 );
 }
}
