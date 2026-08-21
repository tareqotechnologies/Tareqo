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
import '../purchases/purchases_screen.dart';
import '../reports/reports_screen.dart';
import '../shell/app_shell.dart';
import '../stores/stores_screen.dart';

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
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const PurchasesScreen()),
      );
    }

    void openReports() {
      ref.invalidate(salesReportProvider);
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const ReportsScreen()),
      );
    }

    void openStores(Tenant tenant) {
      ref.invalidate(storesProvider(tenant.id));
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => StoresScreen(tenant: tenant),
        ),
      );
    }

    Future<void> confirmSignOut() async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.commonSignOutConfirmTitle),
          content: Text(l10n.commonSignOutConfirmMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
              child: Text(l10n.commonSignOut),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        // ignore: use_build_context_synchronously
        ref.read(signOutUseCaseProvider).call();
      }
    }

    final horizontal = AppSpacing.pagePaddingForWidth(
      MediaQuery.sizeOf(context).width,
    );

    return Scaffold(
      // AppBar estilo iOS large title — mesmo padrão das demais telas.
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
                iconColor: const Color(0xFF60A5FA),
                onTap: () => goTo(AppSection.products),
              ),
              ModuleCard(
                icon: Icons.people_outline_rounded,
                label: l10n.appNavCustomers,
                iconColor: const Color(0xFF34D399),
                onTap: () => goTo(AppSection.customers),
              ),
              ModuleCard(
                icon: Icons.receipt_long_outlined,
                label: l10n.appNavCredit,
                iconColor: const Color(0xFFFBBF24),
                onTap: () => goTo(AppSection.credit),
              ),
              if (accessLevel != UserAccessLevel.employee)
                ModuleCard(
                  icon: Icons.local_shipping_outlined,
                  label: l10n.dashboardModulePurchases,
                  iconColor: const Color(0xFFA78BFA),
                  onTap: openPurchases,
                ),
              if (accessLevel != UserAccessLevel.employee)
                ModuleCard(
                  icon: Icons.bar_chart_outlined,
                  label: l10n.dashboardModuleReports,
                  iconColor: const Color(0xFF2DD4BF),
                  onTap: openReports,
                ),
              if (tenant != null &&
                  tenant.status == TenantStatus.approved &&
                  accessLevel == UserAccessLevel.owner)
                ModuleCard(
                  icon: Icons.storefront_outlined,
                  label: l10n.dashboardModuleStores,
                  iconColor: const Color(0xFF818CF8),
                  onTap: () => openStores(tenant),
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
