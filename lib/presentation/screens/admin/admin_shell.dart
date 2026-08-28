import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../controllers/admin_providers.dart';
import '../../widgets/fade_indexed_stack.dart';
import '../../widgets/sign_out_button.dart';
import 'admin_audit_log_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_plan_requests_screen.dart';
import 'admin_plans_screen.dart';
import 'admin_tenants_screen.dart';

/// Casca de navegação do **super admin** — acessada quando o usuário
/// logado tem o papel de super admin no banco (`public.super_admins` no
/// Supabase, via RPC `is_super_admin`). Possui cinco seções:
/// visão geral (dashboard), solicitações de tenant, planos,
/// upgrades de plano e registo de auditoria.
class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key});

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  int _index = 0;

  static const _sections = [
    AdminDashboardScreen(),
    AdminTenantsScreen(),
    AdminPlansScreen(),
    AdminPlanRequestsScreen(),
    AdminAuditLogScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 880;
    final l10n = context.l10n;

    // Contadores de badge para itens pendentes.
    final pendingTenants =
        ref.watch(pendingTenantsProvider).value?.length ?? 0;
    final pendingUpgrades =
        ref.watch(pendingPlanRequestsProvider).value?.length ?? 0;

    final destinations = [
      (
        Icons.dashboard_outlined,
        Icons.dashboard,
        l10n.adminNavDashboard,
      ),
      (
        Icons.verified_user_outlined,
        Icons.verified_user,
        l10n.adminNavRequests,
      ),
      (Icons.workspaces_outline, Icons.workspaces, l10n.adminNavPlans),
      (Icons.upgrade_outlined, Icons.upgrade, l10n.adminNavUpgrades),
      (
        Icons.history_outlined,
        Icons.history,
        l10n.adminNavAuditLog,
      ),
    ];

    // Badges: tenant pendente no tab "Solicitações", upgrade pendente no
    // tab "Upgrades".
    final badges = [0, pendingTenants, 0, pendingUpgrades, 0];

    final body = FadeIndexedStack(index: _index, children: _sections);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adminTitle),
        actions: const [SignOutButton(), SizedBox(width: 8)],
      ),
      body: wide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _index,
                  onDestinationSelected: (value) =>
                      setState(() => _index = value),
                  labelType: NavigationRailLabelType.all,
                  leading: const SizedBox(height: 8),
                  destinations: [
                    for (var i = 0; i < destinations.length; i++)
                      NavigationRailDestination(
                        icon: _NavIcon(
                          icon: destinations[i].$1,
                          selectedIcon: destinations[i].$2,
                          badgeCount: badges[i],
                          isSelected: _index == i,
                        ),
                        label: Text(destinations[i].$3),
                      ),
                  ],
                ),
                Expanded(child: body),
              ],
            )
          : body,
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (value) =>
                  setState(() => _index = value),
              destinations: [
                for (var i = 0; i < destinations.length; i++)
                  NavigationDestination(
                    icon: _NavIcon(
                      icon: destinations[i].$1,
                      selectedIcon: destinations[i].$2,
                      badgeCount: badges[i],
                      isSelected: _index == i,
                    ),
                    label: destinations[i].$3,
                  ),
              ],
            ),
    );
  }
}

/// Ícone de navegação com badge numérico opcional (estilo iOS).
class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.icon,
    required this.selectedIcon,
    this.badgeCount = 0,
    this.isSelected = false,
  });

  final IconData icon;
  final IconData selectedIcon;
  final int badgeCount;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final activeIcon = Icon(isSelected ? selectedIcon : icon);

    if (badgeCount == 0) return activeIcon;

    return Badge(
      label: Text(
        '$badgeCount',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.tertiary,
      child: activeIcon,
    );
  }
}
