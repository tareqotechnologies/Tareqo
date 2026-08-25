import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/i18n/payment_method_l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/period_utils.dart';
import '../../../core/utils/quantity.dart';
import '../../../domain/entities/debt.dart';
import '../../../domain/entities/financial_transaction.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/purchase.dart';
import '../../../domain/entities/sale.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../controllers/auth_providers.dart';
import '../../controllers/dashboard_providers.dart';
import '../../controllers/debts_providers.dart';
import '../../controllers/expiry_alerts_provider.dart';
import '../../controllers/finance_providers.dart';
import '../../controllers/products_providers.dart';
import '../../controllers/purchases_providers.dart';
import '../../controllers/sales_providers.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/inline_error_card.dart';
import '../../widgets/store_switcher.dart';
import '../sales/sale_detail_screen.dart';

/// Limiar de "stock baixo" (W8 + W11): produtos com estoque inferior a
/// [Quantity.lowStockThresholdUnits] UNIDADES entram no alerta do
/// dashboard (o estoque vive em milésimos — a comparação usa ×1000).

/// Tela inicial do ERP — visão do dia com cara de app de referência:
/// cabeçalho tipográfico (data + saudação), pílula de período, chip da
/// loja, o card-hero de saldo (caixa em destaque + vendas/a receber) e o
/// feed "Atividade de hoje" com ícones circulares tintados.
class DashboardScreen extends ConsumerWidget {
 const DashboardScreen({super.key});

