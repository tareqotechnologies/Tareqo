import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/ui/haptics.dart';
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
import '../../widgets/app_page.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/search_field.dart';
import '../../widgets/smart_amount.dart';
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

  /// Dívida vencida (atrasada) — a data de vencimento já passou.
  bool _isOverdue(Debt debt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(
      debt.dueDate.year,
      debt.dueDate.month,
      debt.dueDate.day,
    );
    return today.difference(due).inDays > 0;
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

    // CTA único: o "Registrar fiado" vive no menu do FAB central do shell
    // (canvas V3 — a tela de Crédito não tem FAB próprio); o estado vazio
    // da aba Pendentes traz o botão "Registrar fiado" centralizado.
    return AppPage(
      title: l10n.debtsTitle,
      subtitle: l10n.debtsHeaderSubtitle,
      useSafeArea: false,
      body: RefreshIndicator(
        // W8: puxar para atualizar — recarrega fiado (pendente e histórico).
        onRefresh: () async {
          ref.invalidate(pendingDebtsProvider);
          ref.invalidate(settledDebtsProvider);
          await Future<void>.delayed(const Duration(milliseconds: 300));
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            AppSpacing.pagePaddingForWidth(MediaQuery.sizeOf(context).width),
            8,
            AppSpacing.pagePaddingForWidth(MediaQuery.sizeOf(context).width),
            96,
          ),
          children: [
            // FittedBox: as abas Pendentes/Quitadas encolhem em telas
            // estreitas com escala de texto alta (o SegmentedButton não
            // quebra linha). Pílulas estilo Apple — mesmo padrão do
            // Financeiro: StadiumBorder com o segmento ativo em
            // primaryContainer.
            Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: SegmentedButton<_DebtView>(
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    // Sem densidade compacta: o segmento é botão de baixa
                    // frequência — alvo de toque ≥ 48dp (guideline a11y).
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    shape: const StadiumBorder(),
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                    backgroundColor: Colors.transparent,
                    selectedBackgroundColor: theme.colorScheme.primaryContainer,
                    selectedForegroundColor:
                        theme.colorScheme.onPrimaryContainer,
                    foregroundColor: theme.colorScheme.onSurfaceVariant,
                    textStyle: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
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
              // Resumo V3 (canvas): valor a receber + contagem de atrasados
              // (vencidas) ao lado — o número de contas em atraso num
              // relance, em vez de apenas o total.
              _SummaryCard(
                color: theme.warning,
                title: l10n.debtsTotalPending,
                valueCents: pendingTotalCents,
                statLabel: l10n.debtsOverdueStat,
                statValue: visibleDebts
                    .where((debt) => _isOverdue(debt))
                    .length,
                statColor: theme.expense,
              ),
              const SizedBox(height: 24),
              SectionHeader(title: l10n.debtsPendingSection),
              const SizedBox(height: 12),
              debtsAsync.when(
                loading: () => const _DebtsListSkeleton(),
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
                      // "Tudo em dia" — sóbrio (check), sem festa: o empty
                      // state de um ERP não celebra, informa.
                      icon: Icons.check_circle_outline,
                      title: l10n.debtsEmptyPendingTitle,
                      subtitle: l10n.debtsEmptyPendingSubtitle,
                      // CTA único (canvas V3): sem FAB próprio na tela, o
                      // estado vazio traz o botão "Registrar fiado" — o
                      // caminho de criação fica SEMPRE visível quando não
                      // há fiado pendente.
                      actionLabel: l10n.debtsAddDebt,
                      onAction: () => _openAddDebt(context),
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
                title: l10n.debtsTotalSettled,
                valueCents: settledTotalCents,
                statLabel: l10n.debtsSettledStat,
                statValue: visibleSettled.length,
                statColor: theme.income,
              ),
              const SizedBox(height: 24),
              SectionHeader(title: l10n.debtsSettledSection),
              const SizedBox(height: 12),
              settledAsync.when(
                loading: () => const _DebtsListSkeleton(),
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

    final confirmed = await showConfirmDialog(
      context,
      title: l10n.debtsSettleTitle,
      message: l10n.debtsSettleBody(
        Formatters.currency(debt.amountCents),
        debt.personName,
      ),
      confirmLabel: l10n.debtsSettle,
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
      // Confirmação tátil da baixa (dinheiro entrou no caixa) — mesmo
      // padrão das sheets de Vendas/Compras/Fiado.
      Haptics.success();
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
      Haptics.error();
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.debtsNotFound)));
      ref.invalidate(pendingDebtsProvider);
    } on OfflineEnqueuedException {
      // Sem conexão: a baixa foi ENFILEIRADA (outbox) — a dívida segue na
      // lista pendente até o replay no servidor; o banner mostra a fila.
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.syncOfflineSaved)));
    } catch (error, stackTrace) {
      Haptics.error();
      CrashReporting.capture(error, stackTrace, hint: 'Erro ao quitar fiado');
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.debtsSettleError)));
    }
  }
}

