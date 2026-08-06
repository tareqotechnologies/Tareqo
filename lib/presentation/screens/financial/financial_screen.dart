import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/financial_transaction.dart';
import '../../controllers/finance_providers.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/kpi_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/status_chip.dart';
import 'add_transaction_sheet.dart';
import '../../../core/observability/crash_reporting.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.financialTitle),
        actions: [
          IconButton(
            tooltip: l10n.commonRefresh,
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(cashFlowProvider.notifier).refresh();
              ref.read(transactionsProvider.notifier).refresh();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-financial',
        onPressed: () => _openAddTransaction(context, ref),
        icon: const Icon(Icons.add),
        label: Text(l10n.financialRegister),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
        children: [
          Center(
            child: SegmentedButton<CashFlowPeriod>(
              showSelectedIcon: false,
              segments: [
                for (final value in CashFlowPeriod.values)
                  ButtonSegment(value: value, label: Text(value.label(l10n))),
              ],
              selected: {period},
              onSelectionChanged: (selection) => ref
                  .read(cashFlowPeriodProvider.notifier)
                  .select(selection.first),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: KpiCard(
                  label: l10n.financialIncome,
                  value: Formatters.currency(cashFlow?.income ?? 0),
                  icon: Icons.south_west,
                  iconBackground: AppColors.income.withValues(alpha: 0.14),
                  iconColor: AppColors.income,
                  loading: cashFlowAsync.isLoading,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: KpiCard(
                  label: l10n.financialExpense,
                  value: Formatters.currency(cashFlow?.expense ?? 0),
                  icon: Icons.north_east,
                  iconBackground: AppColors.expense.withValues(alpha: 0.14),
                  iconColor: AppColors.expense,
                  loading: cashFlowAsync.isLoading,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: KpiCard(
                  label: l10n.financialBalance,
                  value: Formatters.currency(cashFlow?.balance ?? 0),
                  icon: Icons.account_balance_wallet_outlined,
                  loading: cashFlowAsync.isLoading,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SectionHeader(title: l10n.financialTransactions),
          const SizedBox(height: 12),
          transactionsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => ErrorView(
              message: l10n.financialLoadError,
              details: error.toString(),
              onRetry: () => ref.invalidate(transactionsProvider),
            ),
            data: (transactions) {
              if (transactions.isEmpty) {
                return EmptyState(
                  icon: Icons.account_balance_wallet_outlined,
                  title: l10n.financialEmptyTitle,
                  subtitle: l10n.financialEmptySubtitle,
                  actionLabel: l10n.financialRegister,
                  onAction: () => _openAddTransaction(context, ref),
                );
              }
              return Column(
                children: [
                  for (final transaction in transactions) ...[
                    _TransactionCard(
                      transaction: transaction,
                      onReceive:
                          transaction.status == TransactionStatus.pending &&
                              transaction.type == TransactionType.income
                          ? () => _receivePending(context, ref, transaction)
                          : null,
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              );
            },
          ),
        ],
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
            Formatters.currency(transaction.amount),
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
  }
}

/// Linha de movimentação: direção, descrição, categoria, data e valor.
class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.transaction, this.onReceive});

  final FinancialTransaction transaction;

  /// Ação de recebimento para entradas pendentes (null quando não aplicável).
  final VoidCallback? onReceive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIncome = transaction.type == TransactionType.income;
    final color = isIncome ? AppColors.income : AppColors.expense;
    final sign = isIncome ? '+' : '-';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isIncome ? Icons.south_west : Icons.north_east,
                size: 20,
                color: color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${transaction.category} · '
                    '${Formatters.day(transaction.date)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$sign ${Formatters.currency(transaction.amount)}',
                  style: theme.textTheme.titleMedium?.copyWith(color: color),
                ),
                const SizedBox(height: 4),
                if (transaction.status == TransactionStatus.pending) ...[
                  StatusChip(
                    label: context.l10n.statusPending,
                    color: AppColors.warning,
                    icon: Icons.schedule,
                  ),
                  if (onReceive != null) ...[
                    const SizedBox(height: 4),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onPressed: onReceive,
                      icon: const Icon(Icons.done_all, size: 16),
                      label: Text(context.l10n.financialReceive),
                    ),
                  ],
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
