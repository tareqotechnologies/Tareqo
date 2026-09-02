import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
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
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.xs),
              itemBuilder: (context, index) =>
                  _TransferCard(transfer: _transfers[index]),
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
}

class _TransferCard extends StatelessWidget {
  const _TransferCard({required this.transfer});

  final _TransferRecord transfer;

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
          ],
        ),
      ),
    );
  }
}

class _NewTransferSheet extends StatefulWidget {
  const _NewTransferSheet({required this.onSave});

  final ValueChanged<_TransferRecord> onSave;

  @override
  State<_NewTransferSheet> createState() => _NewTransferSheetState();
}

class _NewTransferSheetState extends State<_NewTransferSheet> {
  String? _fromStore;
  String? _toStore;
  final _productController = TextEditingController();
  final _qtyController = TextEditingController(text: '1');
  int _itemCount = 0;

  final _stores = const ['Loja Central', 'Loja Norte', 'Loja Sul'];

  @override
  void dispose() {
    _productController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            AppTextField(
              controller: _productController,
              label: 'Produto',
              prefixIcon: Icons.inventory_2_outlined,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              controller: _qtyController,
              label: 'Quantidade',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: AppButton.secondary(
                label: 'Adicionar Item',
                onPressed: () {
                  if (_productController.text.trim().isNotEmpty) {
                    setState(() => _itemCount++);
                    _productController.clear();
                    _qtyController.text = '1';
                  }
                },
              ),
            ),
            if (_itemCount > 0) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                '$_itemCount item(ns) adicionado(s)',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppButton.primary(
              expanded: true,
              label: 'Criar Transferência',
              onPressed: _fromStore != null &&
                      _toStore != null &&
                      _fromStore != _toStore &&
                      _itemCount > 0
                  ? () {
                      widget.onSave(
                        _TransferRecord(
                          fromStore: _fromStore!,
                          toStore: _toStore!,
                          items: _itemCount,
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
