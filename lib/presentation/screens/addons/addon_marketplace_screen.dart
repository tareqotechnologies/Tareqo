import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../../controllers/addon_providers.dart';
import 'custom_invoice_screen.dart';
import 'quotation_screen.dart';
import 'employee_management_screen.dart';
import 'store_transfers_screen.dart';
import 'advanced_reports_screen.dart';
import 'payment_reconciliation_screen.dart';

/// Ecra do marketplace de add-ons — permite activar/desactivar serviços extras.
class AddOnMarketplaceScreen extends ConsumerWidget {
  const AddOnMarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final addOns = ref.watch(addOnCatalogProvider);
    final activeIds = ref.watch(activeAddOnIdsProvider);

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
              'Serviços extras para potenciar o seu negócio',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          for (final addon in addOns) ...[
            _AddOnCard(
              addon: addon,
              isActive: activeIds.contains(addon.id),
              onToggle: () {
                ref.read(activeAddOnIdsProvider.notifier).toggle(addon.id);
              },
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
}

class _AddOnCard extends StatelessWidget {
  const _AddOnCard({
    required this.addon,
    required this.isActive,
    required this.onToggle,
    required this.onOpen,
  });

  final dynamic addon;
  final bool isActive;
  final VoidCallback onToggle;
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isActive
                      ? scheme.primary.withValues(alpha: 0.15)
                      : scheme.surfaceContainerHighest,
                  borderRadius: AppRadius.smAll,
                ),
                child: Icon(
                  iconData,
                  size: 22,
                  color: isActive ? scheme.primary : scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            addon.name,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Activo',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      addon.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatPrice(addon.priceMonthlyCents),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
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
