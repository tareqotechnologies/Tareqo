import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/addon_localization.dart';
import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/observability/crash_reporting.dart';
import '../../widgets/app_page.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/addon.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../controllers/account_providers.dart';
import '../../controllers/addon_providers.dart';
import '../../controllers/auth_providers.dart';
import 'custom_invoice_screen.dart';
import 'quotation_screen.dart';
import 'employee_management_screen.dart';
import 'store_transfers_screen.dart';
import 'advanced_reports_screen.dart';
import 'payment_reconciliation_screen.dart';

/// Ecra do marketplace de add-ons — apenas visualização.
///
/// A activação/desactivação de add-ons é exclusiva do super admin
/// (AdminAddOnsScreen). O tenant apenas visualiza os add-ons que
/// o super admin activou para o seu tenant e os incluídos no plano.
class AddOnMarketplaceScreen extends ConsumerWidget {
  const AddOnMarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final addOns = ref.watch(addOnCatalogProvider);
    final activeIds = ref.watch(activeAddOnIdsProvider).value ?? {};

    // Add-ons incluídos no plano do tenant.
    final user = ref.watch(authStateProvider).value;
    final tenant = user == null
        ? null
        : ref.watch(myTenantProvider(user.id)).value;
    final bundledAddOns = tenant != null
        ? _getBundledAddOns(ref, tenant.planId)
        : <String>{};

    final horizontal = AppSpacing.pagePaddingForWidth(
      MediaQuery.sizeOf(context).width,
    );

    return AppPage(
      title: l10n.addonsTitle,
      titleStyle: theme.textTheme.titleMedium,
      useSafeArea: false,
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          horizontal,
          AppSpacing.sm,
          horizontal,
          AppSpacing.xxl,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(
              l10n.addonsSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          // Aviso: apenas visualização
          Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.4),
              borderRadius: AppRadius.smAll,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: theme.colorScheme.tertiary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    l10n.addonsManagedByAdmin,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // `isAvailable: false` = BLOCKED por dependência externa (ex.:
          // API de mobile money inexistente) — nunca se oferece/vende um
          // add-on cuja funcionalidade real não existe.
          for (final addon in addOns)
            if (addon.isAvailable &&
                (activeIds.contains(addon.id) ||
                    bundledAddOns.contains(addon.id))) ...[
              _AddOnCard(
                addon: addon,
                isActive: activeIds.contains(addon.id),
                isIncluded: bundledAddOns.contains(addon.id),
                onOpen: () => _openAddOn(context, addon.id),
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
        ],
      ),
    );
  }

  void _openAddOn(BuildContext context, String addOnId) {
    switch (addOnId) {
      case 'ao_custom_invoice':
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const CustomInvoiceScreen()),
        );
      case 'ao_quotation':
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const QuotationScreen()),
        );
      case 'ao_advanced_reports':
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const AdvancedReportsScreen(),
          ),
        );
      case 'ao_employee_mgmt':
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const EmployeeManagementScreen(),
          ),
        );
      case 'ao_multi_store':
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const StoreTransfersScreen()),
        );
      case 'ao_mobile_money':
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const PaymentReconciliationScreen(),
          ),
        );
      default:
        // Add-on do catálogo sem tela ligada (drift futuro de ids): nunca
        // deixa o toque falhar em silêncio — regista para o backoffice.
        CrashReporting.capture(
          StateError('Add-on sem rota de navegação: $addOnId'),
          StackTrace.current,
          hint: 'Marketplace: add-on sem tela mapeada',
        );
    }
  }

  Set<String> _getBundledAddOns(WidgetRef ref, String planId) {
    final plans = ref.read(plansProvider).value ?? [];
    final plan = plans.where((p) => p.id == planId).toList();
    if (plan.isEmpty) return {};
    return Set<String>.from(plan.first.bundledAddOns);
  }
}

class _AddOnCard extends StatelessWidget {
  const _AddOnCard({
    required this.addon,
    required this.isActive,
    this.isIncluded = false,
    required this.onOpen,
  });

  final AddOn addon;
  final bool isActive;
  final bool isIncluded;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final iconData = _iconForName(addon.iconName);

    return Material(
      color: isActive
          ? scheme.primaryContainer.withValues(alpha: 0.3)
          : scheme.surfaceContainerLow,
      borderRadius: AppRadius.lgAll,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        borderRadius: AppRadius.lgAll,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isActive
                      ? scheme.primary.withValues(alpha: 0.12)
                      : scheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  iconData,
                  size: 20,
                  color: isActive ? scheme.primary : scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      addonDisplayName(context.l10n, addon),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Descrição COMPLETA — nunca truncar: o nome e a
                    // descrição são o que explica o add-on ao dono da loja.
                    Text(
                      addonDescription(context.l10n, addon),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Badges + preço — Wrap: nunca corta o rótulo em ecrãs
                    // estreitos (fluem para a linha seguinte).
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (isIncluded)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              context.l10n.addonsIncluded,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        if (!isIncluded && isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              context.l10n.addonsActive,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        Text(
                          isIncluded
                              ? ''
                              : _formatPrice(
                                  addon.priceMonthlyCents,
                                  context.l10n,
                                ),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPrice(int cents, AppLocalizations l10n) {
    final value = cents / 100;
    return l10n.addonsPerMonth(value.toStringAsFixed(0));
  }

  IconData _iconForName(String name) {
    switch (name) {
      case 'receipt_long':
        return Icons.receipt_long_outlined;
      case 'request_quote':
        return Icons.request_quote_outlined;
      case 'analytics':
        return Icons.analytics_outlined;
      case 'groups':
        return Icons.groups_outlined;
      case 'storefront':
        return Icons.storefront_outlined;
      case 'phone_android':
        return Icons.phone_android_outlined;
      default:
        return Icons.extension_outlined;
    }
  }
}
