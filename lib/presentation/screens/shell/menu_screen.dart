import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_page.dart';
import '../../widgets/confirm_dialog.dart';
import '../../../domain/entities/tenant.dart';
import '../../controllers/account_providers.dart';
import '../../controllers/auth_providers.dart';
import '../../controllers/notification_providers.dart';
import '../../controllers/production_providers.dart';
import '../../controllers/purchases_providers.dart';
import '../../controllers/reports_providers.dart';
import '../../widgets/pulse_badge.dart';
import '../dashboard/notifications_screen.dart';
import '../production/production_screen.dart';
import '../purchases/purchases_screen.dart';
import '../reports/reports_screen.dart';
import '../shell/app_shell.dart';
import '../stores/stores_screen.dart';
import '../account/security_settings_screen.dart';
import '../addons/addon_marketplace_screen.dart';

/// Aba Menu — hub dos módulos secundários e acções de conta.
///
/// Clonagem da referência de produto: título grande + subtítulo, grelha de
/// 2 colunas com tiles HORIZONTAIS (ícone circular tintado à esquerda,
/// rótulo e chevron à direita — mesmo idioma IconTone do feed da Home) e
/// "Terminar sessão" destacado em card vermelho destrutivo, com confirmação.
class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
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

    void openProduction() {
      ref.invalidate(recipesProvider);
      ref.invalidate(productionOrdersProvider);
      Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const ProductionScreen()));
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

    final width = MediaQuery.sizeOf(context).width;
    final horizontal = AppSpacing.pagePaddingForWidth(width);
    // Largura do tile: metade do conteúdo menos o vão entre as colunas —
    // os dois tiles da linha ficam sempre espelhados (referência).
    final tileWidth = (width - 2 * horizontal - AppSpacing.xs) / 2;

    return AppPage(
      useSafeArea: false,
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          horizontal,
          AppSpacing.md,
          horizontal,
          AppSpacing.xxl,
        ),
        children: [
          // Cabeçalho grande da referência — "Menu" como heading do corpo
          // (o AppBar do shell mantém a marca TAREQO + sino).
          Text(
            l10n.appNavMenu,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            l10n.menuSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Grelha 2 colunas — tiles horizontais, módulos por frequência.
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              SizedBox(
                width: tileWidth,
                child: _MenuTile(
                  icon: Icons.inventory_2_outlined,
                  label: l10n.appNavProducts,
                  iconColor: ModuleColors.products,
                  onTap: () => goTo(AppSection.products),
                ),
              ),
              SizedBox(
                width: tileWidth,
                child: _MenuTile(
                  icon: Icons.people_outline_rounded,
                  label: l10n.appNavCustomers,
                  iconColor: ModuleColors.customers,
                  onTap: () => goTo(AppSection.customers),
                ),
              ),
              SizedBox(
                width: tileWidth,
                child: _MenuTile(
                  icon: Icons.receipt_long_outlined,
                  label: l10n.appNavCredit,
                  iconColor: ModuleColors.credit,
                  onTap: () => goTo(AppSection.credit),
                ),
              ),
              if (accessLevel != UserAccessLevel.employee)
                SizedBox(
                  width: tileWidth,
                  child: _MenuTile(
                    icon: Icons.local_shipping_outlined,
                    label: l10n.dashboardModulePurchases,
                    iconColor: ModuleColors.purchases,
                    onTap: openPurchases,
                  ),
                ),
              if (accessLevel != UserAccessLevel.employee)
                SizedBox(
                  width: tileWidth,
                  child: _MenuTile(
                    icon: Icons.bakery_dining_outlined,
                    label: l10n.productionTitle,
                    iconColor: ModuleColors.production,
                    onTap: openProduction,
                  ),
                ),
              if (accessLevel != UserAccessLevel.employee)
                SizedBox(
                  width: tileWidth,
                  child: _MenuTile(
                    icon: Icons.bar_chart_outlined,
                    label: l10n.dashboardModuleReports,
                    iconColor: ModuleColors.reports,
                    onTap: openReports,
                  ),
                ),
              if (tenant != null &&
                  tenant.status == TenantStatus.approved &&
                  accessLevel == UserAccessLevel.owner)
                SizedBox(
                  width: tileWidth,
                  child: _MenuTile(
                    icon: Icons.storefront_outlined,
                    label: l10n.dashboardModuleStores,
                    iconColor: ModuleColors.stores,
                    onTap: () => openStores(tenant),
                  ),
                ),
              if (tenant != null &&
                  tenant.status == TenantStatus.approved &&
                  accessLevel == UserAccessLevel.owner)
                SizedBox(
                  width: tileWidth,
                  child: _NotificationsModuleTile(onTap: openNotifications),
                ),
              if (tenant != null &&
                  tenant.status == TenantStatus.approved &&
                  accessLevel == UserAccessLevel.owner)
                SizedBox(
                  width: tileWidth,
                  child: _MenuTile(
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
                ),
              SizedBox(
                width: tileWidth,
                child: _MenuTile(
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
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Terminar sessão — card vermelho destrutivo em largura total
          // (referência), com confirmação antes de deslogar.
          AppCard(
            onTap: confirmSignOut,
            color: IconTone.darkBackground(scheme.error),
            borderColor: scheme.error.withValues(alpha: 0.45),
            borderRadius: const BorderRadius.all(Radius.circular(AppRadius.lg)),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: IconTone.darkBackground(scheme.error),
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    size: 20,
                    color: IconTone.lightForeground(scheme.error),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.commonSignOut,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xxs),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tile de módulo HORIZONTAL da referência — card elevado (cantos 16) com
/// ícone circular tintado à esquerda, rótulo e chevron à direita.
///
/// Substitui o card vertical antigo ([ModuleCard]): no Menu a hierarquia é
/// de LISTA de destino (navegar), não de grade de abertura — o chevron
/// comunica "ir", os módulos continuam com a cor própria (IconTone).
class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Cor do ícone — se nulo, usa [ThemeData.accent].
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = iconColor ?? theme.accent;

    return AppCard(
      onTap: onTap,
      elevated: true,
      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.lg)),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: IconTone.darkBackground(color),
            ),
            child: Icon(icon, size: 20, color: IconTone.lightForeground(color)),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.1,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xxs),
          Icon(Icons.chevron_right, size: 18, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}

/// Tile de notificações com badge de não lidas.
class _NotificationsModuleTile extends ConsumerWidget {
  const _NotificationsModuleTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final unreadCount = ref.watch(unreadNotificationsCountProvider).value ?? 0;

    return PulseBadge(
      count: unreadCount,
      child: _MenuTile(
        icon: Icons.notifications_outlined,
        label: l10n.menuNotifications,
        iconColor: AppColors.statusWarning,
        onTap: onTap,
      ),
    );
  }
}
