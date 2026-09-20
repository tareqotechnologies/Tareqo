import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../domain/entities/audit_entry.dart';
import '../../../domain/entities/tenant.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../controllers/admin_providers.dart';
import '../../widgets/app_card.dart';
import '../../widgets/error_view.dart';

/// Painel do super admin — visão geral compacta com KPIs, crescimento,
/// distribuições, atividade recente e ações rápidas.
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key, this.onNavigateToTab});

  final ValueChanged<int>? onNavigateToTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final allTenantsAsync = ref.watch(allTenantsProvider);
    final allPlansAsync = ref.watch(allPlansProvider);
    final pendingUpgradesAsync = ref.watch(pendingPlanRequestsProvider);
    final auditLogAsync = ref.watch(auditLogProvider);

    final allTenants = allTenantsAsync.value ?? const [];
    final allPlans = allPlansAsync.value ?? const [];
    final pendingUpgrades = pendingUpgradesAsync.value ?? const [];
    final auditEntries = auditLogAsync.value ?? const [];

    final totalTenants = allTenants.length;
    final activeTenants = allTenants
        .where((t) => t.status == TenantStatus.approved)
        .length;
    final pendingTenants = allTenants
        .where((t) => t.status == TenantStatus.pending)
        .length;
    final rejectedTenants = allTenants
        .where((t) => t.status == TenantStatus.rejected)
        .length;
    final totalPlans = allPlans.length;
    final totalPending = pendingTenants + pendingUpgrades.length;

    // ── Growth data ──
    final now = DateTime.now();
    final thisWeekStart = _startOfWeek(now);
    final lastWeekStart = _startOfWeek(
      thisWeekStart.subtract(const Duration(days: 1)),
    );
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);

    final newTenantsThisWeek = allTenants
        .where((t) => t.createdAt.isAfter(thisWeekStart))
        .length;
    final newTenantsLastWeek = allTenants
        .where(
          (t) =>
              t.createdAt.isAfter(lastWeekStart) &&
              !t.createdAt.isAfter(thisWeekStart),
        )
        .length;
    final newTenantsThisMonth = allTenants
        .where((t) => t.createdAt.isAfter(thisMonthStart))
        .length;
    final newTenantsLastMonth = allTenants
        .where(
          (t) =>
              t.createdAt.isAfter(lastMonthStart) &&
              !t.createdAt.isAfter(thisMonthStart),
        )
        .length;

    final approvalsThisWeek = auditEntries
        .where(
          (e) =>
              e.action == 'tenant_decision' &&
              e.detail?['status'] == 'approved' &&
              e.createdAt.isAfter(thisWeekStart),
        )
        .length;
    final approvalsLastWeek = auditEntries
        .where(
          (e) =>
              e.action == 'tenant_decision' &&
              e.detail?['status'] == 'approved' &&
              e.createdAt.isAfter(lastWeekStart) &&
              !e.createdAt.isAfter(thisWeekStart),
        )
        .length;

    // 8-week bucketed trends
    final regBuckets = _buildWeeklyBuckets(
      allTenants.map((t) => t.createdAt).toList(),
      now,
      8,
    );
    final actBuckets = _buildWeeklyBuckets(
      auditEntries.map((e) => e.createdAt).toList(),
      now,
      8,
    );

    final hasError =
        allTenantsAsync.hasError ||
        allPlansAsync.hasError ||
        pendingUpgradesAsync.hasError;
    final isLoading =
        allTenantsAsync.isLoading ||
        allPlansAsync.isLoading ||
        pendingUpgradesAsync.isLoading;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.adminDashboardTitle)),
      body: hasError && !isLoading
          ? ErrorView(
              message: l10n.adminDashboardLoadError,
              onRetry: () {
                ref.invalidate(allTenantsProvider);
                ref.invalidate(allPlansProvider);
                ref.invalidate(pendingPlanRequestsProvider);
              },
            )
          : RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(allTenantsProvider);
                ref.invalidate(allPlansProvider);
                ref.invalidate(pendingPlanRequestsProvider);
                ref.invalidate(auditLogProvider);
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.xxl,
                ),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  // ── Compact Stats Strip ──
                  _StatsStrip(
                    isLoading: isLoading,
                    stats: [
                      _StatItem(
                        value: '$totalTenants',
                        label: l10n.adminDashboardTotalTenants,
                        color: scheme.primary,
                      ),
                      _StatItem(
                        value: '$activeTenants',
                        label: l10n.adminDashboardActiveTenants,
                        // Acento verde do tema (AA sobre superfícies claras) —
                        // Colors.green dava ~2.5:1 no modo claro.
                        color: Theme.of(context).accent,
                      ),
                      _StatItem(
                        value: '$pendingTenants',
                        label: l10n.adminDashboardPendingTenants,
                        color: pendingTenants > 0
                            ? scheme.tertiary
                            : scheme.onSurfaceVariant,
                      ),
                      _StatItem(
                        value: '$totalPlans',
                        label: l10n.adminDashboardTotalPlans,
                        color: scheme.secondary,
                      ),
                      _StatItem(
                        value: '${pendingUpgrades.length}',
                        label: l10n.adminDashboardPendingUpgrades,
                        color: pendingUpgrades.isNotEmpty
                            ? scheme.tertiary
                            : scheme.onSurfaceVariant,
                      ),
                    ],
                  ),

                  // ── Pending Actions Banner ──
                  if (!isLoading && totalPending > 0) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _PendingBanner(
                      totalPending: totalPending,
                      onTap: () {
                        if (pendingTenants > 0) {
                          onNavigateToTab?.call(1);
                        } else {
                          onNavigateToTab?.call(3);
                        }
                      },
                      l10n: l10n,
                    ),
                  ],

                  // ── Growth Summary ──
                  if (!isLoading) ...[
                    const SizedBox(height: AppSpacing.xl),
                    _GrowthSummary(
                      newThisWeek: newTenantsThisWeek,
                      lastWeek: newTenantsLastWeek,
                      newThisMonth: newTenantsThisMonth,
                      lastMonth: newTenantsLastMonth,
                      approvalsThisWeek: approvalsThisWeek,
                      approvalsLastWeek: approvalsLastWeek,
                      regBuckets: regBuckets,
                      actBuckets: actBuckets,
                      now: now,
                      l10n: l10n,
                    ),
                  ],

                  // ── Distribution ──
                  const SizedBox(height: AppSpacing.xl),
                  _DistributionCard(
                    totalTenants: totalTenants,
                    activeTenants: activeTenants,
                    pendingTenants: pendingTenants,
                    rejectedTenants: rejectedTenants,
                    plans: allPlans,
                    tenants: allTenants,
                    isLoading: isLoading,
                    l10n: l10n,
                  ),

                  // ── Recent Activity ──
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.adminDashboardRecentActivity,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      if (auditEntries.isNotEmpty)
                        TextButton(
                          onPressed: () => onNavigateToTab?.call(4),
                          child: Text(l10n.adminActionViewAuditLog),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _RecentActivityFeed(
                    entries: auditEntries,
                    isLoading: auditLogAsync.isLoading,
                    l10n: l10n,
                  ),

                  // ── Quick Actions ──
                  if (!isLoading) ...[
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      l10n.dashboardQuickActions,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _QuickActionGrid(
                      actions: [
                        _QuickAction(
                          icon: Icons.pending_actions_outlined,
                          label: l10n.adminTenantRequests,
                          badge: pendingTenants,
                          color: scheme.tertiary,
                          onTap: () => onNavigateToTab?.call(1),
                        ),
                        _QuickAction(
                          icon: Icons.upgrade_outlined,
                          label: l10n.adminPlanUpgrades,
                          badge: pendingUpgrades.length,
                          color: AppColors.statusPurple,
                          onTap: () => onNavigateToTab?.call(3),
                        ),
                        _QuickAction(
                          icon: Icons.workspaces_outlined,
                          label: l10n.adminActionManagePlans,
                          color: scheme.primary,
                          onTap: () => onNavigateToTab?.call(2),
                        ),
                        _QuickAction(
                          icon: Icons.history_outlined,
                          label: l10n.adminActionViewAuditLog,
                          color: scheme.secondary,
                          onTap: () => onNavigateToTab?.call(4),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Growth helpers
// ═════════════════════════════════════════════════════════════════════════════

DateTime _startOfWeek(DateTime date) {
  final weekday = date.weekday;
  return DateTime(
    date.year,
    date.month,
    date.day,
  ).subtract(Duration(days: weekday - 1));
}

List<int> _buildWeeklyBuckets(List<DateTime> dates, DateTime now, int weeks) {
  final buckets = List.filled(weeks, 0);
  final weekStarts = <DateTime>[];
  for (var i = weeks - 1; i >= 0; i--) {
    weekStarts.add(_startOfWeek(now).subtract(Duration(days: i * 7)));
  }
  for (final date in dates) {
    for (var i = 0; i < weeks; i++) {
      final start = weekStarts[i];
      final end = start.add(const Duration(days: 7));
      if (!date.isBefore(start) && date.isBefore(end)) {
        buckets[i]++;
        break;
      }
    }
  }
  return buckets;
}

// ═════════════════════════════════════════════════════════════════════════════
// Stats Strip — horizontal scrollable key metrics
// ═════════════════════════════════════════════════════════════════════════════

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

    return AppCard(
      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.lg)),
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
                          width: 32,
                          height: 20,
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest,
                            borderRadius: AppRadius.xsAll,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 48,
                          height: 10,
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
          : Row(
              children: [
                for (var i = 0; i < stats.length; i++) ...[
                  if (i > 0)
                    Container(
                      width: 1,
                      height: 28,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      color: scheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                  Expanded(child: _StatCell(stat: stats[i])),
                ],
              ],
            ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.stat});

  final _StatItem stat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          stat.value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: stat.color,
            // Thin: KPI leve (24/w300) — o número respira, a hierarquia
            // vem do tamanho e da cor de estado.
            fontSize: 24,
            fontWeight: FontWeight.w300,
            letterSpacing: -0.4,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          stat.label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
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

    return AppCard(
      borderRadius: const BorderRadius.all(Radius.circular(14)),
      color: scheme.tertiaryContainer.withValues(alpha: 0.5),
      borderColor: scheme.tertiary.withValues(alpha: 0.3),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 10,
      ),
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            Icons.notifications_active_outlined,
            size: 18,
            color: scheme.tertiary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              l10n.adminPendingActionRequired(totalPending),
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.tertiary,
              ),
            ),
          ),
          Icon(Icons.chevron_right, size: 18, color: scheme.tertiary),
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
      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.lg)),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.adminGrowthTrends,
            style: theme.textTheme.labelSmall?.copyWith(
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
              const SizedBox(width: 8),
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
          const SizedBox(height: 8),
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
            style: theme.textTheme.labelSmall?.copyWith(
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
        ? AppColors.success
        : diff < 0
        ? scheme.error
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(trendIcon, size: 14, color: trendColor),
              const SizedBox(width: 4),
              // Pílula de tendência NO PADRÃO do StatusChip: fundo tingido
              // 12% + texto na cor de estado — branco sobre o verde/âmbar
              // do tema não atinge AA (texto pequeno exige 4.5:1).
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: trendColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  trendLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 12,
                    color: trendColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sublabel,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
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
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                  color: scheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (total == 0)
          Container(
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              l10n.adminGrowthNoData,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
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
              const SizedBox(height: 4),
              // Week labels
              SizedBox(
                height: 14,
                child: Row(
                  children: [
                    for (var i = 0; i < weekStarts.length; i++) ...[
                      if (i > 0) const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          i == 0 || i == weekStarts.length - 1
                              ? weekStarts[i]
                              : '',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant.withValues(
                              alpha: 0.4,
                            ),
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
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              valueLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                fontWeight: isLast ? FontWeight.w700 : FontWeight.w400,
                color: isLast
                    ? color
                    : scheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
        // Bar
        Container(
          height: barHeight,
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(value > 0 ? 3 : 0),
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
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.lg)),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Container(
          width: double.infinity,
          height: 64,
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
        ? AppColors.success
        : approvalRate >= 40
        ? AppColors.statusWarning
        : AppColors.statusError;

    // Plan distribution
    final planCounts = <String, int>{};
    for (final tenant in tenants) {
      final planId = tenant.planId as String;
      planCounts[planId] = (planCounts[planId] ?? 0) + 1;
    }
    final sorted = planCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxPlanCount = sorted.isNotEmpty ? sorted.first.value : 1;
    final planColors = [
      scheme.primary,
      AppColors.statusPurple,
      AppColors.statusWarning,
      AppColors.statusInfo,
      scheme.secondary,
    ];

    return AppCard(
      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.lg)),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tenant status bar
          if (totalTenants > 0) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 6,
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
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: rateColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$approvalRate%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: rateColor,
                      fontSize: 12,
                      fontFeatures: const [FontFeature.tabularFigures()],
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
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            for (var i = 0; i < sorted.length; i++) ...[
              if (i > 0) const SizedBox(height: 4),
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
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 12,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _PlanBarRow extends StatelessWidget {
  const _PlanBarRow({
    required this.planName,
    required this.count,
    required this.fraction,
    required this.color,
  });

  final String planName;
  final int count;
  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            planName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 6,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          '$count',
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 12,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Recent Activity Feed
// ═════════════════════════════════════════════════════════════════════════════

class _RecentActivityFeed extends StatelessWidget {
  const _RecentActivityFeed({
    required this.entries,
    required this.isLoading,
    required this.l10n,
  });

  final List<AuditEntry> entries;
  final bool isLoading;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (isLoading) {
      return AppCard(
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.lg)),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            for (var i = 0; i < 3; i++) ...[
              Container(
                width: double.infinity,
                height: 36,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: AppRadius.xsAll,
                ),
              ),
              if (i < 2) const SizedBox(height: AppSpacing.xs),
            ],
          ],
        ),
      );
    }

    final recent = entries.take(5).toList();

    if (recent.isEmpty) {
      return AppCard(
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.lg)),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(
              Icons.history_outlined,
              size: 16,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              l10n.adminAuditLogEmpty,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return AppCard(
      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.lg)),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < recent.length; i++) ...[
            _ActivityRow(entry: recent[i]),
            if (i < recent.length - 1)
              Divider(
                height: 1,
                indent: AppSpacing.md,
                endIndent: AppSpacing.md,
                color: scheme.outlineVariant.withValues(alpha: 0.5),
              ),
          ],
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.entry});

  final AuditEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final timeFormat = DateFormat.Hm();

    final status = entry.detail?['status'] as String?;
    final color = AppColors.decisionStatusColor(status);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 8,
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              entry.actionLabel,
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            timeFormat.format(entry.createdAt),
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Quick Actions
// ═════════════════════════════════════════════════════════════════════════════

class _QuickAction {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    this.badge = 0,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final int badge;
  final VoidCallback? onTap;
}

class _QuickActionGrid extends StatelessWidget {
  const _QuickActionGrid({required this.actions});

  final List<_QuickAction> actions;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 600 ? 4 : 2;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: actions.map((action) {
        final itemWidth =
            (width - AppSpacing.lg * 2 - AppSpacing.sm * (columns - 1)) /
            columns;
        return SizedBox(
          width: itemWidth,
          child: _QuickActionCard(action: action),
        );
      }).toList(),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.action});

  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.lg)),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      onTap: action.onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: action.color.withValues(alpha: 0.14),
                  borderRadius: AppRadius.smAll,
                ),
                child: Icon(action.icon, size: 18, color: action.color),
              ),
              if (action.badge > 0) ...[
                const Spacer(),
                // Contagem em pílula tingida com texto na própria cor do
                // item — `onTertiary` sobre primary/statusPurple era um
                // pareamento sem relação com a cor de fundo (contraste
                // imprevisível nos dois temas).
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: action.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${action.badge}',
                    style: TextStyle(
                      fontSize: 12,
                      color: action.color,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            action.label,
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
