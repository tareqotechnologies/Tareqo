import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/observability/crash_reporting.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/app_clock.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/financial_transaction.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../controllers/dashboard_providers.dart';
import '../../controllers/finance_providers.dart';
import '../../widgets/app_page.dart';
import '../../widgets/app_segmented_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/inline_error_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/skeleton.dart';
import 'add_transaction_sheet.dart';
import 'cash_closing_sheet.dart';
import 'financial_widgets.dart';

/// Tela financeira — fluxo de caixa por período e movimentações agrupadas
/// por data, estilo Apple Wallet / Stripe Dashboard.
class FinancialScreen extends ConsumerWidget {
  const FinancialScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(cashFlowPeriodProvider);
    final cashFlowAsync = ref.watch(cashFlowProvider);
    // Lista recortada pelo período selecionado (mesmo recorte do fluxo).
    final transactionsAsync = ref.watch(periodTransactionsProvider);
    final l10n = context.l10n;

    final cashFlow = cashFlowAsync.value;
    final canClose = ref.watch(canCloseCashRegisterProvider);
    final transactions = transactionsAsync.value ?? const [];
    final pendingCount = transactions
        .where((t) => t.status == TransactionStatus.pending)
        .length;

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final horizontal = AppSpacing.pagePaddingForWidth(
      MediaQuery.sizeOf(context).width,
    );

    return AppPage(
      title: l10n.financialTitle,
      useSafeArea: false,
      actions: [
        if (canClose)
          IconButton(
            tooltip: l10n.cashClosingAction,
            icon: const Icon(Icons.lock_clock_outlined),
            onPressed: () => _openCashClosing(context, ref),
          ),
      ],
      floatingActionButton: transactions.isNotEmpty
          ? FloatingActionButton(
              heroTag: 'fab-financial',
              onPressed: () => _openAddTransaction(context, ref),
              tooltip: l10n.financialRegister,
              child: const Icon(Icons.add),
            )
          : null,
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(cashFlowProvider);
            ref.invalidate(transactionsProvider);
            await Future<void>.delayed(const Duration(milliseconds: 300));
          },
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── Period selector + date range ──
              SliverPadding(
                padding: EdgeInsets.fromLTRB(horizontal, 4, horizontal, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: AppSegmentedButton<CashFlowPeriod>(
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
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          _dateRangeLabel(period, l10n),
                          // U-23: bodySmall 12px em onSurfaceVariant (#757575
                          // = 3.5:1) falha AA para texto pequeno — usar
                          // preto #212121 (11.7:1 sobre gelo).
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Cash flow card stack ──
              SliverPadding(
                padding: EdgeInsets.fromLTRB(horizontal, 16, horizontal, 0),
                sliver: SliverToBoxAdapter(
                  child: cashFlowAsync.hasError
                      ? InlineErrorCard(
                          message: l10n.financialCashFlowError,
                          onRetry: () => ref.invalidate(cashFlowProvider),
                        )
                      : cashFlowAsync.isLoading
                      ? const _CashStackSkeleton()
                      : _CashStack(
                          incomeCents: cashFlow?.incomeCents ?? 0,
                          expenseCents: cashFlow?.expenseCents ?? 0,
                          incomeLabel: l10n.financialIncome,
                          expenseLabel: l10n.financialExpense,
                          balanceLabel: l10n.financialPeriodBalance,
                        ),
                ),
              ),

              // ── Transactions section header ──
              SliverPadding(
                padding: EdgeInsets.fromLTRB(horizontal, 24, horizontal, 0),
                sliver: SliverToBoxAdapter(
                  child: SectionHeader(
                    title: l10n.financialTransactions,
                    subtitle: pendingCount > 0 && transactionsAsync.hasValue
                        ? '${l10n.financialPendingLabel} · $pendingCount'
                        : null,
                  ),
                ),
              ),

              // ── Transactions ──
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  0,
                  AppSpacing.sm,
                  0,
                  AppSpacing.fabBottomClearance,
                ),
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

                    final groups = _groupByDate(transactions);

                    return SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final group = groups[index];
                        return _DateGroup(
                          date: group.date,
                          label: group.label,
                          totalCents: group.totalCents,
                          transactions: group.transactions,
                          onTap: (tx) =>
                              _openTransactionDetail(context, ref, tx),
                          onReceive: (tx) => _settlePending(
                            context,
                            ref,
                            tx,
                            title: l10n.financialReceivePendingTitle,
                            body: l10n.financialReceivePendingBody,
                            confirmLabel: l10n.financialReceive,
                            success: l10n.financialReceived,
                            failure: l10n.financialReceiveError,
                            hint: 'financial_receive_pending',
                          ),
                          onPay: (tx) => _settlePending(
                            context,
                            ref,
                            tx,
                            title: l10n.financialPayPendingTitle,
                            body: l10n.financialPayPendingBody,
                            confirmLabel: l10n.financialPay,
                            success: l10n.financialPaid,
                            failure: l10n.financialPayError,
                            hint: 'financial_pay_pending',
                          ),
                        );
                      }, childCount: groups.length),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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

