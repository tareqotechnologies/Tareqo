import 'package:flutter/material.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/sale.dart';

/// Cabeçalho-resumo da tela de vendas — compact metric card.
class SalesSummaryHeader extends StatelessWidget {
  const SalesSummaryHeader({super.key, required this.sales});

  final List<Sale> sales;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    var todayCents = 0;
    var todayCount = 0;
    var yesterdayCents = 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    for (final sale in sales) {
      if (sale.status == SaleStatus.cancelled) continue;
      final day = DateTime(
        sale.dateTime.year,
        sale.dateTime.month,
        sale.dateTime.day,
      );
      if (day == today) {
        todayCents += sale.totalAmountCents;
        todayCount++;
      } else if (day == yesterday) {
        yesterdayCents += sale.totalAmountCents;
      }
    }

    final deltaPercent = yesterdayCents > 0
        ? ((todayCents - yesterdayCents) / yesterdayCents * 100).round()
        : null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.periodToday,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    Formatters.currency(todayCents),
                    maxLines: 1,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.salesHeaderTransactions(todayCount),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (deltaPercent != null) ...[
            const SizedBox(width: 12),
            _CompactDelta(
              percent: deltaPercent,
              label: l10n.salesHeaderVsYesterday,
              upColor: theme.income,
              downColor: theme.expense,
            ),
          ],
        ],
      ),
    );
  }
}

class _CompactDelta extends StatelessWidget {
  const _CompactDelta({
    required this.percent,
    required this.label,
    this.upColor,
    this.downColor,
  });

  final int percent;
  final String label;
  final Color? upColor;
  final Color? downColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final up = percent > 0;
    final color = up
        ? (upColor ?? theme.colorScheme.primary)
        : percent < 0
            ? (downColor ?? theme.expense)
            : theme.colorScheme.onSurfaceVariant;
    final icon = up
        ? Icons.trending_up
        : percent < 0
            ? Icons.trending_down
            : Icons.trending_flat;
    final sign = up ? '+' : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$sign$percent%',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

