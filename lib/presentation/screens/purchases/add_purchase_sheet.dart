import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/ids.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/purchase.dart';
import '../../../domain/usecases/add_purchase_use_case.dart';
import '../../../domain/usecases/update_product_stock_use_case.dart';
import '../../controllers/account_providers.dart';
import '../../controllers/auth_providers.dart';
import '../../controllers/purchases_providers.dart';
import '../../controllers/products_providers.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/search_field.dart';

/// Carrinho de nova compra: fornecedor, produtos com steppers de quantidade
/// e confirmação via [ProcessPurchaseUseCase] (aumenta o estoque + saída no
/// caixa).
class AddPurchaseSheet extends ConsumerStatefulWidget {
  const AddPurchaseSheet({super.key});

  @override
  ConsumerState<AddPurchaseSheet> createState() => _AddPurchaseSheetState();
}

class _AddPurchaseSheetState extends ConsumerState<AddPurchaseSheet> {
  final _supplierController = TextEditingController();
  final _searchController = TextEditingController();
  String _query = '';

  /// Carrinho: id do produto → quantidade.
  final Map<String, int> _cart = {};

  /// Catálogo por id — evita busca O(n) a cada interação do carrinho.
  Map<String, Product> _productsById = const {};

  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _supplierController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  double get _total {
    var total = 0.0;
    for (final entry in _cart.entries) {
      final product = _productById(entry.key);
      if (product == null) continue;
      // Preço de compra na data — o custo de reposição do produto.
      total += product.purchasePrice * entry.value;
    }
    return total;
  }

  int get _itemCount =>
      _cart.values.fold(0, (sum, quantity) => sum + quantity);

  Product? _productById(String id) => _productsById[id];

  void _add(Product product) {
    setState(() => _cart[product.id] = (_cart[product.id] ?? 0) + 1);
  }

  void _remove(Product product) {
    final current = _cart[product.id] ?? 0;
    if (current <= 1) {
      setState(() => _cart.remove(product.id));
    } else {
      setState(() => _cart[product.id] = current - 1);
    }
  }

  Future<void> _confirm() async {
    final l10n = context.l10n;

    if (_supplierController.text.trim().isEmpty) {
      setState(() => _error = l10n.purchasesSupplierError);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final products = ref.read(productsProvider).value ?? const <Product>[];
    final productsById = {for (final product in products) product.id: product};

    final items = <PurchaseItem>[];
    for (final entry in _cart.entries) {
      final product = productsById[entry.key];
      if (product == null) {
        // Desfaz o loading antes de sair (o finally do try não cobre este
        // caminho).
        setState(() {
          _isSubmitting = false;
          _error = l10n.purchasesCartItemUnavailable;
        });
        return;
      }
      items.add(
        PurchaseItem(
          productId: product.id,
          productName: product.name,
          quantity: entry.value,
          unitPrice: product.purchasePrice,
        ),
      );
    }

    // A compra pertence à loja ativa (a entrada de estoque é por loja).
    final user = ref.read(authStateProvider).value;
    final storeId = user == null
        ? null
        : ref.read(activeStoreIdProvider(user.id));

    final purchase = Purchase(
      id: AppIds.newId('pc'),
      storeId: storeId ?? 'st1',
      supplierName: _supplierController.text.trim(),
      items: items,
      totalAmount: _total,
      dateTime: DateTime.now(),
    );

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      // ProcessPurchaseUseCase registra a compra, aumenta o estoque e lança
      // a saída no caixa — uma única porta de entrada para o fluxo.
      await ref.read(processPurchaseUseCaseProvider).call(purchase);

      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n.purchasesRegistered(
              Formatters.currency(purchase.totalAmount),
            ),
          ),
        ),
      );
    } on ProductNotFoundException catch (error) {
      setState(() {
        _error = l10n.purchasesProductNotFound(error.productId);
      });
    } catch (error, stackTrace) {
      debugPrint('Erro ao registrar compra: $error\n$stackTrace');
      setState(() {
        _error = l10n.purchasesRegisterError;
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final productsAsync = ref.watch(productsProvider);
    // Mantém o catálogo por id em sincronia com o provider.
    _productsById = {
      for (final product in productsAsync.value ?? const <Product>[])
        product.id: product,
    };

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      child: Column(
        children: [
          AppSheetHeader(title: l10n.purchasesAddNew),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: TextField(
              controller: _supplierController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.purchasesSupplierLabel,
                prefixIcon: const Icon(Icons.local_shipping_outlined),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: SearchField(
              controller: _searchController,
              hintText: l10n.productsSearchHint,
              onChanged: (value) => setState(() => _query = value.trim()),
            ),
          ),
          Expanded(
            child: productsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(
                child: Text(
                  l10n.productsLoadError,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              data: (all) {
                final filtered = _query.isEmpty
                    ? all
                    : all
                        .where((product) =>
                            product.name.toLowerCase().contains(_query))
                        .toList();

                if (filtered.isEmpty) {
                  return EmptyState(
                    icon: Icons.search_off,
                    title: l10n.purchasesNoProductsTitle,
                    subtitle: l10n.purchasesNoProductsSubtitle,
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (context, index) =>
                      _CartProductRow(
                    product: filtered[index],
                    quantity: _cart[filtered[index].id] ?? 0,
                    onAdd: () => _add(filtered[index]),
                    onRemove: () => _remove(filtered[index]),
                  ),
                );
              },
            ),
          ),
          // Rodapé: total + confirmar
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                top: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.dashboardSaleItems(_itemCount),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Text(
                      Formatters.currency(_total),
                      style: theme.textTheme.titleLarge,
                    ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _cart.isEmpty || _isSubmitting ? null : _confirm,
                  icon: _isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(l10n.purchasesConfirm),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Linha do produto no carrinho de compra com stepper de quantidade.
class _CartProductRow extends StatelessWidget {
  const _CartProductRow({
    required this.product,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  final Product product;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${Formatters.currency(product.purchasePrice)} · '
                    '${l10n.purchasesStockLabel(product.stockQuantity, l10n.commonUnits)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.remove, size: 18),
                    onPressed: quantity == 0 ? null : onRemove,
                  ),
                  SizedBox(
                    width: 24,
                    child: Text(
                      '$quantity',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelLarge,
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.add, size: 18),
                    onPressed: onAdd,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