 @override
 Widget build(BuildContext context, WidgetRef ref) {
 final theme = Theme.of(context);
 final l10n = context.l10n;
 final user = ref.watch(authStateProvider).value;

 // Período da pílula "Hoje" — escopo das métricas Vendas/Caixa.
 final period = ref.watch(dashboardPeriodProvider);

 final productsAsync = ref.watch(productsProvider);
 final salesAsync = ref.watch(salesListProvider);
 final purchasesAsync = ref.watch(purchasesProvider);
 // Baixas de fiado (feed "Pagamento fiado") e movimentações (feed de
 // despesas) — o watch é incondicional; erro/ausência vira lista vazia.
 final settledAsync = ref.watch(settledDebtsProvider);
 final transactionsAsync = ref.watch(transactionsProvider);
 final pendingAsync = ref.watch(pendingDebtsProvider);
 // KPIs (W5): no modo Supabase a agregação roda no SERVIDOR (RPC
 // `get_dashboard_kpis`); no modo local, fallback client-side.
 final kpisAsync = ref.watch(dashboardKpisProvider);
 // Fluxo de caixa do período do DASHBOARD (Caixa do topo).
 final cashFlowAsync = ref.watch(dashboardCashFlowProvider);
 // Alertas de validade (W11): vermelho = vencido; amarelo = < 30 dias.
 final expiryAlertsAsync = ref.watch(expiryAlertsProvider);

 final kpis = kpisAsync.value;
 final cashFlow = cashFlowAsync.value;

 // ----- Métricas (3 cards compactos — app de referência) --------------
 final now = DateTime.now();
 final (start, previousStart) = switch (period) {
 CashFlowPeriod.today => (
 startOfDay(now),
 startOfDay(now).subtract(const Duration(days: 1)),
 ),
 CashFlowPeriod.week => (
 startOfDay(now).subtract(const Duration(days: 7)),
 startOfDay(now).subtract(const Duration(days: 14)),
 ),
 CashFlowPeriod.month => (
 DateTime(now.year, now.month, 1),
 DateTime(now.year, now.month - 1, 1),
 ),
 CashFlowPeriod.all => (DateTime(2000), null),
 };

 // Vendas do período + delta vs o período anterior ("+18%").
 var periodSalesCents = 0;
 var previousSalesCents = 0;
 for (final sale in salesAsync.value ?? const <Sale>[]) {
 if (sale.status == SaleStatus.cancelled) continue;
 if (!sale.dateTime.isBefore(start)) {
 periodSalesCents += sale.totalAmountCents;
 } else if (previousStart != null &&
 !sale.dateTime.isBefore(previousStart)) {
 previousSalesCents += sale.totalAmountCents;
 }
 }
 final salesDelta = previousSalesCents > 0
 ? ((periodSalesCents - previousSalesCents) /
 previousSalesCents *
 100)
 .round()
 : null;

 // ----- Feed "Atividade de hoje" --------------------------------------
 final todayStart = startOfDay(now);

 final todaySales = (salesAsync.value ?? const <Sale>[])
 .where(
 (sale) =>
 sale.status == SaleStatus.active &&
 !sale.dateTime.isBefore(todayStart),
 )
 .toList();
 final todayPurchases = (purchasesAsync.value ?? const <Purchase>[])
 .where((purchase) => !purchase.dateTime.isBefore(todayStart))
 .toList();
 final todaySettled = (settledAsync.value ?? const <Debt>[])
 .where(
 (debt) =>
 debt.isCustomerDebt &&
 debt.paidAt != null &&
 !debt.paidAt!.isBefore(todayStart),
 )
 .toList();
 final todayExpenses =
 (transactionsAsync.value ?? const <FinancialTransaction>[])
 .where(
 (t) =>
 t.type == TransactionType.expense &&
 t.status == TransactionStatus.paid &&
 !t.date.isBefore(todayStart),
 )
 .toList();

 // Produtos ATIVOS com estoque baixo (< 5 un) — alerta do feed.
 final lowStock = (productsAsync.value ?? const <Product>[])
 .where(
 (product) =>
 product.isActive &&
 product.stockQuantity <
 Quantity.lowStockThresholdUnits * Quantity.milliFactor,
 )
 .toList();

 // Feed: eventos datados de hoje ordenados por hora + alertas no fim.
 final events = <_ActivityItem>[
 for (final sale in todaySales)
 _ActivityItem.sale(
 sale: sale,
 l10n: l10n,
 // Tocar na venda do feed abre os detalhes (mesma navegação do
 // card compartilhado da lista de Vendas).
 onTap: () => Navigator.of(context).push(
 MaterialPageRoute<void>(
 builder: (_) => SaleDetailScreen(sale: sale),
 ),
 ),
 ),
 for (final purchase in todayPurchases)
 for (final item in purchase.items)
 _ActivityItem.stockEntry(purchase: purchase, item: item, l10n: l10n),
 for (final debt in todaySettled)
 _ActivityItem.fiadoPayment(debt: debt, l10n: l10n),
 for (final transaction in todayExpenses)
 _ActivityItem.expense(transaction: transaction, l10n: l10n),
 ]..sort((a, b) => b.dateTime.compareTo(a.dateTime));

 final expiryAlerts = expiryAlertsAsync.value ?? const <ExpiryAlert>[];
 final activity = <_ActivityItem>[
 ...events.take(6),
 for (final product in lowStock)
 _ActivityItem.lowStock(product: product, l10n: l10n),
 for (final alert in expiryAlerts)
 _ActivityItem.expiry(alert: alert, l10n: l10n),
 ];

 final displayName = (user?.fullName.isNotEmpty ?? false)
 ? user!.fullName.split(' ').first
 : (user?.email.isNotEmpty ?? false)
 ? user!.email.split('@').first
 : l10n.dashboardOwnerFallback;

 // Cabeçalho: data ACIMA da saudação ("Segunda, 17 ago").
 final dateLabel =
 '${_weekday(now.weekday, l10n)}, ${Formatters.shortDate(now)}';

 final horizontal = AppSpacing.pagePaddingForWidth(
 MediaQuery.sizeOf(context).width,
 );

 // Saldo de caixa (centavos → unidades) para o card-hero.
 final cashCents = (cashFlow?.incomeCents ?? 0) - (cashFlow?.expenseCents ?? 0);

 return Scaffold(
 body: SafeArea(
 child: RefreshIndicator(
 onRefresh: () async {
 ref.invalidate(dashboardKpisProvider);
 ref.invalidate(dashboardCashFlowProvider);
 ref.invalidate(productsProvider);
 ref.invalidate(salesListProvider);
 ref.invalidate(purchasesProvider);
 ref.invalidate(settledDebtsProvider);
 ref.invalidate(transactionsProvider);
 ref.invalidate(expiryAlertsProvider);
 await Future.wait<void>([
 ref
 .read(dashboardKpisProvider.future)
 .then<void>((_) {}, onError: (_) {}),
 ref
 .read(dashboardCashFlowProvider.future)
 .then<void>((_) {}, onError: (_) {}),
 ref
 .read(productsProvider.future)
 .then<void>((_) {}, onError: (_) {}),
 ref
 .read(salesListProvider.future)
 .then<void>((_) {}, onError: (_) {}),
 ref
 .read(purchasesProvider.future)
 .then<void>((_) {}, onError: (_) {}),
 ref
 .read(settledDebtsProvider.future)
 .then<void>((_) {}, onError: (_) {}),
 ref
 .read(transactionsProvider.future)
 .then<void>((_) {}, onError: (_) {}),
 ref
 .read(expiryAlertsProvider.future)
 .then<void>((_) {}, onError: (_) {}),
 ]);
 },
 child: ListView(
 // Sempre rolável: permite o pull-to-refresh mesmo com pouco
 // conteúdo na tela.
 physics: const AlwaysScrollableScrollPhysics(),
 padding: EdgeInsets.fromLTRB(horizontal, AppSpacing.sm, horizontal, AppSpacing.xxl),
 children: [
 // Cabeçalho tipográfico: data em caption ACIMA da saudação;
 // pílula de período à direita.
 Row(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 dateLabel,
 style: theme.textTheme.labelSmall?.copyWith(
 color: theme.colorScheme.onSurfaceVariant,
 letterSpacing: 0.6,
 fontWeight: FontWeight.w500,
 ),
 ),
 const SizedBox(height: 2),
 Text(
 l10n.dashboardGreeting(displayName),
 maxLines: 1,
 overflow: TextOverflow.ellipsis,
 style: theme.textTheme.headlineMedium?.copyWith(
 fontWeight: FontWeight.w500,
 letterSpacing: -0.6,
 ),
 ),
 ],
 ),
 ),
 const SizedBox(width: AppSpacing.sm),
 const _PeriodPill(),
 ],
 ),
 // Chip da loja ativa — discreto; com 2+ lojas vira o
 // seletor rápido; com 1 loja fica apenas informativo.
 const SizedBox(height: AppSpacing.sm + 2),
 const StoreSwitcher(hideWhenSingle: false),
 const SizedBox(height: AppSpacing.lg),
 const _SyncPendingBanner(),
 const SizedBox(height: AppSpacing.lg),
 // Card-hero de saldo (canvas estilo app de referência):
 // caixa em DESTAQUE + vendas/a receber como colunas
 // secundárias. Erro de KPIs: em vez de zeros falsos, um
 // aviso compacto com retry (`hasError` cobre o retry mesmo
 // quando o AsyncError retém o valor anterior).
 if (kpisAsync.hasError)
 InlineErrorCard(
 message: l10n.dashboardKpisError,
 onRetry: () => ref.invalidate(dashboardKpisProvider),
 )
 else
 _BalanceHero(
 cashValue: Formatters.amountWithCode(cashCents / 100),
 cashNegative: cashCents < 0,
 cashLoading: cashFlowAsync.isLoading,
 salesValue: Formatters.amountWithCode(periodSalesCents / 100),
 salesSubtext: salesDelta == null
 ? null
 : '${salesDelta >= 0 ? '+' : ''}$salesDelta%',
 salesSubtextColor: salesDelta == null
 ? null
 : salesDelta >= 0
 ? theme.income
 : theme.expense,
 salesLoading: salesAsync.isLoading,
 receivablesValue: Formatters.amountWithCode(
 (kpis?.pendingTotalCents ?? 0) / 100,
 ),
 receivablesSubtext: l10n.dashboardFiadoCount(
 (pendingAsync.value ?? const <Debt>[]).length,
 ),
 receivablesLoading: kpisAsync.isLoading,
 ),
 const SizedBox(height: AppSpacing.xl),
 // Feed de atividade — título à esquerda, contagem numa
 // pílula sutil à direita (estilo iOS: "Atividade" + badge).
 Row(
 children: [
 Expanded(
 child: Text(
 l10n.dashboardActivityTitle,
 style: theme.textTheme.titleLarge?.copyWith(
 fontWeight: FontWeight.w500,
 letterSpacing: -0.3,
 ),
 ),
 ),
 Container(
 padding: const EdgeInsets.symmetric(
 horizontal: 10,
 vertical: 4,
 ),
 decoration: BoxDecoration(
 color: theme.colorScheme.surfaceContainerHighest,
 borderRadius: BorderRadius.circular(AppRadius.full),
 ),
 child: Text(
 l10n.dashboardActivityEvents(activity.length),
 style: theme.textTheme.labelSmall?.copyWith(
 color: theme.colorScheme.onSurfaceVariant,
 fontWeight: FontWeight.w500,
 ),
 ),
 ),
 ],
 ),
 const SizedBox(height: AppSpacing.sm),
 if (activity.isEmpty)
 InlineEmpty(message: l10n.dashboardActivityEmpty)
 else
 _ActivityFeed(items: activity),
 ],
 ),
 ),
 ),
 );
 }

 static String _weekday(int weekday, AppLocalizations l10n) =>
 switch (weekday) {
 DateTime.monday => l10n.weekdayMonday,
 DateTime.tuesday => l10n.weekdayTuesday,
 DateTime.wednesday => l10n.weekdayWednesday,
 DateTime.thursday => l10n.weekdayThursday,
 DateTime.friday => l10n.weekdayFriday,
 DateTime.saturday => l10n.weekdaySaturday,
 _ => l10n.weekdaySunday,
 };
}

