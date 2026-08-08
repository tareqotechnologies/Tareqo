import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/debt.dart';
import '../../../domain/usecases/settle_debt_use_case.dart';
import '../../controllers/account_providers.dart';
import '../../controllers/auth_providers.dart';
import '../../controllers/dashboard_providers.dart';
import '../../controllers/debts_providers.dart';
import '../../controllers/finance_providers.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/section_header.dart';
import '../../widgets/status_chip.dart';
import 'add_debt_sheet.dart';
import '../../../core/observability/crash_reporting.dart';

/// Aba exibida na tela de crédito.
enum _DebtView {
  /// Dívidas a receber ainda pendentes (com ação de quitação).
  pending,

  /// Histórico de quitações (dívidas já baixadas).
  settled,
}

/// Tela de crédito ("fiado") — quanto o comerciante tem a receber de
/// clientes e de quem, com aba de histórico de quitações.
class DebtsScreen extends ConsumerStatefulWidget {
  const DebtsScreen({super.key});

  @override
  ConsumerState<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends ConsumerState<DebtsScreen> {
  _DebtView _view = _DebtView.pending;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final debtsAsync = ref.watch(pendingDebtsProvider);
    final settledAsync = ref.watch(settledDebtsProvider);

    final debts = debtsAsync.value ?? const <Debt>[];
    // Somas em CENTAVOS inteiros (W4) — int é exato.
    final pendingTotalCents = debts.fold<int>(
      0,
      (sum, debt) => sum + debt.amountCents,
    );

    final settled = settledAsync.value ?? const <Debt>[];
    final settledTotalCents = settled.fold<int>(
      0,
      (sum, debt) => sum + debt.amountCents,
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.debtsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-credit',
        onPressed: () => _openAddDebt(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.debtsAddDebt),
      ),
      body: RefreshIndicator(
        // W8: puxar para atualizar — recarrega fiado (pendente e histórico).
        onRefresh: () async {
          ref.invalidate(pendingDebtsProvider);
          ref.invalidate(settledDebtsProvider);
          await Future<void>.delayed(const Duration(milliseconds: 300));
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
          children: [
            // FittedBox: as abas Pendentes/Quitadas encolhem em telas
            // estreitas com escala de texto alta (o SegmentedButton não
            // quebra linha).
            Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: SegmentedButton<_DebtView>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: _DebtView.pending,
                      label: Text(l10n.debtsTabPending),
                    ),
                    ButtonSegment(
                      value: _DebtView.settled,
                      label: Text(l10n.debtsTabSettled),
                    ),
                  ],
                  selected: {_view},
                  onSelectionChanged: (selection) =>
                      setState(() => _view = selection.first),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_view == _DebtView.pending) ...[
              _SummaryCard(
                color: theme.warning,
                icon: Icons.receipt_long,
                title: l10n.debtsTotalPending,
                value: Formatters.currency(pendingTotalCents),
                subtitle: debts.isEmpty
                    ? l10n.debtsNoPendingCustomers
                    : l10n.debtsPendingCustomers(debts.length),
              ),
              const SizedBox(height: 24),
              SectionHeader(title: l10n.debtsPendingSection),
              const SizedBox(height: 12),
              debtsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => ErrorView(
                  message: l10n.debtsLoadError,
                  details: error.toString(),
                  onRetry: () => ref.invalidate(pendingDebtsProvider),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return EmptyState(
                      icon: Icons.celebration_outlined,
                      title: l10n.debtsEmptyPendingTitle,
                      subtitle: l10n.debtsEmptyPendingSubtitle,
                    );
                  }
                  return Column(
                    children: [
                      for (final debt in items) ...[
                        _DebtCard(
                          debt: debt,
                          onSettle: () => _settleDebt(context, debt),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  );
                },
              ),
            ] else ...[
              _SummaryCard(
                color: theme.income,
                icon: Icons.history,
                title: l10n.debtsTotalSettled,
                value: Formatters.currency(settledTotalCents),
                subtitle: l10n.debtsSettledCount(settled.length),
              ),
              const SizedBox(height: 24),
              SectionHeader(title: l10n.debtsSettledSection),
              const SizedBox(height: 12),
              settledAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => ErrorView(
                  message: l10n.debtsHistoryLoadError,
                  details: error.toString(),
                  onRetry: () => ref.invalidate(settledDebtsProvider),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return EmptyState(
                      icon: Icons.history_toggle_off,
                      title: l10n.debtsEmptySettledTitle,
                      subtitle: l10n.debtsEmptySettledSubtitle,
                    );
                  }
                  return Column(
                    children: [
                      for (final debt in items) ...[
                        _SettledDebtCard(debt: debt),
                        const SizedBox(height: 8),
                      ],
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openAddDebt(BuildContext context) async {
    await showAppSheet<void>(context, builder: (_) => const AddDebtSheet());
    if (!context.mounted) return;
    ref.invalidate(pendingDebtsProvider);
    ref.invalidate(dashboardKpisProvider);
  }

  /// Fluxo de baixa do fiado: confirmação → marca como paga → entrada no
  /// caixa (via [SettleDebtUseCase]) → recarrega fiado, histórico, caixa e
  /// saldo.
  Future<void> _settleDebt(BuildContext context, Debt debt) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.debtsSettleTitle),
        content: Text(
          l10n.debtsSettleBody(
            Formatters.currency(debt.amountCents),
            debt.personName,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.debtsSettle),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    // A baixa e a entrada no caixa pertencem à loja da dívida (a mesma
    // loja ativa que a exibiu).
    final user = ref.read(authStateProvider).value;
    final storeId = user == null
        ? null
        : ref.read(activeStoreIdProvider(user.id));
    if (storeId == null) return;

    try {
      await ref.read(settleDebtUseCaseProvider).call(debt.id, storeId: storeId);
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n.debtsSettled(
              debt.personName,
              Formatters.currency(debt.amountCents),
            ),
          ),
        ),
      );
      // Fiado, histórico, caixa, saldo e KPIs mudaram — as telas recarregam.
      ref.invalidate(pendingDebtsProvider);
      ref.invalidate(settledDebtsProvider);
      ref.invalidate(transactionsProvider);
      ref.invalidate(cashFlowProvider);
      ref.invalidate(dashboardKpisProvider);
    } on DebtNotFoundException {
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.debtsNotFound)));
      ref.invalidate(pendingDebtsProvider);
    } catch (error, stackTrace) {
      CrashReporting.capture(error, stackTrace, hint: 'Erro ao quitar fiado');
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.debtsSettleError)));
    }
  }
}

