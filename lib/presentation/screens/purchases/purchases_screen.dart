import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/purchase.dart';
import '../../controllers/dashboard_providers.dart';
import '../../controllers/finance_providers.dart';
import '../../controllers/products_providers.dart';
import '../../controllers/purchases_providers.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/feed_card.dart';
import '../../widgets/payment_filter.dart';
import '../../widgets/period_filter.dart';
import '../../widgets/pinned_header.dart';
import '../../widgets/purchase_card.dart';
import '../../widgets/search_field.dart';
import '../../../core/theme/app_tokens.dart';
import '../../widgets/app_page.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/store_scoped_content.dart';
import 'add_purchase_sheet.dart';
import 'purchase_detail_sheet.dart';
import 'purchases_widgets.dart';

/// Tela de compras — histórico de entradas de mercadoria de fornecedores.
/// Registrar uma compra aumenta o estoque e lança a saída no caixa
/// (ProcessPurchaseUseCase).
///
/// [ConsumerStatefulWidget] apenas para o estado LOCAL de UI (busca e
/// filtro de período); os dados continuam 100% no Riverpod
/// ([purchasesProvider]).
class PurchasesScreen extends ConsumerStatefulWidget {
  const PurchasesScreen({super.key});

  @override
  ConsumerState<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends ConsumerState<PurchasesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  PeriodFilter _period = PeriodFilter.all;
  PaymentFilter _payment = PaymentFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openNewPurchase() async {
    await showAppSheet<void>(context, builder: (_) => const AddPurchaseSheet());
    if (!mounted) return;
    // Estoque, compras, caixa e KPIs mudaram — as telas recarregam.
    ref.invalidate(purchasesProvider);
    ref.invalidate(productsProvider);
    ref.invalidate(transactionsProvider);
    ref.invalidate(cashFlowProvider);
    ref.invalidate(dashboardKpisProvider);
  }

  Future<void> _refresh() => ref.read(purchasesProvider.notifier).refresh();

  @override
  Widget build(BuildContext context) {
    final purchasesAsync = ref.watch(purchasesProvider);
    final l10n = context.l10n;
    // Sem nenhuma compra na loja, o FAB some: o estado vazio já traz o
    // botão primário centralizado ("Nova compra") — sem CTA duplicado.
    // Com dados, o FAB volta como ação rápida persistente.
    final hasPurchases = purchasesAsync.value?.isNotEmpty ?? false;

    return AppPage(
      title: l10n.purchasesTitle,
      useSafeArea: false,
      floatingActionButton: hasPurchases
          // FAB minimalista — usando cor da identidade do design system.
          ? FloatingActionButton(
              heroTag: 'fab-purchases',
              onPressed: _openNewPurchase,
              tooltip: l10n.purchasesAddNew,
              backgroundColor: AppColors.accentOrangeDark,
              foregroundColor: AppColors.softWhite,
              child: const Icon(Icons.add),
            )
          : null,
      // A tela é empurrada por cima do AppShell (fora da casca): o seletor
      // de loja ativa é re-adicionado para o usuário ver/trocar a loja e
      // as compras da loja selecionada.
      body: StoreScopedContent(
        child: purchasesAsync.when(
          // Skeleton loading no primeiro carregamento.
          loading: () => const _PurchasesSkeleton(),
          error: (error, _) => ErrorView(
            message: l10n.purchasesLoadError,
            details: error.toString(),
            onRetry: () => ref.invalidate(purchasesProvider),
          ),
          data: (purchases) => _PurchasesBody(
            purchases: purchases,
            searchController: _searchController,
            query: _query,
            period: _period,
            payment: _payment,
            onQueryChanged: (value) =>
                setState(() => _query = value.trim().toLowerCase()),
            onPeriodChanged: (value) => setState(() => _period = value),
            onPaymentChanged: (value) => setState(() => _payment = value),
            onClearFilters: () {
              _searchController.clear();
              setState(() {
                _query = '';
                _period = PeriodFilter.all;
                _payment = PaymentFilter.all;
              });
            },
            onRefresh: _refresh,
            onNewPurchase: _openNewPurchase,
          ),
        ),
      ),
    );
  }
}

/// Conteúdo da tela com dados carregados: resumo do dia, busca + filtro de
/// período FIXOS e a lista (slivers — só os cards visíveis são construídos).
class _PurchasesBody extends StatelessWidget {
  const _PurchasesBody({
    required this.purchases,
    required this.searchController,
    required this.query,
    required this.period,
    required this.payment,
    required this.onQueryChanged,
    required this.onPeriodChanged,
    required this.onPaymentChanged,
    required this.onClearFilters,
    required this.onRefresh,
    required this.onNewPurchase,
  });

