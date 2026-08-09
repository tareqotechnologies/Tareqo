import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/observability/crash_reporting.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/financial_transaction.dart';
import '../../controllers/dashboard_providers.dart';
import '../../controllers/finance_providers.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/kpi_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/skeleton.dart';
import 'add_transaction_sheet.dart';
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

    return Scaffold(
      appBar: AppBar(title: Text(l10n.financialTitle)),
      // CTA único: sem movimentações, o FAB some — o estado vazio já traz
      // o botão "Registrar" centralizado (sem duplicação).
      floatingActionButton: transactionsAsync.value?.isNotEmpty ?? false
          ? FloatingActionButton.extended(
              heroTag: 'fab-financial',
              onPressed: () => _openAddTransaction(context, ref),
              icon: const Icon(Icons.add),
              label: Text(l10n.financialRegister),
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
                            value: Formatters.currency(cashFlow?.incomeCents ?? 0),
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
                            value:
                                Formatters.currency(cashFlow?.expenseCents ?? 0),
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
                            value:
                                Formatters.currency(cashFlow?.balanceCents ?? 0),
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
                              ? () =>
                                  _receivePending(context, ref, transaction)
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

  /// Recebimento manual de uma entrada pendente (fiado): marca como paga
  /// e recarrega caixa e movimentações.
  Future<void> _receivePending(
    BuildContext context,
    WidgetRef ref,
    FinancialTransaction transaction,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.financialReceivePendingTitle),
        content: Text(
          l10n.financialReceivePendingBody(
            Formatters.currency(transaction.amountCents),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.financialReceive),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      // O recebimento é escopado pela loja da transação — a baixa nunca
      // alcança um movimento de outra loja.
      await ref
          .read(markTransactionAsPaidUseCaseProvider)
          .call(transaction.id, storeId: transaction.storeId);
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.financialReceived)));
      ref.invalidate(transactionsProvider);
      ref.invalidate(cashFlowProvider);
      ref.invalidate(dashboardKpisProvider);
    } catch (error, stackTrace) {
      CrashReporting.capture(
        error,
        stackTrace,
        hint: 'Erro ao receber pendência',
      );
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.financialReceiveError)),
      );
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
            Card(
              child: Padding(
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
            ),
            SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
