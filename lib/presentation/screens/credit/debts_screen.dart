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
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/search_field.dart';
import '../../widgets/smart_amount.dart';
import '../../widgets/store_switcher.dart';
import '../../widgets/error_view.dart';
import '../../widgets/section_header.dart';
import '../../widgets/status_chip.dart';
import 'add_debt_sheet.dart';
import '../../../core/observability/crash_reporting.dart';
import '../../../data/services/offline_sync_service.dart';

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

  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Busca local pelo nome do devedor (case-insensitive) — filtra a lista
  /// do provider; o provider continua entregando TODA a dívida da loja.
  List<Debt> _filtered(List<Debt> debts) {
    if (_query.isEmpty) return debts;
    final query = _query.toLowerCase();
    return debts
        .where((debt) => debt.personName.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final debtsAsync = ref.watch(pendingDebtsProvider);
    final settledAsync = ref.watch(settledDebtsProvider);

    final debts = debtsAsync.value ?? const <Debt>[];
    final settled = settledAsync.value ?? const <Debt>[];

    // Busca local pelo nome: o filtro também afeta os totais/resumos — com
    // a busca ativa o resumo mostra o quanto AQUELE devedor deve.
    final visibleDebts = _filtered(debts);
    final visibleSettled = _filtered(settled);
    // Somas em CENTAVOS inteiros (W4) — int é exato.
    final pendingTotalCents = visibleDebts.fold<int>(
      0,
      (sum, debt) => sum + debt.amountCents,
    );
    final settledTotalCents = visibleSettled.fold<int>(
      0,
      (sum, debt) => sum + debt.amountCents,
    );

    // CTA único: sem NENHUM fiado na loja (pendente OU quitado), o FAB
    // some e o estado vazio da aba Pendentes traz o botão "Registrar
    // fiado" centralizado. Com histórico, o FAB volta.
    final hasDebtActivity = debts.isNotEmpty || settled.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.debtsTitle),
        actions: const [StoreSwitcher()],
      ),
      floatingActionButton: hasDebtActivity
          // FAB circular (design system — igual ao "Novo produto"): só o
          // sinal de +, com tooltip — o rótulo nunca é cortado pelo círculo.
          ? FloatingActionButton(
              heroTag: 'fab-credit',
              onPressed: () => _openAddDebt(context),
              tooltip: l10n.debtsAddDebt,
              child: const Icon(Icons.add),
            )
          : null,
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
            const SizedBox(height: 12),
            SearchField(
              controller: _searchController,
              hintText: l10n.debtsSearchHint,
              onChanged: (value) => setState(() => _query = value.trim()),
            ),
            const SizedBox(height: 16),
            if (_view == _DebtView.pending) ...[
              _SummaryCard(
                color: theme.warning,
                icon: Icons.receipt_long,
                title: l10n.debtsTotalPending,
                value: Formatters.currency(pendingTotalCents),
                subtitle: visibleDebts.isEmpty
                    ? l10n.debtsNoPendingCustomers
                    : l10n.debtsPendingCustomers(visibleDebts.length),
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
                  final filtered = _filtered(items);
                  if (filtered.isEmpty) {
                    // Busca sem resultado: estado próprio (sem CTA — a
                    // busca é sobre a lista carregada, não sobre a loja).
                    if (_query.isNotEmpty) {
                      return EmptyState(
                        icon: Icons.search_off,
                        title: l10n.commonNoResults,
                        subtitle: l10n.commonNoResultsHint,
                      );
                    }
                    return EmptyState(
                      icon: Icons.celebration_outlined,
                      title: l10n.debtsEmptyPendingTitle,
                      subtitle: l10n.debtsEmptyPendingSubtitle,
                      // CTA único no estado vazio (o FAB some quando a loja
                      // não tem nenhum fiado pendente nem quitado).
                      actionLabel: hasDebtActivity ? null : l10n.debtsAddDebt,
                      onAction: hasDebtActivity
                          ? null
                          : () => _openAddDebt(context),
                    );
                  }
                  return Column(
                    children: [
                      for (final debt in filtered) ...[
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
                subtitle: l10n.debtsSettledCount(visibleSettled.length),
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
                  final filtered = _filtered(items);
                  if (filtered.isEmpty) {
                    // Busca sem resultado no histórico (mesmo tratamento
                    // da aba Pendentes — sem CTA).
                    if (_query.isNotEmpty) {
                      return EmptyState(
                        icon: Icons.search_off,
                        title: l10n.commonNoResults,
                        subtitle: l10n.commonNoResultsHint,
                      );
                    }
                    return EmptyState(
                      icon: Icons.history_toggle_off,
                      title: l10n.debtsEmptySettledTitle,
                      subtitle: l10n.debtsEmptySettledSubtitle,
                    );
                  }
                  return Column(
                    children: [
                      for (final debt in filtered) ...[
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
          // AppButton (design system ultra-clean): altura 48, cantos 12,
          // texto w400 — a confirmação segue o padrão dos diálogos.
          AppButton.primary(
            onPressed: () => Navigator.of(context).pop(true),
            label: l10n.debtsSettle,
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
    } on OfflineEnqueuedException {
      // Sem conexão: a baixa foi ENFILEIRADA (outbox) — a dívida segue na
      // lista pendente até o replay no servidor; o banner mostra a fila.
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.syncOfflineSaved)));
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

    // AppCard (design system ultra-clean): radius 12, borda 0.5px — o
    // resumo do fiado usa fundo tingido (color) e borda tingida.
    return AppCard(
      color: color.withValues(alpha: 0.1),
      borderColor: color.withValues(alpha: 0.35),
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

    // AppCard (design system ultra-clean): radius 12, borda 0.5px, flat.
    return AppCard(
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
                      // Nome COMPLETO do cliente — quebra em linhas quando
                      // necessário (nada de truncar nomes nos cards).
                      Text(
                        debt.personName,
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
                // Valor MINIMALISTA (15px Medium, sem bold) + FittedBox:
                // ENCOLHE para caber — nunca trunca ("MTn 1.500,...") e
                // fica sempre visível ao lado do chip de vencimento.
                // Valor MINIMALISTA (15px Medium, sem bold) — SmartAmount
                // (design system ultra-clean): ENCOLHE para caber — nunca
                // trunca; visível ao lado do chip de vencimento.
                Flexible(
                  child: SmartAmount(
                    cents: debt.amountCents,
                    alignment: Alignment.centerRight,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
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

    // AppCard (design system ultra-clean): radius 12, borda 0.5px, flat.
    return AppCard(
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
                  // Nome COMPLETO do cliente — quebra em linhas quando
                  // necessário (nada de truncar nomes no histórico).
                  Text(
                    debt.personName,
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
            // Valor MINIMALISTA (15px Medium, sem bold) + FittedBox:
            // ENCOLHE para caber — nunca trunca; visível no histórico.
            // Valor MINIMALISTA (15px Medium, sem bold) — SmartAmount
            // (design system ultra-clean): ENCOLHE para caber — nunca
            // trunca; visível no histórico.
            Flexible(
              child: SmartAmount(
                cents: debt.amountCents,
                alignment: Alignment.centerRight,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