/// Card de resumo parametrizado — usado nas abas Pendentes ("Total a
/// receber") e Quitadas ("Total quitado").
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: color.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card de dívida pendente: pessoa, vencimento, valor e ação de quitação.
class _DebtCard extends StatelessWidget {
  const _DebtCard({required this.debt, required this.onSettle});

  final Debt debt;
  final VoidCallback onSettle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(
      debt.dueDate.year,
      debt.dueDate.month,
      debt.dueDate.day,
    );
    final daysUntilDue = today.difference(due).inDays;

    final l10n = context.l10n;
    final (chipLabel, chipColor) = daysUntilDue > 0
        ? (l10n.debtsLate, theme.expense)
        : daysUntilDue == 0
        ? (l10n.debtsDueToday, theme.warning)
        : (l10n.debtsDueIn(-daysUntilDue), theme.colorScheme.primary);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    debt.personName.isEmpty
                        ? '?'
                        : debt.personName.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        debt.personName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Número SEQUENCIAL do fiado na loja (D-00001) + chip
                      // de vencimento — Wrap para não estourar em telas
                      // estreitas com escala de texto alta.
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            Formatters.debtLabel(debt.number),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          StatusChip(label: chipLabel, color: chipColor),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Flexible: valores altos (ou escala de texto alta) encolhem
                // com ellipsis em vez de estourar o card.
                Flexible(
                  child: Text(
                    Formatters.currency(debt.amountCents),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onSettle,
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: Text(context.l10n.debtsSettleAction),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card de dívida quitada (histórico): pessoa, data da baixa e valor.
class _SettledDebtCard extends StatelessWidget {
  const _SettledDebtCard({required this.debt});

  final Debt debt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: theme.income.withValues(alpha: 0.14),
              child: Text(
                debt.personName.isEmpty
                    ? '?'
                    : debt.personName.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: theme.income,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    debt.personName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Número SEQUENCIAL do fiado (D-00001) + chip de baixa
                  // (Wrap, mesma proteção contra overflow de escala de
                  // texto alta).
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        Formatters.debtLabel(debt.number),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      StatusChip(
                        label: debt.paidAt == null
                            ? context.l10n.debtsSettledLabel
                            : context.l10n.debtsSettledOn(
                                Formatters.date(debt.paidAt!),
                              ),
                        color: theme.income,
                        icon: Icons.check_circle_outline,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                Formatters.currency(debt.amountCents),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
