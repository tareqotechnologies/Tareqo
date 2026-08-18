import 'package:flutter/material.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../widgets/fade_indexed_stack.dart';
import '../../widgets/sign_out_button.dart';
import 'admin_plan_requests_screen.dart';
import 'admin_plans_screen.dart';
import 'admin_tenants_screen.dart';

/// Casca de navegação do **super admin** — acessada quando o usuário
/// logado tem o papel de super admin no banco (`public.super_admins` no
/// Supabase, via RPC `is_super_admin`). Possui três seções: solicitações
/// de tenant (aprovar/rejeitar), planos (CRUD) e upgrades de plano
/// (aprovar/rejeitar).
class AdminShell extends StatefulWidget {
 const AdminShell({super.key});

 @override
 State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
 int _index = 0;

 static const _sections = [
 AdminTenantsScreen(),
 AdminPlansScreen(),
 AdminPlanRequestsScreen(),
 ];

 @override
 Widget build(BuildContext context) {
 final wide = MediaQuery.sizeOf(context).width >= 880;
 final l10n = context.l10n;

 final destinations = [
 (
 Icons.verified_user_outlined,
 Icons.verified_user,
 l10n.adminNavRequests,
 ),
 (Icons.workspaces_outline, Icons.workspaces, l10n.adminNavPlans),
 (Icons.upgrade_outlined, Icons.upgrade, l10n.adminNavUpgrades),
 ];

 // Fase 3 — navegação híbrida: fade suave ao trocar de seção, com o
 // estado preservado (IndexedStack interno do FadeIndexedStack).
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
 destinations: [
 for (final (icon, selected, label) in destinations)
 NavigationRailDestination(
 icon: Icon(icon),
 selectedIcon: Icon(selected),
 label: Text(label),
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
 onDestinationSelected: (value) => setState(() => _index = value),
 destinations: [
 for (final (icon, selected, label) in destinations)
 NavigationDestination(
 icon: Icon(icon),
 selectedIcon: Icon(selected),
 label: label,
 ),
 ],
 ),
 );
 }
}
