import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_tokens.dart';
import '../../controllers/admin_providers.dart';
import '../../widgets/app_card.dart';
import '../../widgets/error_view.dart';

/// Painel do super admin — visão geral com KPIs e indicadores-chave
/// para acompanhamento rápido do estado da plataforma.
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final allTenantsAsync = ref.watch(allTenantsProvider);
    final allPlansAsync = ref.watch(allPlansProvider);
    final pendingUpgradesAsync = ref.watch(pendingPlanRequestsProvider);

    // Calcular KPIs a partir dos dados carregados.
    final allTenants = allTenantsAsync.value ?? const [];
    final allPlans = allPlansAsync.value ?? const [];
    final pendingUpgrades = pendingUpgradesAsync.value ?? const [];

    final totalTenants = allTenants.length;
    final activeTenants =
        allTenants.where((t) => t.status.name == 'approved').length;
    final pendingTenants =
        allTenants.where((t) => t.status.name == 'pending').length;
    final totalPlans = allPlans.length;

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
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w500,
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
                  // ── KPIs de Tenants ──
                  Text(
                    l10n.adminTenantsTitle,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: _AdminKpiCard(
                          label: l10n.adminDashboardTotalTenants,
                          value: isLoading ? null : '$totalTenants',
                          icon: Icons.business_outlined,
                          loading: isLoading,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _AdminKpiCard(
                          label: l10n.adminDashboardActiveTenants,
                          value: isLoading ? null : '$activeTenants',
                          icon: Icons.check_circle_outline,
                          iconColor: Theme.of(context).colorScheme.primary,
                          loading: isLoading,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _AdminKpiCard(
                          label: l10n.adminDashboardPendingTenants,
                          value: isLoading ? null : '$pendingTenants',
                          icon: Icons.hourglass_top_outlined,
                          iconColor: pendingTenants > 0
                              ? Theme.of(context).colorScheme.tertiary
                              : null,
                          loading: isLoading,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── KPIs de Planos e Upgrades ──
                  Text(
                    l10n.adminNavPlans,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: _AdminKpiCard(
                          label: l10n.adminDashboardTotalPlans,
                          value: isLoading ? null : '$totalPlans',
                          icon: Icons.workspaces_outlined,
                          loading: isLoading,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _AdminKpiCard(
                          label: l10n.adminDashboardPendingUpgrades,
                          value: isLoading
                              ? null
                              : '${pendingUpgrades.length}',
                          icon: Icons.upgrade_outlined,
                          iconColor: pendingUpgrades.isNotEmpty
                              ? Theme.of(context).colorScheme.tertiary
                              : null,
                          loading: isLoading,
                        ),
                      ),
                    ],
                  ),

                  // ── Ações rápidas ──
                  if (!isLoading) ...[
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      l10n.dashboardQuickActions,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _QuickActionRow(
                      icon: Icons.pending_actions_outlined,
                      label: l10n.adminNavRequests,
                      trailing: pendingTenants > 0
                          ? _Badge(count: pendingTenants)
                          : null,
                    ),
                    _QuickActionRow(
                      icon: Icons.upgrade_outlined,
                      label: l10n.adminNavUpgrades,
                      trailing: pendingUpgrades.isNotEmpty
                          ? _Badge(count: pendingUpgrades.length)
                          : null,
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

/// KPI card simplificado para o painel admin — sem variantes de cor
/// complexas, só valor + label + ícone.
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
    final color = iconColor ?? theme.colorScheme.primary;

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
              color: color.withValues(alpha: 0.1),
              borderRadius: AppRadius.smAll,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (loading)
            Container(
              width: 32,
              height: 20,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: AppRadius.xsAll,
              ),
            )
          else
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value ?? '—',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Linha de ação rápida — ícone + label + badge opcional.
class _QuickActionRow extends StatelessWidget {
  const _QuickActionRow({
    required this.icon,
    required this.label,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      borderRadius: const BorderRadius.all(Radius.circular(14)),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: scheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          ?trailing,
          const SizedBox(width: AppSpacing.xs),
          Icon(Icons.chevron_right, size: 18, color: scheme.outline),
        ],
      ),
    );
  }
}

/// Badge numérico para contagens pendentes.
class _Badge extends StatelessWidget {
  const _Badge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.tertiary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: scheme.tertiary,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