/// Seletor de período minimalista ("Hoje ▾") — só texto + chevron, sem
/// caixa nem borda (estilo iOS). Abre o menu Hoje / Semana / Mês / Tudo
/// e escopa as métricas Vendas/Caixa.
class _PeriodPill extends ConsumerWidget {
 const _PeriodPill();

 @override
 Widget build(BuildContext context, WidgetRef ref) {
 final theme = Theme.of(context);
 final l10n = context.l10n;
 final period = ref.watch(dashboardPeriodProvider);

 return PopupMenuButton<CashFlowPeriod>(
 key: const ValueKey('dashboardPeriodPill'),
 onSelected: (selected) =>
 ref.read(dashboardPeriodProvider.notifier).select(selected),
 itemBuilder: (context) => [
 for (final option in CashFlowPeriod.values)
 CheckedPopupMenuItem(
 value: option,
 checked: option == period,
 child: Text(option.label(l10n)),
 ),
 ],
 // Ripple mínimo só no próprio conteúdo (sem fundo próprio).
 child: Padding(
 padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
 child: Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 Text(
 period.label(l10n),
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
 );
 }
}

/// Card-hero de saldo (estilo app de referência) — caixa em destaque com
/// tipografia grande e tabular, mais as métricas Vendas / A receber em
/// colunas secundárias separadas por uma régua fina.
class _BalanceHero extends StatelessWidget {
 const _BalanceHero({
 required this.cashValue,
 required this.cashNegative,
 required this.cashLoading,
 required this.salesValue,
 required this.salesSubtext,
 required this.salesSubtextColor,
 required this.salesLoading,
 required this.receivablesValue,
 required this.receivablesSubtext,
 required this.receivablesLoading,
 });

 final String cashValue;
 final bool cashNegative;
 final bool cashLoading;

 final String salesValue;
 final String? salesSubtext;
 final Color? salesSubtextColor;
 final bool salesLoading;

 final String receivablesValue;
 final String receivablesSubtext;
 final bool receivablesLoading;

 @override
 Widget build(BuildContext context) {
 final theme = Theme.of(context);
 final l10n = context.l10n;

 return Container(
 decoration: BoxDecoration(
 borderRadius: BorderRadius.circular(AppRadius.xxl),
 gradient: const LinearGradient(
 begin: Alignment.topLeft,
 end: Alignment.bottomRight,
 stops: [0.0, 0.55, 1.0],
 colors: [
 Color(0xFF1E7A45),
 Color(0xFF0F4D2C),
 Color(0xFF0A3320),
 ],
 ),
 border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
 boxShadow: [
 BoxShadow(
 color: Colors.black.withValues(alpha: 0.40),
 blurRadius: 28,
 offset: const Offset(0, 14),
 ),
 ],
 ),
 clipBehavior: Clip.antiAlias,
 child: Stack(
 children: [
 // Brilhos internos (profundidade estilo iOS): um halo quente no
 // canto superior direito e um reflexo frio no inferior esquerdo.
 Positioned(
 right: -70,
 top: -90,
 child: Container(
 width: 240,
 height: 240,
 decoration: BoxDecoration(
 shape: BoxShape.circle,
 gradient: RadialGradient(
 colors: [
 Colors.white.withValues(alpha: 0.12),
 Colors.transparent,
 ],
 ),
 ),
 ),
 ),
 Positioned(
 left: -60,
 bottom: -100,
 child: Container(
 width: 200,
 height: 200,
 decoration: BoxDecoration(
 shape: BoxShape.circle,
 gradient: RadialGradient(
 colors: [
 const Color(0xFF34D399).withValues(alpha: 0.10),
 Colors.transparent,
 ],
 ),
 ),
 ),
 ),
 // Aresta superior de "vidro" — um filete claro que dá o efeito
 // de luz incidindo no topo do card (Apple Materials).
 Positioned(
 left: 0,
 right: 0,
 top: 0,
 child: IgnorePointer(
 child: Container(
 height: 1.2,
 decoration: BoxDecoration(
 gradient: LinearGradient(
 begin: Alignment.centerLeft,
 end: Alignment.centerRight,
 colors: [
 Colors.white.withValues(alpha: 0.0),
 Colors.white.withValues(alpha: 0.35),
 Colors.white.withValues(alpha: 0.0),
 ],
 ),
 ),
 ),
 ),
 ),
 Padding(
 padding: const EdgeInsets.all(AppSpacing.lg),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 // Coluna da métrica CAIXA — chave cobre rótulo + valor
 // (os testes localizam label e número pelo mesmo key).
 Column(
 key: const ValueKey('metric-cash'),
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Row(
 children: [
 Icon(
 Icons.account_balance_wallet_rounded,
 size: 16,
 color: Colors.white.withValues(alpha: 0.8),
 ),
 const SizedBox(width: 6),
 Text(
 l10n.dashboardMetricCash,
 style: theme.textTheme.labelMedium?.copyWith(
 color: Colors.white.withValues(alpha: 0.8),
 fontWeight: FontWeight.w500,
 letterSpacing: 0.5,
 ),
 ),
 ],
 ),
 const SizedBox(height: 6),
 // Valor grande e tabular — o destaque visual da Home.
 // Formato "1.000,00 MZN": valor + código da moeda.
 FittedBox(
 fit: BoxFit.scaleDown,
 alignment: Alignment.centerLeft,
 child: Text(
 cashLoading ? '—' : cashValue,
 maxLines: 1,
 style: theme.textTheme.displaySmall?.copyWith(
 color: cashNegative ? theme.expense : Colors.white,
 fontWeight: FontWeight.w500,
 letterSpacing: -1.2,
 height: 1.1,
 ),
 ),
 ),
 ],
 ),
 const SizedBox(height: AppSpacing.md),
 // Régua fina separando o saldo das métricas secundárias.
 Divider(
 height: 1,
 color: Colors.white.withValues(alpha: 0.14),
 ),
 const SizedBox(height: AppSpacing.sm),
 Row(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Expanded(
 child: _HeroMetric(
 label: l10n.dashboardMetricSales,
 value: salesValue,
 subtext: salesSubtext,
 subtextColor: salesSubtextColor,
 loading: salesLoading,
 valueKey: const ValueKey('metric-sales'),
 ),
 ),
 const SizedBox(width: AppSpacing.md),
 Container(
 width: 1,
 height: 40,
 color: Colors.white.withValues(alpha: 0.14),
 ),
 const SizedBox(width: AppSpacing.md),
 Expanded(
 child: _HeroMetric(
 label: l10n.dashboardMetricReceivables,
 value: receivablesValue,
 subtext: receivablesSubtext,
 subtextColor: theme.warning,
 loading: receivablesLoading,
 valueKey: const ValueKey('metric-receivables'),
 ),
 ),
 ],
 ),
 ],
 ),
 ),
 ],
 ),
 );
 }
}

