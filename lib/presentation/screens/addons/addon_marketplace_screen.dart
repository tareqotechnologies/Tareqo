import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/addon_localization.dart';
import '../../../core/i18n/l10n_ext.dart';
import '../../../core/observability/crash_reporting.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/entities/addon.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../controllers/account_providers.dart';
import '../../controllers/addon_providers.dart';
import '../../controllers/auth_providers.dart';
import '../../navigation/app_routes.dart';
import '../../widgets/app_page.dart';

/// Ecra do marketplace de add-ons — apenas visualização.
///
/// A activação/desactivação de add-ons é exclusiva do super admin
/// (AdminAddOnsScreen). O tenant apenas visualiza os add-ons que
/// o super admin activou para o seu tenant e os incluídos no plano.
class AddOnMarketplaceScreen extends ConsumerWidget {
  const AddOnMarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
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
      titleStyle: AppTypography.titleMedium,
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
              style: AppTypography.bodyMedium.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          // Aviso: apenas visualização
          Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: AppRadius.smAll,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: AppSizes.iconSm,
                  color: scheme.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.addonsManagedByAdmin,
                    style: AppTypography.bodySmall.copyWith(
                      color: scheme.onPrimaryContainer,
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
    // U-09: rotas nomeadas por add-on (tabela em app_routes.dart).
    final route = switch (addOnId) {
      'ao_custom_invoice' => AppRoutes.addonCustomInvoice,
      'ao_quotation' => AppRoutes.addonQuotation,
      'ao_advanced_reports' => AppRoutes.addonAdvancedReports,
      'ao_employee_mgmt' => AppRoutes.addonEmployeeMgmt,
      'ao_multi_store' => AppRoutes.addonStoreTransfers,
      'ao_mobile_money' => AppRoutes.addonMobileMoney,
      _ => null,
    };
    if (route != null) {
      AppNavigator.push(context, route);
      return;
    }
    switch (addOnId) {
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
      color: isActive ? scheme.primaryContainer : scheme.surfaceContainerLow,
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
                width: AppSizes.avatarSm,
                height: AppSizes.avatarSm,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  // No cartão activo o fundo já é primaryContainer: a caixa
                  // usa a superfície para o ícone continuar legível.
                  color: isActive
                      ? scheme.surface
                      : scheme.surfaceContainerHighest,
                  borderRadius: AppRadius.smAll,
                ),
                child: Icon(
                  iconData,
                  size: AppSizes.iconMd,
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
                      style: AppTypography.labelLarge.copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.micro),
                    // Descrição COMPLETA — nunca truncar: o nome e a
                    // descrição são o que explica o add-on ao dono da loja.
                    Text(
                      addonDescription(context.l10n, addon),
                      style: AppTypography.bodySmall.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    // Badges + preço — Wrap: nunca corta o rótulo em ecrãs
                    // estreitos (fluem para a linha seguinte).
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xxs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (isIncluded)
                          _AddOnBadge(
                            label: context.l10n.addonsIncluded,
                            color: theme.income,
                            textColor: theme.income,
                          ),
                        if (!isIncluded && isActive)
                          _AddOnBadge(
                            label: context.l10n.addonsActive,
                            color: scheme.primary,
                            textColor: scheme.onPrimaryContainer,
                          ),
                        if (!isIncluded)
                          Text(
                            _formatPrice(addon.priceMonthlyCents, context.l10n),
                            style: AppTypography.labelMedium.copyWith(
                              color: scheme.onSurfaceVariant,
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
                size: AppSizes.iconMd,
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

/// Selo compacto do add-on — véu da própria cor com texto de contraste.
class _AddOnBadge extends StatelessWidget {
  const _AddOnBadge({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.micro,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.xsAll,
      ),
      child: Text(
        label,
        style: AppTypography.labelMedium.copyWith(color: textColor),
      ),
    );
  }
}
