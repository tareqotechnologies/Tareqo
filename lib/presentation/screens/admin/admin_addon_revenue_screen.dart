import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/addon_catalog.dart';
import '../../../domain/entities/addon.dart';
import '../../controllers/admin_providers.dart';
import '../../widgets/premium_decor.dart';

/// Dashboard de receitas de add-ons para o super admin.
///
/// Mostra receita potencial por add-on, tenants activos e distribuição.
class AdminAddOnRevenueScreen extends ConsumerWidget {
  const AdminAddOnRevenueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    final addOns = AddOnCatalog.addOns();
    final tenants = ref.watch(allTenantsProvider).value ?? const [];

    // Calcular receita potencial (se todos os tenants pagassem todos os add-ons).
    final totalPotentialRevenue = addOns.fold<int>(
      0,
      (sum, a) => sum + a.priceMonthlyCents,
    );

    // Receita se cada tenant pagasse apenas o add-on mais caro.

    return Scaffold(
      backgroundColor: scheme.surface,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ── KPI Cards ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _KpiCard(
                      label: l10n.adminRevenuePotential,
                      value: Formatters.currency(totalPotentialRevenue),
                      subtitle: l10n.adminRevenuePotentialSub,
                      icon: Icons.trending_up,
                      color: theme.income,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: _KpiCard(
                      label: l10n.adminRevenueAvailableAddOns,
                      value: '${addOns.length}',
                      subtitle: l10n.adminRevenueAvailableAddOnsSub,
                      icon: Icons.extension_outlined,
                      color: scheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xs)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: _KpiCard(
                      label: l10n.adminRevenueActiveTenants,
                      value: '${tenants.length}',
                      subtitle: l10n.adminRevenueActiveTenantsSub,
                      icon: Icons.business_outlined,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: _KpiCard(
                      label: l10n.adminRevenueMaxMonthly,
                      value: Formatters.currency(
                        totalPotentialRevenue * tenants.length,
                      ),
                      subtitle: l10n.adminRevenueMaxMonthlySub,
                      icon: Icons.account_balance_wallet_outlined,
                      color: scheme.tertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Receita por Add-on ──
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                l10n.adminRevenueByAddOn,
                style: AppTypography.sectionTitle,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            sliver: SliverList.separated(
              itemCount: addOns.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                indent: AppSpacing.xxxl,
                endIndent: 0,
                color: PremiumDecor.hairline(scheme),
              ),
              itemBuilder: (_, i) => _AddOnRevenueTile(
                addon: addOns[i],
                tenantCount: tenants.length,
              ),
            ),
          ),

          // ── Distribuição por Categoria ──
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                l10n.adminRevenueByCategory,
                style: AppTypography.sectionTitle,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            sliver: SliverList.builder(
              itemCount: AddOnCategory.values.length,
              itemBuilder: (_, i) {
                final category = AddOnCategory.values[i];
                final categoryAddOns = addOns
                    .where((a) => a.category == category)
                    .toList();
                final categoryRevenue = categoryAddOns.fold<int>(
                  0,
                  (sum, a) => sum + a.priceMonthlyCents,
                );
                return _CategoryTile(
                  category: category,
                  addOnCount: categoryAddOns.length,
                  revenue: categoryRevenue,
                );
              },
            ),
          ),

          // ── Bottom padding ──
          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.fabBottomClearance),
          ),
        ],
      ),
    );
  }
}

// ─── KPI Card ──────────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: color.withValues(alpha: 0.06),
      borderRadius: AppRadius.lgAll,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: AppSizes.iconSm, color: color),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    label,
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
            Text(
              value,
              style: AppTypography.titleMedium.copyWith(
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.micro),
            Text(
              subtitle,
              style: AppTypography.labelSmall.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Add-on Revenue Tile ──────────────────────────────────────────────────

class _AddOnRevenueTile extends StatelessWidget {
  const _AddOnRevenueTile({required this.addon, required this.tenantCount});

  final AddOn addon;
  final int tenantCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final maxRevenue = addon.priceMonthlyCents * tenantCount;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          // ── Accent bar ──
          Container(
            width: AppSpacing.xxs,
            height: AppSpacing.xxxl,
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: AppRadius.microAll,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // ── Content ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  addon.name,
                  style: AppTypography.labelLarge,
                ),
                const SizedBox(height: AppSpacing.micro),
                Text(
                  '${Formatters.currency(addon.priceMonthlyCents)}/tenant/mês',
                  style: AppTypography.bodySmall.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: AppSpacing.sm),

          // ── Max revenue ──
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Formatters.currency(maxRevenue),
                style: AppTypography.bodyMedium.copyWith(
                  color: theme.income,
                ),
              ),
              Text(
                context.l10n.adminRevenuePerMonth,
                style: AppTypography.labelSmall.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Category Tile ─────────────────────────────────────────────────────────

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.addOnCount,
    required this.revenue,
  });

  final AddOnCategory category;
  final int addOnCount;
  final int revenue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: AppSizes.avatarSm,
            height: AppSizes.avatarSm,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: AppRadius.smAll,
            ),
            child: Icon(
              _iconForCategory(category),
              size: AppSizes.iconMd,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.label,
                  style: AppTypography.labelLarge,
                ),
                Text(
                  context.l10n.adminAddOnsCount(addOnCount),
                  style: AppTypography.bodySmall.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            Formatters.currency(revenue),
            style: AppTypography.bodyMedium.copyWith(color: theme.income),
          ),
        ],
      ),
    );
  }

  IconData _iconForCategory(AddOnCategory category) {
    switch (category) {
      case AddOnCategory.invoice:
        return Icons.receipt_long_outlined;
      case AddOnCategory.quotation:
        return Icons.request_quote_outlined;
      case AddOnCategory.reports:
        return Icons.analytics_outlined;
      case AddOnCategory.employees:
        return Icons.groups_outlined;
      case AddOnCategory.multiStore:
        return Icons.storefront_outlined;
      case AddOnCategory.payments:
        return Icons.phone_android_outlined;
    }
  }
}
