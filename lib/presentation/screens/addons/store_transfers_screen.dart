import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final theme = Theme.of(context);
    final transfers = ref.watch(stockTransfersProvider);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        titleSpacing: AppSpacing.lg,
        title: Text(
          'Transferências entre Lojas',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w500,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: transfers.isEmpty
          ? EmptyState(
              icon: Icons.swap_horiz_outlined,
              title: 'Sem transferências',
              subtitle:
                  'Transfira estoque entre lojas do\nmesmo tenant de forma rastreável',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: transfers.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.xs),
              itemBuilder: (context, index) => _TransferCard(
                transfer: transfers[index],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-transfer',
        onPressed: _openNewTransfer,
        tooltip: 'Nova Transferência',
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
      StockTransferStatus.pending =>
        (ModuleColors.credit, Icons.schedule_outlined),
      StockTransferStatus.inTransit =>
        (ModuleColors.reports, Icons.local_shipping_outlined),
      StockTransferStatus.received =>
        (IconTone.green, Icons.check_circle_outline),
      StockTransferStatus.cancelled =>
        (IconTone.red, Icons.cancel_outlined),
    };

    final formattedQty = Quantity.format(
      transfer.quantityMilli,
      unitLabel: transfer.unitLabel,
    );

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
                      '${transfer.fromStoreName}  →  ${transfer.toStoreName}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${transfer.productName}  ·  $formattedQty  ·  ${Formatters.date(transfer.createdAt)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
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
                      transfer.status.label,
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
  _NewTransferItem({
    required this.product,
    required this.qtyMilli,
  });

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
    final product = products.firstWhere(
      (p) => p.id == _selectedProductId,
      orElse: () => products.first,
    );

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

    setState(() => _executing = true);

    final stores = ref.read(storesProvider(
      ref.read(myTenantProvider(ref.read(authStateProvider).value!.id)).value!.id,
    )).value ?? [];

    final fromName = stores.firstWhere((s) => s.id == _fromStoreId).name;
    final toName = stores.firstWhere((s) => s.id == _toStoreId).name;

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
          SnackBar(
            content: Text(
              '${_items.length} produto(s) transferido(s) com sucesso',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro na transferência: $e')),
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
    final destStores = stores
        .where((s) => s.id != _fromStoreId)
        .toList();

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
                'Cadastre pelo menos 2 lojas',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'É necessário ter 2+ lojas para\ntransferir estoque entre elas',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontSize: 11,
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
              'Nova Transferência',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            DropdownButtonFormField<String>(
              initialValue: _fromStoreId,
              decoration: const InputDecoration(
                labelText: 'Loja de Origem',
                prefixIcon: Icon(Icons.store_outlined),
              ),
              items: stores
                  .map<DropdownMenuItem<String>>((s) => DropdownMenuItem(
                        value: s.id,
                        child: Text(s.name, style: theme.textTheme.bodySmall),
                      ))
                  .toList(),
              onChanged: (v) => setState(() {
                _fromStoreId = v;
                if (_toStoreId == v) _toStoreId = null;
              }),
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              initialValue: _toStoreId,
              decoration: const InputDecoration(
                labelText: 'Loja de Destino',
                prefixIcon: Icon(Icons.storefront_outlined),
              ),
              items: destStores
                  .map<DropdownMenuItem<String>>((s) => DropdownMenuItem(
                        value: s.id,
                        child: Text(s.name, style: theme.textTheme.bodySmall),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _toStoreId = v),
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),
            _SectionLabel(text: 'Produto'),
            const SizedBox(height: 6),
            if (activeProducts.isNotEmpty)
              DropdownButtonFormField<String>(
                initialValue: _selectedProductId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Produto',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
                items: activeProducts
                    .map<DropdownMenuItem<String>>(
                      (p) => DropdownMenuItem(
                        value: p.id,
                        child: Text(
                          '${p.name}  ·  ${Quantity.format(p.stockQuantity, unitLabel: p.vendaPorFracao ? p.unitLabel : null)}',
                          style: theme.textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (id) =>
                    setState(() => _selectedProductId = id),
              )
            else
              InputDecorator(
                decoration: InputDecoration(
                  hintText: 'Sem produtos cadastrados',
                  prefixIcon: const Icon(
                    Icons.inventory_2_outlined,
                    size: 20,
                  ),
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
                    label: 'Quantidade',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: AppButton.secondary(
                    label: 'Adicionar',
                    onPressed:
                        _selectedProductId != null ? _addItem : null,
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
                          Icon(Icons.check_circle_outline,
                              size: 16, color: scheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${entry.value.product.name}  ·  ${Quantity.format(entry.value.qtyMilli, unitLabel: entry.value.product.vendaPorFracao ? entry.value.product.unitLabel : null)}',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                          InkWell(
                            onTap: () => setState(
                                () => _items.removeAt(entry.key)),
                            child: Icon(Icons.close,
                                size: 16, color: scheme.error),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppButton.primary(
              expanded: true,
              label: _executing ? 'A transferir...' : 'Executar Transferência',
              onPressed: _executing ||
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
