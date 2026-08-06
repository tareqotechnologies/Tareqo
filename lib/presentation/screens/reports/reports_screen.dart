import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../controllers/reports_providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reportsTitle),
        actions: [
          IconButton(
            tooltip: l10n.commonRefresh,
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(salesReportProvider.notifier).refresh(),
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
        children: [
          Center(
            child: SegmentedButton<ReportPeriod>(
              showSelectedIcon: false,
              segments: [
                for (final value in ReportPeriod.values)
                  ButtonSegment(value: value, label: Text(value.label(l10n))),
              ],
              selected: {period},
              onSelectionChanged: (selection) => ref
                  .read(reportPeriodProvider.notifier)
                  .select(selection.first),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: KpiCard(
                  label: l10n.reportsRevenue,
                  value: Formatters.currency(report?.totalRevenueCents ?? 0),
                  icon: Icons.point_of_sale_outlined,
                  loading: reportAsync.isLoading,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: KpiCard(
                  label: l10n.reportsProfit,
                  value: Formatters.currency(report?.totalProfitCents ?? 0),
                  icon: Icons.trending_up,
                  iconBackground: AppColors.income.withValues(alpha: 0.14),
                  iconColor: AppColors.income,
                  loading: reportAsync.isLoading,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: KpiCard(
                  label: l10n.reportsMargin,
                  value: '${(report?.margin ?? 0).toStringAsFixed(1)}%',
                  icon: Icons.percent,
                  iconBackground: AppColors.warning.withValues(alpha: 0.14),
                  iconColor: AppColors.warning,
                  loading: reportAsync.isLoading,
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
              return Card(
                child: Column(
                  children: [
                    for (var i = 0; i < data.perDay.length; i++) ...[
                      if (i > 0) const Divider(height: 1, indent: 14, endIndent: 14),
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

    return Card(
      child: Padding(
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
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
              label: '$quantity ${l10n.commonUnits}',
              color: theme.colorScheme.primary,
              icon: Icons.shopping_bag_outlined,
            ),
          ],
        ),
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
          Text(
            Formatters.currency(total),
            style: theme.textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
