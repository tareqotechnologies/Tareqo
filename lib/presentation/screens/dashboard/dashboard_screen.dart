import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/i18n/payment_method_l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/ui/dashed_circle_painter.dart';
import '../../../core/utils/app_clock.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/period_utils.dart';
import '../../../core/utils/quantity.dart';
import '../../../domain/entities/debt.dart';
import '../../../domain/entities/financial_transaction.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/purchase.dart';
import '../../../domain/entities/sale.dart';
import '../../../domain/entities/stock_transfer.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../controllers/auth_providers.dart';
import '../../controllers/dashboard_providers.dart';
import '../../controllers/debts_providers.dart';
import '../../controllers/expiry_alerts_provider.dart';
import '../../controllers/finance_providers.dart';
import '../../controllers/products_providers.dart';
import '../../controllers/purchases_providers.dart';
import '../../controllers/sales_providers.dart';
import '../../controllers/stock_transfers_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/premium_decor.dart';
import '../../widgets/app_menu_option.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/inline_error_card.dart';
import '../../widgets/store_switcher.dart';
import '../../navigation/app_routes.dart';
import '../../widgets/detail_row.dart';
import '../shell/app_shell.dart' show AppSection;

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
    final now = AppClock.now();
    final start = period.startOf(now);
    final previousStart = period.previousStartOf(now);

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
        ? ((periodSalesCents - previousSalesCents) / previousSalesCents * 100)
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
    final todayTransfers = ref
        .watch(stockTransfersProvider)
        .where((t) => !t.createdAt.isBefore(todayStart))
        .toList();
    final events = <_ActivityItem>[
      for (final sale in todaySales)
        _ActivityItem.sale(
          sale: sale,
          l10n: l10n,
          // U-09: rotas nomeadas (venda com argumento, resto sem).
          onTap: () => AppNavigator.pushWith(context, AppRoutes.saleDetail, {
            'sale': sale,
          }),
        ),
      for (final purchase in todayPurchases)
        for (final item in purchase.items)
          _ActivityItem.stockEntry(
            purchase: purchase,
            item: item,
            l10n: l10n,
            onTap: () => AppNavigator.push(context, AppRoutes.purchases),
          ),
      for (final debt in todaySettled)
        _ActivityItem.fiadoPayment(
          debt: debt,
          l10n: l10n,
          onTap: () => AppNavigator.pushSection(context, AppSection.credit),
        ),
      for (final transaction in todayExpenses)
        _ActivityItem.expense(
          transaction: transaction,
          l10n: l10n,
          // Despesa → secção Financeiro do shell: abrir a tela via rota da
          // secção (o Navigator empurra a secção correspondente — ver
          // AppNavigator.pushSection em app_routes.dart).
          onTap: () => AppNavigator.pushSection(context, AppSection.financial),
        ),
      for (final transfer in todayTransfers)
        _ActivityItem.transfer(
          transfer: transfer,
          l10n: l10n,
          onTap: () => _showTransferDetails(context, transfer),
        ),
    ]..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    final expiryAlerts = expiryAlertsAsync.value ?? const <ExpiryAlert>[];
    final activity = <_ActivityItem>[
      ...events.take(6),
      for (final product in lowStock)
        _ActivityItem.lowStock(
          product: product,
          l10n: l10n,
          onTap: () => AppNavigator.pushSection(context, AppSection.products),
        ),
      for (final alert in expiryAlerts)
        _ActivityItem.expiry(
          alert: alert,
          l10n: l10n,
          onTap: () => AppNavigator.pushSection(context, AppSection.products),
        ),
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
    final cashCents =
        (cashFlow?.incomeCents ?? 0) - (cashFlow?.expenseCents ?? 0);

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
            padding: EdgeInsets.fromLTRB(
              horizontal,
              AppSpacing.sm,
              horizontal,
              AppSpacing.xxl,
            ),
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
                            fontWeight: FontWeight.w600,
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
                  // 4.2: os KPIs chegam em centavos (int) — a contagem
                  // animada acontece no widget, o formato no final.
                  cashCents: cashCents,
                  cashNegative: cashCents < 0,
                  cashLoading: cashFlowAsync.isLoading,
                  salesCents: periodSalesCents,
                  salesSubtext: salesDelta == null
                      ? null
                      : '${salesDelta >= 0 ? '+' : ''}$salesDelta%',
                  salesSubtextColor: salesDelta == null
                      ? null
                      : salesDelta >= 0
                      ? AppColors.successNeutral
                      : AppColors.errorNeutral,
                  salesLoading: salesAsync.isLoading,
                  receivablesCents: kpis?.pendingTotalCents ?? 0,
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
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xxs,
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
    final l10n = context.l10n;
    final period = ref.watch(dashboardPeriodProvider);

    return AppMenuOption<CashFlowPeriod>(
      key: const ValueKey('dashboardPeriodPill'),
      label: period.label(l10n),
      options: [
        for (final option in CashFlowPeriod.values)
          AppMenuOptionItem(
            value: option,
            label: option.label(l10n),
            checked: option == period,
          ),
      ],
      onSelected: (selected) =>
          ref.read(dashboardPeriodProvider.notifier).select(selected),
    );
  }
}

