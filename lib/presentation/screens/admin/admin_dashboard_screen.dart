import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/entities/audit_entry.dart';
import '../../../domain/entities/tenant.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../controllers/admin_providers.dart';
import '../../widgets/app_card.dart';
import '../../widgets/error_view.dart';
import '../../widgets/premium_decor.dart';

import 'admin_thin_theme.dart';

part 'admin_dashboard_chart_widgets.dart';
part 'admin_dashboard_feed_widgets.dart';

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
                          style: AppTypography.labelSmall.copyWith(
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
                      style: AppTypography.labelSmall.copyWith(
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
                          color: AppColors.accentBlue,
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
