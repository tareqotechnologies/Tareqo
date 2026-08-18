import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/observability/crash_reporting.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/financial_transaction.dart';
import '../../controllers/dashboard_providers.dart';
import '../../controllers/finance_providers.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/feed_card.dart';
import '../../widgets/inline_error_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/skeleton.dart';
import 'add_transaction_sheet.dart';
import 'cash_closing_sheet.dart';
import 'financial_widgets.dart';

/// Tela financeira — fluxo de caixa por período e movimentações.
class FinancialScreen extends ConsumerWidget {
 const FinancialScreen({super.key});

 @override
 Widget build(BuildContext context, WidgetRef ref) {
 final period = ref.watch(cashFlowPeriodProvider);
 final cashFlowAsync = ref.watch(cashFlowProvider);
 final transactionsAsync = ref.watch(transactionsProvider);
 final l10n = context.l10n;

 final cashFlow = cashFlowAsync.value;
 // Fecho de caixa é operação GERENCIAL (dono/gerente) — mesmo critério
 // de compras e anulação de venda. A autoridade é o servidor (RPC
 // close_cash_register); aqui só orientamos a navegação.
 final canClose = ref.watch(canCloseCashRegisterProvider);

 final theme = Theme.of(context);

 return Scaffold(
 // AppBar estilo iOS large title: título grande, tracking apertado,
 // sem elevação — mesmo padrão da tela de Vendas.
 appBar: AppBar(
 toolbarHeight: 64,
 titleSpacing: AppSpacing.lg,
 title: Text(
 l10n.financialTitle,
 style: theme.textTheme.headlineSmall?.copyWith(
 fontWeight: FontWeight.w500,
 letterSpacing: -0.5,
 ),
 ),
 actions: [
 if (canClose)
 IconButton(
 tooltip: l10n.cashClosingAction,
 icon: const Icon(Icons.lock_clock_outlined),
 onPressed: () => _openCashClosing(context, ref),
 ),
 ],
 ),
 // CTA único: sem movimentações, o FAB some — o estado vazio já traz
 // o botão "Registrar" centralizado (sem duplicação).
 floatingActionButton: transactionsAsync.value?.isNotEmpty ?? false
 // FAB circular (design system — igual ao "Novo produto"): só o
 // sinal de +, com tooltip — o rótulo nunca é cortado pelo círculo.
 ? FloatingActionButton(
 heroTag: 'fab-financial',
 onPressed: () => _openAddTransaction(context, ref),
 tooltip: l10n.financialRegister,
 child: const Icon(Icons.add),
 )
 : null,
 body: RefreshIndicator(
 // W8: puxar para atualizar — recarrega caixa e movimentações.
 onRefresh: () async {
 ref.invalidate(cashFlowProvider);
 ref.invalidate(transactionsProvider);
 await Future<void>.delayed(const Duration(milliseconds: 300));
 },
 child: CustomScrollView(
 physics: const AlwaysScrollableScrollPhysics(),
 slivers: [
 SliverPadding(
 padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
 sliver: SliverToBoxAdapter(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 // FittedBox: os 4 períodos (Hoje/7 dias/30 dias/Tudo)
 // encolhem em telas estreitas com escala de texto alta —
 // o SegmentedButton não quebra linha e estouraria sem o
 // scaleDown.
 //
 // Seletor em PÍLULAS (estilo Apple): StadiumBorder com
 // contorno sutil e o segmento ativo em primaryContainer —
 // mesma linguagem dos chips e da navegação. Sem sombra,
 // sem fundo "chapa": cada segmento é uma cápsula.
 Center(
 child: FittedBox(
 fit: BoxFit.scaleDown,
 child: SegmentedButton<CashFlowPeriod>(
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
 fontWeight: FontWeight.w500,
 ),
 ),
 segments: [
 for (final value in CashFlowPeriod.values)
 ButtonSegment(
 value: value,
 label: Text(value.label(l10n)),
 ),
 ],
 selected: {period},
 onSelectionChanged: (selection) => ref
 .read(cashFlowPeriodProvider.notifier)
 .select(selection.first),
 ),
 ),
 ),
 const SizedBox(height: 16),
 // Erro no fluxo de caixa: a linha de KPIs daria lugar
 // a três cards com "R$ 0,00" (ou um sentinela vazio
 // retido como valor anterior) — números falsos
 // parecendo reais. Um aviso compacto com retry toma o
 // lugar (mesmo padrão do dashboard). `hasError` sozinho:
 // o AsyncError retém o valor anterior, então testar
 // `value == null` nunca dispararia neste caso.
 // Card stack (V3): cartão de Entradas à frente (com
 // sparkline) + cartão de Saídas atrás — os totais do
 // período num relance, em vez de três KPIs lado a lado.
 if (cashFlowAsync.hasError)
 InlineErrorCard(
 message: l10n.financialCashFlowError,
 onRetry: () => ref.invalidate(cashFlowProvider),
 )
 else if (cashFlowAsync.isLoading)
 _CashStackSkeleton()
 else
 _CashStack(
 incomeCents: cashFlow?.incomeCents ?? 0,
 expenseCents: cashFlow?.expenseCents ?? 0,
 incomeLabel: l10n.financialIncome,
 expenseLabel: l10n.financialExpense,
 balanceLabel: l10n.financialPeriodBalance,
 currency: Formatters.currencySymbol,
 ),
 const SizedBox(height: 24),
 SectionHeader(title: l10n.financialTransactions),
 const SizedBox(height: 12),
 ],
 ),
 ),
 ),
 SliverPadding(
 padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
 sliver: transactionsAsync.when(
 loading: () =>
 const SliverToBoxAdapter(child: _TransactionsSkeleton()),
 error: (error, _) => SliverToBoxAdapter(
 child: ErrorView(
 message: l10n.financialLoadError,
 details: error.toString(),
 onRetry: () => ref.invalidate(transactionsProvider),
 ),
 ),
 data: (transactions) {
 if (transactions.isEmpty) {
 return SliverToBoxAdapter(
 child: EmptyState(
 icon: Icons.account_balance_wallet_outlined,
 title: l10n.financialEmptyTitle,
 subtitle: l10n.financialEmptySubtitle,
 actionLabel: l10n.financialRegister,
 onAction: () => _openAddTransaction(context, ref),
 ),
 );
 }
 // Folha única estilo Home (FeedCard): um só card com os
 // movimentos como linhas separadas por divisórias.
 return SliverToBoxAdapter(
 child: FeedCard(
 rows: [
 for (final transaction in transactions)
 RepaintBoundary(
 key: ValueKey(transaction.id),
 child: TransactionCard(
 transaction: transaction,
 onReceive:
 transaction.status ==
 TransactionStatus.pending &&
 transaction.type == TransactionType.income
 ? () => _settlePending(
 context,
 ref,
 transaction,
 title: l10n.financialReceivePendingTitle,
 body: l10n.financialReceivePendingBody,
 confirmLabel: l10n.financialReceive,
 success: l10n.financialReceived,
 failure: l10n.financialReceiveError,
 hint: 'Erro ao receber pendência',
 )
 : null,
 onPay:
 transaction.status ==
 TransactionStatus.pending &&
 transaction.type ==
 TransactionType.expense
 ? () => _settlePending(
 context,
 ref,
 transaction,
 title: l10n.financialPayPendingTitle,
 body: l10n.financialPayPendingBody,
 confirmLabel: l10n.financialPay,
 success: l10n.financialPaid,
 failure: l10n.financialPayError,
 hint: 'Erro ao pagar saída pendente',
 )
 : null,
 ),
 ),
 ],
 ),
 );
 },
 ),
 ),
 ],
 ),
 ),
 );
 }

 /// Quitação manual de uma pendência: RECEBE entradas pendentes (fiado)
 /// e PAGA saídas pendentes (contas a pagar) — o mesmo ciclo
 /// `pending → paid`, com textos e ação específicos por direção.
 ///
 /// A baixa é escopada pela loja da transação (nunca alcança um movimento
 /// de outra loja); após o sucesso, caixa, movimentações e KPIs recarregam.
 Future<void> _settlePending(
 BuildContext context,
 WidgetRef ref,
 FinancialTransaction transaction, {
 required String title,
 required String Function(String amount) body,
 required String confirmLabel,
 required String success,
 required String failure,
 required String hint,
 }) async {
 final messenger = ScaffoldMessenger.of(context);

 final confirmed = await showDialog<bool>(
 context: context,
 builder: (context) => AlertDialog(
 title: Text(title),
 content: Text(body(Formatters.currency(transaction.amountCents))),
 actions: [
 TextButton(
 onPressed: () => Navigator.of(context).pop(false),
 child: Text(context.l10n.commonCancel),
 ),
 // AppButton (design system ultra-clean): altura 48, cantos 12,
 // texto w400 — a confirmação segue o padrão dos demais diálogos.
 AppButton.primary(
 onPressed: () => Navigator.of(context).pop(true),
 label: confirmLabel,
 ),
 ],
 ),
 );
 if (confirmed != true || !context.mounted) return;

 try {
 await ref
 .read(markTransactionAsPaidUseCaseProvider)
 .call(transaction.id, storeId: transaction.storeId);
 if (!context.mounted) return;
 messenger.showSnackBar(SnackBar(content: Text(success)));
 ref.invalidate(transactionsProvider);
 ref.invalidate(cashFlowProvider);
 ref.invalidate(dashboardKpisProvider);
 } catch (error, stackTrace) {
 CrashReporting.capture(error, stackTrace, hint: hint);
 if (!context.mounted) return;
 messenger.showSnackBar(SnackBar(content: Text(failure)));
 }
 }

 Future<void> _openAddTransaction(BuildContext context, WidgetRef ref) async {
 await showAppSheet<void>(
 context,
 builder: (_) => const AddTransactionSheet(),
 );
 if (!context.mounted) return;
 ref.invalidate(cashFlowProvider);
 ref.invalidate(transactionsProvider);
 ref.invalidate(dashboardKpisProvider);
 }

 /// Abre o fecho de caixa do dia (Z-report com conferência física).
 Future<void> _openCashClosing(BuildContext context, WidgetRef ref) async {
 await showAppSheet<void>(context, builder: (_) => const CashClosingSheet());
 if (!context.mounted) return;
 ref.invalidate(cashFlowProvider);
 ref.invalidate(dashboardKpisProvider);
 }
}