/// Card-hero de saldo — o destaque da Home. Flat como o resto do design
/// system: superfície elevada, borda 1px e o rótulo da métrica CAIXA em
/// primaryContainer (mesma linguagem dos chips selecionados) — sem
/// gradientes nem sombras coloridas, que destoavam do resto do app.
/// Métricas Vendas / A receber em colunas secundárias separadas por uma
/// régua fina.
class _BalanceHero extends StatelessWidget {
  const _BalanceHero({
    required this.cashCents,
    required this.cashNegative,
    required this.cashLoading,
    required this.salesCents,
    required this.salesSubtext,
    required this.salesSubtextColor,
    required this.salesLoading,
    required this.receivablesCents,
    required this.receivablesSubtext,
    required this.receivablesLoading,
  });

  final int cashCents;
  final bool cashNegative;
  final bool cashLoading;

  final int salesCents;
  final String? salesSubtext;
  final Color? salesSubtextColor;
  final bool salesLoading;

  final int receivablesCents;
  final String? receivablesSubtext;
  final bool receivablesLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final scheme = theme.colorScheme;

    // Acabamento premium: superfície com véu de marca nos cantos e sombra
    // elevada em camadas — o conteúdo e a semântica são os mesmos.
    return AppCard(
      elevated: true,
      gradient: PremiumDecor.heroSurface(scheme, tint: theme.accent),
      borderRadius: AppRadius.xlAll,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Coluna da métrica CAIXA — chave cobre rótulo + valor
          // (os testes localizam label e número pelo mesmo key).
          // A11y (plano UI/UX — Fase 3.1): o leitor de ecrã lê RÓTULO +
          // VALOR como UM nó ("Caixa: 1.234,00 MZN") em vez de percorrer
          // pílula e número dígito a dígito.
          Semantics(
            key: const ValueKey('metric-cash'),
            container: true,
            excludeSemantics: true,
            label:
                '${l10n.dashboardMetricCash}: ${cashLoading ? '—' : Formatters.amountWithCode(cashCents / 100)}',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rótulo da métrica CAIXA em pílula de marca — o mesmo
                // papel visual dos chips selecionados do tema.
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 14,
                        color: scheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.dashboardMetricCash,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Valor grande e tabular — o destaque visual da Home.
                // Formato "1.000,00 MZN": valor + código da moeda.
                // 4.2: contagem animada até o valor final.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: _CountUpText(
                    cents: cashCents,
                    loading: cashLoading,
                    // Mesmo papel monetário do hero de Vendas — o app tem
                    // UMA escala de dinheiro (AppTypography.heroAmount).
                    style: AppTypography.heroAmount(
                      cashNegative ? AppColors.errorNeutral : scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Régua fina separando o saldo das métricas secundárias.
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _HeroMetric(
                  label: l10n.dashboardMetricSales,
                  cents: salesCents,
                  subtext: salesSubtext,
                  subtextColor: salesSubtextColor,
                  loading: salesLoading,
                  valueKey: const ValueKey('metric-sales'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Container(width: 1, height: 40, color: scheme.outlineVariant),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _HeroMetric(
                  label: l10n.dashboardMetricReceivables,
                  cents: receivablesCents,
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
    );
  }
}

/// Contagem animada dos KPIs do hero (plano UI/UX — item 4.2): o valor
/// sobe de 0 ao total em 600ms (`easeOutCubic`) — a Home "acorda". Com
/// `disableAnimations` (acessibilidade) renderiza o valor final direto;
/// trocar o período anima do valor atual ao novo. O rótulo semântico
/// (leitor de ecrã) é montado pelo PAI com o valor final — a animação é
/// só visual, nunca anunciada dígito a dígito.
class _CountUpText extends StatelessWidget {
  const _CountUpText({
    required this.cents,
    required this.loading,
    required this.style,
  });

  final int cents;
  final bool loading;
  final TextStyle? style;

  /// 600ms — o valor do plano (4.2) para a contagem do hero.
  static const Duration _countUp = Duration(milliseconds: 600);

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Text('—', maxLines: 1, style: style);
    }
    final valueText = Formatters.amountWithCode(cents / 100);
    if (MediaQuery.disableAnimationsOf(context)) {
      return Text(valueText, maxLines: 1, style: style);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: cents / 100),
      duration: _countUp,
      curve: AppCurves.standard,
      builder: (context, units, _) =>
          Text(Formatters.amountWithCode(units), maxLines: 1, style: style),
    );
  }
}

/// Coluna de métrica dentro do card-hero — rótulo, valor e subtexto
/// colorido (delta de vendas / contagem de fiados).
class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.label,
    required this.cents,
    required this.subtext,
    required this.subtextColor,
    required this.loading,
    required this.valueKey,
  });

  final String label;
  final int cents;
  final String? subtext;
  final Color? subtextColor;
  final bool loading;
  final Key valueKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final valueText = Formatters.amountWithCode(cents / 100);
    return Semantics(
      key: valueKey,
      container: true,
      excludeSemantics: true,
      // A11y (Fase 3.1): rótulo + valor (+ delta/contagem) lidos como UM
      // nó — "Vendas: 1.250,00 MZN, +18%" — em vez de nós separados.
      label: subtext == null
          ? '$label: ${loading ? '—' : valueText}'
          : '$label: ${loading ? '—' : valueText}, $subtext',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: _CountUpText(
              cents: cents,
              loading: loading,
              style: theme.textTheme.titleLarge?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
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
                color: subtextColor ?? scheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
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
    // ignore: unused_element_parameter — cor explícita é opcional;
    // quando null, _ActivityRow resolve via ThemeData (U-02).
    this.amountColor,
    this.badge,
    this.badgeColor,
    this.badgeBackground,
    this.dashedBorder = false,
    this.onTap,
  });
  factory _ActivityItem.sale({
    required Sale sale,
    required AppLocalizations l10n,
    required VoidCallback onTap,
  }) {
    // Cor de venda derivada do acento no call site (tema-aware) — o
    // factory não recebe context; o chamador passa scheme.primary /
    // IconTone derivados. Placeholder neutro mantido via defaults
    // resolvidos em _ActivityRow (ver amountColor fallback).
    return _ActivityItem(
      title: l10n.dashboardSaleEntry(Formatters.saleLabel(sale.number)),
      details:
          '${sale.paymentMethod.labelFor(l10n)} · '
          '${_timeLabel(sale.dateTime, l10n)}',
      dateTime: sale.dateTime,
      icon: Icons.north_east_rounded,
      // Círculo tingido (não sólido) — igual ao padrão IconTone dos
      // restantes itens; evita branco-sobre-laranja (U-02).
      iconBackground: IconTone.darkBackground(AppColors.accentOrange),
      iconColor: IconTone.lightForeground(AppColors.accentOrange),
      amount: Formatters.signedAmount(sale.totalAmountCents),
      // amountColor resolvido como scheme.primary em _ActivityRow
      // quando null (antes: AppColors.accentOrange fixo — claro em
      // ambos os temas, U-02).
      onTap: onTap,
    );
  }
  factory _ActivityItem.stockEntry({
    required Purchase purchase,
    required PurchaseItem item,
    required AppLocalizations l10n,
    VoidCallback? onTap,
  }) => _ActivityItem(
    title: l10n.dashboardStockEntry(item.productName),
    details: l10n.dashboardStockEntryDetail(
      '${Quantity.format(item.quantity)} un',
      _timeLabel(purchase.dateTime, l10n),
    ),
    dateTime: purchase.dateTime,
    icon: Icons.inventory_2_outlined,
    iconBackground: IconTone.darkBackground(IconTone.slate),
    iconColor: IconTone.lightForeground(IconTone.slate),
    amount: '+${Quantity.format(item.quantity)}',
    // Antes Colors.white incondicional — invisível sobre surface clara
    // (U-02). Null → _ActivityRow usa scheme.income (tema-aware).
    onTap: onTap,
  );
  factory _ActivityItem.fiadoPayment({
    required Debt debt,
    required AppLocalizations l10n,
    VoidCallback? onTap,
  }) {
    final paidAt = debt.paidAt ?? debt.dueDate;
    return _ActivityItem(
      title: l10n.dashboardFiadoPayment,
      details: '${debt.personName} · ${_timeLabel(paidAt, l10n)}',
      dateTime: paidAt,
      icon: Icons.payments_outlined,
      iconBackground: IconTone.darkBackground(IconTone.amber),
      iconColor: IconTone.lightForeground(IconTone.amber),
      amount: Formatters.signedAmount(debt.amountCents),
      // amountColor null → scheme.primary em _ActivityRow (U-02).
      dashedBorder: true,
      onTap: onTap,
    );
  }
  factory _ActivityItem.expense({
    required FinancialTransaction transaction,
    required AppLocalizations l10n,
    VoidCallback? onTap,
  }) => _ActivityItem(
    title: l10n.dashboardExpenseRow(transaction.description),
    details: _timeLabel(transaction.date, l10n),
    dateTime: transaction.date,
    icon: Icons.south_west_rounded,
    iconBackground: IconTone.darkBackground(IconTone.errorNeutral),
    iconColor: IconTone.lightForeground(IconTone.errorNeutral),
    amount: Formatters.signedAmount(-transaction.amountCents),
    // amountColor null → scheme.expense via _ActivityRow (U-02).
    onTap: onTap,
  );
  factory _ActivityItem.lowStock({
    required Product product,
    required AppLocalizations l10n,
    VoidCallback? onTap,
  }) => _ActivityItem(
    title: l10n.dashboardLowStock,
    details: l10n.dashboardLowStockDetail(
      product.name,
      '${Quantity.format(product.stockQuantity)} un',
    ),
    dateTime: AppClock.now(),
    icon: Icons.warning_amber_rounded,
    iconBackground: IconTone.darkBackground(IconTone.amber),
    iconColor: IconTone.lightForeground(IconTone.amber),
    badge: l10n.dashboardAlertBadge,
    badgeColor: IconTone.amber,
    badgeBackground: IconTone.amber,
    onTap: onTap,
  );
  factory _ActivityItem.expiry({
    required ExpiryAlert alert,
    required AppLocalizations l10n,
    VoidCallback? onTap,
  }) {
    final expired = alert.isExpired;
    final color = expired ? IconTone.errorNeutral : IconTone.amber;
    return _ActivityItem(
      title: alert.product.name,
      details: expired
          ? l10n.dashboardExpiredIn(-alert.daysRemaining)
          : l10n.dashboardExpiresIn(alert.daysRemaining),
      dateTime: AppClock.now(),
      icon: expired ? Icons.dangerous_outlined : Icons.hourglass_top_rounded,
      iconBackground: IconTone.darkBackground(color),
      iconColor: IconTone.lightForeground(color),
      badge: Quantity.format(
        alert.lot.currentQuantity,
        unitLabel: alert.product.vendaPorFracao
            ? alert.product.unitLabel
            : null,
        language: Formatters.currentLanguage,
      ),
      badgeColor: color,
      onTap: onTap,
    );
  }
  factory _ActivityItem.transfer({
    required StockTransfer transfer,
    required AppLocalizations l10n,
    VoidCallback? onTap,
  }) {
    final formattedQty = Quantity.format(
      transfer.quantityMilli,
      unitLabel: transfer.unitLabel,
      language: Formatters.currentLanguage,
    );
    return _ActivityItem(
      title: '${transfer.productName}  ·  $formattedQty',
      details: '${transfer.fromStoreName} → ${transfer.toStoreName}',
      dateTime: transfer.createdAt,
      icon: Icons.swap_horiz_outlined,
      iconBackground: IconTone.darkBackground(ModuleColors.stores),
      iconColor: IconTone.lightForeground(ModuleColors.stores),
      onTap: onTap,
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

/// Mostra detalhes da transferência num bottom sheet.
void _showTransferDetails(BuildContext context, StockTransfer transfer) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final formattedQty = Quantity.format(
    transfer.quantityMilli,
    unitLabel: transfer.unitLabel,
    language: Formatters.currentLanguage,
  );

  String transferStatusLabel(StockTransferStatus status) => switch (status) {
    StockTransferStatus.pending => context.l10n.transferStatusPending,
    StockTransferStatus.inTransit => context.l10n.transferStatusInTransit,
    StockTransferStatus.received => context.l10n.transferStatusReceived,
    StockTransferStatus.cancelled => context.l10n.transferStatusCancelled,
  };

  showModalBottomSheet<void>(
    context: context,
    builder: (_) => Padding(
      padding: AppSpacing.sheetPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: AppSpacing.xxxl,
              height: AppSpacing.xxs,
              margin: const EdgeInsets.only(
                top: AppSpacing.sm,
                bottom: AppSpacing.lg,
              ),
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: AppRadius.microAll,
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: IconTone.darkBackground(ModuleColors.stores),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.swap_horiz,
                  size: 18,
                  color: IconTone.lightForeground(ModuleColors.stores),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  transfer.productName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DetailRow.inline(
            icon: Icons.store_outlined,
            label: context.l10n.transfersRowOrigin,
            value: transfer.fromStoreName,
          ),
          const SizedBox(height: 8),
          DetailRow.inline(
            icon: Icons.storefront_outlined,
            label: context.l10n.transfersRowDest,
            value: transfer.toStoreName,
          ),
          const SizedBox(height: 8),
          DetailRow.inline(
            icon: Icons.inventory_2_outlined,
            label: context.l10n.transfersQuantity,
            value: formattedQty,
          ),
          const SizedBox(height: 8),
          DetailRow.inline(
            icon: Icons.calendar_today_outlined,
            label: context.l10n.transfersRowDate,
            value: Formatters.date(transfer.createdAt),
          ),
          const SizedBox(height: 8),
          DetailRow.inline(
            icon: Icons.info_outline,
            label: context.l10n.transfersRowStatus,
            value: transferStatusLabel(transfer.status),
          ),
          const SizedBox(height: 20),
        ],
      ),
    ),
  );
}