/// Card de resumo V3 (canvas) — usado nas abas Pendentes ("Total a
/// receber" + contagem de atrasados) e Quitadas ("Total quitado" +
/// contagem de baixas).
///
/// Layout do canvas: valor em destaque à esquerda e uma **stat** à
/// direita (label + contagem com cor própria) — a informação de quantas
/// contas estão em atraso / foram baixadas fica num relance, em vez de
/// apenas o total. O valor é renderizado com [SmartAmount] (auto-size):
/// em telas estreitas ou com escala de texto alta, ENCOLHE em vez de
/// quebrar em duas linhas — mesmo padrão dos KPIs do dashboard.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.color,
    required this.title,
    required this.valueCents,
    required this.statLabel,
    required this.statValue,
    required this.statColor,
  });

  final Color color;
  final String title;
  final int valueCents;
  final String statLabel;
  final int statValue;
  final Color statColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Card premium (estilo Apple): cantos 20, superfície elevada e
    // fundo/borda tingidos pela cor do estado.
    return AppCard(
      elevated: true,
      borderRadius: AppRadius.xlAll,
      color: color.withValues(alpha: 0.1),
      borderColor: color.withValues(alpha: 0.35),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
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
                // SmartAmount (design system ultra-clean): o valor em
                // destaque ENCOLHE para caber — nunca trunca nem quebra.
                // Tabular figures: dígitos alinhados.
                SmartAmount(
                  cents: valueCents,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.5,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Stat à direita (canvas): label pequeno + contagem em destaque
          // com a cor do estado (vermelho para atrasados, verde para
          // baixas).
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                statLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$statValue',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: statColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Card de dívida pendente V3 (canvas): nome + tag de vencimento inline,
/// descrição "D-00001 · venceu há X dias", valor à direita e o botão de
/// quitação verde em largura total — sem avatar, como no canvas.
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
    // Tag de vencimento (canvas): Atrasada (vermelho) / Vence hoje
    // (âmbar) / Em X dias (primary).
    final (chipLabel, chipColor) = daysUntilDue > 0
        ? (l10n.debtsLate, theme.expense)
        : daysUntilDue == 0
        ? (l10n.debtsDueToday, theme.warning)
        : (l10n.debtsDueIn(-daysUntilDue), theme.colorScheme.primary);

    // Descrição relativa (canvas "venceu 12 ago"): venceu há X dias /
    // vence hoje / vence em X dias.
    final dueDesc = daysUntilDue > 0
        ? l10n.debtsDueAgo(daysUntilDue)
        : daysUntilDue == 0
        ? l10n.debtsDueTodayDesc
        : l10n.debtsDueIn(-daysUntilDue);

    // Card premium (estilo Apple): cantos 18, superfície elevada e borda
    // TINGIDA pelo estado de vencimento (vermelho para atrasada, âmbar
    // para vence hoje, neutra para em dia).
    return AppCard(
      elevated: true,
      borderRadius: const BorderRadius.all(Radius.circular(18)),
      borderColor: chipColor.withValues(alpha: 0.35),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nome + tag de vencimento inline (canvas) — Wrap para
                    // não estourar em telas estreitas com escala alta.
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Nome COMPLETO do cliente — quebra em linhas
                        // quando necessário (nada de truncar nomes).
                        Text(
                          debt.personName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        StatusChip(label: chipLabel, color: chipColor),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Descrição: número SEQUENCIAL + vencimento relativo
                    // (ex.: "D-00001 · venceu há 3 dias").
                    Text(
                      '${Formatters.debtLabel(debt.number)} · $dueDesc',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Valor — SmartAmount (design system ultra-clean): ENCOLHE
              // para caber — nunca trunca. Tabular: alinhado na coluna.
              Flexible(
                child: SmartAmount(
                  cents: debt.amountCents,
                  alignment: Alignment.centerRight,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Botão de quitação verde em largura total (canvas): a ação
          // principal do card, sólida e clara.
          AppButton.primary(onPressed: onSettle, label: l10n.debtsSettleAction),
        ],
      ),
    );
  }
}

/// Card de dívida quitada (histórico) V3: nome + chip de baixa inline,
/// descrição "D-00001" e valor à direita — mesmo padrão do card pendente
/// (sem avatar), com a cor da baixa (verde) na borda.
class _SettledDebtCard extends StatelessWidget {
  const _SettledDebtCard({required this.debt});

  final Debt debt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    // Card premium (estilo Apple): cantos 18, superfície elevada e borda
    // tingida de verde (baixa) — mesmo padrão do card pendente.
    return AppCard(
      elevated: true,
      borderRadius: const BorderRadius.all(Radius.circular(18)),
      borderColor: theme.income.withValues(alpha: 0.35),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nome + chip de baixa inline (mesmo padrão do pendente).
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Nome COMPLETO do cliente — quebra em linhas quando
                    // necessário (nada de truncar nomes no histórico).
                    Text(
                      debt.personName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    StatusChip(
                      label: debt.paidAt == null
                          ? l10n.debtsSettledLabel
                          : l10n.debtsSettledOn(Formatters.date(debt.paidAt!)),
                      color: theme.income,
                      icon: Icons.check_circle_outline,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Número SEQUENCIAL do fiado (D-00001).
                Text(
                  Formatters.debtLabel(debt.number),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Valor — SmartAmount (design system ultra-clean): ENCOLHE para
          // caber — nunca trunca; visível no histórico. Tabular: alinhado.
          Flexible(
            child: SmartAmount(
              cents: debt.amountCents,
              alignment: Alignment.centerRight,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton das listas de fiado (pendente/histórico) — blocos NÃO-roláveis:
/// as seções vivem dentro do ListView da tela, então um `ListSkeleton`
/// (que é um ListView) criaria scroll aninhado inválido.
class _DebtsListSkeleton extends StatelessWidget {
  const _DebtsListSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Skeleton(
      child: Column(
        children: [
          SkeletonBlock(height: 64, radius: 16),
          SizedBox(height: 8),
          SkeletonBlock(height: 64, radius: 16),
          SizedBox(height: 8),
          SkeletonBlock(height: 64, radius: 16),
        ],
      ),
    );
  }
}
