part of 'admin_dashboard_screen.dart';

class _StatItem {
  const _StatItem({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;
}

class _StatsStrip extends StatelessWidget {
  const _StatsStrip({required this.isLoading, required this.stats});

  final bool isLoading;
  final List<_StatItem> stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // Em texto grande as cinco colunas deixam de caber: a strip vira lista
    // de linhas valor/rótulo (mesma hierarquia, leitura preservada).
    final stacked =
        MediaQuery.textScalerOf(context).scale(AppTypography.bodyMediumSize) >=
        22;

    return AppCard(
      borderRadius: AppRadius.lgAll,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: isLoading
          ? Row(
              children: List.generate(
                5,
                (i) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: i == 0 ? 0 : AppSpacing.sm),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: AppSpacing.xxl,
                          height: AppSpacing.lg,
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest,
                            borderRadius: AppRadius.xsAll,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Container(
                          width: AppSpacing.huge,
                          height: AppSpacing.sm,
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest,
                            borderRadius: AppRadius.xsAll,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : stacked
          ? Column(
              children: [
                for (var i = 0; i < stats.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      color: PremiumDecor.hairline(scheme),
                    ),
                  _StatCell(stat: stats[i], inline: true),
                ],
              ],
            )
          : Row(
              children: [
                for (var i = 0; i < stats.length; i++) ...[
                  if (i > 0)
                    Container(
                      width: 1,
                      height: AppSizes.iconXl,
                      margin: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.micro,
                      ),
                      color: PremiumDecor.hairline(scheme),
                    ),
                  Expanded(child: _StatCell(stat: stats[i])),
                ],
              ],
            ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.stat, this.inline = false});

  final _StatItem stat;
  final bool inline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final value = Text(
      stat.value,
      style: theme.textTheme.headlineSmall?.copyWith(
        color: stat.color,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.4,
        fontFeatures: AppTypography.tabularFigures,
      ),
    );

    if (inline) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            value,
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                stat.label,
                style: AppTypography.bodySmall.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.end,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    return AdminStatValue(
      value: stat.value,
      label: stat.label,
      color: stat.color,
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Pending Banner
// ═════════════════════════════════════════════════════════════════════════════

class _PendingBanner extends StatelessWidget {
  const _PendingBanner({
    required this.totalPending,
    required this.onTap,
    required this.l10n,
  });

  final int totalPending;
  final VoidCallback onTap;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Banner de atenção: superfície neutra + hairline; o alerta vive no
    // ícone (semântico, >=3:1) e no texto em tinta (AA de texto).
    return AppCard(
      borderRadius: AppRadius.mdAll,
      color: scheme.surfaceContainerHighest,
      borderColor: scheme.outlineVariant,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            Icons.notifications_active_outlined,
            size: AppSizes.iconMd,
            color: theme.warning,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              l10n.adminPendingActionRequired(totalPending),
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurface,
              ),
            ),
          ),
          Icon(
            Icons.chevron_right,
            size: AppSizes.iconMd,
            color: scheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Growth Summary — consolidated card
// ═════════════════════════════════════════════════════════════════════════════

class _GrowthSummary extends StatelessWidget {
  const _GrowthSummary({
    required this.newThisWeek,
    required this.lastWeek,
    required this.newThisMonth,
    required this.lastMonth,
    required this.approvalsThisWeek,
    required this.approvalsLastWeek,
    required this.regBuckets,
    required this.actBuckets,
    required this.now,
    required this.l10n,
  });

  final int newThisWeek;
  final int lastWeek;
  final int newThisMonth;
  final int lastMonth;
  final int approvalsThisWeek;
  final int approvalsLastWeek;
  final List<int> regBuckets;
  final List<int> actBuckets;
  final DateTime now;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final weekDiff = newThisWeek - lastWeek;
    final monthDiff = newThisMonth - lastMonth;
    final approvalDiff = approvalsThisWeek - approvalsLastWeek;

    return AppCard(
      borderRadius: AppRadius.lgAll,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.adminGrowthTrends,
            style: AppTypography.labelSmall.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // KPI comparison cards
          Row(
            children: [
              Expanded(
                child: _GrowthKpi(
                  label: l10n.adminGrowthNewTenants,
                  sublabel:
                      '${l10n.adminGrowthThisWeek}: $newThisWeek · ${l10n.adminGrowthLastWeek}: $lastWeek',
                  diff: weekDiff,
                  color: scheme.primary,
                  l10n: l10n,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _GrowthKpi(
                  label: l10n.adminGrowthApprovals,
                  sublabel:
                      '${l10n.adminGrowthThisWeek}: $approvalsThisWeek · ${l10n.adminGrowthLastWeek}: $approvalsLastWeek',
                  diff: approvalDiff,
                  color: scheme.secondary,
                  l10n: l10n,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          _GrowthKpi(
            // Título próprio — o mensal usava o mesmo rótulo do semanal
            // e só o sublabel os diferenciava (ambiguidade no ecrã).
            label: l10n.adminGrowthNewTenantsMonth,
            sublabel:
                '${l10n.adminGrowthThisMonth}: $newThisMonth · ${l10n.adminGrowthLastMonth}: $lastMonth',
            diff: monthDiff,
            color: scheme.tertiary,
            l10n: l10n,
          ),

          // Charts
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.adminGrowthTrendsLabel,
            style: AppTypography.labelSmall.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: _TrendChart(
                  title: l10n.adminGrowthRegistrationsTrend,
                  buckets: regBuckets,
                  color: scheme.primary,
                  now: now,
                  l10n: l10n,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _TrendChart(
                  title: l10n.adminGrowthActivityTrend,
                  buckets: actBuckets,
                  color: scheme.secondary,
                  now: now,
                  l10n: l10n,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GrowthKpi extends StatelessWidget {
  const _GrowthKpi({
    required this.label,
    required this.sublabel,
    required this.diff,
    required this.color,
    required this.l10n,
  });

  final String label;
  final String sublabel;
  final int diff;
  final Color color;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final trendColor = diff > 0
        ? theme.income
        : diff < 0
        ? theme.expense
        : scheme.onSurfaceVariant;
    final trendIcon = diff > 0
        ? Icons.trending_up
        : diff < 0
        ? Icons.trending_down
        : Icons.trending_flat;
    final trendLabel = diff > 0
        ? l10n.adminGrowthUp('$diff')
        : diff < 0
        ? l10n.adminGrowthDown('${diff.abs()}')
        : l10n.adminGrowthFlat;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: AppRadius.mdAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(trendIcon, size: AppSizes.iconSm, color: trendColor),
              const SizedBox(width: AppSpacing.xxs),
              // Pílula de tendência NO PADRÃO do StatusChip: fundo tingido
              // 12% + texto na cor de estado — branco sobre o verde/âmbar
              // do tema não atinge AA (texto pequeno exige 4.5:1).
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.micro,
                ),
                decoration: BoxDecoration(
                  color: trendColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  trendLabel,
                  style: AppTypography.labelMedium.copyWith(color: trendColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.micro),
          Text(
            sublabel,
            style: AppTypography.bodySmall.copyWith(
              color: scheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Trend Chart — barras verticais com labels de semana
// ═════════════════════════════════════════════════════════════════════════════

class _TrendChart extends StatelessWidget {
  const _TrendChart({
    required this.title,
    required this.buckets,
    required this.color,
    required this.now,
    required this.l10n,
  });

  final String title;
  final List<int> buckets;
  final Color color;
  final DateTime now;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final maxVal = buckets.isEmpty
        ? 1
        : buckets.reduce(math.max).clamp(1, 9999);
    final total = buckets.fold(0, (a, b) => a + b);

    // Week labels (last 4 chars of abbreviated month)
    final weekStarts = <String>[];
    final thisWeekStart = _startOfWeek(now);
    for (var i = buckets.length - 1; i >= 0; i--) {
      final ws = thisWeekStart.subtract(Duration(days: i * 7));
      weekStarts.add(DateFormat('dd/MM').format(ws));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: AppSpacing.xs,
              height: AppSpacing.xs,
              decoration: BoxDecoration(
                color: color,
                borderRadius: AppRadius.microAll,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                title,
                style: AppTypography.bodySmall.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        if (total == 0)
          Container(
            height: AppSpacing.huge,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: AppRadius.xsAll,
            ),
            child: Text(
              l10n.adminGrowthNoData,
              style: AppTypography.bodySmall.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          )
        else
          Column(
            children: [
              // Bars
              SizedBox(
                height: 80,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < buckets.length; i++) ...[
                      if (i > 0) const SizedBox(width: 3),
                      Expanded(
                        child: _TrendBar(
                          value: buckets[i],
                          maxValue: maxVal,
                          color: color,
                          isLast: i == buckets.length - 1,
                          valueLabel: '${buckets[i]}',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              // Week labels
              SizedBox(
                height: AppSpacing.md,
                child: Row(
                  children: [
                    for (var i = 0; i < weekStarts.length; i++) ...[
                      if (i > 0) const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          i == 0 || i == weekStarts.length - 1
                              ? weekStarts[i]
                              : '',
                          style: AppTypography.bodySmall.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                          textAlign: i == 0 ? TextAlign.left : TextAlign.right,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _TrendBar extends StatelessWidget {
  const _TrendBar({
    required this.value,
    required this.maxValue,
    required this.color,
    required this.isLast,
    required this.valueLabel,
  });

  final int value;
  final int maxValue;
  final Color color;
  final bool isLast;
  final String valueLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fraction = maxValue > 0 ? value / maxValue : 0.0;
    final barHeight = (fraction * 56).clamp(2.0, 56.0);
    final barColor = isLast ? color : color.withValues(alpha: 0.3);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Value label on top
        if (value > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.micro),
            child: Text(
              valueLabel,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: isLast ? FontWeight.w500 : FontWeight.w400,
                color: isLast ? color : scheme.onSurfaceVariant,
              ),
            ),
          ),
        // Bar
        Container(
          height: barHeight,
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(value > 0 ? AppRadius.microRadius : 0),
            ),
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Distribution Card — tenant + plan combined
// ═════════════════════════════════════════════════════════════════════════════

class _DistributionCard extends StatelessWidget {
  const _DistributionCard({
    required this.totalTenants,
    required this.activeTenants,
    required this.pendingTenants,
    required this.rejectedTenants,
    required this.plans,
    required this.tenants,
    required this.isLoading,
    required this.l10n,
  });

  final int totalTenants;
  final int activeTenants;
  final int pendingTenants;
  final int rejectedTenants;
  final List plans;
  final List tenants;
  final bool isLoading;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (isLoading) {
      return AppCard(
        borderRadius: AppRadius.lgAll,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Container(
          width: double.infinity,
          height: AppSpacing.gigantic,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: AppRadius.smAll,
          ),
        ),
      );
    }

    // Tenant distribution
    final activePct = totalTenants > 0
        ? (activeTenants / totalTenants * 100).round()
        : 0;
    final pendingPct = totalTenants > 0
        ? (pendingTenants / totalTenants * 100).round()
        : 0;
    final rejectedPct = totalTenants > 0
        ? (rejectedTenants / totalTenants * 100).round()
        : 0;

    // Approval rate
    final approvalRate = totalTenants > 0
        ? (activeTenants / totalTenants * 100).round()
        : 0;
    final rateColor = approvalRate >= 70
        ? theme.income
        : approvalRate >= 40
        ? scheme.tertiary
        : theme.expense;

    // Plan distribution
    final planCounts = <String, int>{};
    for (final tenant in tenants) {
      final planId = tenant.planId as String;
      planCounts[planId] = (planCounts[planId] ?? 0) + 1;
    }
    final sorted = planCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxPlanCount = sorted.isNotEmpty ? sorted.first.value : 1;
    // Rampa neutra (10 passos da escala) — barras legíveis nos dois temas
    // sem introduzir cores fora da paleta.
    final planColors = [
      scheme.onSurface,
      AppColors.black70,
      AppColors.black60,
      AppColors.white60,
      scheme.secondary,
    ];

    return AppCard(
      borderRadius: AppRadius.lgAll,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tenant status bar
          if (totalTenants > 0) ...[
            ClipRRect(
              borderRadius: AppRadius.xsAll,
              child: SizedBox(
                height: AppSpacing.xxs + AppSpacing.micro,
                child: Row(
                  children: [
                    if (activeTenants > 0)
                      Expanded(
                        flex: activePct,
                        child: Container(color: scheme.primary),
                      ),
                    if (pendingTenants > 0)
                      Expanded(
                        flex: pendingPct,
                        child: Container(color: scheme.tertiary),
                      ),
                    if (rejectedTenants > 0)
                      Expanded(
                        flex: rejectedPct,
                        child: Container(color: scheme.error),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                _LegendDot(color: scheme.primary, label: '$activeTenants'),
                const SizedBox(width: AppSpacing.md),
                _LegendDot(color: scheme.tertiary, label: '$pendingTenants'),
                const SizedBox(width: AppSpacing.md),
                _LegendDot(color: scheme.error, label: '$rejectedTenants'),
                const Spacer(),
                // Approval rate inline
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.micro,
                  ),
                  decoration: BoxDecoration(
                    color: rateColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    '$approvalRate%',
                    style: AppTypography.labelMedium.copyWith(
                      color: rateColor,
                    ),
                  ),
                ),
              ],
            ),
          ] else
            Text(
              l10n.adminDashboardTotalTenants,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),

          // Plan distribution
          if (sorted.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.adminDashboardPlanDistribution,
              style: AppTypography.bodySmall.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            for (var i = 0; i < sorted.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.xxs),
              _PlanBarRow(
                planName:
                    plans
                        .where((p) => p.id == sorted[i].key)
                        .firstOrNull
                        ?.name ??
                    sorted[i].key,
                count: sorted[i].value,
                fraction: maxPlanCount > 0 ? sorted[i].value / maxPlanCount : 0,
                color: planColors[i % planColors.length],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
        ),
        const SizedBox(width: AppSpacing.xxs),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
