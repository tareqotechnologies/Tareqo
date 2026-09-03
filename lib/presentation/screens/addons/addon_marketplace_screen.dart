import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
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
    final addOns = ref.watch(addOnCatalogProvider);
    final activeIds = ref.watch(activeAddOnIdsProvider).value ?? {};

    // Add-ons incluídos no plano do tenant.
    final user = ref.watch(authStateProvider).value;
    final tenant = user == null
        ? null
        : ref.watch(myTenantProvider(user.id)).value;
    final bundledAddOns = tenant != null ? _getBundledAddOns(ref, tenant.planId) : <String>{};

    final horizontal = AppSpacing.pagePaddingForWidth(
      MediaQuery.sizeOf(context).width,
    );

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        titleSpacing: AppSpacing.lg,
        title: Text(
          'Add-ons',
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
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(
              'Add-ons activos e disponíveis no seu plano',
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
                    'A activação de add-ons é gerida pelo administrador do sistema.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (final addon in addOns)
            if (activeIds.contains(addon.id) || bundledAddOns.contains(addon.id)) ...[
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
          MaterialPageRoute<void>(
            builder: (_) => const CustomInvoiceScreen(),
          ),
        );
      case 'ao_quotation':
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const QuotationScreen(),
          ),
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
          MaterialPageRoute<void>(
            builder: (_) => const StoreTransfersScreen(),
          ),
        );
      case 'ao_mobile_money':
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const PaymentReconciliationScreen(),
          ),
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

  final dynamic addon;
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
                      addon.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      addon.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (isIncluded)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Incluído',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: const Color(0xFF16A34A),
                                fontWeight: FontWeight.w400,
                                fontSize: 11,
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
                              'Activo',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w400,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        if (isIncluded || isActive) const SizedBox(width: 6),
                        Text(
                          isIncluded ? '' : _formatPrice(addon.priceMonthlyCents),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w300,
                            fontSize: 12,
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

  String _formatPrice(int cents) {
    final value = cents / 100;
    return '${value.toStringAsFixed(0)} MT/mês';
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
