import 'package:flutter/material.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/financial_transaction.dart';
import '../../widgets/app_button.dart';

/// Ícone inteligente por direção do movimento: entrada (north_east) em
/// verde e saída (south_west) em vermelho — mesma direção do feed da
/// Home (dinheiro que entra sobe, que sai desce).
extension TransactionDirectionIcon on TransactionType {
  IconData get icon => switch (this) {
    TransactionType.income => Icons.north_east,
    TransactionType.expense => Icons.south_west,
  };
}

/// Linha de movimentação — rótulo à esquerda (categoria + hora), valor à
/// direita na mesma margem de todas as linhas da lista.
///
/// A hierarquia é intencionalmente plana: a categoria identifica, a hora
/// contextualiza e o montante fecha a linha à direita com dígitos tabulares
/// (coluna alinhada entre linhas consecutivas).
class TransactionCard extends StatelessWidget {
  const TransactionCard({
    super.key,
    required this.transaction,
    this.onTap,
    this.onReceive,
    this.onPay,
  });

  final FinancialTransaction transaction;
  final VoidCallback? onTap;
  final VoidCallback? onReceive;
  final VoidCallback? onPay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isIncome = transaction.type == TransactionType.income;
    final color = isIncome ? theme.income : theme.expense;
    final sign = isIncome ? '+' : '-';

