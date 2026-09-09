import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_tokens.dart';
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
import '../../widgets/app_picker_field.dart';
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

    return Scaffold(
      appBar: AppBar(title: Text(l10n.transfersTitle)),
      body: transfers.isEmpty
          ? EmptyState(
              icon: Icons.swap_horiz_outlined,
              title: l10n.transfersEmpty,
              subtitle: l10n.transfersEmptySubtitle,
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: transfers.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
              itemBuilder: (context, index) =>
                  _TransferCard(transfer: transfers[index]),
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-transfer',
        onPressed: _openNewTransfer,
        tooltip: l10n.transfersNewFab,
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }

  void _openNewTransfer() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _NewTransferSheet(),
    );
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

    final (statusColor, statusIcon) = switch (transfer.status) {
      StockTransferStatus.pending => (
        ModuleColors.credit,
        Icons.schedule_outlined,
      ),
      StockTransferStatus.inTransit => (
        ModuleColors.reports,
        Icons.local_shipping_outlined,
      ),
      StockTransferStatus.received => (
        IconTone.green,
        Icons.check_circle_outline,
      ),
      StockTransferStatus.cancelled => (IconTone.red, Icons.cancel_outlined),
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
      borderRadius: const BorderRadius.all(Radius.circular(18)),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: IconTone.darkBackground(ModuleColors.stores),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.swap_horiz,
                  size: 16,
                  color: IconTone.lightForeground(ModuleColors.stores),
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
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${transfer.productName}  ·  $formattedQty  ·  ${Formatters.date(transfer.createdAt)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 12, color: statusColor),
                    const SizedBox(width: 3),
                    Text(
                      statusLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.store_outlined,
                size: 40,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.3),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.transfersNoStoresTitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.transfersNoStoresSubtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.transfersNewFab,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
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
            const SizedBox(height: AppSpacing.md),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),
            _SectionLabel(text: l10n.transfersProduct),
            const SizedBox(height: 6),
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
                  prefixIcon: const Icon(Icons.inventory_2_outlined, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
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
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 16,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${entry.value.product.name}  ·  ${Quantity.format(entry.value.qtyMilli, unitLabel: entry.value.product.vendaPorFracao ? entry.value.product.unitLabel : null)}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      InkWell(
                        onTap: () => setState(() => _items.removeAt(entry.key)),
                        child: Icon(Icons.close, size: 16, color: scheme.error),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppButton.primary(
              expanded: true,
              label: _executing
                  ? l10n.transfersExecuting
                  : l10n.transfersExecute,
              onPressed:
                  _executing ||
                      _fromStoreId == null ||
                      _toStoreId == null ||
                      _fromStoreId == _toStoreId ||
                      _items.isEmpty
                  ? null
                  : _executeTransfer,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Shared widgets
// ═══════════════════════════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
      ),
    );
  }
}
