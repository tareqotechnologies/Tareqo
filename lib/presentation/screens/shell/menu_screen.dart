import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../widgets/app_page.dart';
import '../../widgets/confirm_dialog.dart';
import '../../../domain/entities/tenant.dart';
import '../../controllers/account_providers.dart';
import '../../controllers/auth_providers.dart';
import '../../controllers/notification_providers.dart';
import '../../controllers/purchases_providers.dart';
import '../../controllers/reports_providers.dart';
import '../../widgets/module_card.dart';
import '../../widgets/pulse_badge.dart';
import '../dashboard/notifications_screen.dart';
import '../purchases/purchases_screen.dart';
import '../reports/reports_screen.dart';
import '../shell/app_shell.dart';
import '../stores/stores_screen.dart';
import '../account/security_settings_screen.dart';
import '../addons/addon_marketplace_screen.dart';

/// Aba Menu V5 — hub dos módulos secundários e acções de conta.
///
/// Apple-clean: subtítulo simples, sem SectionHeader, grelha 2 colunas
/// compacta e confirmação antes de terminar sessão.
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

    void openNotifications() {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
      );
    }

    Future<void> confirmSignOut() async {
      final confirmed = await showConfirmDialog(
        context,
        title: l10n.commonSignOutConfirmTitle,
        message: l10n.commonSignOutConfirmMessage,
        confirmLabel: l10n.commonSignOut,
        destructive: true,
      );
      if (confirmed == true) {
        // B4: apenas `ref` é usado após o await (nada de context) — o
        // ignore era desnecessário.
        ref.read(signOutUseCaseProvider).call();
      }
    }

    final horizontal = AppSpacing.pagePaddingForWidth(
      MediaQuery.sizeOf(context).width,
    );

    return AppPage(
      title: l10n.appNavMenu,
      useSafeArea: false,
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          horizontal,
          AppSpacing.sm,
          horizontal,
          AppSpacing.xxl,
        ),
        children: [
          // Subtítulo simples — hierarquia limpa (sem SectionHeader).
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(
              l10n.menuSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          // Grelha 2 colunas — módulos reordenados por frequência.
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              ModuleCard(
                icon: Icons.inventory_2_outlined,
                label: l10n.appNavProducts,
                iconColor: ModuleColors.products,
                onTap: () => goTo(AppSection.products),
              ),
              ModuleCard(
                icon: Icons.people_outline_rounded,
                label: l10n.appNavCustomers,
                iconColor: ModuleColors.customers,
                onTap: () => goTo(AppSection.customers),
              ),
              ModuleCard(
                icon: Icons.receipt_long_outlined,
                label: l10n.appNavCredit,
                iconColor: ModuleColors.credit,
                onTap: () => goTo(AppSection.credit),
              ),
              if (accessLevel != UserAccessLevel.employee)
                ModuleCard(
                  icon: Icons.local_shipping_outlined,
                  label: l10n.dashboardModulePurchases,
                  iconColor: ModuleColors.purchases,
                  onTap: openPurchases,
                ),
              if (accessLevel != UserAccessLevel.employee)
                ModuleCard(
                  icon: Icons.bar_chart_outlined,
                  label: l10n.dashboardModuleReports,
                  iconColor: ModuleColors.reports,
                  onTap: openReports,
                ),
              if (tenant != null &&
                  tenant.status == TenantStatus.approved &&
                  accessLevel == UserAccessLevel.owner)
                ModuleCard(
                  icon: Icons.storefront_outlined,
                  label: l10n.dashboardModuleStores,
                  iconColor: ModuleColors.stores,
                  onTap: () => openStores(tenant),
                ),
              if (tenant != null &&
                  tenant.status == TenantStatus.approved &&
                  accessLevel == UserAccessLevel.owner)
                _NotificationsModuleCard(onTap: openNotifications),
              if (tenant != null &&
                  tenant.status == TenantStatus.approved &&
                  accessLevel == UserAccessLevel.owner)
                ModuleCard(
                  icon: Icons.extension_outlined,
                  label: l10n.addonsTitle,
                  iconColor: AppColors.statusPurple,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const AddOnMarketplaceScreen(),
                      ),
                    );
                  },
                ),
              ModuleCard(
                icon: Icons.shield_outlined,
                label: l10n.securitySectionTitle,
                iconColor: AppColors.statusIndigo,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SecuritySettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Terminar sessão — com confirmação (previne saídas acidentais).
          InkWell(
            onTap: confirmSignOut,
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
                      color: IconTone.darkBackground(theme.colorScheme.error),
                    ),
                    child: Icon(
                      Icons.logout_rounded,
                      size: 18,
                      color: IconTone.lightForeground(theme.colorScheme.error),
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

/// Módulo de notificações com badge de não lidas.
class _NotificationsModuleCard extends ConsumerWidget {
  const _NotificationsModuleCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final unreadCount = ref.watch(unreadNotificationsCountProvider).value ?? 0;

    return PulseBadge(
      count: unreadCount,
      child: ModuleCard(
        icon: Icons.notifications_outlined,
        label: l10n.menuNotifications,
        iconColor: AppColors.statusWarning,
        onTap: onTap,
      ),
    );
  }
}