/// Rótulo de tempo do feed: < 1h → "há X min"; senão → hora absoluta.
String _timeLabel(DateTime date, AppLocalizations l10n) {
  final diff = AppClock.now().difference(date);
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

/// Linha do feed — ícone em container circular tingido + título/detalhe +
/// âncora à direita (valor ou badge). O valor recebido ≠ total no fiado usa
/// a borda tracejada térmica como marca de valor fora do padrão.
class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.item});

  final _ActivityItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Cores tema-aware de fallback (U-02): factories sem cor explícita
    // herdam do ThemeData (income/expense via AppColorsTheme) —entrada (+)
    // = income, saída (−) = expense, restante = scheme.primary.
    final amountFg =
        item.amountColor ??
        (item.amount != null
            ? (item.amount!.startsWith('+')
                  ? theme.income
                  : item.amount!.startsWith('-')
                  ? theme.expense
                  : scheme.primary)
            : item.badgeColor);

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
                  ? DashedCirclePainter(color: item.iconColor)
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
                    fontWeight: FontWeight.w600,
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
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: item.badgeBackground,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        // FittedBox scaleDown (mesmo padrão do StatusChip):
                        // badge longo (locale fr, fonte ampliada) ENCOLHE
                        // em vez de cortar — o texto da pílula fica 100%
                        // legível e nunca estoura a Row do feed.
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            item.badge!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                    : Text(
                        item.amount ?? item.badge!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            (item.amount != null
                                    ? theme.textTheme.bodyMedium
                                    : theme.textTheme.labelMedium)
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: item.amount != null
                                      ? amountFg
                                      : item.badgeColor,
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
