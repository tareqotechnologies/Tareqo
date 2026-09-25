import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/observability/crash_reporting.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
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
    final transactionsAsync = ref.watch(transactionsProvider);
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
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
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
                          currency: Formatters.currencySymbol,
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
                padding: const EdgeInsets.fromLTRB(0, AppSpacing.sm, 0, AppSpacing.fabBottomClearance),
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
                            hint: 'Erro ao receber pendência',
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
                            hint: 'Erro ao pagar saída pendente',
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
      context,
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
                hint: 'Erro ao receber pendência',
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
                hint: 'Erro ao pagar saída pendente',
              )
            : null,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cash flow card stack — saldo em destaque + entradas/saídas discretas.
// ---------------------------------------------------------------------------

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
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    return Semantics(
      container: true,
      excludeSemantics: true,
      label:
          '$balanceLabel: ${Formatters.currency(balance)}, '
          '$incomeLabel: ${Formatters.signedAmount(incomeCents)}, '
          '$expenseLabel: ${Formatters.signedAmount(-expenseCents)}',
      child: AppCard(
        elevated: true,
        borderRadius: AppRadius.xlAll,
        padding: const EdgeInsets.fromLTRB(20, AppSpacing.lg, 20, AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isLandscape) ...[
              // Landscape: label + balance + currency badge na mesma linha
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          balanceLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          Formatters.currency(balance),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: balanceColor,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppRadius.full),
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
              const SizedBox(height: 12),
              Divider(height: 1, color: scheme.outlineVariant),
              const SizedBox(height: 12),
              // Landscape: income e expense lado a lado
              Row(
                children: [
                  Expanded(
                    child: _CashLine(
                      icon: Icons.north_east,
                      color: theme.income,
                      label: incomeLabel,
                      value: Formatters.signedAmount(incomeCents),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _CashLine(
                      icon: Icons.south_west,
                      color: theme.expense,
                      label: expenseLabel,
                      value: Formatters.signedAmount(-expenseCents),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Portrait: layout vertical (original)
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
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppRadius.full),
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
              LayoutBuilder(
                builder: (context, constraints) {
                  final text = Formatters.currency(balance);
                  final baseSize =
                      theme.textTheme.displaySmall?.fontSize ?? 34.0;
                  final scale =
                      (constraints.maxWidth / (text.length * baseSize * 0.52))
                          .clamp(0.55, 1.0);
                  return Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontSize: baseSize * scale,
                      color: balanceColor,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.8,
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: scheme.outlineVariant),
              const SizedBox(height: 12),
              _CashLine(
                icon: Icons.north_east,
                color: theme.income,
                label: incomeLabel,
                value: Formatters.signedAmount(incomeCents),
              ),
              const SizedBox(height: 8),
              _CashLine(
                icon: Icons.south_west,
                color: theme.expense,
                label: expenseLabel,
                value: Formatters.signedAmount(-expenseCents),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

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
    final scheme = theme.colorScheme;

    return Semantics(
      container: true,
      label: '$label: $value',
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: IconTone.darkBackground(color),
            ),
            child: Icon(icon, size: 14, color: IconTone.lightForeground(color)),
          ),
          const SizedBox(width: 12),
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
          // Badge com folga ENCOLHÍVEL: o padding horizontal cede antes de
          // a Row estourar (escala de texto 2.0 em 360dp — migração 2.3
          // apanhou este limite: sm 12px +2px de folga zero).
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xxs,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
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
            color: scheme.surfaceContainerHighest,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl),
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
                      indent: 60,
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
    return Skeleton(
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
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
                    Row(
                      children: const [
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
                    if (i < 2) SizedBox(height: 16),
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

String _dateRangeLabel(CashFlowPeriod period, AppLocalizations l10n) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final fmt = Formatters.date;
  return switch (period) {
    CashFlowPeriod.today => fmt(today),
    CashFlowPeriod.week =>
      '${fmt(today.subtract(Duration(days: today.weekday - 1)))}–'
          '${fmt(today.add(Duration(days: 7 - today.weekday)))}',
    CashFlowPeriod.month =>
      '${fmt(DateTime(now.year, now.month, 1))}–'
          '${fmt(DateTime(now.year, now.month + 1, 0))}',
    CashFlowPeriod.all => l10n.periodAll,
  };
}