  final List<Purchase> purchases;
  final TextEditingController searchController;
  final String query;
  final PeriodFilter period;
  final PaymentFilter payment;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<PeriodFilter> onPeriodChanged;
  final ValueChanged<PaymentFilter> onPaymentChanged;
  final VoidCallback onClearFilters;
  final Future<void> Function() onRefresh;
  final VoidCallback onNewPurchase;

  // Busca local: fornecedor, número SEQUENCIAL (C-00001) ou dia relativo
  // (Formatters.day usa o idioma global ativo — não precisa de l10n).
  bool _matchesQuery(Purchase purchase) {
    if (query.isEmpty) return true;
    return purchase.supplierName.toLowerCase().contains(query) ||
        Formatters.purchaseLabel(
          purchase.number,
        ).toLowerCase().contains(query) ||
        Formatters.day(purchase.dateTime).toLowerCase().contains(query);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final filtered = [
      for (final purchase in purchases)
        if (period.matches(purchase.dateTime) &&
            payment.matches(purchase.paymentMethod) &&
            _matchesQuery(purchase))
          purchase,
    ];

    // Sem nenhuma compra na loja: estado vazio focado na ação principal.
    if (purchases.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.shopping_cart_outlined,
                title: l10n.purchasesEmptyTitle,
                subtitle: l10n.purchasesEmptySubtitle,
                actionLabel: l10n.purchasesAddNew,
                onAction: onNewPurchase,
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
          // Resumo do dia rola junto com o conteúdo.
          SliverPadding(
            padding: EdgeInsets.fromLTRB(horizontal, 8, horizontal, 16),
            sliver: SliverToBoxAdapter(
              child: PurchasesSummaryHeader(purchases: purchases),
            ),
          ),
          // Busca + filtro de período FIXOS: a lista rola por baixo deles
          // ([PinnedHeader] compartilhado com Vendas).
          PinnedHeader(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SearchField(
                  controller: searchController,
                  hintText: l10n.purchasesSearchHint,
                  onChanged: onQueryChanged,
                ),
                const SizedBox(height: 12),
                // Filtros MINIMALISTAS (canvas V3): os dois seletores numa
                // única linha — chips compactos com menu; fluem para a
                // linha seguinte em escala de texto alta (nunca estouram).
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    PeriodFilterBar(value: period, onChanged: onPeriodChanged),
                    PaymentFilterBar(
                      value: payment,
                      onChanged: onPaymentChanged,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.filter_alt_off_outlined,
                title: l10n.purchasesEmptyFilteredTitle,
                subtitle: l10n.purchasesEmptyFilteredSubtitle,
                actionLabel: l10n.purchasesClearFilters,
                onAction: onClearFilters,
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontal,
                0,
                horizontal,
                AppSpacing.fabBottomClearance + AppSpacing.md,
              ),
              // Folha única estilo Home (FeedCard): um só card com as
              // compras como linhas separadas por divisórias hairline.
              sliver: SliverToBoxAdapter(
                child: FeedCard(
                  rows: [
                    for (final purchase in filtered)
                      // RepaintBoundary: o ripple de uma linha não repinta
                      // as vizinhas; ValueKey preserva identidade.
                      RepaintBoundary(
                        key: ValueKey('purchase-card-${purchase.id}'),
                        child: PurchaseCard(
                          purchase: purchase,
                          // Detalhes da compra em sheet de leitura
                          // (fornecedor, data, pagamento, itens, validade).
                          onTap: () => showPurchaseDetailSheet(
                            context,
                            purchase: purchase,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Skeleton loading — blocos com o mesmo shape dos elementos reais e pulso
/// suave (via [Skeleton]/[SkeletonBlock] compartilhados).
class _PurchasesSkeleton extends StatelessWidget {
  const _PurchasesSkeleton();

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
          // Resumo do dia.
          const SkeletonBlock(height: 118, radius: 20),
          const SizedBox(height: 16),
          // Busca.
          const SkeletonBlock(height: 52),
          const SizedBox(height: 12),
          // Filtros: período.
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
          const SizedBox(height: 8),
          // Filtros: forma de pagamento.
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SkeletonBlock(height: 32, width: 64),
              SkeletonBlock(height: 32, width: 88),
              SkeletonBlock(height: 32, width: 72),
              SkeletonBlock(height: 32, width: 84),
              SkeletonBlock(height: 32, width: 96),
            ],
          ),
          const SizedBox(height: 20),
          // Cards.
          for (var i = 0; i < 4; i++) ...[
            const SkeletonBlock(height: 96, radius: 20),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
