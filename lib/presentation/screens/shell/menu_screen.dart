import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_colors.dart';
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
import '../../navigation/app_routes.dart';
import '../../widgets/pulse_badge.dart';
import '../shell/app_shell.dart';

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

    // U-09: rotas nomeadas via AppNavigator (tabela em app_routes.dart).
    // As transições vêm do PageTransitionsTheme global.
    void openPurchases() {
      ref.invalidate(purchasesProvider);
      AppNavigator.push(context, AppRoutes.purchases);
    }

    void openReports() {
      ref.invalidate(salesReportProvider);
      AppNavigator.push(context, AppRoutes.reports);
    }

    void openProduction() {
      ref.invalidate(recipesProvider);
      ref.invalidate(productionOrdersProvider);
      AppNavigator.push(context, AppRoutes.production);
    }

    void openStores(Tenant tenant) {
      ref.invalidate(storesProvider(tenant.id));
      AppNavigator.pushWith(context, AppRoutes.stores, {'tenant': tenant});
    }

    void openNotifications() {
      AppNavigator.push(context, AppRoutes.notifications);
    }

    Future<void> confirmSignOut() async {
      final confirmed = await showConfirmDialog(context: 
        context,
        title: l10n.commonSignOutConfirmTitle,
        message: l10n.commonSignOutConfirmMessage,
        confirmLabel: l10n.commonSignOut,
        destructive: true,
      );
      if (confirmed == true) {
        ref.read(signOutUseCaseProvider).call();
      }
    }

    final width = MediaQuery.sizeOf(context).width;
    final horizontal = AppSpacing.pagePaddingForWidth(width);
    // Largura do tile: metade do conteúdo menos o vão entre as colunas.
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
          // Cabeçalho premium — título elegante + subtítulo discreto.
          Text(
            l10n.appNavMenu,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.menuSubtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Grelha 2 colunas — tiles com ícone laranja padronizado.
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              SizedBox(
                width: tileWidth,
                child: _MenuTile(
                  icon: Icons.inventory_2_outlined,
                  label: l10n.appNavProducts,
                  onTap: () => goTo(AppSection.products),
                ),
              ),
              SizedBox(
                width: tileWidth,
                child: _MenuTile(
                  icon: Icons.people_outline_rounded,
                  label: l10n.appNavCustomers,
                  onTap: () => goTo(AppSection.customers),
                ),
              ),
              SizedBox(
                width: tileWidth,
                child: _MenuTile(
                  icon: Icons.receipt_long_outlined,
                  label: l10n.appNavCredit,
                  onTap: () => goTo(AppSection.credit),
                ),
              ),
              if (accessLevel != UserAccessLevel.employee)
                SizedBox(
                  width: tileWidth,
                  child: _MenuTile(
                    icon: Icons.local_shipping_outlined,
                    label: l10n.dashboardModulePurchases,
                    onTap: openPurchases,
                  ),
                ),
              if (accessLevel != UserAccessLevel.employee)
                SizedBox(
                  width: tileWidth,
                  child: _MenuTile(
                    icon: Icons.bakery_dining_outlined,
                    label: l10n.productionTitle,
                    onTap: openProduction,
                  ),
                ),
              if (accessLevel != UserAccessLevel.employee)
                SizedBox(
                  width: tileWidth,
                  child: _MenuTile(
                    icon: Icons.bar_chart_outlined,
                    label: l10n.dashboardModuleReports,
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
                    onTap: () => AppNavigator.push(context, AppRoutes.addons),
                  ),
                ),
              SizedBox(
                width: tileWidth,
                child: _MenuTile(
                  icon: Icons.shield_outlined,
                  label: l10n.securitySectionTitle,
                  onTap: () => AppNavigator.push(context, AppRoutes.security),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Terminar sessão — botão Apple style: ícone laranja, texto elegante.
          _SignOutButton(onTap: confirmSignOut, label: l10n.commonSignOut),
        ],
      ),
    );
  }
}

/// Tile de módulo — ícone circular laranja oficial, texto pequeno.
class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AppCard(
      onTap: onTap,
      elevated: true,
      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.md)),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          // Ícone circular oficial (U-24): fundo laranja #FF6A2A padrão
          // de ícones em toda a app (nunca HSL derivado, nunca cor fora
          // da paleta). O tile inteiro é o alvo (≥48).
          Container(
            width: AppSizes.avatarSm,
            height: AppSizes.avatarSm,
            decoration: const BoxDecoration(
              color: AppColors.brandOrange,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: AppSizes.iconMd,
              color: AppColors.softWhite,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Botão "Sair" no estilo Apple — minimalista, ícone laranja, texto discreto.
class _SignOutButton extends StatelessWidget {
  const _SignOutButton({required this.onTap, required this.label});

  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        constraints: const BoxConstraints(
          minHeight: AppSizes.touchTarget,
        ),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            // Ícone circular oficial (U-24): fundo laranja #FF6A2A —
            // padrão de ícones em toda a app.
            Container(
              width: AppSizes.avatarSm,
              height: AppSizes.avatarSm,
              decoration: const BoxDecoration(
                color: AppColors.brandOrange,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.logout_rounded,
                size: AppSizes.iconSm,
                color: AppColors.softWhite,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
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
        onTap: onTap,
      ),
    );
  }
}
