import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../../controllers/products_providers.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

/// Ecra de transferências entre lojas — envio, recebimento e histórico.
class StoreTransfersScreen extends ConsumerStatefulWidget {
  const StoreTransfersScreen({super.key});

  @override
  ConsumerState<StoreTransfersScreen> createState() =>
      _StoreTransfersScreenState();
}

class _StoreTransfersScreenState extends ConsumerState<StoreTransfersScreen> {
  final List<_TransferRecord> _transfers = [];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

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
      body: _transfers.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.swap_horiz_outlined,
                      size: 48,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Sem transferências',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Transfira estoque entre lojas do\nmesmo tenant de forma rastreável',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: _transfers.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.xs),
              itemBuilder: (context, index) =>
                  _TransferCard(
                    transfer: _transfers[index],
                    onStatusChange: (newStatus) {
                      setState(() {
                        final idx = _transfers.indexOf(_transfers[index]);
                        _transfers[idx] = _transfers[idx].copyWith(status: newStatus);
                      });
                    },
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
      builder: (_) => _NewTransferSheet(
        onSave: (record) {
          setState(() => _transfers.insert(0, record));
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

class _TransferRecord {
  _TransferRecord({
    required this.fromStore,
    required this.toStore,
    required this.items,
    required this.status,
    required this.date,
  });

  final String fromStore;
  final String toStore;
  final int items;
  final String status;
  final String date;

  _TransferRecord copyWith({String? status}) {
    return _TransferRecord(
      fromStore: fromStore,
      toStore: toStore,
      items: items,
      status: status ?? this.status,
      date: date,
    );
  }
}

class _TransferCard extends StatelessWidget {
  const _TransferCard({
    required this.transfer,
    this.onStatusChange,
  });

  final _TransferRecord transfer;
  final ValueChanged<String>? onStatusChange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final statusColor = switch (transfer.status) {
      'Pendente' => const Color(0xFFF59E0B),
      'Em Trânsito' => const Color(0xFF3B82F6),
      'Recebida' => const Color(0xFF16A34A),
      'Cancelada' => scheme.error,
      _ => scheme.onSurfaceVariant,
    };

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: AppRadius.lgAll,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.swap_horiz,
                  size: 20,
                  color: scheme.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '${transfer.fromStore}  →  ${transfer.toStore}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    transfer.status,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${transfer.items} itens  •  ${transfer.date}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (transfer.status == 'Pendente' && onStatusChange != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: AppButton.secondary(
                      label: 'Despachar',
                      icon: const Icon(Icons.local_shipping_outlined, size: 16),
                      onPressed: () => onStatusChange!('Em Trânsito'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: AppButton.danger(
                      label: 'Cancelar',
                      onPressed: () => onStatusChange!('Cancelada'),
                    ),
                  ),
                ],
              ),
            ],
            if (transfer.status == 'Em Trânsito' && onStatusChange != null) ...[
              const SizedBox(height: AppSpacing.sm),
              AppButton.primary(
                expanded: true,
                label: 'Confirmar Recebimento',
                icon: const Icon(Icons.check_circle_outline, size: 16),
                onPressed: () => onStatusChange!('Recebida'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TransferItem {
  _TransferItem({
    required this.name,
    required this.qty,
  });

  final String name;
  final int qty;
}

class _NewTransferSheet extends ConsumerStatefulWidget {
  const _NewTransferSheet({required this.onSave});

  final ValueChanged<_TransferRecord> onSave;

  @override
  ConsumerState<_NewTransferSheet> createState() => _NewTransferSheetState();
}

class _NewTransferSheetState extends ConsumerState<_NewTransferSheet> {
  String? _fromStore;
  String? _toStore;
  String? _selectedProductId;
  final _qtyController = TextEditingController(text: '1');
  final List<_TransferItem> _items = [];

  final _stores = const ['Loja Central', 'Loja Norte', 'Loja Sul'];

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  void _addItem() {
    final qty = int.tryParse(_qtyController.text) ?? 1;
    if (_selectedProductId == null || qty <= 0) return;

    final products = ref.read(productsProvider).value ?? [];
    final product = products.firstWhere(
      (p) => p.id == _selectedProductId,
      orElse: () => products.first,
    );

    setState(() {
      _items.add(_TransferItem(name: product.name, qty: qty));
      _selectedProductId = null;
      _qtyController.text = '1';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final products = ref.watch(productsProvider).value ?? [];
    final activeProducts = products.where((p) => p.isActive).toList();

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
              initialValue: _fromStore,
              decoration: const InputDecoration(
                labelText: 'Loja de Origem',
                prefixIcon: Icon(Icons.store_outlined),
              ),
              items: _stores
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _fromStore = v),
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              initialValue: _toStore,
              decoration: const InputDecoration(
                labelText: 'Loja de Destino',
                prefixIcon: Icon(Icons.storefront_outlined),
              ),
              items: _stores
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _toStore = v),
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),

            // ─── Produto (picker do estoque) ──
            Text('Produto', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            if (activeProducts.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: AppRadius.mdAll,
                ),
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedProductId,
                  isExpanded: true,
                  menuMaxHeight: 250,
                  decoration: InputDecoration(
                    hintText: 'Selecionar produto...',
                    prefixIcon: const Icon(Icons.inventory_2_outlined, size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: activeProducts
                      .map((p) => DropdownMenuItem(
                            value: p.id,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(p.name, style: theme.textTheme.bodyMedium, overflow: TextOverflow.ellipsis),
                                Text(
                                  'Estoque: ${p.stockQuantity ~/ 1000} ${p.unitLabel}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (id) => setState(() => _selectedProductId = id),
                ),
              )
            else
              InputDecorator(
                decoration: InputDecoration(
                  hintText: 'Sem produtos cadastrados',
                  prefixIcon: const Icon(Icons.inventory_2_outlined, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: AppButton.secondary(
                    label: 'Adicionar',
                    onPressed: _selectedProductId != null ? _addItem : null,
                  ),
                ),
              ],
            ),
            if (_items.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              ..._items.asMap().entries.map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline, size: 16, color: scheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('${entry.value.name} x${entry.value.qty}', style: theme.textTheme.bodyMedium),
                        ),
                        InkWell(
                          onTap: () => setState(() => _items.removeAt(entry.key)),
                          child: Icon(Icons.close, size: 16, color: scheme.error),
                        ),
                      ],
                    ),
                  )),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppButton.primary(
              expanded: true,
              label: 'Criar Transferência',
              onPressed: _fromStore != null &&
                      _toStore != null &&
                      _fromStore != _toStore &&
                      _items.isNotEmpty
                  ? () {
                      widget.onSave(
                        _TransferRecord(
                          fromStore: _fromStore!,
                          toStore: _toStore!,
                          items: _items.length,
                          status: 'Pendente',
                          date: DateTime.now().toString().substring(0, 10),
                        ),
                      );
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