/// Coluna de métrica dentro do card-hero — rótulo, valor e subtexto
/// colorido (delta de vendas / contagem de fiados).
class _HeroMetric extends StatelessWidget {
 const _HeroMetric({
 required this.label,
 required this.value,
 required this.subtext,
 required this.subtextColor,
 required this.loading,
 required this.valueKey,
 });

 final String label;
 final String value;
 final String? subtext;
 final Color? subtextColor;
 final bool loading;
 final Key valueKey;

 @override
 Widget build(BuildContext context) {
 final theme = Theme.of(context);

 return Column(
 key: valueKey,
 crossAxisAlignment: CrossAxisAlignment.start,
 mainAxisSize: MainAxisSize.min,
 children: [
 Text(
 label,
 maxLines: 1,
 overflow: TextOverflow.ellipsis,
 style: theme.textTheme.labelSmall?.copyWith(
 color: Colors.white.withValues(alpha: 0.6),
 fontWeight: FontWeight.w500,
 letterSpacing: 0.2,
 ),
 ),
 const SizedBox(height: 4),
 FittedBox(
 fit: BoxFit.scaleDown,
 alignment: Alignment.centerLeft,
 child: Text(
 loading ? '—' : value,
 maxLines: 1,
 style: theme.textTheme.titleLarge?.copyWith(
 color: Colors.white,
 fontWeight: FontWeight.w500,
 letterSpacing: -0.4,
 ),
 ),
 ),
 if (subtext != null) ...[
 const SizedBox(height: 2),
 Text(
 subtext!,
 maxLines: 1,
 overflow: TextOverflow.ellipsis,
 style: theme.textTheme.labelSmall?.copyWith(
 color: subtextColor ?? Colors.white.withValues(alpha: 0.6),
 fontWeight: FontWeight.w500,
 ),
 ),
 ],
 ],
 );
 }
}