    return Semantics(
      container: true,
      label:
          '${transaction.category}, $sign ${Formatters.currency(transaction.amountCents)}, ${Formatters.time(transaction.date)}',
      child: InkWell(
        onTap: onTap,
        // Alvo de toque ≥ 48dp: a linha é compacta, mas abrir o detalhe é o
        // gesto principal — o Container garante altura mínima.
        child: Container(
          constraints: const BoxConstraints(minHeight: AppSizes.touchTarget),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              // ── Direção (esquerda) ──
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: IconTone.darkBackground(color),
                ),
                child: Icon(
                  transaction.type.icon,
                  size: AppSizes.iconSm,
                  color: IconTone.lightForeground(color),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // ── Categoria + hora (esquerda) ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      transaction.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      // Categoria = 14/w500: identifica sem competir com o
                      // valor, que é o número da linha.
                      style: AppTypography.bodyMedium.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.micro),
                    Text(
                      Formatters.time(transaction.date),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      // Hora = metadado (12), discreta.
                      style: AppTypography.bodySmall.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              // ── Valor (direita) ──
              // FittedBox: encolhe em escala 2.0 em vez de estourar o Row.
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    '$sign ${Formatters.currency(transaction.amountCents)}',
                    maxLines: 1,
                    // Valor em linha: 15/w500 tabular — alinha coluna a
                    // coluna sem dominar a lista.
                    style: AppTypography.amountInRow(color),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cabeçalho de grupo por data — rótulo relativo (Hoje/Ontem) à esquerda e
/// total do dia à direita, na mesma margem da lista que ele encabeça.
class DateSectionHeader extends StatelessWidget {
  const DateSectionHeader({
    super.key,
    required this.label,
    required this.totalCents,
  });

  final String label;
  final int totalCents;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final totalColor = totalCents >= 0 ? theme.income : theme.expense;
    final horizontal = AppSpacing.pagePaddingForWidth(
      MediaQuery.sizeOf(context).width,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontal,
        AppSpacing.sm,
        horizontal,
        AppSpacing.xxs,
      ),
      child: Row(
        children: [
          // Rótulo do dia (esquerda).
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelMedium.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          // Total do dia (direita) — sem pílula: alinha com os valores das
          // linhas abaixo e mantém o cabeçalho silencioso.
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                Formatters.signedAmount(totalCents),
                maxLines: 1,
                style: AppTypography.amountInRow(totalColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sheet de detalhes de uma transação — exibida ao tocar num [TransactionCard].
///
/// Transações pendentes oferecem a ação de quitação ([onReceive] para
/// entradas fiadas, [onPay] para saídas a pagar) — a confirmação e a baixa
/// ficam no chamador (a tela), que fecha a sheet antes de abrir o diálogo.
class TransactionDetailSheet extends StatelessWidget {
  const TransactionDetailSheet({
    super.key,
    required this.transaction,
    this.onReceive,
    this.onPay,
  });

  final FinancialTransaction transaction;

  /// Aciona a quitação de uma entrada pendente (fiado recebido).
  final VoidCallback? onReceive;

  /// Aciona o pagamento de uma saída pendente.
  final VoidCallback? onPay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final isIncome = transaction.type == TransactionType.income;
    final color = isIncome ? theme.income : theme.expense;
    final sign = isIncome ? '+' : '-';
    final pending = transaction.status == TransactionStatus.pending;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xs,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Cabeçalho: tipo à esquerda, valor à direita ──
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: IconTone.darkBackground(color),
                ),
                child: Icon(
                  transaction.type.icon,
                  size: AppSizes.iconMd,
                  color: IconTone.lightForeground(color),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  transaction.type.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    '$sign ${Formatters.currency(transaction.amountCents)}',
                    maxLines: 1,
                    style: AppTypography.headline.copyWith(color: color),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Divider(
            height: 1,
            thickness: 1,
            color: scheme.outlineVariant.withValues(alpha: 0.6),
          ),
          const SizedBox(height: AppSpacing.xs),

          // ── Detalhes: rótulo à esquerda, valor à direita ──
          _DetailLine(
            label: l10n.financialDetailDescription,
            value: transaction.description,
          ),
          _DetailLine(
            label: l10n.financialDetailCategory,
            value: transaction.category,
          ),
          _DetailLine(
            label: l10n.financialDetailNumber,
            value: Formatters.entityNumber(transaction.id),
          ),
          _DetailLine(
            label: l10n.financialDetailDate,
            value: Formatters.dateTime(transaction.date),
          ),
          _DetailLine(
            label: l10n.financialDetailStatus,
            value: transaction.status.label,
            valueColor: pending ? theme.warning : theme.income,
          ),

          // ── Ação pendente ──
          if (pending && isIncome && onReceive != null) ...[
            const SizedBox(height: AppSpacing.lg),
            AppButton.primary(
              onPressed: () {
                Navigator.of(context).pop();
                // Confirmação + baixa no chamador (depois de fechar a sheet).
                onReceive?.call();
              },
              label: l10n.financialReceive,
              icon: const Icon(Icons.done_all, size: 18),
            ),
          ],
          if (pending && !isIncome && onPay != null) ...[
            const SizedBox(height: AppSpacing.lg),
            AppButton.primary(
              onPressed: () {
                Navigator.of(context).pop();
                // Confirmação + baixa no chamador (depois de fechar a sheet).
                onPay?.call();
              },
              label: l10n.financialPay,
              icon: const Icon(Icons.payments_outlined, size: 18),
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
        ],
      ),
    );
  }
}

/// Linha chave → valor da sheet de detalhe: rótulo à esquerda, valor
/// alinhado à direita (mesma margem em todas as linhas).
class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rótulo (esquerda) — metadado de 12, nunca 11 (corta em nomes
          // de campo longos).
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Valor (direita) — 14/w500, quebra em linhas quando necessário
          // sem esconder dados de contato/descrição.
          Flexible(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTypography.labelLarge.copyWith(
                color: valueColor ?? scheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// NOVOS WIDGETS PARA O LAYOUT IMAGE 2
// ================================================================

/// Header TAREQO + título Financeiro no topo da tela.
class FinanceHeader extends StatelessWidget {
  const FinanceHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Row(
      children: [
        // TAREQO badge circular laranja
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.accentOrange,
            shape: BoxShape.circle,
          ),
          child: Text(
            'T',
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Título "Financeiro"
        Text(
          l10n.financialTitle,
          style: theme.textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
      ],
    );
  }
}

/// Pills de filtro: Hoje / Esta semana / Este mês / Tudo.
class FinanceFilterPills extends StatelessWidget {
  const FinanceFilterPills({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        FilterPill('Hoje', isSelected: true),
        const SizedBox(width: 8),
        FilterPill('Esta semana', isSelected: false),
        const SizedBox(width: 8),
        FilterPill('Este mês', isSelected: true,
          // Background dourado/escuro quando selecionado
          backgroundColor: Color(0xFFB45F06), // brownish dark-gold
          textColor: Colors.white),
        const SizedBox(width: 8),
        FilterPill('Tudo', isSelected: false),
      ],
    );
  }
}

class FilterPill extends StatelessWidget {
  const FilterPill(this.label, {this.isSelected = false, this.backgroundColor, this.textColor});
  final String label;
  final bool isSelected;
  final Color? backgroundColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = textColor ?? theme.colorScheme.onSurface;
    final bg = backgroundColor ?? (isSelected ? theme.colorScheme.primary : Colors.transparent);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: theme.colorScheme.outlineVariant, width: 1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }
}

/// Card de resumo: Saldo líquido + Entradas / Saídas com setas.
class FinanceSummaryCard extends StatelessWidget {
  const FinanceSummaryCard({
    required this.incomeCents,
    required this.expenseCents,
    super.key,
  });

  final int incomeCents;
  final int expenseCents;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final balanceCents = incomeCents - expenseCents;
    final balanceColor = balanceCents >= 0 ? AppColors.accentOrange : theme.expense;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3), width: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top row: "Saldo líquido do período" à esquerda, saldo à direita
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.financialPeriodBalance,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  Formatters.currency(balanceCents),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: balanceColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Divider(
            height: 1,
            thickness: 1,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),

          // Second row: Entradas
          FinanceRowIconLabel(
            icon: Icons.arrow_upward_rounded,
            label: l10n.financialIncome,
            value: Formatters.signedAmount(incomeCents),
            color: AppColors.accentOrange,
          ),

          // Third row: Saídas
          FinanceRowIconLabel(
            icon: Icons.arrow_downward_rounded,
            label: l10n.financialExpense,
            value: Formatters.signedAmount(-expenseCents),
            color: theme.expense,
          ),
        ],
      ),
    );
  }
}

class FinanceRowIconLabel extends StatelessWidget {
  const FinanceRowIconLabel({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Headline do section "Movimentos do período".
class MovementsHeader extends StatelessWidget {
  const MovementsHeader({required this.subtitle, super.key});
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.financialTransactions,
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (subtitle != null)...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
