import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/sale.dart';
import '../../controllers/products_providers.dart';
import '../../controllers/sales_providers.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/payment_filter.dart' show PaymentFilter, PaymentFilterBar;
import '../../widgets/period_filter.dart' show PeriodFilter, PeriodFilterBar;
import '../../widgets/pinned_header.dart';
import '../../widgets/sale_card.dart';
import '../../widgets/app_page.dart';
import '../../widgets/skeleton.dart';
import 'new_sale_sheet.dart';
import 'sales_widgets.dart';

/// Tela de vendas — histórico e registro de novas vendas.
///
/// [ConsumerStatefulWidget] apenas para o estado LOCAL de UI (filtros);
/// os dados continuam 100% no Riverpod ([salesListProvider]).
class SalesScreen extends ConsumerStatefulWidget {
  const SalesScreen({super.key});

  @override
  ConsumerState<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends ConsumerState<SalesScreen> {
  PeriodFilter _period = PeriodFilter.all;
  PaymentFilter _payment = PaymentFilter.all;

  Future<void> _openNewSale() async {
    await showAppSheet<void>(
      context,
      builder: (_) => const NewSaleSheet(),
      fullscreen: true,
    );
    if (!mounted) return;
    ref.invalidate(salesListProvider);
    ref.invalidate(productsProvider);
  }

  Future<void> _refresh() => ref.read(salesListProvider.notifier).refresh();

  @override
  Widget build(BuildContext context) {
    final salesAsync = ref.watch(salesListProvider);
    final l10n = context.l10n;
    final hasSales = salesAsync.value?.isNotEmpty ?? false;

    return AppPage(
      title: l10n.salesTitle,
      useSafeArea: false,
      floatingActionButton: hasSales
          ? FloatingActionButton(
              heroTag: 'fab-sales',
              onPressed: _openNewSale,
              tooltip: l10n.salesNewSale,
              child: const Icon(Icons.add),
            )
          : null,
      body: salesAsync.when(
        loading: () => const _SalesSkeleton(),
        error: (error, _) => ErrorView(
          message: l10n.salesLoadError,
          details: error.toString(),
          onRetry: () => ref.invalidate(salesListProvider),
        ),
        data: (sales) => _SalesBody(
          sales: sales,
          period: _period,
          payment: _payment,
          onPeriodChanged: (value) => setState(() => _period = value),
          onPaymentChanged: (value) => setState(() => _payment = value),
          onClearFilters: () {
            setState(() {
              _period = PeriodFilter.all;
              _payment = PaymentFilter.all;
            });
          },
          onRefresh: _refresh,
          onNewSale: _openNewSale,
        ),
      ),
    );
  }
}

/// Conteúdo da tela com dados carregados.
class _SalesBody extends StatelessWidget {
  const _SalesBody({
    required this.sales,
    required this.period,
    required this.payment,
    required this.onPeriodChanged,
    required this.onPaymentChanged,
    required this.onClearFilters,
    required this.onRefresh,
    required this.onNewSale,
  });

  final List<Sale> sales;
  final PeriodFilter period;
  final PaymentFilter payment;
  final ValueChanged<PeriodFilter> onPeriodChanged;
  final ValueChanged<PaymentFilter> onPaymentChanged;
  final VoidCallback onClearFilters;
  final Future<void> Function() onRefresh;
  final VoidCallback onNewSale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final filtered = [
      for (final sale in sales)
        if (period.matches(sale.dateTime) &&
            payment.matches(sale.paymentMethod))
          sale,
    ];

    final filteredTotalCents = filtered.fold<int>(
      0,
      (sum, sale) => sale.status == SaleStatus.cancelled
          ? sum
          : sum + sale.totalAmountCents,
    );
    final isFiltering =
        period != PeriodFilter.all || payment != PaymentFilter.all;

    // Estado vazio.
    if (sales.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.point_of_sale_outlined,
                title: l10n.salesEmptyTitle,
                subtitle: l10n.salesEmptySubtitle,
                actionLabel: l10n.salesNewSale,
                onAction: onNewSale,
              ),
            ),
          ],
        ),
      );
    }

    final horizontal = AppSpacing.pagePaddingForWidth(
      MediaQuery.sizeOf(context).width,
    );

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ── Resumo do dia ──
          SliverPadding(
            padding: EdgeInsets.fromLTRB(horizontal, 8, horizontal, 16),
            sliver: SliverToBoxAdapter(child: SalesSummaryHeader(sales: sales)),
          ),
          // ── Filtros dropdown FIXOS ──
          // Wrap (não Row): em telas estreitas / escala de texto alta os
          // dois seletores fluem para a 2.ª linha — o PinnedHeader mede a
          // altura em runtime, então a barra cresce sem estourar.
          PinnedHeader(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  PeriodFilterBar(value: period, onChanged: onPeriodChanged),
                  PaymentFilterBar(value: payment, onChanged: onPaymentChanged),
                ],
              ),
            ),
          ),
          // ── Linha-resumo do filtro ──
          SliverToBoxAdapter(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isFiltering && filtered.isNotEmpty
                  ? Padding(
                      key: const ValueKey('sales-filtered-summary'),
                      padding: EdgeInsets.fromLTRB(
                        horizontal,
                        6,
                        horizontal,
                        0,
                      ),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          l10n.salesFilteredSummary(
                            filtered.length,
                            Formatters.currency(filteredTotalCents),
                          ),
                          textAlign: TextAlign.right,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          // Nota auxiliar do filtro: 12/400, sem ênfase.
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('sales-filtered-none')),
            ),
          ),
          // ── Lista de vendas ──
          if (filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.search_off,
                title: l10n.salesEmptyFilteredTitle,
                subtitle: l10n.salesEmptyFilteredSubtitle,
                actionLabel: l10n.salesClearFilters,
                onAction: onClearFilters,
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontal,
                AppSpacing.xs,
                horizontal,
                AppSpacing.fabBottomClearance + AppSpacing.md,
              ),
              sliver: SliverList.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final sale = filtered[index];
                  return RepaintBoundary(
                    key: ValueKey('sales-card-${sale.id}'),
                    child: SalesCard(sale: sale),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Skeleton loading.
class _SalesSkeleton extends StatelessWidget {
  const _SalesSkeleton();

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xs,
          AppSpacing.lg,
          AppSpacing.fabBottomClearance,
        ),
        children: [
          const SkeletonBlock(height: 108, radius: 16),
          const SizedBox(height: 16),
          const SkeletonBlock(height: 48, radius: 24),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SkeletonBlock(height: 32, width: 88),
              SkeletonBlock(height: 32, width: 70),
              SkeletonBlock(height: 32, width: 112),
              SkeletonBlock(height: 32, width: 96),
            ],
          ),
          const SizedBox(height: 20),
          for (var i = 0; i < 5; i++) ...[
            const SkeletonBlock(height: 80, radius: 14),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