/// Um item do feed de atividade — venda, entrada de estoque, pagamento de
/// fiado, despesa, estoque baixo ou alerta de validade.
class _ActivityItem {
 const _ActivityItem({
 required this.title,
 required this.details,
 required this.dateTime,
 required this.icon,
 required this.iconBackground,
 required this.iconColor,
 this.amount,
 this.amountColor,
 this.badge,
 this.badgeColor,
 this.badgeBackground,
 this.dashedBorder = false,
 this.onTap,
 });  factory _ActivityItem.sale({
    required Sale sale,
    required AppLocalizations l10n,
    required VoidCallback onTap,
  }) {
    return _ActivityItem(
      title: 'Venda ${Formatters.saleLabel(sale.number)}',
      details: '${sale.paymentMethod.labelFor(l10n)} · '
          '${_timeLabel(sale.dateTime, l10n)}',
      dateTime: sale.dateTime,
      icon: Icons.north_east_rounded,
      iconBackground: IconTone.greenDark,
      iconColor: IconTone.green,
      amount: Formatters.signedAmount(sale.totalAmountCents),
      amountColor: IconTone.green,
      onTap: onTap,
    );
  }  factory _ActivityItem.stockEntry({
    required Purchase purchase,
    required PurchaseItem item,
    required AppLocalizations l10n,
  }) =>
      _ActivityItem(
        title: l10n.dashboardStockEntry(item.productName),
        details: l10n.dashboardStockEntryDetail(
          '${Quantity.format(item.quantity)} un',
          _timeLabel(purchase.dateTime, l10n),
        ),
        dateTime: purchase.dateTime,
        icon: Icons.inventory_2_outlined,
        iconBackground: IconTone.slate,
        iconColor: Colors.white,
        amount: '+${Quantity.format(item.quantity)}',
        amountColor: Colors.white,
      );  factory _ActivityItem.fiadoPayment({
    required Debt debt,
    required AppLocalizations l10n,
  }) {
    final paidAt = debt.paidAt ?? debt.dueDate;
    return _ActivityItem(
      title: l10n.dashboardFiadoPayment,
      details: '${debt.personName} · ${_timeLabel(paidAt, l10n)}',
      dateTime: paidAt,
      icon: Icons.payments_outlined,
      iconBackground: IconTone.amberDark,
      iconColor: IconTone.amber,
      amount: Formatters.signedAmount(debt.amountCents),
      amountColor: IconTone.green,
      dashedBorder: true,
    );
  }  factory _ActivityItem.expense({
    required FinancialTransaction transaction,
    required AppLocalizations l10n,
  }) =>
      _ActivityItem(
        title: l10n.dashboardExpenseRow(transaction.description),
        details: _timeLabel(transaction.date, l10n),
        dateTime: transaction.date,
        icon: Icons.south_west_rounded,
        iconBackground: IconTone.redDark,
        iconColor: IconTone.red,
        amount: Formatters.signedAmount(-transaction.amountCents),
        amountColor: IconTone.red,
      );  factory _ActivityItem.lowStock({
    required Product product,
    required AppLocalizations l10n,
  }) =>
      _ActivityItem(
        title: l10n.dashboardLowStock,
        details: l10n.dashboardLowStockDetail(
          product.name,
          '${Quantity.format(product.stockQuantity)} un',
        ),
        dateTime: DateTime.now(),
        icon: Icons.warning_amber_rounded,
        iconBackground: IconTone.amberDark,
        iconColor: IconTone.amber,
        badge: l10n.dashboardAlertBadge,
        badgeColor: IconTone.amber,
        badgeBackground: IconTone.amber,
      );  factory _ActivityItem.expiry({
    required ExpiryAlert alert,
    required AppLocalizations l10n,
  }) {
    final expired = alert.isExpired;
    final color = expired ? IconTone.red : IconTone.amber;
    return _ActivityItem(
      title: alert.product.name,
      details: expired
          ? l10n.dashboardExpiredIn(-alert.daysRemaining)
          : l10n.dashboardExpiresIn(alert.daysRemaining),
      dateTime: DateTime.now(),
      icon: expired
          ? Icons.dangerous_outlined
          : Icons.hourglass_top_rounded,
      iconBackground: color.withValues(alpha: 0.18),
      iconColor: color,
      badge: Quantity.format(
        alert.lot.currentQuantity,
        unitLabel: alert.product.vendaPorFracao
            ? alert.product.unitLabel
            : null,
        language: Formatters.currentLanguage,
      ),
      badgeColor: color,
    );
  }

