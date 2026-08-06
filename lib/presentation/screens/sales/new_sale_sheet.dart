import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/i18n/payment_method_l10n.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/ids.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/sale.dart';
import '../../../domain/entities/sale_item.dart';
import '../../../domain/usecases/process_sale_use_case.dart';
import '../../../domain/usecases/update_product_stock_use_case.dart';
import '../../controllers/account_providers.dart';
import '../../controllers/auth_providers.dart';
import '../../controllers/dashboard_providers.dart';
import '../../controllers/finance_providers.dart';
import '../../controllers/products_providers.dart';
import '../../controllers/sales_providers.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/search_field.dart';
import '../../../core/observability/crash_reporting.dart';

/// Carrinho de nova venda: seleciona produtos, define quantidades,
/// escolhe a forma de pagamento e confirma via [ProcessSaleUseCase].
class NewSaleSheet extends ConsumerStatefulWidget {
  const NewSaleSheet({super.key});

  @override
  ConsumerState<NewSaleSheet> createState() => _NewSaleSheetState();
}

class _NewSaleSheetState extends ConsumerState<NewSaleSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  /// Carrinho: id do produto → quantidade.
  final Map<String, int> _cart = {};

  /// Catálogo por id — evita busca O(n) a cada interação do carrinho.
  Map<String, Product> _productsById = const {};

  PaymentMethod _paymentMethod = PaymentMethod.pix;
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Total do carrinho em CENTAVOS inteiros (W4): quantidade × preço de
  // venda em centavos — soma exata, sem artefatos de double (0.1+0.2).
  int get _totalCents => _cart.entries.fold<int>(
        0,
        (sum, entry) => sum +
            (entry.value * (_productById(entry.key)?.salePriceCents ?? 0)),
      );

  int get _itemCount => _cart.values.fold(0, (sum, quantity) => sum + quantity);

  Product? _productById(String id) => _productsById[id];

  void _add(Product product) {
    final current = _cart[product.id] ?? 0;
    if (current < product.stockQuantity) {
      setState(() => _cart[product.id] = current + 1);
    }
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
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final products = ref.read(productsProvider).value ?? const <Product>[];
    // Lookup seguro: se um produto do carrinho sumir da lista (recarga em
    // andamento), aborta com mensagem amigável em vez de estourar.
    final productsById = {for (final product in products) product.id: product};

    final items = <SaleItem>[];
    for (final entry in _cart.entries) {
      final product = productsById[entry.key];
      if (product == null) {
        // Desfaz o loading antes de sair (o finally do try não cobre este
        // caminho).
        setState(() {
          _isSubmitting = false;
          _error = l10n.salesItemUnavailable;
        });
        return;
      }
      items.add(
        SaleItem(
          productId: product.id,
          productName: product.name,
          quantity: entry.value,
          unitPriceCents: product.salePriceCents,
        ),
      );
    }

    // A venda pertence à loja ativa (cada loja tem seu próprio histórico
    // e baixa o estoque da própria loja).
    final user = ref.read(authStateProvider).value;
    final storeId = user == null
        ? null
        : ref.read(activeStoreIdProvider(user.id));

    final sale = Sale(
      id: AppIds.newId('s'),
      storeId: storeId ?? 'st1',
      items: items,
      totalAmountCents: _totalCents,
      paymentMethod: _paymentMethod,
      dateTime: DateTime.now(),
    );

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      // O ProcessSaleUseCase registra a venda, baixa o estoque e lança a
      // entrada no caixa — uma única porta de entrada para o fluxo.
      await ref.read(processSaleUseCaseProvider).call(sale);

      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n.salesRegistered(Formatters.currency(sale.totalAmountCents)),
          ),
        ),
      );
      // Estoque, vendas, caixa e KPIs mudaram — as telas recarregam.
      ref.invalidate(productsProvider);
      ref.invalidate(salesListProvider);
      ref.invalidate(transactionsProvider);
      ref.invalidate(cashFlowProvider);
      ref.invalidate(dashboardKpisProvider);
    } on InsufficientStockException catch (error) {
      final product = _productById(error.productId);
      setState(() {
        final nameSuffix = product != null
            ? ' ${l10n.salesStockFor(product.name)}'
            : '';
        _error = l10n.salesInsufficientStock(nameSuffix, error.available);
      });
    } on ProductNotFoundException catch (error) {
      setState(() {
        _error = l10n.salesProductNotFound(error.productId);
      });
    } catch (error, stackTrace) {
      CrashReporting.capture(
        error,
        stackTrace,
        hint: 'Erro ao registrar venda',
      );
      setState(() {
        _error = l10n.salesRegisterError;
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
    // Mantém o catálogo por id em sincronia com o provider (recarrega
    // junto com a lista — o carrinho continua válido).
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
          AppSheetHeader(title: l10n.salesNewSale),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: SearchField(
              controller: _searchController,
              hintText: l10n.salesSearchProducts,
              onChanged: (value) => setState(() => _query = value.trim()),
            ),
          ),
          Expanded(
            child: productsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
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
                          .where(
                            (product) =>
                                product.name.toLowerCase().contains(_query),
                          )
                          .toList();

                if (filtered.isEmpty) {
                  return EmptyState(
                    icon: Icons.search_off,
                    title: l10n.salesNoProductsTitle,
                    subtitle: l10n.salesNoProductsSubtitle,
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (context, index) => _CartProductRow(
                    product: filtered[index],
                    quantity: _cart[filtered[index].id] ?? 0,
                    onAdd: () => _add(filtered[index]),
                    onRemove: () => _remove(filtered[index]),
                  ),
                );
              },
            ),
          ),
          // -----------------------------------------------------------
          // Rodapé: total + forma de pagamento + confirmar
          // -----------------------------------------------------------
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
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final method in PaymentMethod.values)
                      ChoiceChip(
                        label: Text(method.labelFor(context.l10n)),
                        selected: _paymentMethod == method,
                        onSelected: (_) =>
                            setState(() => _paymentMethod = method),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
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
                      Formatters.currency(_totalCents),
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
                  label: Text(l10n.salesConfirm),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Linha do produto no carrinho com stepper de quantidade.
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
    final outOfStock = product.stockQuantity == 0;
    final soldOut = quantity >= product.stockQuantity;

    return Card(
      color: outOfStock
          ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
          : null,
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
                      color: outOfStock ? theme.colorScheme.outline : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    outOfStock
                        ? l10n.commonSoldOut
                        : '${Formatters.currency(product.salePriceCents)} · '
                              '${product.stockQuantity} ${l10n.commonUnits}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (!outOfStock)
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
                      onPressed: soldOut ? null : onAdd,
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
