import 'package:flutter/material.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/financial_transaction.dart';
import '../../widgets/app_button.dart';
import '../../widgets/premium_decor.dart';

/// Ícone inteligente por direção do movimento: entrada (north_east) em
/// verde e saída (south_west) em vermelho — mesma direção do feed da
/// Home (dinheiro que entra sobe, que sai desce).
extension TransactionDirectionIcon on TransactionType {
  IconData get icon => switch (this) {
    TransactionType.income => Icons.north_east,
    TransactionType.expense => Icons.south_west,
  };
}

/// Linha de movimentação — categoria e hora à esquerda, valor à direita.
///
/// Sem ícone nem moldura: a linha lê-se como um extrato. O sinal e a cor
/// semântica do valor bastam para a direção; a hora contextualiza em
/// segundo plano e o montante fecha a coluna com dígitos tabulares.
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
    final pending = transaction.status == TransactionStatus.pending;

    return Semantics(
      container: true,
      button: onTap != null,
      label:
          '${transaction.category}, $sign ${Formatters.currency(transaction.amountCents)}, ${Formatters.time(transaction.date)}',
      child: InkWell(
        onTap: onTap,
        // Alvo de toque ≥ 48dp: a linha é compacta, mas abrir o detalhe é o
        // gesto principal — o Container garante altura mínima.
        child: Container(
          constraints: const BoxConstraints(minHeight: AppSizes.touchTarget),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              // ── Categoria + hora ──
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      transaction.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      // Linha de lista = 14/w500 (título da linha).
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.micro),
                    // Metadados: hora e, quando existe, o estado pendente —
                    // ambos em segundo plano face ao valor da linha.
                    Row(
                      children: [
                        Text(
                          Formatters.time(transaction.date),
                          maxLines: 1,
                          style: AppTypography.bodySmall.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        if (pending) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: theme.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xxs),
                          // U-03: sem clamp global, a escala 2.0 precisa de
                          // Flexible+ellipsis também no estado "pendente".
                          Flexible(
                            child: Text(
                              context.l10n.financialPendingLabel.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.labelSmall.copyWith(
                                color: scheme.onSurfaceVariant,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // ── Valor ──
              // Slot TIGHT (flex 2 contra 3 da categoria): o valor ocupa a
              // fatia direita até à margem e fecha a coluna encostado à
              // direita. FittedBox mantém a escala 2.0 sem estourar o Row.
              Flexible(
                flex: 2,
                fit: FlexFit.tight,
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
    final scheme = Theme.of(context).colorScheme;
    final horizontal = AppSpacing.pagePaddingForWidth(
      MediaQuery.sizeOf(context).width,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontal,
        AppSpacing.md,
        horizontal,
        AppSpacing.xxs,
      ),
      child: Row(
        children: [
          // Rótulo do dia (esquerda) — etiqueta de contexto, discreta.
          Expanded(
            flex: 3,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.eyebrow(scheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          // Total do dia (direita) — em tinta: o sinal já indica a direção e
          // o cabeçalho não compete com os montantes das linhas. Slot tight
          // para encostar à mesma margem direita da lista.
          Flexible(
            flex: 2,
            fit: FlexFit.tight,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                Formatters.signedAmount(totalCents),
                maxLines: 1,
                style: AppTypography.amountInRow(scheme.onSurface),
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

    // U-19/U-03: sheet de detalhe — SingleChildScrollView para conteúdo
    // longo em ecrãs baixos/escala 2.0 sem overflow (showAppSheet já
    // envolve em SafeArea + AnimatedPadding; o scroll é da sheet).
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Cabeçalho ──
          Row(
            children: [
              Container(
                width: AppSizes.avatarLg,
                height: AppSizes.avatarLg,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: AppRadius.mdAll,
                  color: color.withValues(alpha: 0.1),
                ),
                child: Icon(
                  transaction.type.icon,
                  size: AppSizes.iconMd,
                  color: color,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.category,
                      style: AppTypography.labelLarge.copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                    Text(
                      transaction.type.label,
                      style: AppTypography.bodySmall.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Valor em destaque — sem moldura: o número é o elemento do sheet.
          Column(
            children: [
              Text(
                l10n.financialAmountLabel,
                style: AppTypography.eyebrow(scheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.xxs),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '$sign ${Formatters.currency(transaction.amountCents)}',
                  // Token heroAmount (26/w500) — teto do sistema (U-06).
                  style: AppTypography.heroAmount(color),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),
          Divider(height: 1, color: PremiumDecor.hairline(scheme)),
          const SizedBox(height: AppSpacing.xs),

          _DetailLine(
            label: l10n.financialDetailDescription,
            value: transaction.description.isNotEmpty
                ? transaction.description
                : '-',
          ),
          if (transaction.category != transaction.description)
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
              icon: const Icon(Icons.done_all, size: AppSizes.iconSm),
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
              icon: const Icon(Icons.payments_outlined, size: AppSizes.iconSm),
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