 final String title;
 final String details;
 final DateTime dateTime;
 final IconData icon;
 final Color iconBackground;
 final Color iconColor;

 /// Valor à direita (ex.: "+500,00").
 final String? amount;
 final Color? amountColor;

 /// Contagem/estado à direita (estoque baixo, validade).
 final String? badge;
 final Color? badgeColor;

 /// Fundo do badge (pílula sólida — ex.: "Alerta").
 final Color? badgeBackground;

 /// Borda TRACEJADA ao redor do ícone (pagamento de fiado).
 final bool dashedBorder;

 final VoidCallback? onTap;
}

/// Rótulo de tempo do feed: < 1h → "há X min"; senão → hora absoluta.
String _timeLabel(DateTime date, AppLocalizations l10n) {
 final diff = DateTime.now().difference(date);
 if (diff.inMinutes < 60) {
 return l10n.dashboardActivityMinutesAgo(diff.inMinutes);
 }
 return Formatters.time(date);
}

/// Feed de atividade — um card único elevado com as linhas separadas por
/// divisórias finas (mesma linguagem do app de referência).
class _ActivityFeed extends StatelessWidget {
 const _ActivityFeed({required this.items});

 final List<_ActivityItem> items;

 @override
 Widget build(BuildContext context) {
 final theme = Theme.of(context);

 return Material(
 color: theme.colorScheme.surfaceContainerHighest,
 elevation: 0,
 shape: RoundedRectangleBorder(
 borderRadius: BorderRadius.circular(AppRadius.xl),
 side: BorderSide(
 color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
 ),
 ),
 clipBehavior: Clip.antiAlias,
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.stretch,
 children: [
 for (var i = 0; i < items.length; i++) ...[
 if (i > 0)
 Divider(
 height: 1,
 indent: 60,
 endIndent: AppSpacing.md,
 color: theme.colorScheme.outlineVariant,
 ),
 _ActivityRow(item: items[i]),
 ],
 ],
 ),
 );
 }
}

