import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/i18n/payment_method_l10n.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/sale.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../controllers/products_providers.dart';
import '../../controllers/sales_providers.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/feed_card.dart';
import '../../widgets/payment_filter.dart';
import '../../widgets/period_filter.dart';
import '../../widgets/pinned_header.dart';
import '../../widgets/sale_card.dart';
import '../../widgets/search_field.dart';
import '../../widgets/skeleton.dart';
import 'new_sale_sheet.dart';
import 'sales_widgets.dart';

/// Tela de vendas — histórico e registro de novas vendas.
///
/// [ConsumerStatefulWidget] apenas para o estado LOCAL de UI (busca e
/// filtros); os dados continuam 100% no Riverpod ([salesListProvider]).
class SalesScreen extends ConsumerStatefulWidget {
 const SalesScreen({super.key});

 @override
 ConsumerState<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends ConsumerState<SalesScreen> {
 final TextEditingController _searchController = TextEditingController();
 String _query = '';
 PeriodFilter _period = PeriodFilter.all;
 PaymentFilter _payment = PaymentFilter.all;

 @override
 void dispose() {
 _searchController.dispose();
 super.dispose();
 }

 Future<void> _openNewSale() async {
 // PDV fullscreen (V3): a sheet cobre o ecrã com a zona de scanner no
 // topo e o catálogo ocupando o espaço restante.
 await showAppSheet<void>(
 context,
 builder: (_) => const NewSaleSheet(),
 fullscreen: true,
 );
 if (!mounted) return;
 // O carrinho pode ter registrado uma venda e baixado o estoque.
 ref.invalidate(salesListProvider);
 ref.invalidate(productsProvider);
 }

 Future<void> _refresh() => ref.read(salesListProvider.notifier).refresh();

 @override
 Widget build(BuildContext context) {
 final salesAsync = ref.watch(salesListProvider);
 final l10n = context.l10n;
 // Sem nenhuma venda na loja, o FAB some: o estado vazio já traz o
 // botão primário centralizado ("Nova venda") — sem CTA duplicado.
 // Com dados, o FAB volta como ação rápida persistente.
 final hasSales = salesAsync.value?.isNotEmpty ?? false;

 final theme = Theme.of(context);

 return Scaffold(
 // AppBar estilo iOS large title: título grande, tracking apertado,
 // sem elevação — o conteúdo rola por baixo com o fundo contínuo.
 appBar: AppBar(
 toolbarHeight: 64,
 titleSpacing: AppSpacing.lg,
 title: Text(
 l10n.salesTitle,
 style: theme.textTheme.headlineSmall?.copyWith(
 fontWeight: FontWeight.w700,
 letterSpacing: -0.5,
 ),
 ),
 ),
 floatingActionButton: hasSales
 // FAB circular (design system — igual ao "Novo produto"): só o
 // sinal de +, com tooltip — o rótulo nunca é cortado pelo círculo.
 ? FloatingActionButton(
 heroTag: 'fab-sales',
 onPressed: _openNewSale,
 tooltip: l10n.salesNewSale,
 child: const Icon(Icons.add),
 )
 : null,
 body: salesAsync.when(
 // Skeleton loading no primeiro carregamento (o pull-to-refresh usa o
 // próprio indicador e mantém a lista visível).
 loading: () => const _SalesSkeleton(),
 error: (error, _) => ErrorView(
 message: l10n.salesLoadError,
 details: error.toString(),
 onRetry: () => ref.invalidate(salesListProvider),
 ),
 data: (sales) => _SalesBody(
 sales: sales,
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
 onNewSale: _openNewSale,
 ),
 ),
 );
 }
}

/// Conteúdo da tela com dados carregados: resumo do dia, busca, filtros e a
/// lista (slivers — só os cards visíveis são construídos).
class _SalesBody extends StatelessWidget {
 const _SalesBody({
 required this.sales,
 required this.searchController,
 required this.query,
 required this.period,
 required this.payment,
 required this.onQueryChanged,
 required this.onPeriodChanged,
 required this.onPaymentChanged,
 required this.onClearFilters,
 required this.onRefresh,
 required this.onNewSale,
 });

 final List<Sale> sales;
 final TextEditingController searchController;
 final String query;
 final PeriodFilter period;
 final PaymentFilter payment;
 final ValueChanged<String> onQueryChanged;
 final ValueChanged<PeriodFilter> onPeriodChanged;
 final ValueChanged<PaymentFilter> onPaymentChanged;
 final VoidCallback onClearFilters;
 final Future<void> Function() onRefresh;
 final VoidCallback onNewSale;