/// Card principal do fluxo de caixa — design MINIMALISTA (V4): um único
/// cartão com cantos generosos e superfície elevada. O **saldo do período**
/// domina em display grande (tabular, cor semântica verde/vermelho), e
/// Entradas/Saídas ficam em duas linhas discretas por baixo — a leitura é
/// instantânea: o número grande primeiro, os componentes depois.
class _CashStack extends StatelessWidget {
 const _CashStack({
 required this.incomeCents,
 required this.expenseCents,
 required this.incomeLabel,
 required this.expenseLabel,
 required this.balanceLabel,
 required this.currency,
 });

 final int incomeCents;
 final int expenseCents;
 final String incomeLabel;
 final String expenseLabel;
 final String balanceLabel;
 final String currency;

 @override
 Widget build(BuildContext context) {
 final theme = Theme.of(context);
 final scheme = theme.colorScheme;
 final balance = incomeCents - expenseCents;
 final balanceColor = balance < 0 ? theme.expense : theme.income;

 return AppCard(
 elevated: true,
 borderRadius: AppRadius.xlAll,
 padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.stretch,
 children: [
 // Linha superior: rótulo do saldo + moeda em pílula discreta.
 Row(
 children: [
 Expanded(
 child: Text(
 balanceLabel,
 maxLines: 1,
 overflow: TextOverflow.ellipsis,
 style: theme.textTheme.labelLarge?.copyWith(
 color: scheme.onSurfaceVariant,
 ),
 ),
 ),
 const SizedBox(width: 12),
 Container(
 padding: const EdgeInsets.symmetric(
 horizontal: 10,
 vertical: 4,
 ),
 decoration: BoxDecoration(
 color: scheme.surfaceContainerLow,
 borderRadius: BorderRadius.circular(999),
 ),
 child: Text(
 currency,
 style: theme.textTheme.labelSmall?.copyWith(
 color: scheme.onSurfaceVariant,
 fontWeight: FontWeight.w500,
 letterSpacing: 0.4,
 ),
 ),
 ),
 ],
 ),
 const SizedBox(height: 8),
 // Saldo do período — o número grande que domina o card.
 FittedBox(
 fit: BoxFit.scaleDown,
 alignment: Alignment.centerLeft,
 child: Text(
 Formatters.currency(balance),
 maxLines: 1,
 style: theme.textTheme.displaySmall?.copyWith(
 color: balanceColor,
 fontWeight: FontWeight.w500,
 letterSpacing: -0.8,
 fontFeatures: const [FontFeature.tabularFigures()],
 ),
 ),
 ),
 const SizedBox(height: 16),
 // Divisória hairline separa o saldo dos componentes.
 Divider(height: 1, color: scheme.outlineVariant),
 const SizedBox(height: 10),
 // Entradas / Saídas em linhas discretas com ícone circular mínimo
 // e valor com sinal SEM o símbolo repetido — a moeda já está na
 // pílula e no saldo em destaque (uma única referência no card).
 // Direção igual ao feed da Home: entrada sobe, saída desce.
 _CashLine(
 icon: Icons.north_east,
 color: theme.income,
 label: incomeLabel,
 value: Formatters.signedAmount(incomeCents),
 ),
 const SizedBox(height: 6),
 _CashLine(
 icon: Icons.south_west,
 color: theme.expense,
 label: expenseLabel,
 value: Formatters.signedAmount(-expenseCents),
 ),
 ],
 ),
 );
 }
}

