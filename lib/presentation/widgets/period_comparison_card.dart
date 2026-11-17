import 'package:flutter/material.dart';

import '../../core/i18n/l10n_ext.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import 'app_card.dart';

/// One money metric compared with the equivalent preceding period.
final class PeriodComparisonMetric {
  const PeriodComparisonMetric({
    required this.label,
    required this.currentCents,
    required this.previousCents,
  });

  final String label;
  final int currentCents;
  final int previousCents;
}

/// Compact, localized comparison card shared by standard and advanced reports.
class PeriodComparisonCard extends StatelessWidget {
  const PeriodComparisonCard({super.key, required this.metrics});

  final List<PeriodComparisonMetric> metrics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    return AppCard(
      elevated: true,
      borderRadius: AppRadius.lgAll,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.reportsComparisonHeading,
            style: AppTypography.labelLarge.copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < metrics.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.xs),
            _ComparisonRow(metric: metrics[i]),
          ],
        ],
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({required this.metric});

  final PeriodComparisonMetric metric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final delta = metric.currentCents - metric.previousCents;
    final previous = metric.previousCents;
    final hasBaseline = previous != 0;
    final percent = hasBaseline ? delta / previous.abs() * 100 : 0.0;
    final positive = delta > 0;
    final negative = delta < 0;
    final color = positive
        ? theme.income
        : negative
        ? theme.expense
        : scheme.onSurfaceVariant;
    final signedAmount =
        '${positive
            ? '+'
            : negative
            ? '−'
            : ''}'
        '${Formatters.currency(delta.abs())}';
    final signedPercent =
        '${positive
            ? '+'
            : negative
            ? '−'
            : ''}'
        '${percent.abs().toStringAsFixed(1)}%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          metric.label,
          style: AppTypography.bodySmall.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.micro),
        Row(
          children: [
            Icon(
              positive
                  ? Icons.trending_up_rounded
                  : negative
                  ? Icons.trending_down_rounded
                  : Icons.trending_flat_rounded,
              size: AppSizes.iconSm,
              color: color,
            ),
            const SizedBox(width: AppSpacing.xxs),
            Expanded(
              child: Text(
                hasBaseline
                    ? l10n.reportsComparisonValue(signedAmount, signedPercent)
                    : l10n.reportsComparisonNoBaseline,
                style: AppTypography.labelMedium.copyWith(color: color),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
