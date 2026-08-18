import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../domain/entities/tenant.dart';
import '../../controllers/account_providers.dart';
import '../../controllers/auth_providers.dart';
import '../../controllers/purchases_providers.dart';
import '../../controllers/reports_providers.dart';
import '../../widgets/module_card.dart';
import '../../widgets/section_header.dart';
import '../purchases/purchases_screen.dart';
import '../reports/reports_screen.dart';
import '../shell/app_shell.dart';
import '../stores/stores_screen.dart';

/// Aba Menu V4 — hub dos módulos secundários e acções de conta.
class MenuScreen extends ConsumerWidget {
 const MenuScreen({super.key});

 @override
 Widget build(BuildContext context, WidgetRef ref) {
 final theme = Theme.of(context);
 final l10n = context.l10n;
 final accessLevel = ref.watch(currentAccessLevelProvider);
 final user = ref.watch(authStateProvider).value;
 final tenant = user == null
 ? null
 : ref.watch(myTenantProvider(user.id)).value;

 void goTo(AppSection section) =>
 ref.read(shellIndexProvider.notifier).goTo(section);

 void openPurchases() {
 ref.invalidate(purchasesProvider);
 Navigator.of(
 context,
 ).push(MaterialPageRoute<void>(builder: (_) => const PurchasesScreen()));
 }

 void openReports() {
 ref.invalidate(salesReportProvider);
 Navigator.of(
 context,
 ).push(MaterialPageRoute<void>(builder: (_) => const ReportsScreen()));
 }

 void openStores(Tenant tenant) {
 ref.invalidate(storesProvider(tenant.id));
 Navigator.of(context).push(
 MaterialPageRoute<void>(builder: (_) => StoresScreen(tenant: tenant)),
 );
 }

 final horizontal = AppSpacing.pagePaddingForWidth(
 MediaQuery.sizeOf(context).width,
 );

 return Scaffold(
 // AppBar estilo iOS large title — mesmo padrão de Vendas/Financeiro.
 appBar: AppBar(
 toolbarHeight: 64,
 titleSpacing: AppSpacing.lg,
 title: Text(
 l10n.appNavMenu,
 style: theme.textTheme.headlineSmall?.copyWith(
 fontWeight: FontWeight.w500,
 letterSpacing: -0.5,
 ),
 ),
 ),
 body: ListView(
 padding: EdgeInsets.fromLTRB(
 horizontal,
 AppSpacing.sm,
 horizontal,
 AppSpacing.xxl,
 ),
 children: [
 SectionHeader(
 title: l10n.dashboardModules,
 subtitle: l10n.fabMenuSubtitle,
 ),
 const SizedBox(height: AppSpacing.md),
 Wrap(
 spacing: AppSpacing.xs,
 runSpacing: AppSpacing.xs,
 children: [
 ModuleCard(
 icon: Icons.inventory_2_outlined,
 label: l10n.appNavProducts,
 onTap: () => goTo(AppSection.products),
 ),
 ModuleCard(
 icon: Icons.receipt_long_outlined,
 label: l10n.appNavCredit,
 onTap: () => goTo(AppSection.credit),
 ),
 ModuleCard(
 icon: Icons.people_outline_rounded,
 label: l10n.appNavCustomers,
 onTap: () => goTo(AppSection.customers),
 ),
 if (accessLevel != UserAccessLevel.employee)
 ModuleCard(
 icon: Icons.local_shipping_outlined,
 label: l10n.dashboardModulePurchases,
 onTap: openPurchases,
 ),
 if (accessLevel != UserAccessLevel.employee)
 ModuleCard(
 icon: Icons.bar_chart_outlined,
 label: l10n.dashboardModuleReports,
 onTap: openReports,
 ),
 if (tenant != null &&
 tenant.status == TenantStatus.approved &&
 accessLevel == UserAccessLevel.owner)
 ModuleCard(
 icon: Icons.storefront_outlined,
 label: l10n.dashboardModuleStores,
 onTap: () => openStores(tenant),
 ),
 ],
 ),
 const SizedBox(height: AppSpacing.xl),
 // Sair da conta — linha única MINIMALISTA (sem cabeçalho nem card
 // duplicados): ícone circular tintado de erro + rótulo vermelho,
 // mesmo padrão das linhas do feed.
 InkWell(
 onTap: () => ref.read(signOutUseCaseProvider).call(),
 borderRadius: BorderRadius.circular(AppRadius.lg),
 child: Padding(
 padding: const EdgeInsets.symmetric(
 horizontal: AppSpacing.md,
 vertical: AppSpacing.sm + 2,
 ),
 child: Row(
 children: [
 Container(
 width: AppSizes.avatarSm,
 height: AppSizes.avatarSm,
 alignment: Alignment.center,
 decoration: BoxDecoration(
 shape: BoxShape.circle,
 color: theme.colorScheme.error.withValues(alpha: 0.12),
 ),
 child: Icon(
 Icons.logout_rounded,
 size: 18,
 color: theme.colorScheme.error,
 ),
 ),
 const SizedBox(width: AppSpacing.sm),
 Text(
 l10n.commonSignOut,
 style: theme.textTheme.bodyMedium?.copyWith(
 color: theme.colorScheme.error,
 fontWeight: FontWeight.w500,
 ),
 ),
 ],
 ),
 ),
 ),
 ],
 ),
 );
 }
}
