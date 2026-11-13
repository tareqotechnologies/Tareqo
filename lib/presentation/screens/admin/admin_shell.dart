import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../controllers/admin_providers.dart';
import '../../controllers/invoice_providers.dart';
import '../../widgets/admin_thin_bridge.dart';
import '../../widgets/fade_indexed_stack.dart';
import '../../widgets/premium_decor.dart';
import '../../widgets/sign_out_button.dart';
import 'admin_addons_screen.dart';
import 'admin_addon_revenue_screen.dart';
import 'admin_audit_log_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_invoices_screen.dart';
import 'admin_messages_screen.dart';
import 'admin_plan_requests_screen.dart';
import 'admin_plans_screen.dart';
import 'admin_tenants_screen.dart';
import 'admin_thin_theme.dart';

/// Casca de navegação do **super admin** — estilo minimalista com FAB.
///
/// Em vez de 7 tabs na barra inferior (que estouram o layout), usa um
/// único FAB que abre um bottom sheet com todas as secções.
class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key});

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  int _index = 0;

  late final List<Widget> _sections = [
    AdminDashboardScreen(onNavigateToTab: (i) => setState(() => _index = i)),
    const AdminTenantsScreen(),
    const AdminPlansScreen(),
    const AdminPlanRequestsScreen(),
    const AdminInvoicesScreen(),
    const AdminAddOnsScreen(),
    const AdminAddOnRevenueScreen(),
    const AdminMessagesScreen(),
    const AdminAuditLogScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 880;
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    final pendingTenants = ref.watch(pendingTenantsProvider).value?.length ?? 0;
    final pendingUpgrades =
        ref.watch(pendingPlanRequestsProvider).value?.length ?? 0;
    final pendingInvoices =
        ref.watch(pendingInvoicesProvider).value?.length ?? 0;

    final items = _buildItems(
      l10n,
      pendingTenants: pendingTenants,
      pendingUpgrades: pendingUpgrades,
      pendingInvoices: pendingInvoices,
    );

    final totalBadge = items
        .where((i) => i.badge > 0)
        .fold<int>(0, (s, i) => s + i.badge);

    // Tipografia THIN em todo o painel — títulos leves (w300), rótulos
    // w400; inputs/dropdowns/chips herdam via Theme local.
    final body = AdminThin(
      child: FadeIndexedStack(index: _index, children: _sections),
    );

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: AppSizes.touchTarget,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            Container(
              width: AppSizes.iconXl,
              height: AppSizes.iconXl,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: AppRadius.smAll,
              ),
              child: Icon(
                Icons.admin_panel_settings_outlined,
                size: AppSizes.iconSm,
                color: scheme.onPrimary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              l10n.adminTitle,
              // Identidade thin do painel: título em 400, hierarquia pela
              // cor e pelo espaço — a escala vem do papel (titleSmall).
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        titleSpacing: AppSpacing.md,
        actions: const [
          SignOutButton(),
          SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: wide
          ? Row(
              children: [
                _MinimalSidebar(
                  items: items,
                  selectedIndex: _index,
                  onSelect: (i) => setState(() => _index = i),
                ),
                Expanded(child: body),
              ],
            )
          : body,
      floatingActionButton: wide
          ? null
          : _AdminFab(
              currentLabel: items[_index].label,
              currentIcon: items[_index].icon,
              totalBadge: totalBadge,
              onTap: () => _openNavSheet(context, items),
            ),
    );
  }

  List<_NavItem> _buildItems(
    AppLocalizations l10n, {
    required int pendingTenants,
    required int pendingUpgrades,
    required int pendingInvoices,
  }) {
    return [
      _NavItem(
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard_rounded,
        label: l10n.adminNavDashboard,
      ),
      _NavItem(
        icon: Icons.how_to_reg_outlined,
        selectedIcon: Icons.how_to_reg_rounded,
        label: l10n.adminNavRequests,
        badge: pendingTenants,
      ),
      _NavItem(
        icon: Icons.workspace_premium_outlined,
        selectedIcon: Icons.workspace_premium_rounded,
        label: l10n.adminNavPlans,
      ),
      _NavItem(
        icon: Icons.upgrade_outlined,
        selectedIcon: Icons.upgrade_rounded,
        label: l10n.adminNavUpgrades,
        badge: pendingUpgrades,
      ),
      _NavItem(
        icon: Icons.receipt_long_outlined,
        selectedIcon: Icons.receipt_long_rounded,
        label: l10n.adminNavInvoices,
        badge: pendingInvoices,
      ),
      _NavItem(
        icon: Icons.extension_outlined,
        selectedIcon: Icons.extension_rounded,
        label: l10n.addonsTitle,
      ),
      _NavItem(
        icon: Icons.payments_outlined,
        selectedIcon: Icons.payments_rounded,
        label: l10n.adminNavRevenue,
      ),
      _NavItem(
        icon: Icons.mail_outline_rounded,
        selectedIcon: Icons.mail_rounded,
        label: l10n.adminNavMessages,
      ),
      _NavItem(
        icon: Icons.history_rounded,
        selectedIcon: Icons.history_rounded,
        label: l10n.adminNavAuditLog,
      ),
    ];
  }

  void _openNavSheet(BuildContext context, List<_NavItem> items) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => adminThinIfNeeded(
        sheetContext,
        thinStyle: true,
        child: _NavBottomSheet(
          items: items,
          selectedIndex: _index,
          onSelect: (i) {
            Navigator.of(context).pop();
            setState(() => _index = i);
          },
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// FAB
// ═══════════════════════════════════════════════════════════════════════════════

class _AdminFab extends StatelessWidget {
  const _AdminFab({
    required this.currentLabel,
    required this.currentIcon,
    required this.totalBadge,
    required this.onTap,
  });

  final String currentLabel;
  final IconData currentIcon;
  final int totalBadge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Semantics(
        button: true,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(currentIcon, size: AppSizes.iconMd, color: scheme.onPrimary),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  currentLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(
                Icons.keyboard_arrow_up_rounded,
                size: AppSizes.iconMd,
                color: scheme.onPrimary,
              ),
              if (totalBadge > 0) ...[
                const SizedBox(width: AppSpacing.xxs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.micro,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.error,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    '$totalBadge',
                    // Badge de ênfase: w500 explícito — a ponte thin do painel
                    // rebaixa labelMedium para w400, mas o badge sobre vermelho
                    // precisa de destaque (mesmo contrato do teste).
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onError,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// BOTTOM SHEET DE NAVEGAÇÃO
// ═══════════════════════════════════════════════════════════════════════════════

class _NavBottomSheet extends StatelessWidget {
  const _NavBottomSheet({
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<_NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      margin: EdgeInsets.only(top: topPadding + AppSpacing.xs),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppRadius.sheetTop,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(
                top: AppSpacing.sm,
                bottom: AppSpacing.md,
              ),
              width: AppSizes.avatarSm,
              height: AppSpacing.xxs,
              decoration: BoxDecoration(
                color: PremiumDecor.hairline(scheme),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Navegação',
                style: AppTypography.eyebrow(scheme.onSurfaceVariant),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // Items — scrollável para ecrãs pequenos
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
              child: Column(
                children: List.generate(items.length, (i) {
                  final item = items[i];
                  final selected = i == selectedIndex;
                  return _NavSheetItem(
                    item: item,
                    selected: selected,
                    onTap: () => onSelect(i),
                  );
                }),
              ),
            ),
          ),

          SizedBox(
            height: MediaQuery.of(context).padding.bottom + AppSpacing.md,
          ),
        ],
      ),
    );
  }
}

class _NavSheetItem extends StatelessWidget {
  const _NavSheetItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = selected ? scheme.primary : scheme.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: AppSizes.avatarMd,
                height: AppSizes.avatarMd,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? scheme.primary
                      : scheme.surfaceContainerHighest,
                  borderRadius: AppRadius.smAll,
                ),
                child: Icon(
                  selected ? item.selectedIcon : item.icon,
                  size: AppSizes.iconMd,
                  color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Label
              Expanded(
                child: Text(
                  item.label,
                  style: AppTypography.labelLarge.copyWith(
                    fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                    color: color,
                  ),
                ),
              ),

              // Badge
              if (item.badge > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.micro,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.error,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    '${item.badge}',
                    // Mesmo badge de ênfase do FAB: labelMedium (12) + w500
                    // explícito contra o rebaixamento do tema thin.
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onError,
                      fontWeight: FontWeight.w500,
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

// ═══════════════════════════════════════════════════════════════════════════════
// SIDEBAR MINIMALISTA (wide screens)
// ═══════════════════════════════════════════════════════════════════════════════

class _MinimalSidebar extends StatelessWidget {
  const _MinimalSidebar({
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<_NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: AppSpacing.gigantic,
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(right: BorderSide(color: PremiumDecor.hairline(scheme))),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.xxs,
              ),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final item = items[i];
                final selected = i == selectedIndex;
                return _SidebarIcon(
                  item: item,
                  selected: selected,
                  onTap: () => onSelect(i),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarIcon extends StatelessWidget {
  const _SidebarIcon({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          width: AppSizes.touchTarget,
          height: AppSizes.touchTarget,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? scheme.primary : Colors.transparent,
            borderRadius: AppRadius.mdAll,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                selected ? item.selectedIcon : item.icon,
                size: AppSizes.navIcon,
                color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
              ),
              if (item.badge > 0)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: AppSizes.iconSm,
                    height: AppSizes.iconSm,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: scheme.error,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${item.badge}',
                      // Ícone da sidebar: badge compacto sobre vermelho —
                      // labelMedium (12) + w500 explícito, em tinta onError.
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onError,
                        fontWeight: FontWeight.w500,
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

// ═══════════════════════════════════════════════════════════════════════════════
// MODEL
// ═══════════════════════════════════════════════════════════════════════════════

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.badge = 0,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final int badge;
}
