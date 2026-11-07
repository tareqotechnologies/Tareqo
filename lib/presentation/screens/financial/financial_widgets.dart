import 'package:flutter/material.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/financial_transaction.dart';
import '../../widgets/app_button.dart';
import '../../widgets/detail_row.dart';

/// Ícone inteligente por direção do movimento: entrada (north_east) em
/// verde e saída (south_west) em vermelho — mesma direção do feed da
/// Home (dinheiro que entra sobe, que sai desce).
extension TransactionDirectionIcon on TransactionType {
  IconData get icon => switch (this) {
    TransactionType.income => Icons.north_east,
    TransactionType.expense => Icons.south_west,
  };
}

/// Card de movimentação ultra-compacto — apenas 3 informações:
/// tipo (categoria), valor e timestamp.
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
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              // ── Descrição (esquerda) ──
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      // Minimalista: labelMedium = 14/w400, igual vendas
                      style: theme.textTheme.labelMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      Formatters.time(transaction.date),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      // Metadado = 12/w400, discreto.
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // ── Valor, alinhado à direita, fonte menor ──
              // FittedBox agressivo: encolhe em escala 2.0 sem estourar.
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      '$sign ${Formatters.currency(transaction.amountCents)}',
                      maxLines: 1,
                      // Minimalista: labelMedium = 14/w400, sem bold.
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
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
    final totalColor = totalCents >= 0 ? theme.income : theme.expense;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        4,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              // Cabeçalho de data = 12/w500 (a escala já traz o peso).
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          // Flexible + FittedBox: o total do dia encolhe em vez de cortar
          // quando o valor é longo ou a escala de texto aumenta.
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: totalColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  Formatters.signedAmount(totalCents),
                  maxLines: 1,
                  // Total do dia: 12/w500, discreto no cabeçalho do grupo.
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: totalColor,
                  ),
                ),
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
          // ── Valor em destaque ──
          Center(
            child: Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: IconTone.darkBackground(color),
              ),
              child: Icon(
                transaction.type.icon,
                size: 24,
                color: IconTone.lightForeground(color),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              '$sign ${Formatters.currency(transaction.amountCents)}',
              // Valor principal do detalhe: 24/w600 da escala.
              style: AppTypography.headline.copyWith(color: color),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              transaction.type.label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Detalhes ──
          DetailRow(
            label: l10n.financialDetailDescription,
            value: transaction.description,
          ),
          DetailRow(
            label: l10n.financialDetailCategory,
            value: transaction.category,
          ),
          DetailRow(
            label: l10n.financialDetailNumber,
            value: Formatters.entityNumber(transaction.id),
          ),
          DetailRow(
            label: l10n.financialDetailDate,
            value: Formatters.dateTime(transaction.date),
          ),
          DetailRow(
            label: l10n.financialDetailStatus,
            value: transaction.status.label,
            valueColor: pending ? theme.warning : theme.income,
          ),

          // ── Ação pendente ──
          if (pending && isIncome && onReceive != null) ...[
            const SizedBox(height: 20),
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
            const SizedBox(height: 20),
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
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
