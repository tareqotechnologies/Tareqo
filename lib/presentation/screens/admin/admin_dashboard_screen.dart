import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../domain/entities/audit_entry.dart';
import '../../../domain/entities/tenant.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../controllers/admin_providers.dart';
import '../../widgets/app_card.dart';
import '../../widgets/error_view.dart';

/// Painel do super admin — visão geral panorâmica com KPIs, tendências de
/// crescimento, distribuições, atividade recente e ações rápidas.
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
    final activeTenants =
        allTenants.where((t) => t.status == TenantStatus.approved).length;
    final pendingTenants =
        allTenants.where((t) => t.status == TenantStatus.pending).length;
    final rejectedTenants =
        allTenants.where((t) => t.status == TenantStatus.rejected).length;
    final totalPlans = allPlans.length;
    final totalPending = pendingTenants + pendingUpgrades.length;

    // ── Growth data ──
    final now = DateTime.now();
    final thisWeekStart = _startOfWeek(now);
    final lastWeekStart = _startOfWeek(thisWeekStart.subtract(const Duration(days: 1)));
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);

    final newTenantsThisWeek = allTenants
        .where((t) => t.createdAt.isAfter(thisWeekStart))
        .length;
    final newTenantsLastWeek = allTenants.where((t) =>
        t.createdAt.isAfter(lastWeekStart) &&
        !t.createdAt.isAfter(thisWeekStart)).length;
    final newTenantsThisMonth = allTenants
        .where((t) => t.createdAt.isAfter(thisMonthStart))
        .length;
    final newTenantsLastMonth = allTenants.where((t) =>
        t.createdAt.isAfter(lastMonthStart) &&
        !t.createdAt.isAfter(thisMonthStart)).length;

    final approvalsThisWeek = auditEntries
        .where((e) =>
            e.action == 'tenant_decision' &&
            e.detail?['status'] == 'approved' &&
            e.createdAt.isAfter(thisWeekStart))
        .length;
    final approvalsLastWeek = auditEntries.where((e) =>
        e.action == 'tenant_decision' &&
        e.detail?['status'] == 'approved' &&
        e.createdAt.isAfter(lastWeekStart) &&
        !e.createdAt.isAfter(thisWeekStart)).length;

    // 8-week bucketed registration trend
    final regBuckets = _buildWeeklyBuckets(
      allTenants.map((t) => t.createdAt).toList(),
      now,
      8,
    );
    // 8-week bucketed activity trend
    final actBuckets = _buildWeeklyBuckets(
      auditEntries.map((e) => e.createdAt).toList(),
      now,
      8,
    );

    final hasError = allTenantsAsync.hasError ||
        allPlansAsync.hasError ||
        pendingUpgradesAsync.hasError;
    final isLoading = allTenantsAsync.isLoading ||
        allPlansAsync.isLoading ||
        pendingUpgradesAsync.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.adminDashboardTitle,
          style: theme.textTheme.labelMedium?.copyWith(
            letterSpacing: -0.5,
          ),
        ),
      ),
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
                  // ── Status Banner ──
                  _StatusBanner(
                    isLoading: isLoading,
                    totalPending: totalPending,
                    totalTenants: totalTenants,
                    totalPlans: totalPlans,
                    l10n: l10n,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // ── KPI Grid ──
                  Text(
                    l10n.adminPlatformStatus,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _KpiGrid(
                    isLoading: isLoading,
                    items: [
                      _KpiData(
                        label: l10n.adminDashboardTotalTenants,
                        value: totalTenants,
                        icon: Icons.business_outlined,
                        color: scheme.primary,
                      ),
                      _KpiData(
                        label: l10n.adminDashboardActiveTenants,
                        value: activeTenants,
                        icon: Icons.check_circle_outline,
                        color: scheme.primary,
                      ),
                      _KpiData(
                        label: l10n.adminDashboardPendingTenants,
                        value: pendingTenants,
                        icon: Icons.hourglass_top_outlined,
                        color: pendingTenants > 0
                            ? scheme.tertiary
                            : scheme.onSurfaceVariant,
                      ),
                      _KpiData(
                        label: l10n.adminDashboardTotalPlans,
                        value: totalPlans,
                        icon: Icons.workspaces_outlined,
                        color: scheme.secondary,
                      ),
                      _KpiData(
                        label: l10n.adminDashboardPendingUpgrades,
                        value: pendingUpgrades.length,
                        icon: Icons.upgrade_outlined,
                        color: pendingUpgrades.isNotEmpty
                            ? scheme.tertiary
                            : scheme.onSurfaceVariant,
                      ),
                      if (rejectedTenants > 0)
                        _KpiData(
                          label: l10n.statusRejected,
                          value: rejectedTenants,
                          icon: Icons.block_outlined,
                          color: scheme.error,
                        ),
                    ],
                  ),

                  // ── Growth Trends ──
                  if (!isLoading) ...[
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      l10n.adminGrowthTrends,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Period comparison cards
                    _GrowthComparisonRow(
                      title: l10n.adminGrowthNewTenants,
                      thisPeriod: newTenantsThisWeek,
                      lastPeriod: newTenantsLastWeek,
                      thisLabel: l10n.adminGrowthThisWeek,
                      lastLabel: l10n.adminGrowthLastWeek,
                      icon: Icons.person_add_outlined,
                      color: scheme.primary,
                      l10n: l10n,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _GrowthComparisonRow(
                      title: l10n.adminGrowthApprovals,
                      thisPeriod: approvalsThisWeek,
                      lastPeriod: approvalsLastWeek,
                      thisLabel: l10n.adminGrowthThisWeek,
                      lastLabel: l10n.adminGrowthLastWeek,
                      icon: Icons.verified_outlined,
                      color: Colors.green,
                      l10n: l10n,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _GrowthComparisonRow(
                      title: l10n.adminGrowthNewTenants,
                      thisPeriod: newTenantsThisMonth,
                      lastPeriod: newTenantsLastMonth,
                      thisLabel: l10n.adminGrowthThisMonth,
                      lastLabel: l10n.adminGrowthLastMonth,
                      icon: Icons.calendar_month_outlined,
                      color: scheme.tertiary,
                      l10n: l10n,
                    ),

                    // Registration trend sparkline
                    const SizedBox(height: AppSpacing.xl),
                    _SparklineChart(
                      title: l10n.adminGrowthRegistrationsTrend,
                      buckets: regBuckets,
                      color: scheme.primary,
                      now: now,
                      l10n: l10n,
                    ),

                    // Activity trend sparkline
                    const SizedBox(height: AppSpacing.sm),
                    _SparklineChart(
                      title: l10n.adminGrowthActivityTrend,
                      buckets: actBuckets,
                      color: scheme.tertiary,
                      now: now,
                      l10n: l10n,
                    ),

                    // Average velocity
                    const SizedBox(height: AppSpacing.sm),
                    _VelocityCard(
                      regBuckets: regBuckets,
                      actBuckets: actBuckets,
                      l10n: l10n,
                    ),
                  ],

                  // ── Tenant Distribution ──
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    l10n.adminDashboardTenantDistribution,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _TenantDistributionBar(
                    total: totalTenants,
                    active: activeTenants,
                    pending: pendingTenants,
                    rejected: rejectedTenants,
                    isLoading: isLoading,
                    l10n: l10n,
                  ),

                  // ── Approval Rate ──
                  const SizedBox(height: AppSpacing.xl),
                  _ApprovalRateCard(
                    total: totalTenants,
                    approved: activeTenants,
                    rejected: rejectedTenants,
                    isLoading: isLoading,
                    l10n: l10n,
                  ),

                  // ── Plan Distribution ──
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    l10n.adminDashboardPlanDistribution,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _PlanDistribution(
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
                          color: const Color(0xFF7C3AED),
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

/// Returns the start of the week (Monday) containing [date].
DateTime _startOfWeek(DateTime date) {
  final weekday = date.weekday; // 1=Mon
  return DateTime(date.year, date.month, date.day)
      .subtract(Duration(days: weekday - 1));
}

/// Builds [weeks] weekly buckets of item counts ending at [now].
/// Returns a list of length [weeks], index 0 = oldest week.
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
// Growth Comparison Row
// ═════════════════════════════════════════════════════════════════════════════

class _GrowthComparisonRow extends StatelessWidget {
  const _GrowthComparisonRow({
    required this.title,
    required this.thisPeriod,
    required this.lastPeriod,
    required this.thisLabel,
    required this.lastLabel,
    required this.icon,
    required this.color,
    required this.l10n,
  });

  final String title;
  final int thisPeriod;
  final int lastPeriod;
  final String thisLabel;
  final String lastLabel;
  final IconData icon;
  final Color color;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final diff = thisPeriod - lastPeriod;
    final diffStr = diff > 0
        ? '$diff'
        : diff < 0
            ? '${diff.abs()}'
            : '0';
    final trend = diff > 0 ? 'up' : diff < 0 ? 'down' : 'flat';
    final trendColor = diff > 0
        ? Colors.green
        : diff < 0
            ? scheme.error
            : scheme.onSurfaceVariant;

    return AppCard(
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: AppRadius.xsAll,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  '$thisLabel: $thisPeriod · $lastLabel: $lastPeriod',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          _TrendBadge(
            count: diffStr,
            trend: trend,
            color: trendColor,
            l10n: l10n,
          ),
        ],
      ),
    );
  }
}

class _TrendBadge extends StatelessWidget {
  const _TrendBadge({
    required this.count,
    required this.trend,
    required this.color,
    required this.l10n,
  });

  final String count;
  final String trend;
  final Color color;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = trend == 'up'
        ? l10n.adminGrowthUp(count)
        : trend == 'down'
            ? l10n.adminGrowthDown(count)
            : l10n.adminGrowthFlat;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            trend == 'up'
                ? Icons.trending_up
                : trend == 'down'
                    ? Icons.trending_down
                    : Icons.trending_flat,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Sparkline Chart (custom painted bar chart)
// ═════════════════════════════════════════════════════════════════════════════

class _SparklineChart extends StatelessWidget {
  const _SparklineChart({
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
    final avg = buckets.isEmpty
        ? '0'
        : (total / buckets.length).toStringAsFixed(1);
    final weekStart = _startOfWeek(now);

    return AppCard(
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(
                  ),
                ),
              ),
              Text(
                l10n.adminGrowthAvgPerWeek(avg),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (total == 0)
            Text(
              l10n.adminGrowthNoData,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            )
          else
            SizedBox(
              height: 80,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < buckets.length; i++) ...[
                    if (i > 0) const SizedBox(width: 4),
                    Expanded(
                      child: _BarColumn(
                        value: buckets[i],
                        maxValue: maxVal,
                        color: i == buckets.length - 1
                            ? color
                            : color.withValues(alpha: 0.4),
                        showLabel: i == buckets.length - 1 && buckets[i] > 0,
                        labelColor: color,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.xs),
          // Week labels
          if (total > 0)
            Row(
              children: [
                for (var i = 0; i < buckets.length; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  Expanded(
                    child: Center(
                      child: Text(
                        l10n.adminGrowthWeekLabel(
                          '${_weekOfYear(weekStart.subtract(Duration(days: (buckets.length - 1 - i) * 7)))}',
                        ),
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  static int _weekOfYear(DateTime date) {
    final jan1 = DateTime(date.year, 1, 1);
    final days = date.difference(jan1).inDays;
    return (days / 7).ceil().clamp(1, 53);
  }
}

class _BarColumn extends StatelessWidget {
  const _BarColumn({
    required this.value,
    required this.maxValue,
    required this.color,
    this.showLabel = false,
    this.labelColor,
  });

  final int value;
  final int maxValue;
  final Color color;
  final bool showLabel;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    final fraction = maxValue > 0 ? value / maxValue : 0.0;
    final barHeight = (fraction * 64).clamp(4.0, 64.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabel)
          Text(
            '$value',
            style: TextStyle(
              fontSize: 10,
              color: labelColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        if (showLabel) const SizedBox(height: 2),
        Container(
          height: barHeight,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Velocity Card
// ═════════════════════════════════════════════════════════════════════════════

class _VelocityCard extends StatelessWidget {
  const _VelocityCard({
    required this.regBuckets,
    required this.actBuckets,
    required this.l10n,
  });

  final List<int> regBuckets;
  final List<int> actBuckets;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final regTotal = regBuckets.fold(0, (a, b) => a + b);
    final actTotal = actBuckets.fold(0, (a, b) => a + b);
    final regAvg = regBuckets.isEmpty
        ? '0'
        : (regTotal / regBuckets.length).toStringAsFixed(1);
    final actAvg = actBuckets.isEmpty
        ? '0'
        : (actTotal / actBuckets.length).toStringAsFixed(1);

    // Trend direction based on last 2 buckets vs previous 2
    final regTrend = regBuckets.length >= 4
        ? (regBuckets.last + regBuckets[regBuckets.length - 2]) -
            (regBuckets[regBuckets.length - 3] + regBuckets[regBuckets.length - 4])
        : 0;
    final actTrend = actBuckets.length >= 4
        ? (actBuckets.last + actBuckets[actBuckets.length - 2]) -
            (actBuckets[actBuckets.length - 3] + actBuckets[actBuckets.length - 4])
        : 0;

    return AppCard(
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: _VelocityItem(
              label: l10n.adminGrowthNewTenants,
              avg: regAvg,
              trend: regTrend,
              color: scheme.primary,
              l10n: l10n,
            ),
          ),
          Container(
            width: 1,
            height: 28,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
          Expanded(
            child: _VelocityItem(
              label: l10n.adminGrowthApprovals,
              avg: actAvg,
              trend: actTrend,
              color: Colors.green,
              l10n: l10n,
            ),
          ),
        ],
      ),
    );
  }
}

class _VelocityItem extends StatelessWidget {
  const _VelocityItem({
    required this.label,
    required this.avg,
    required this.trend,
    required this.color,
    required this.l10n,
  });

  final String label;
  final String avg;
  final int trend;
  final Color color;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final trendColor = trend > 0
        ? Colors.green
        : trend < 0
            ? scheme.error
            : scheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            fontSize: 10,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                l10n.adminGrowthAvgPerWeek(avg),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color,
                  fontSize: 11,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              trend > 0
                  ? Icons.arrow_upward
                  : trend < 0
                      ? Icons.arrow_downward
                      : Icons.remove,
              size: 12,
              color: trendColor,
            ),
          ],
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Status Banner
// ═════════════════════════════════════════════════════════════════════════════

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.isLoading,
    required this.totalPending,
    required this.totalTenants,
    required this.totalPlans,
    required this.l10n,
  });

  final bool isLoading;
  final int totalPending;
  final int totalTenants;
  final int totalPlans;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasUrgent = totalPending > 0;

    return AppCard(
      borderRadius: const BorderRadius.all(Radius.circular(18)),
      color: hasUrgent
          ? scheme.tertiaryContainer.withValues(alpha: 0.5)
          : scheme.primaryContainer.withValues(alpha: 0.4),
      borderColor: hasUrgent
          ? scheme.tertiary.withValues(alpha: 0.3)
          : scheme.primary.withValues(alpha: 0.3),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: hasUrgent
                  ? scheme.tertiary.withValues(alpha: 0.2)
                  : scheme.primary.withValues(alpha: 0.2),
              borderRadius: AppRadius.mdAll,
            ),
            child: Icon(
              hasUrgent
                  ? Icons.notifications_active_outlined
                  : Icons.shield_outlined,
              size: 24,
              color: hasUrgent ? scheme.tertiary : scheme.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.adminPlatformSummary('$totalPlans', '$totalTenants'),
                  style: theme.textTheme.bodySmall?.copyWith(
                  ),
                ),
                const SizedBox(height: 2),
                if (isLoading)
                  Container(
                    width: 80,
                    height: 12,
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: AppRadius.xsAll,
                    ),
                  )
                else
                  Text(
                    hasUrgent
                        ? l10n.adminPendingActionRequired(totalPending)
                        : l10n.adminNoPendingActions,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: hasUrgent
                          ? scheme.tertiary
                          : scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          if (hasUrgent && !isLoading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: scheme.tertiary,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$totalPending',
                style: TextStyle(
                  fontSize: 10,
                  color: scheme.onTertiary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Tenant Distribution Bar
// ═════════════════════════════════════════════════════════════════════════════

class _TenantDistributionBar extends StatelessWidget {
  const _TenantDistributionBar({
    required this.total,
    required this.active,
    required this.pending,
    required this.rejected,
    required this.isLoading,
    required this.l10n,
  });

  final int total;
  final int active;
  final int pending;
  final int rejected;
  final bool isLoading;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (isLoading) {
      return AppCard(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Container(
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: AppRadius.smAll,
          ),
        ),
      );
    }

    if (total == 0) {
      return AppCard(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(
          l10n.adminDashboardTotalTenants,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final activePct = (active / total * 100).round();
    final pendingPct = (pending / total * 100).round();
    final rejectedPct = (rejected / total * 100).round();

    return AppCard(
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Distribution bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  if (active > 0)
                    Expanded(
                      flex: activePct,
                      child: Container(color: scheme.primary),
                    ),
                  if (pending > 0)
                    Expanded(
                      flex: pendingPct,
                      child: Container(color: scheme.tertiary),
                    ),
                  if (rejected > 0)
                    Expanded(
                      flex: rejectedPct,
                      child: Container(color: scheme.error),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Legend
          Row(
            children: [
              _LegendDot(color: scheme.primary, label: '$active'),
              const SizedBox(width: AppSpacing.md),
              _LegendDot(
                color: scheme.tertiary,
                label: '$pending',
              ),
              const SizedBox(width: AppSpacing.md),
              _LegendDot(
                color: scheme.error,
                label: '$rejected',
              ),
              const Spacer(),
              Text(
                l10n.adminDashboardActivePercent(activePct),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.primary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
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
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Approval Rate Card
// ═════════════════════════════════════════════════════════════════════════════

class _ApprovalRateCard extends StatelessWidget {
  const _ApprovalRateCard({
    required this.total,
    required this.approved,
    required this.rejected,
    required this.isLoading,
    required this.l10n,
  });

  final int total;
  final int approved;
  final int rejected;
  final bool isLoading;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final rate = total > 0 ? (approved / total * 100).round() : 0;
    final color = rate >= 70
        ? Colors.green
        : rate >= 40
            ? Colors.orange
            : Colors.red;

    return AppCard(
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          // Circular progress
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: isLoading ? 0 : rate / 100,
                  strokeWidth: 6,
                  backgroundColor: scheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isLoading ? scheme.onSurfaceVariant : color,
                  ),
                ),
                if (!isLoading)
                  Text(
                    '$rate%',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: color,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.adminDashboardApprovalRate,
                  style: theme.textTheme.labelMedium?.copyWith(
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$approved ${l10n.adminAuditLogApproved.toLowerCase()} · $rejected ${l10n.adminAuditLogRejected.toLowerCase()}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Plan Distribution
// ═════════════════════════════════════════════════════════════════════════════

class _PlanDistribution extends StatelessWidget {
  const _PlanDistribution({
    required this.plans,
    required this.tenants,
    required this.isLoading,
    required this.l10n,
  });

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
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Container(
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: AppRadius.smAll,
          ),
        ),
      );
    }

    // Count tenants per plan
    final planCounts = <String, int>{};
    for (final tenant in tenants) {
      final planId = tenant.planId as String;
      planCounts[planId] = (planCounts[planId] ?? 0) + 1;
    }

    final sorted = planCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final maxCount = sorted.isNotEmpty ? sorted.first.value : 1;
    final colors = [
      scheme.primary,
      const Color(0xFF7C3AED),
      const Color(0xFFF59E0B),
      const Color(0xFF3B82F6),
      scheme.secondary,
    ];

    return AppCard(
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: sorted.isEmpty
          ? Text(
              '—',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < sorted.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.xs),
                  _PlanBarRow(
                    planName: plans
                            .where((p) => p.id == sorted[i].key)
                            .firstOrNull
                            ?.name ??
                        sorted[i].key,
                    count: sorted[i].value,
                    fraction: maxCount > 0 ? sorted[i].value / maxCount : 0,
                    color: colors[i % colors.length],
                  ),
                ],
              ],
            ),
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
          width: 80,
          child: Text(
            planName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 8,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '$count',
          style: theme.textTheme.bodySmall?.copyWith(
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
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            for (var i = 0; i < 3; i++) ...[
              Container(
                width: double.infinity,
                height: 40,
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
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(
              Icons.history_outlined,
              size: 18,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.sm),
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
      borderRadius: const BorderRadius.all(Radius.circular(16)),
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
    final color = _statusColor(status);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              entry.actionLabel,
              style: theme.textTheme.bodySmall?.copyWith(
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            timeFormat.format(entry.createdAt),
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// KPI Grid
// ═════════════════════════════════════════════════════════════════════════════

class _KpiData {
  const _KpiData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.isLoading, required this.items});

  final bool isLoading;
  final List<_KpiData> items;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 600 ? 3 : 2;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: items.map((item) {
        final itemWidth =
            (width - AppSpacing.lg * 2 - AppSpacing.sm * (columns - 1)) /
                columns;
        return SizedBox(
          width: itemWidth,
          child: _AdminKpiCard(
            label: item.label,
            value: isLoading ? null : '${item.value}',
            icon: item.icon,
            iconColor: item.color,
            loading: isLoading,
          ),
        );
      }).toList(),
    );
  }
}

class _AdminKpiCard extends StatelessWidget {
  const _AdminKpiCard({
    required this.label,
    this.value,
    required this.icon,
    this.iconColor,
    this.loading = false,
  });

  final String label;
  final String? value;
  final IconData icon;
  final Color? iconColor;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = iconColor ?? scheme.primary;

    return AppCard(
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: AppRadius.smAll,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (loading)
            Container(
              width: 32,
              height: 24,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: AppRadius.xsAll,
              ),
            )
          else
            Text(
              value ?? '—',
              style: theme.textTheme.labelMedium?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
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
    final scheme = theme.colorScheme;

    return AppCard(
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      onTap: action.onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: action.color.withValues(alpha: 0.14),
                  borderRadius: AppRadius.smAll,
                ),
                child: Icon(action.icon, size: 20, color: action.color),
              ),
              if (action.badge > 0) ...[
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: action.color,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${action.badge}',
                    style: TextStyle(
                      fontSize: 10,
                      color: scheme.onTertiary,
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
            style: theme.textTheme.bodySmall?.copyWith(
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
