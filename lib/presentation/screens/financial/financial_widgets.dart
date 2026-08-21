import 'package:flutter/material.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/financial_transaction.dart';
import '../../widgets/smart_amount.dart';
import '../../widgets/status_chip.dart';

/// Ícone inteligente por direção do movimento: entrada (north_east) em
/// verde e saída (south_west) em vermelho — mesma direção do feed da
/// Home (dinheiro que entra sobe, que sai desce).
extension TransactionDirectionIcon on TransactionType {
  IconData get icon => switch (this) {
        TransactionType.income => Icons.north_east,
        TransactionType.expense => Icons.south_west,
      };
}

/// Card de movimentação premium — direção com ícone semântico, descrição,
/// número amigável + categoria, dia/hora inteligente, status e valor em
/// destaque com sinal e cor. Pendências ganham a ação logo abaixo:
/// "Receber" para entradas (fiado) e "Pagar" para saídas (contas a pagar).
class TransactionCard extends StatelessWidget {
  const TransactionCard({
    super.key,
    required this.transaction,
    this.onReceive,
    this.onPay,
  });

  final FinancialTransaction transaction;
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

    final semanticLabel = [
      transaction.description,
      Formatters.entityNumber(transaction.id),
      transaction.category,
      '$sign ${Formatters.currency(transaction.amountCents)}',
      '${Formatters.day(transaction.date)} ${Formatters.time(transaction.date)}',
      if (pending) context.l10n.statusPending,
    ].join(', ');

    return Semantics(
      container: true,
      label: semanticLabel,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.14),
                    border: Border.all(
                      color: color.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Icon(transaction.type.icon, size: 20, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.description,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${Formatters.entityNumber(transaction.id)} · '
                        '${transaction.category}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SmartAmount(
                          cents: transaction.amountCents,
                          prefix: '$sign ',
                          alignment: Alignment.centerRight,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: color,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        if (pending) ...[
                          const SizedBox(height: 4),
                          StatusChip(
                            label: context.l10n.statusPending,
                            color: theme.warning,
                            icon: Icons.schedule,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${Formatters.day(transaction.date)} • '
              '${Formatters.time(transaction.date)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (pending && (onReceive != null || onPay != null)) ...[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: isIncome
                    ? TextButton.icon(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        onPressed: onReceive,
                        icon: const Icon(Icons.done_all, size: 16),
                        label: Text(context.l10n.financialReceive),
                      )
                    : TextButton.icon(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        onPressed: onPay,
                        icon: const Icon(Icons.payments_outlined, size: 16),
                        label: Text(context.l10n.financialPay),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Cabeçalho de grupo por data — rótulo relativo (Hoje/Ontem) + total do dia.
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
    final totalColor =
        totalCents >= 0 ? theme.income : theme.expense;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        12,
        AppSpacing.lg,
        6,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: totalColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              Formatters.signedAmount(totalCents),
              style: theme.textTheme.labelMedium?.copyWith(
                color: totalColor,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
