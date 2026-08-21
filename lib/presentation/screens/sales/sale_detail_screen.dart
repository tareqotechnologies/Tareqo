import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/i18n/payment_method_l10n.dart';
import '../../../core/observability/crash_reporting.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/quantity.dart';
import '../../../data/services/offline_sync_service.dart';
import '../../../domain/entities/sale.dart';
import '../../../domain/entities/sale_item.dart';
import '../../../domain/entities/store.dart';
import '../../../domain/usecases/cancel_sale_use_case.dart';
import '../../controllers/account_providers.dart';
import '../../controllers/auth_providers.dart';
import '../../controllers/dashboard_providers.dart';
import '../../controllers/finance_providers.dart';
import '../../controllers/products_providers.dart';
import '../../controllers/sales_providers.dart';
import '../../widgets/app_button.dart';
import '../../widgets/payment_filter.dart' show PaymentMethodAccent, PaymentMethodIcon;
import '../../widgets/product_image.dart';
import '../../widgets/section_header.dart';
import '../../widgets/smart_amount.dart';
import '../../widgets/status_chip.dart';
import 'sale_receipt_share_sheet.dart';

/// Tela de detalhes de uma venda — layout clean Google-style.
///
/// Quando a venda está ativa e o usuário tem acesso gerencial,
/// oferece a ação de anular venda.
class SaleDetailScreen extends ConsumerStatefulWidget {
  const SaleDetailScreen({super.key, required this.sale});

  final Sale sale;

  @override
  ConsumerState<SaleDetailScreen> createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends ConsumerState<SaleDetailScreen> {
  bool _cancelling = false;

  Sale get sale => widget.sale;

  Store? _activeStore() {
    final user = ref.watch(authStateProvider).value;
    if (user == null) return null;
    final tenant = ref.watch(myTenantProvider(user.id)).value;
    if (tenant == null) return null;
    final storeId = ref.watch(activeStoreIdProvider(user.id));
    if (storeId == null) return null;
    final stores =
        ref.watch(storesProvider(tenant.id)).value ?? const <Store>[];
    return stores.where((store) => store.id == storeId).firstOrNull;
  }

  void _openShareSheet(Store? store) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SaleReceiptShareSheet(
        sale: sale,
        storeName: store?.name,
        storeAddress: (store?.address ?? '').isEmpty ? null : store?.address,
      ),
    );
  }

  Future<void> _confirmCancel() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.saleDetailCancelConfirmTitle),
        content: Text(
          l10n.saleDetailCancelConfirmBody(
            Formatters.currency(sale.totalAmountCents),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          AppButton.danger(
            label: l10n.saleDetailCancelConfirm,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final user = ref.read(authStateProvider).value;
    final storeId =
        user == null ? null : ref.read(activeStoreIdProvider(user.id));
    if (storeId == null) return;

    setState(() => _cancelling = true);
    try {
      await ref
          .read(cancelSaleUseCaseProvider)
          .call(sale.id, storeId: storeId);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.saleCancelledSuccess)),
      );
      ref.invalidate(salesListProvider);
      ref.invalidate(productsProvider);
      ref.invalidate(transactionsProvider);
      ref.invalidate(cashFlowProvider);
      ref.invalidate(dashboardKpisProvider);
      Navigator.of(context).pop();
    } on SaleNotFoundException {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.saleNotFoundError)));
      ref.invalidate(salesListProvider);
      Navigator.of(context).pop();
    } on OfflineEnqueuedException {
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text(l10n.syncOfflineSaved)));
    } catch (error, stackTrace) {
      CrashReporting.capture(error, stackTrace, hint: 'Erro ao anular venda');
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.saleCancelError)));
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final canCancel = ref.watch(canCancelSalesProvider);
    final isCancelled = sale.status == SaleStatus.cancelled;
    final activeStore = _activeStore();
    final accent = sale.paymentMethod.accent(theme);
    final itemsLabel = l10n.dashboardSaleItems(sale.items.length);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.saleDetailTitle,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w500,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          // ── Header: sale ID + date + payment chip ──
          Text(
            l10n.saleDetailId(Formatters.saleLabel(sale.number)),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${Formatters.dateTime(sale.dateTime)}  ·  $itemsLabel',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          if (isCancelled)
            StatusChip(
              label: l10n.salesStatusCancelled,
              color: theme.expense,
              icon: Icons.block,
            )
          else
            StatusChip(
              label: sale.paymentMethod.labelFor(context.l10n),
              color: accent,
              icon: sale.paymentMethod.icon,
            ),
          if (isCancelled && sale.cancelledAt != null) ...[
            const SizedBox(height: 8),
            Text(
              '${l10n.saleDetailCancelledAt} '
              '${Formatters.dateTime(sale.cancelledAt!)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 24),

          // ── Total ──
          Text(
            l10n.saleDetailTotalLabel,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          SmartAmount(
            cents: sale.totalAmountCents,
            alignment: Alignment.centerLeft,
            style: isCancelled
                ? theme.textTheme.headlineMedium?.copyWith(
                    color: scheme.outline,
                    decoration: TextDecoration.lineThrough,
                  )
                : theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
          ),
          const SizedBox(height: 28),

          // ── Items ──
          SectionHeader(title: l10n.saleDetailItems),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < sale.items.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      indent: 14,
                      endIndent: 14,
                      color: scheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  _ItemRow(item: sale.items[i]),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Snapshot note ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_clock_outlined,
                size: 14,
                color: scheme.outline,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  l10n.saleDetailSnapshot,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.outline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // ── Actions ──
          AppButton.primary(
            label: l10n.saleDetailShareAction,
            onPressed: () => _openShareSheet(activeStore),
            icon: const Icon(Icons.ios_share, size: 20),
          ),
          if (canCancel && !isCancelled) ...[
            const SizedBox(height: 12),
            AppButton.secondary(
              label: l10n.saleDetailCancelAction,
              onPressed: _cancelling ? null : _confirmCancel,
              icon: _cancelling
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.warning,
                side: BorderSide(color: theme.warning),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Single item row: product image, name, quantity × price, subtotal.
class _ItemRow extends ConsumerWidget {
  const _ItemRow({required this.item});

  final SaleItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final subtotal = Quantity.lineTotal(item.quantity, item.unitPriceCents);
    final imagePath = ref
            .watch(productsProvider)
            .value
            ?.where((p) => p.id == item.productId)
            .map((p) => p.imagePath)
            .firstOrNull ??
        '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          ProductImage(imagePath: imagePath, size: 40, radius: 10),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${Quantity.format(item.quantity, language: Formatters.currentLanguage)} × '
                  '${Formatters.currency(item.unitPriceCents)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            Formatters.currency(subtotal),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