    final confirmed = await showConfirmDialog(
      context: context,
      title: title,
      message: body(Formatters.currency(transaction.amountCents)),
      confirmLabel: confirmLabel,
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

  Future<void> _openCashClosing(BuildContext context, WidgetRef ref) async {
    await showAppSheet<void>(context, builder: (_) => const CashClosingSheet());
    if (!context.mounted) return;
    ref.invalidate(cashFlowProvider);
    ref.invalidate(dashboardKpisProvider);
  }

  void _openTransactionDetail(
    BuildContext context,
    WidgetRef ref,
    FinancialTransaction tx,
  ) {
    final l10n = context.l10n;
    final pending = tx.status == TransactionStatus.pending;
    showAppSheet<void>(
      context,
      builder: (_) => TransactionDetailSheet(
        transaction: tx,
        onReceive: pending && tx.type == TransactionType.income
            ? () => _settlePending(
                context,
                ref,
                tx,
                title: l10n.financialReceivePendingTitle,
                body: l10n.financialReceivePendingBody,
                confirmLabel: l10n.financialReceive,
                success: l10n.financialReceived,
                failure: l10n.financialReceiveError,
                hint: 'financial_receive_pending',
              )
            : null,
        onPay: pending && tx.type == TransactionType.expense
            ? () => _settlePending(
                context,
                ref,
                tx,
                title: l10n.financialPayPendingTitle,
                body: l10n.financialPayPendingBody,
                confirmLabel: l10n.financialPay,
                success: l10n.financialPaid,
                failure: l10n.financialPayError,
                hint: 'financial_pay_pending',
              )
            : null,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cash flow card — rótulo à esquerda, valor à direita, mesma margem.
// ---------------------------------------------------------------------------

class _CashStack extends StatelessWidget {
  const _CashStack({
    required this.incomeCents,
    required this.expenseCents,
    required this.incomeLabel,
    required this.expenseLabel,
    required this.balanceLabel,
  });

  final int incomeCents;
  final int expenseCents;
  final String incomeLabel;
  final String expenseLabel;
  final String balanceLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final balance = incomeCents - expenseCents;
    final balanceColor = balance < 0 ? theme.expense : theme.income;

    return Semantics(
      container: true,
      excludeSemantics: true,
      label:
          '$balanceLabel: ${Formatters.currency(balance)}, '
          '$incomeLabel: ${Formatters.signedAmount(incomeCents)}, '
          '$expenseLabel: ${Formatters.signedAmount(-expenseCents)}',
      child: AppCard(
        color: scheme.surface,
        borderRadius: AppRadius.xlAll,
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Saldo Principal ──
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.xl),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    balanceLabel,
                    style: AppTypography.labelMedium.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      Formatters.currency(balance),
                      // Token heroAmount (26/w600) — teto do sistema
                      // (U-06). Sem copyWith de tamanho/peso.
                      style: AppTypography.heroAmount(balanceColor),
                    ),
                  ),
                ],
              ),
            ),

            // ── Entradas e Saídas ──
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      child: _CashStatItem(
                        icon: Icons.arrow_downward_rounded,
                        color: theme.income,
                        label: incomeLabel,
                        value: Formatters.signedAmount(incomeCents),
                      ),
                    ),
                    VerticalDivider(
                      width: 32,
                      thickness: 1,
                      color: scheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                    Expanded(
                      child: _CashStatItem(
                        icon: Icons.arrow_upward_rounded,
                        color: theme.expense,
                        label: expenseLabel,
                        value: Formatters.signedAmount(-expenseCents),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CashStatItem extends StatelessWidget {
  const _CashStatItem({
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
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 14, color: color),
            ),
            const SizedBox(width: AppSpacing.xs),
            // U-03: escala 2.0 sem clamp — rótulo encolhe/trunca.
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelSmall.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Date-grouped transaction list.
// ---------------------------------------------------------------------------

class _DateGroup extends StatelessWidget {
  const _DateGroup({
    required this.date,
    required this.label,
    required this.totalCents,
    required this.transactions,
    required this.onTap,
    required this.onReceive,
    required this.onPay,
  });

  final DateTime date;
  final String label;
  final int totalCents;
  final List<FinancialTransaction> transactions;
  final ValueChanged<FinancialTransaction> onTap;
  final ValueChanged<FinancialTransaction> onReceive;
  final ValueChanged<FinancialTransaction> onPay;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final horizontal = AppSpacing.pagePaddingForWidth(
      MediaQuery.sizeOf(context).width,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DateSectionHeader(label: label, totalCents: totalCents),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontal),
          child: Material(
            // Painel de lista = mesmo raio dos cartões (lg/18) — U-17.
            // (O comentário anterior dizia 16/20, valores que não são
            // tokens do sistema.)
            color: scheme.surface,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              side: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < transactions.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      indent: AppSpacing.huge + AppSpacing.sm,
                      endIndent: AppSpacing.md,
                      color: scheme.outlineVariant,
                    ),
                  TransactionCard(
                    key: ValueKey(transactions[i].id),
                    transaction: transactions[i],
                    onTap: () => onTap(transactions[i]),
                    onReceive:
                        transactions[i].status == TransactionStatus.pending &&
                            transactions[i].type == TransactionType.income
                        ? () => onReceive(transactions[i])
                        : null,
                    onPay:
                        transactions[i].status == TransactionStatus.pending &&
                            transactions[i].type == TransactionType.expense
                        ? () => onPay(transactions[i])
                        : null,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Skeletons.
// ---------------------------------------------------------------------------

class _CashStackSkeleton extends StatelessWidget {
  const _CashStackSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Skeleton(
      child: AppCard(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBlock(width: 96, height: 14),
            SizedBox(height: 12),
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

class _TransactionsSkeleton extends StatelessWidget {
  const _TransactionsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xs,
            ),
            child: SkeletonBlock(width: 120, height: 14),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    const Row(
                      children: [
                        SkeletonBlock(width: 42, height: 42),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SkeletonBlock(width: 160, height: 14),
                              SizedBox(height: 8),
                              SkeletonBlock(width: 96, height: 12),
                            ],
                          ),
                        ),
                        SizedBox(width: 8),
                        SkeletonBlock(width: 72, height: 20),
                      ],
                    ),
                    if (i < 2) const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers.
// ---------------------------------------------------------------------------

List<_DateGroupData> _groupByDate(List<FinancialTransaction> transactions) {
  final map = <String, _DateGroupData>{};

  for (final tx in transactions) {
    final day = DateTime(tx.date.year, tx.date.month, tx.date.day);
    final key = day.toIso8601String().substring(0, 10);

    if (map.containsKey(key)) {
      final prev = map[key]!;
      map[key] = _DateGroupData(
        date: day,
        label: prev.label,
        totalCents: prev.totalCents + _signedCents(tx),
        transactions: [...prev.transactions, tx],
      );
    } else {
      map[key] = _DateGroupData(
        date: day,
        label: Formatters.day(day),
        totalCents: _signedCents(tx),
        transactions: [tx],
      );
    }
  }

  final groups = map.values.toList()..sort((a, b) => b.date.compareTo(a.date));
  return groups;
}

int _signedCents(FinancialTransaction tx) =>
    tx.type == TransactionType.income ? tx.amountCents : -tx.amountCents;

class _DateGroupData {
  const _DateGroupData({
    required this.date,
    required this.label,
    required this.totalCents,
    required this.transactions,
  });

  final DateTime date;
  final String label;
  final int totalCents;
  final List<FinancialTransaction> transactions;
}

/// Intervalo REAL consultado pelo fluxo de caixa: do início do período
/// ([CashFlowPeriodStart.startOf] — a mesma regra do provider) até agora.
/// O rótulo nunca deve divergir do que a soma mostra.
String _dateRangeLabel(CashFlowPeriod period, AppLocalizations l10n) {
  if (period == CashFlowPeriod.all) return l10n.periodAll;
  final now = AppClock.now();
  final start = period.startOf(now);
  return '${Formatters.date(start)}–${Formatters.date(now)}';
}