/// Linha do feed — ícone em container circular tingido (com borda tracejada
/// opcional) + título/detalhe + âncora à direita (valor ou badge).
class _ActivityRow extends StatelessWidget {
 const _ActivityRow({required this.item});

 final _ActivityItem item;

 @override
 Widget build(BuildContext context) {
 final theme = Theme.of(context);

 final row = Padding(
 padding: const EdgeInsets.symmetric(
 horizontal: AppSpacing.md,
 vertical: AppSpacing.sm + 2,
 ),
 child: Row(
 children: [
 // Container circular do ícone (40px) — mesmo padrão do canvas.
 Container(
 width: 40,
 height: 40,
 decoration: BoxDecoration(
 color: item.iconBackground,
 shape: BoxShape.circle,
 ),
 child: CustomPaint(
 painter: item.dashedBorder
 ? _DashedCirclePainter(color: item.iconColor)
 : null,
 child: Icon(item.icon, size: 18, color: item.iconColor),
 ),
 ),
 const SizedBox(width: AppSpacing.sm),
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 item.title,
 maxLines: 1,
 overflow: TextOverflow.ellipsis,
 style: theme.textTheme.bodyMedium?.copyWith(
 fontWeight: FontWeight.w500,
 ),
 ),
 const SizedBox(height: 2),
 Text(
 item.details,
 maxLines: 1,
 overflow: TextOverflow.ellipsis,
 style: theme.textTheme.labelSmall?.copyWith(
 color: theme.colorScheme.onSurfaceVariant,
 ),
 ),
 ],
 ),
 ),
 const SizedBox(width: AppSpacing.xs),
 if (item.amount != null || item.badge != null)
 Flexible(
 child: Align(
 alignment: Alignment.centerRight,
 child: item.badgeBackground != null
 // Pílula sólida (ex.: "Alerta") — fundo colorido com
 // texto escuro, igual ao canvas.
 ? Container(
 padding: const EdgeInsets.symmetric(
 horizontal: 10,
 vertical: 4,
 ),
 decoration: BoxDecoration(
 color: item.badgeBackground,
 borderRadius: BorderRadius.circular(AppRadius.full),
 ),
 child: Text(
 item.badge!,
 maxLines: 1,
 style: theme.textTheme.labelSmall?.copyWith(
 color: const Color(0xFF101413),
 fontWeight: FontWeight.w500,
 ),
 ),
 )
 : Text(
 item.amount ?? item.badge!,
 maxLines: 1,
 overflow: TextOverflow.ellipsis,
 style: (item.amount != null
 ? theme.textTheme.bodyMedium
 : theme.textTheme.labelMedium)
 ?.copyWith(
 fontWeight: FontWeight.w500,
 color: item.amountColor ?? item.badgeColor,
 fontFeatures: const [
 FontFeature.tabularFigures(),
 ],
 ),
 ),
 ),
 ),
 ],
 ),
 );

 if (item.onTap == null) return row;
 return InkWell(
 onTap: item.onTap,
 borderRadius: BorderRadius.circular(AppRadius.lg),
 child: row,
 );
 }
}

