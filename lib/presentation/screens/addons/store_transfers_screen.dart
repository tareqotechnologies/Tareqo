import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/quantity.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/stock_transfer.dart';
import '../../controllers/account_providers.dart';
import '../../controllers/auth_providers.dart';
import '../../controllers/products_providers.dart';
import '../../controllers/stock_transfers_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_page.dart';
import '../../widgets/app_picker_field.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/empty_state.dart';

/// Ecra de transferências entre lojas — envio, recebimento e histórico.
class StoreTransfersScreen extends ConsumerStatefulWidget {
  const StoreTransfersScreen({super.key});

  @override
  ConsumerState<StoreTransfersScreen> createState() =>
      _StoreTransfersScreenState();
}

class _StoreTransfersScreenState extends ConsumerState<StoreTransfersScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final transfers = ref.watch(stockTransfersProvider);
    final horizontal = AppSpacing.pagePaddingForWidth(
      MediaQuery.sizeOf(context).width,
    );

    return AppPage(
      title: l10n.transfersTitle,
      titleStyle: AppTypography.titleMedium,
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-transfer',
        onPressed: _openNewTransfer,
        tooltip: l10n.transfersNewFab,
        child: const Icon(Icons.add_rounded),
      ),
      body: transfers.isEmpty
          ? EmptyState(
              icon: Icons.swap_horiz_outlined,
              title: l10n.transfersEmpty,
              subtitle: l10n.transfersEmptySubtitle,
            )
          : ListView.separated(
              padding: EdgeInsets.fromLTRB(
                horizontal,
                AppSpacing.sm,
                horizontal,
                AppSpacing.fabBottomClearance,
              ),
              itemCount: transfers.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
              itemBuilder: (context, index) =>
                  _TransferCard(transfer: transfers[index]),
            ),
    );
  }

  void _openNewTransfer() {
    showAppSheet<void>(context, builder: (_) => const _NewTransferSheet());
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Transfer Card
// ═══════════════════════════════════════════════════════════════════════════════

class _TransferCard extends StatelessWidget {
  const _TransferCard({required this.transfer});

  final StockTransfer transfer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final (statusTone, statusIcon) = switch (transfer.status) {
      StockTransferStatus.pending => (
        AppColors.alertWarning,
        Icons.schedule_outlined,
      ),
      StockTransferStatus.inTransit => (
        scheme.primary,
        Icons.local_shipping_outlined,
      ),
      StockTransferStatus.received => (
        theme.income,
        Icons.check_circle_outline,
      ),
      StockTransferStatus.cancelled => (theme.expense, Icons.cancel_outlined),
    };

    final formattedQty = Quantity.format(
      transfer.quantityMilli,
      unitLabel: transfer.unitLabel,
    );
    final l10n = context.l10n;
    final statusLabel = switch (transfer.status) {
      StockTransferStatus.pending => l10n.transferStatusPending,
      StockTransferStatus.inTransit => l10n.transferStatusInTransit,
      StockTransferStatus.received => l10n.transferStatusReceived,
      StockTransferStatus.cancelled => l10n.transferStatusCancelled,
    };

    return AppCard(
      elevated: true,
      borderRadius: AppRadius.lgAll,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: AppSizes.avatarSm,
            height: AppSizes.avatarSm,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: AppRadius.smAll,
            ),
            child: Icon(
              Icons.swap_horiz,
              size: AppSizes.iconMd,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  // Nomes COMPLETOS das lojas — quebra quando necessário
                  // (nunca truncar o percurso da transferência).
                  '${transfer.fromStoreName}  →  ${transfer.toStoreName}',
                  style: AppTypography.labelLarge.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.micro),
                Text(
                  '${transfer.productName}  ·  $formattedQty  ·  ${Formatters.date(transfer.createdAt)}',
                  style: AppTypography.bodySmall.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.micro,
            ),
            decoration: BoxDecoration(
              color: statusTone.withValues(alpha: 0.12),
              borderRadius: AppRadius.xsAll,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, size: AppSizes.iconSm, color: statusTone),
                const SizedBox(width: AppSpacing.xxs),
                Text(
                  statusLabel,
                  style: AppTypography.labelMedium.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// New Transfer Sheet
// ═══════════════════════════════════════════════════════════════════════════════

class _NewTransferItem {
  _NewTransferItem({required this.product, required this.qtyMilli});

  final Product product;
  final int qtyMilli;
}

class _NewTransferSheet extends ConsumerStatefulWidget {
  const _NewTransferSheet();

  @override
  ConsumerState<_NewTransferSheet> createState() => _NewTransferSheetState();
}

class _NewTransferSheetState extends ConsumerState<_NewTransferSheet> {
  String? _fromStoreId;
  String? _toStoreId;
  String? _selectedProductId;
  final _qtyController = TextEditingController(text: '1');
  final List<_NewTransferItem> _items = [];
  bool _executing = false;

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  void _addItem() {
    final qtyText = _qtyController.text.trim();
    final qty = double.tryParse(qtyText.replaceAll(',', '.')) ?? 0;
    if (_selectedProductId == null || qty <= 0) return;

    final products = ref.read(productsProvider).value ?? [];
    final product = products
        .where((p) => p.id == _selectedProductId)
        .firstOrNull;
    // Produto não encontrado → ignora (antes o fallback caía no PRIMEIRO
    // produto da lista, transferindo o produto errado).
    if (product == null) return;

    // Converter para milésimos
    final qtyMilli = (qty * 1000).round();

    setState(() {
      _items.add(_NewTransferItem(product: product, qtyMilli: qtyMilli));
      _selectedProductId = null;
      _qtyController.text = '1';
    });
  }

  Future<void> _executeTransfer() async {
    if (_fromStoreId == null || _toStoreId == null || _items.isEmpty) return;

    final stores =
        ref
            .read(
              storesProvider(
                ref
                    .read(
                      myTenantProvider(ref.read(authStateProvider).value!.id),
                    )
                    .value!
                    .id,
              ),
            )
            .value ??
        [];

    // Resolve os NOMES antes de executar: se uma loja selecionada sumir da
    // lista (ex.: refresh/stale), aborta sem crashar (o antigo firstWhere
    // sem fallback lançava StateError fora do try).
    final fromName = stores
        .where((s) => s.id == _fromStoreId)
        .firstOrNull
        ?.name;
    final toName = stores.where((s) => s.id == _toStoreId).firstOrNull?.name;
    if (fromName == null || toName == null) return;

    setState(() => _executing = true);

    final transfersNotifier = ref.read(stockTransfersProvider.notifier);

    try {
      for (final item in _items) {
        await transfersNotifier.executeTransfer(
          productId: item.product.id,
          productName: item.product.name,
          fromStoreId: _fromStoreId!,
          fromStoreName: fromName,
          toStoreId: _toStoreId!,
          toStoreName: toName,
          quantityMilli: item.qtyMilli,
          unitLabel: item.product.unitLabel,
        );
      }

      // Refresh products to reflect new stock.
      ref.invalidate(productsProvider);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.transfersSuccess(_items.length))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.transfersError('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _executing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final products = ref.watch(productsProvider).value ?? [];
    final activeProducts = products.where((p) => p.isActive).toList();

    // Buscar lojas reais do tenant.
    final user = ref.watch(authStateProvider).value;
    final tenant = user == null
        ? null
        : ref.watch(myTenantProvider(user.id)).value;
    final stores = tenant != null
        ? ref.watch(storesProvider(tenant.id)).value ?? []
        : [];

    // Loja ativa como origem padrão.
    final activeStoreId = user == null
        ? null
        : ref.watch(activeStoreIdProvider(user.id));

    // Filtrar loja de destino (não pode ser igual à origem).
    final destStores = stores.where((s) => s.id != _fromStoreId).toList();

    // Definir origem padrão se ainda não selecionada.
    if (_fromStoreId == null &&
        activeStoreId != null &&
        stores.any((s) => s.id == activeStoreId)) {
      _fromStoreId = activeStoreId;
    }

    if (stores.length < 2) {
      return SheetForm(
        title: l10n.transfersNewFab,
        children: [
          SheetSection(
            icon: Icons.store_outlined,
            children: [
              Icon(
                Icons.store_outlined,
                size: AppSpacing.xxxl,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.3),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.transfersNoStoresTitle,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.transfersNoStoresSubtitle,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return SheetForm(
      title: l10n.transfersNewFab,
      maxHeightFactor: 0.9,
      actionLabel: _executing ? l10n.transfersExecuting : l10n.transfersExecute,
      onSubmit:
          _fromStoreId == null ||
              _toStoreId == null ||
              _fromStoreId == _toStoreId ||
              _items.isEmpty
          ? null
          : _executeTransfer,
      isSubmitting: _executing,
      children: [
        // Rota — origem e destino da transferência.
        SheetSection(
          icon: Icons.swap_horiz_outlined,
          children: [
            AppPickerField<String>(
              value: _fromStoreId,
              label: l10n.transfersOriginStore,
              prefixIcon: Icons.store_outlined,
              items: [
                for (final s in stores)
                  DropdownMenuItem(value: s.id, child: Text(s.name)),
              ],
              onChanged: (v) => setState(() {
                _fromStoreId = v;
                if (_toStoreId == v) _toStoreId = null;
              }),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppPickerField<String>(
              value: _toStoreId,
              label: l10n.transfersDestStore,
              prefixIcon: Icons.storefront_outlined,
              items: [
                for (final s in destStores)
                  DropdownMenuItem(value: s.id, child: Text(s.name)),
              ],
              onChanged: (v) => setState(() => _toStoreId = v),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        // Produtos — seletor, quantidade e itens adicionados.
        SheetSection(
          icon: Icons.inventory_2_outlined,
          title: l10n.transfersProduct,
          children: [
            if (activeProducts.isNotEmpty)
              AppPickerField<String>(
                value: _selectedProductId,
                isExpanded: true,
                label: l10n.transfersProduct,
                prefixIcon: Icons.inventory_2_outlined,
                items: [
                  for (final p in activeProducts)
                    DropdownMenuItem(
                      value: p.id,
                      child: Text(
                        '${p.name}  ·  ${Quantity.format(p.stockQuantity, unitLabel: p.vendaPorFracao ? p.unitLabel : null)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (id) => setState(() => _selectedProductId = id),
              )
            else
              InputDecorator(
                decoration: InputDecoration(
                  hintText: l10n.transfersProductPlaceholder,
                  prefixIcon: const Icon(
                    Icons.inventory_2_outlined,
                    size: AppSizes.iconMd,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
                child: const Text(''),
              ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _qtyController,
                    label: l10n.transfersQuantity,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: AppButton.secondary(
                    label: l10n.transfersAddItem,
                    onPressed: _selectedProductId != null ? _addItem : null,
                  ),
                ),
              ],
            ),
            if (_items.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              ..._items.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: AppSizes.iconSm,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          '${entry.value.product.name}  ·  ${Quantity.format(entry.value.qtyMilli, unitLabel: entry.value.product.vendaPorFracao ? entry.value.product.unitLabel : null)}',
                          style: AppTypography.bodyMedium.copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => setState(() => _items.removeAt(entry.key)),
                        child: Icon(
                          Icons.close,
                          size: AppSizes.iconSm,
                          color: scheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Shared widgets
// ═══════════════════════════════════════════════════════════════════════════════
