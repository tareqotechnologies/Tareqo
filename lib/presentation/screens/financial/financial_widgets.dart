import 'package:flutter/material.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/financial_transaction.dart';
import '../../widgets/status_chip.dart';

/// Ícone inteligente por direção do movimento: entrada (south_west) em
/// verde e saída (north_east) em vermelho — mesma semântica dos KPIs do
/// Financeiro.
extension TransactionDirectionIcon on TransactionType {
  IconData get icon => switch (this) {
        TransactionType.income => Icons.south_west,
        TransactionType.expense => Icons.north_east,
      };
}

/// Card de movimentação premium — direção com ícone semântico, descrição,
/// número amigável + categoria, dia/hora inteligente, status e valor em
/// destaque com sinal e cor. Entradas pendentes (fiado) ganham a ação
/// "Receber" logo abaixo.
class TransactionCard extends StatelessWidget {
  const TransactionCard({super.key, required this.transaction, this.onReceive});

  final FinancialTransaction transaction;

  /// Ação de recebimento para entradas pendentes (null quando não aplicável).
  final VoidCallback? onReceive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIncome = transaction.type == TransactionType.income;
    final color = isIncome ? theme.income : theme.expense;
    final sign = isIncome ? '+' : '-';
    final pending = transaction.status == TransactionStatus.pending;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    transaction.type.icon,
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
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        // Número amigável (derivado do id) + categoria.
                        '${Formatters.entityNumber(transaction.id)} · '
                        '${transaction.category}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Pendências ganham o chip de status. Align + Flexible: o
                // chip fica ANCORADO à direita do card (não flutuando colado
                // ao texto) e encolhe (ellipsis interno) em telas estreitas
                // com escala alta.
                if (pending)
                  Flexible(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: StatusChip(
                        label: context.l10n.statusPending,
                        color: theme.warning,
                        icon: Icons.schedule,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    // Data inteligente: 'Hoje/Ontem/04/08' + hora, sem
                    // repetir a data completa ao lado.
                    '${Formatters.day(transaction.date)} • '
                    '${Formatters.time(transaction.date)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Valor MINIMALISTA (15px Medium — regra de ouro da escala:
                // colunas de preços MZN em tamanho médio com peso Medium, sem
                // bold). FittedBox + Align: o valor fica ANCORADO à direita
                // do card e ENCOLHE para caber — nunca trunca ("MTn 600....")
                // e fica sempre visível ao lado da data.
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      '$sign ${Formatters.currency(transaction.amountCents)}',
                      maxLines: 1,
                      textAlign: TextAlign.end,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: color,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (pending && onReceive != null) ...[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: onReceive,
                  icon: const Icon(Icons.done_all, size: 16),
                  label: Text(context.l10n.financialReceive),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