/// Linha discreta do card de caixa — ícone circular mínimo, rótulo e valor
/// ancorado à direita (tabular).
class _CashLine extends StatelessWidget {
 const _CashLine({
 required this.icon,
 required this.color,
 required this.label,
 required this.value,
 });

 final IconData icon;
 final Color color;
 final String label;
 final String value;

 @override
 Widget build(BuildContext context) {
 final theme = Theme.of(context);
 final scheme = theme.colorScheme;    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.12),
            border: Border.all(
              color: color.withValues(alpha: 0.25),
            ),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
 const SizedBox(width: 10),
 Expanded(
 child: Text(
 label,
 maxLines: 1,
 overflow: TextOverflow.ellipsis,
 style: theme.textTheme.bodyMedium?.copyWith(
 color: scheme.onSurfaceVariant,
 ),
 ),
 ),
 const SizedBox(width: 12),
 // FittedBox: com escala de texto alta o valor encolhe em vez de
 // estourar a linha.
 Flexible(
 child: FittedBox(
 fit: BoxFit.scaleDown,
 alignment: Alignment.centerRight,
 child: Text(
 value,
 maxLines: 1,
 style: theme.textTheme.bodyMedium?.copyWith(
 color: color,
 fontWeight: FontWeight.w500,
 fontFeatures: const [FontFeature.tabularFigures()],
 ),
 ),
 ),
 ),
 ],
 );
 }
}

