import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/observability/crash_reporting.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/financial_transaction.dart';
import '../../controllers/dashboard_providers.dart';
import '../../controllers/finance_providers.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/kpi_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/store_switcher.dart';
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
    final theme = Theme.of(context);

    final cashFlow = cashFlowAsync.value;
    // Fecho de caixa é operação GERENCIAL (dono/gerente) — mesmo critério
    // de compras e anulação de venda. A autoridade é o servidor (RPC
    // close_cash_register); aqui só orientamos a navegação.
    final canClose = ref.watch(canCloseCashRegisterProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.financialTitle),
        actions: [
          if (canClose)
            IconButton(
              tooltip: l10n.cashClosingAction,
              icon: const Icon(Icons.lock_clock_outlined),
              onPressed: () => _openCashClosing(context, ref),
            ),
          // Seletor rápido de loja ativa (multi-loja) — mais à direita.
          const StoreSwitcher(),
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
                    Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: SegmentedButton<CashFlowPeriod>(
                          showSelectedIcon: false,
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
                    Row(
                      children: [
                        Expanded(
                          child: KpiCard(
                            label: l10n.financialIncome,
                            amountCents: cashFlow?.incomeCents ?? 0,
                            icon: Icons.south_west,
                            iconBackground:
                                theme.income.withValues(alpha: 0.14),
                            iconColor: theme.income,
                            loading: cashFlowAsync.isLoading,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: KpiCard(
                            label: l10n.financialExpense,
                            amountCents: cashFlow?.expenseCents ?? 0,
                            icon: Icons.north_east,
                            iconBackground:
                                theme.expense.withValues(alpha: 0.14),
                            iconColor: theme.expense,
                            loading: cashFlowAsync.isLoading,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: KpiCard(
                            label: l10n.financialBalance,
                            amountCents: cashFlow?.balanceCents ?? 0,
                            icon: Icons.account_balance_wallet_outlined,
                            loading: cashFlowAsync.isLoading,
                          ),
                        ),
                      ],
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
                loading: () => const SliverToBoxAdapter(
                  child: _TransactionsSkeleton(),
                ),
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
                  return SliverList.separated(
                    itemCount: transactions.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final transaction = transactions[index];
                      return RepaintBoundary(
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
                                  transaction.type == TransactionType.expense
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
                      );
                    },
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
        content: Text(
          body(Formatters.currency(transaction.amountCents)),
        ),
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
    await showAppSheet<void>(
      context,
      builder: (_) => const CashClosingSheet(),
    );
    if (!context.mounted) return;
    ref.invalidate(cashFlowProvider);
    ref.invalidate(dashboardKpisProvider);
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