 bool _matchesQuery(Sale sale, AppLocalizations l10n) {
 if (query.isEmpty) return true;
 return Formatters.saleLabel(sale.number).toLowerCase().contains(query) ||
 sale.paymentMethod.labelFor(l10n).toLowerCase().contains(query) ||
 Formatters.day(sale.dateTime).toLowerCase().contains(query);
 }

 @override
 Widget build(BuildContext context) {
 final theme = Theme.of(context);
 final l10n = context.l10n;
 final filtered = [
 for (final sale in sales)
 if (period.matches(sale.dateTime) &&
 payment.matches(sale.paymentMethod) &&
 _matchesQuery(sale, l10n))
 sale,
 ];

 // Total (centavos) da seleção filtrada — exibido na linha-resumo. As
 // vendas ANULADAS saem da soma (mesmo critério do resumo do dia e dos
 // KPIs: o estorno já ajustou o caixa).
 final filteredTotalCents = filtered.fold<int>(
 0,
 (sum, sale) => sale.status == SaleStatus.cancelled
 ? sum
 : sum + sale.totalAmountCents,
 );
 // Filtro ativo (busca, período ou pagamento): mostra a linha-resumo
 // "X vendas · Total Y" para o caixa conferir o que está na tela.
 final isFiltering =
 query.isNotEmpty ||
 period != PeriodFilter.all ||
 payment != PaymentFilter.all;

 // Sem nenhuma venda na loja: estado vazio focado na ação principal.
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

 return RefreshIndicator(
 onRefresh: onRefresh,
 child: CustomScrollView(
 physics: const AlwaysScrollableScrollPhysics(),
 slivers: [
 // Resumo do dia rola junto com o conteúdo.
 SliverPadding(
 padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
 sliver: SliverToBoxAdapter(child: SalesSummaryHeader(sales: sales)),
 ),
 // Busca + filtros FIXOS: a lista rola por baixo deles
 // ([PinnedHeader] compartilhado com Compras).
 PinnedHeader(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.stretch,
 children: [
 SearchField(
 controller: searchController,
 hintText: l10n.salesSearchHint,
 onChanged: onQueryChanged,
 ),
 const SizedBox(height: 12),
 SalesFilterBar(
 period: period,
 payment: payment,
 onPeriodChanged: onPeriodChanged,
 onPaymentChanged: onPaymentChanged,
 ),
 ],
 ),
 ),
 // Linha-resumo do filtro: "3 vendas · Total R$ 1.234,56" — só
 // com filtro ativo, com fade sutil ao mudar (AnimatedSwitcher).
 SliverToBoxAdapter(
 child: AnimatedSwitcher(
 duration: const Duration(milliseconds: 200),
 child: isFiltering && filtered.isNotEmpty
 ? Padding(
 key: const ValueKey('sales-filtered-summary'),
 padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
 child: Align(
 alignment: Alignment.centerRight,
 // Sem ellipsis: o total filtrado é informação
 // essencial — quebra em linhas se não couber.
 child: Text(
 l10n.salesFilteredSummary(
 filtered.length,
 Formatters.currency(filteredTotalCents),
 ),
 textAlign: TextAlign.right,
 // Quebra em até 2 linhas — o total nunca é cortado.
 maxLines: 2,
 overflow: TextOverflow.ellipsis,
 style: theme.textTheme.labelSmall?.copyWith(
 color: theme.colorScheme.onSurfaceVariant,
 fontWeight: FontWeight.w600,
 ),
 ),
 ),
 )
 : const SizedBox.shrink(key: ValueKey('sales-filtered-none')),
 ),
 ),
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
 padding: const EdgeInsets.fromLTRB(20, 0, 20, 112),
 // Folha única estilo Home (FeedCard): um só card com as
 // vendas como linhas separadas por divisórias hairline.
 sliver: SliverToBoxAdapter(
 child: FeedCard(
 rows: [
 for (final sale in filtered)
 // RepaintBoundary: o ripple/tap de uma linha não
 // repinta as vizinhas; ValueKey preserva identidade.
 RepaintBoundary(
 key: ValueKey('sales-card-${sale.id}'),
 child: SalesCard(sale: sale),
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
/// suave (via [Skeleton]/[SkeletonBlock] compartilhados, sem shimmer e sem
/// dependência nova).
class _SalesSkeleton extends StatelessWidget {
 const _SalesSkeleton();

 @override
 Widget build(BuildContext context) {
 return Skeleton(
 child: ListView(
 padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
 children: [
 // Resumo do dia.
 const SkeletonBlock(height: 118, radius: 20),
 const SizedBox(height: 16),
 // Busca.
 const SkeletonBlock(height: 52),
 const SizedBox(height: 12),
 // Filtros.
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