/// Skeleton do card stack enquanto o fluxo de caixa carrega.
class _CashStackSkeleton extends StatelessWidget {
 const _CashStackSkeleton();

 @override
 Widget build(BuildContext context) {
 return Skeleton(
 child: AppCard(
 padding: const EdgeInsets.all(20),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: const [
 SkeletonBlock(width: 96, height: 14),
 SizedBox(height: 10),
 SkeletonBlock(width: 180, height: 32),
 SizedBox(height: 20),
 SkeletonBlock(width: 999, height: 1),
 SizedBox(height: 12),
 SkeletonBlock(width: 160, height: 16),
 SizedBox(height: 8),
 SkeletonBlock(width: 140, height: 16),
 ],
 ),
 ),
 );
 }
}

/// Skeleton loading das movimentações — blocos com o mesmo shape dos cards
/// reais e pulso suave (compartilhado com Vendas/Compras, sem shimmer).
class _TransactionsSkeleton extends StatelessWidget {
 const _TransactionsSkeleton();

 @override
 Widget build(BuildContext context) {
 return Skeleton(
 child: Column(
 children: [
 for (var i = 0; i < 4; i++) ...[
 // AppCard (design system ultra-clean): mesmo shape dos cards
 // reais (radius 12, flat) para o esqueleto não "pular" ao
 // carregar.
 AppCard(
 padding: const EdgeInsets.all(14),
 child: Row(
 children: const [
 SkeletonBlock(width: 44, height: 44),
 SizedBox(width: 12),
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 SkeletonBlock(width: 160, height: 14),
 SizedBox(height: 6),
 SkeletonBlock(width: 96, height: 12),
 ],
 ),
 ),
 SizedBox(width: 8),
 SkeletonBlock(width: 72, height: 20),
 ],
 ),
 ),
 SizedBox(height: 8),
 ],
 ],
 ),
 );
 }
}