/// Desenha a borda TRACEJADA circular do ícone de pagamento de fiado.
class _DashedCirclePainter extends CustomPainter {
 const _DashedCirclePainter({required this.color});

 final Color color;

 @override
 void paint(Canvas canvas, Size size) {
 final paint = Paint()
 ..color = color
 ..style = PaintingStyle.stroke
 ..strokeWidth = 1.4;
 final center = size.center(Offset.zero);
 final radius = size.width / 2 - 2;
 const dashCount = 12;
 const totalAngle = 2 * 3.141592653589793;
 final dashAngle = totalAngle / dashCount;
 for (var i = 0; i < dashCount; i++) {
 canvas.drawArc(
 Rect.fromCircle(center: center, radius: radius),
 i * dashAngle,
 dashAngle * 0.55,
 false,
 paint,
 );
 }
 }

 @override
 bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) =>
 oldDelegate.color != color;
}

/// Banner de sincronização pendente (outbox offline do modo SaaS).
///
/// Aparece no topo do dashboard quando há operações do caminho de dinheiro
/// enfileiradas sem conexão ([pendingOpsCountProvider] > 0) e some sozinho
/// quando a fila esvazia. "Sincronizar" dispara o dreno imediato da fila.
class _SyncPendingBanner extends ConsumerWidget {
 const _SyncPendingBanner();

 @override
 Widget build(BuildContext context, WidgetRef ref) {
 final theme = Theme.of(context);
 final l10n = context.l10n;
 final count = ref.watch(pendingOpsCountProvider).value ?? 0;
 if (count <= 0) return const SizedBox.shrink();

 return AppCard(
 color: theme.warning.withValues(alpha: 0.08),
 borderColor: theme.warning.withValues(alpha: 0.30),
 padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
 child: Row(
 children: [
 Icon(
 Icons.cloud_off_outlined,
 color: theme.warning.withValues(alpha: 0.9),
 size: 20,
 ),
 const SizedBox(width: AppSpacing.sm),
 Expanded(
 child: Text(
 l10n.syncPendingCount(count),
 style: theme.textTheme.bodySmall?.copyWith(
 color: theme.colorScheme.onSurfaceVariant,
 fontWeight: FontWeight.w500,
 ),
 ),
 ),
 TextButton(
 onPressed: () => _syncNow(context, ref),
 style: TextButton.styleFrom(
 minimumSize: const Size(0, 36),
 padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
 ),
 child: Text(l10n.syncNow),
 ),
 ],
 ),
 );
 }

 Future<void> _syncNow(BuildContext context, WidgetRef ref) async {
 final messenger = ScaffoldMessenger.of(context);
 final l10n = context.l10n;
 final sync = ref.read(offlineSyncServiceProvider);
 if (sync == null) return;
 final synced = await sync.drain();
 if (!context.mounted) return;
 messenger.showSnackBar(
 SnackBar(
 content: Text(
 synced > 0 ? l10n.syncDone(synced) : l10n.syncStillOffline,
 ),
 ),
 );
 }
}
