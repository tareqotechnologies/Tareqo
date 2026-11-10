import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
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
import '../../widgets/app_segmented_button.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/search_field.dart';
import '../../widgets/smart_amount.dart';
import '../../widgets/semantics_composed.dart';
import '../../widgets/error_view.dart';
import '../../widgets/section_header.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/summary_hero.dart';
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
            AppSpacing.xs,
            AppSpacing.pagePaddingForWidth(MediaQuery.sizeOf(context).width),
            AppSpacing.fabBottomClearance,
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
                child: AppSegmentedButton<_DebtView>(
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
            const SizedBox(height: AppSpacing.sm),
            SearchField(
              controller: _searchController,
              hintText: l10n.debtsSearchHint,
              onChanged: (value) => setState(() => _query = value.trim()),
            ),
            const SizedBox(height: AppSpacing.md),
            if (_view == _DebtView.pending) ...[
              // Resumo V3 (canvas): valor a receber + contagem de atrasados
              // (vencidas) ao lado — o número de contas em atraso num
              // relance, em vez de apenas o total.
              _SummaryCard(
                title: l10n.debtsTotalPending,
                valueCents: pendingTotalCents,
                statLabel: l10n.debtsOverdueStat,
                statValue: visibleDebts
                    .where((debt) => _isOverdue(debt))
                    .length,
                statColor: theme.expense,
              ),
              const SizedBox(height: AppSpacing.xl),
              SectionHeader(title: l10n.debtsPendingSection),
              const SizedBox(height: AppSpacing.sm),
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
                        const SizedBox(height: AppSpacing.xs),
                      ],
                    ],
                  );
                },
              ),
            ] else ...[
              _SummaryCard(
                title: l10n.debtsTotalSettled,
                valueCents: settledTotalCents,
                statLabel: l10n.debtsSettledStat,
                statValue: visibleSettled.length,
                statColor: theme.income,
              ),
              const SizedBox(height: AppSpacing.xl),
              SectionHeader(title: l10n.debtsSettledSection),
              const SizedBox(height: AppSpacing.sm),
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
                        const SizedBox(height: AppSpacing.xs),
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
      context: context,
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

/// Card de resumo das abas de Crédito — o hero partilhado ([SummaryHero])
/// com a estatística secundária ancorada à direita.
///
/// Pendentes: total a receber + quantas contas estão atrasadas. Quitadas:
/// total baixado + quantas quitações. O valor principal fica neutro (é um
/// total, não um alerta); a cor do estado aparece só na estatística.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.valueCents,
    required this.statLabel,
    required this.statValue,
    required this.statColor,
  });

  final String title;
  final int valueCents;
  final String statLabel;
  final int statValue;
  final Color statColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SummaryHero(
      label: title,
      value: Formatters.currency(valueCents),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            statLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.micro),
          Text(
            '$statValue',
            // 20/500 — um degrau abaixo do valor do hero (26): a
            // estatística secundária nunca compete com o total.
            style: AppTypography.titleLarge.copyWith(color: statColor),
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
    final scheme = theme.colorScheme;
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
    // (âmbar) / Em X dias (neutro). O chip futuro fica em tinta neutra:
    // laranja a 12px sobre a superfície não alcança AA em tema claro — o
    // prazo não é um alerta, a cor ali só decorava.
    final (chipLabel, chipColor) = daysUntilDue > 0
        ? (l10n.debtsLate, theme.expense)
        : daysUntilDue == 0
        ? (l10n.debtsDueToday, theme.warning)
        : (l10n.debtsDueIn(-daysUntilDue), scheme.onSurface);

    // Descrição relativa (canvas "venceu 12 ago"): venceu há X dias /
    // vence hoje / vence em X dias.
    final dueDesc = daysUntilDue > 0
        ? l10n.debtsDueAgo(daysUntilDue)
        : daysUntilDue == 0
        ? l10n.debtsDueTodayDesc
        : l10n.debtsDueIn(-daysUntilDue);

    // Card com ação: superfície do tema + borda de cabelo, cantos 16. O
    // estado de vencimento vive no [StatusChip] — o card não tinge o fundo
    // nem a borda pela cor semântica (regra "cor = função no indicador").
    //
    // A11y (plano UI/UX — Fase 3.1): as informações do card são UM nó —
    // "João: Atrasada, D-00001 · venceu há 3 dias, 25,00" — e o botão de
    // quitação mantém NÓ PRÓPRIO (ação anunciável com gesto padrão).
    return AppCard(
      color: theme.colorScheme.surface,
      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.lg)),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // A11y (plano UI/UX — Fase 3.1): a linha de informações é UM nó —
          // "João: Atrasada, D-00001 · venceu há 3 dias, 25,00" — e o botão
          // de quitação fica FORA dele, com nó próprio: a ação segue
          // anunciável e acionável com o gesto padrão do leitor de ecrã.
          Semantics(
            container: true,
            excludeSemantics: true,
            label: buildComposedLabel([
              '${debt.personName}: $chipLabel',
              '${Formatters.debtLabel(debt.number)} · $dueDesc',
              Formatters.currency(debt.amountCents),
            ]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      // Nome + tag de vencimento inline (canvas) — Wrap para
                      // não estourar em telas estreitas com escala alta.
                      child: Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xxs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // Nome COMPLETO do cliente — quebra em linhas
                          // quando necessário (nada de truncar nomes).
                          Text(
                            debt.personName,
                            style: AppTypography.labelLarge.copyWith(
                              color: scheme.onSurface,
                            ),
                          ),
                          StatusChip(label: chipLabel, color: chipColor),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    // Valor — SmartAmount (design system ultra-clean): ENCOLHE
                    // para caber — nunca trunca. Tabular: alinhado na coluna.
                    Flexible(
                      child: SmartAmount(
                        cents: debt.amountCents,
                        alignment: Alignment.centerRight,
                        style: AppTypography.amountInRow(scheme.onSurface),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                // Descrição: número SEQUENCIAL + vencimento relativo
                // (ex.: "D-00001 · venceu há 3 dias"). Largura total para
                // não partir a frase ao lado do valor.
                Text(
                  '${Formatters.debtLabel(debt.number)} · $dueDesc',
                  style: AppTypography.bodySmall.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Botão de quitação verde em largura total (canvas): a ação
          // principal do card, sólida e clara — FORA do nó de informações.
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
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    // Mesmo card do pendente — sem tingir a superfície: o estado de baixa
    // está no chip verde do cabeçalho.
    //
    // A11y (Fase 3.1): o card do histórico é UM nó — nome, data da baixa,
    // número e valor falados de uma vez.
    return AppCard(
      color: theme.colorScheme.surface,
      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.lg)),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Semantics(
        container: true,
        excludeSemantics: true,
        label: buildComposedLabel([
          '${debt.personName}: '
              '${debt.paidAt == null ? l10n.debtsSettledLabel : l10n.debtsSettledOn(Formatters.date(debt.paidAt!))}',
          Formatters.debtLabel(debt.number),
          Formatters.currency(debt.amountCents),
        ]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  // Nome + chip de baixa inline (mesmo padrão do pendente).
                  child: Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xxs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Nome COMPLETO do cliente — quebra em linhas quando
                      // necessário (nada de truncar nomes no histórico).
                      Text(
                        debt.personName,
                        style: AppTypography.labelLarge.copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                      StatusChip(
                        label: debt.paidAt == null
                            ? l10n.debtsSettledLabel
                            : l10n.debtsSettledOn(
                                Formatters.date(debt.paidAt!),
                              ),
                        color: theme.income,
                        icon: Icons.check_circle_outline,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                // Valor — SmartAmount (design system ultra-clean): ENCOLHE
                // para caber — nunca trunca; visível no histórico. Tabular.
                Flexible(
                  child: SmartAmount(
                    cents: debt.amountCents,
                    alignment: Alignment.centerRight,
                    style: AppTypography.amountInRow(scheme.onSurface),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxs),
            // Número SEQUENCIAL do fiado (D-00001) — largura total.
            Text(
              Formatters.debtLabel(debt.number),
              style: AppTypography.bodySmall.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
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
          SkeletonBlock(height: AppSizes.listRowHeight, radius: AppRadius.lg),
          SizedBox(height: AppSpacing.xs),
          SkeletonBlock(height: AppSizes.listRowHeight, radius: AppRadius.lg),
          SizedBox(height: AppSpacing.xs),
          SkeletonBlock(height: AppSizes.listRowHeight, radius: AppRadius.lg),
        ],
      ),
    );
  }
}
