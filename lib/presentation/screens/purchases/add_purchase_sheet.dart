import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/i18n/payment_method_l10n.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/ids.dart';
import '../../../core/utils/quantity.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/purchase.dart';
import '../../../domain/entities/sale.dart' show PaymentMethod;
import '../../../domain/usecases/add_purchase_use_case.dart';
import '../../../domain/usecases/update_product_stock_use_case.dart';
import '../../controllers/account_providers.dart';
import '../../controllers/auth_providers.dart';
import '../../controllers/purchases_providers.dart';
import '../../controllers/products_providers.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/search_field.dart';
import '../../../core/observability/crash_reporting.dart';

/// Carrinho de nova compra: fornecedor, produtos com steppers de quantidade
/// e VALIDADE OPCIONAL por item (cria o lote FIFO correspondente) e
/// confirmação via [ProcessPurchaseUseCase] (aumenta o estoque + saída no
/// caixa).
///
/// W11: quantidades em MILÉSIMOS; produtos por peso aceitam decimais
/// (ex.: 1,75 kg); a data de validade alimenta o lote da entrada.
class AddPurchaseSheet extends ConsumerStatefulWidget {
  const AddPurchaseSheet({super.key});

  @override
  ConsumerState<AddPurchaseSheet> createState() => _AddPurchaseSheetState();
}

class _AddPurchaseSheetState extends ConsumerState<AddPurchaseSheet> {
  final _supplierController = TextEditingController();
  final _searchController = TextEditingController();
  String _query = '';

  /// Carrinho: id do produto → quantidade em MILÉSIMOS.
  final Map<String, int> _cart = {};

  /// Validade opcional por item do carrinho (lote FIFO).
  final Map<String, DateTime?> _expiryByProduct = {};

  /// Catálogo por id — evita busca O(n) a cada interação do carrinho.
  Map<String, Product> _productsById = const {};

  // Padrão: M-Pesa (dinheiro móvel dominante em Moçambique — mesmo padrão
  // do carrinho de Vendas).
  PaymentMethod _paymentMethod = PaymentMethod.mPesa;

  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _supplierController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Total em CENTAVOS inteiros (W4 + W11): qtd(milésimos) × preço ~/ 1000.
  int get _totalCents => _cart.entries.fold<int>(
        0,
        (sum, entry) =>
            sum +
            Quantity.lineTotal(
              entry.value,
              _productById(entry.key)?.purchasePriceCents ?? 0,
            ),
      );

  /// Contagem de itens em UNIDADES para exibição.
  int get _itemCount =>
      _cart.values.fold(0, (sum, quantity) => sum + quantity) ~/
      Quantity.milliFactor;

  Product? _productById(String id) => _productsById[id];

  void _add(Product product) {
    setState(() {
      _cart[product.id] =
          (_cart[product.id] ?? 0) + Quantity.milliFactor;
    });
  }

  void _addFraction(Product product) {
    setState(() {
      // Passo de 0,1 unidade (100 milésimos) para produtos por peso.
      _cart[product.id] = (_cart[product.id] ?? 0) + 100;
    });
  }

  void _remove(Product product) {
    final current = _cart[product.id] ?? 0;
    if (current <= 0) return;
    setState(() {
      if (current <= (product.vendaPorFracao ? 100 : Quantity.milliFactor)) {
        _cart.remove(product.id);
        _expiryByProduct.remove(product.id);
      } else {
        _cart[product.id] = current - (product.vendaPorFracao ? 100 : Quantity.milliFactor);
      }
    });
  }

  /// Define a quantidade exata (em milésimos) de um item do carrinho.
  void _setQuantity(Product product, int milli) {
    setState(() {
      if (milli <= 0) {
        _cart.remove(product.id);
        _expiryByProduct.remove(product.id);
      } else {
        _cart[product.id] = milli;
      }
    });
  }

  /// Diálogo de quantidade decimal (produtos por peso — ex.: 1,75).
  Future<void> _editFraction(Product product) async {
    final l10n = context.l10n;
    final controller = TextEditingController(
      text: Quantity.format(
        _cart[product.id] ?? 0,
        unitLabel: product.unitLabel,
        language: Formatters.currentLanguage,
      ).split(' ').first,
    );
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product.name),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: l10n.salesQuantityLabel,
            hintText: l10n.salesQuantityHint,
            suffixText: product.unitLabel,
          ),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(l10n.commonConfirm),
          ),
        ],
      ),
    );
    if (result == null) return;
    final milli = Quantity.parse(result);
    if (milli > 0) _setQuantity(product, milli);
  }

  /// Abre o seletor de data de validade do item (lote FIFO).
  Future<void> _pickExpiry(Product product) async {
    final l10n = context.l10n;
    final current = _expiryByProduct[product.id];
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 3650)),
      helpText: l10n.purchasesExpiryHelp,
    );
    if (picked == null || !mounted) return;
    setState(() => _expiryByProduct[product.id] = picked);
  }

  /// Remove a validade definida (produto não perecível).
  void _clearExpiry(Product product) {
    setState(() => _expiryByProduct.remove(product.id));
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
          unitPriceCents: product.purchasePriceCents,
          // W11: validade opcional — o lote FIFO da entrada nasce com ela.
          expiryDate: _expiryByProduct[product.id],
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
      totalAmountCents: _totalCents,
      paymentMethod: _paymentMethod,
      dateTime: DateTime.now(),
    );

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      // ProcessPurchaseUseCase registra a compra, cria os lotes FIFO,
      // aumenta o estoque e lança a saída no caixa.
      await ref.read(processPurchaseUseCaseProvider).call(purchase);

      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n.purchasesRegistered(Formatters.currency(purchase.totalAmountCents)),
          ),
        ),
      );
    } on ProductNotFoundException catch (error) {
      setState(() {
        _error = l10n.purchasesProductNotFound(error.productId);
      });
    } catch (error, stackTrace) {
      CrashReporting.capture(
        error,
        stackTrace,
        hint: 'Erro ao registrar compra',
      );
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
                    title: l10n.purchasesNoProductsTitle,
                    subtitle: l10n.purchasesNoProductsSubtitle,
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (context, index) => _CartProductRow(
                    product: filtered[index],
                    quantity: _cart[filtered[index].id] ?? 0,
                    expiry: _expiryByProduct[filtered[index].id],
                    onAdd: () => _add(filtered[index]),
                    onAddFraction: () => _addFraction(filtered[index]),
                    onRemove: () => _remove(filtered[index]),
                    onEdit: () => _editFraction(filtered[index]),
                    onPickExpiry: () => _pickExpiry(filtered[index]),
                    onClearExpiry: () => _clearExpiry(filtered[index]),
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
                // Forma de pagamento do fornecedor (mesmo padrão de Vendas).
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
                    // Total do carrinho em destaque (22) — FittedBox
                    // defensivo: valores extremos ENCOLHEM para caber em vez
                    // de truncar/estourar o rodapé em telas estreitas.
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          Formatters.currency(_totalCents),
                          maxLines: 1,
                          textAlign: TextAlign.end,
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
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

/// Linha do produto no carrinho de compra com stepper de quantidade e
/// VALIDADE opcional (lote FIFO).
class _CartProductRow extends StatelessWidget {
  const _CartProductRow({
    required this.product,
    required this.quantity,
    required this.expiry,
    required this.onAdd,
    required this.onAddFraction,
    required this.onRemove,
    required this.onEdit,
    required this.onPickExpiry,
    required this.onClearExpiry,
  });

  final Product product;
  final int quantity;
  final DateTime? expiry;
  final VoidCallback onAdd;
  final VoidCallback onAddFraction;
  final VoidCallback onRemove;
  final VoidCallback onEdit;
  final VoidCallback onPickExpiry;
  final VoidCallback onClearExpiry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isWeight = product.vendaPorFracao;

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
                    '${Formatters.currency(product.purchasePriceCents)} · '
                    '${l10n.purchasesStockLabel(
                      Quantity.toUnits(product.stockQuantity).round(),
                      l10n.commonUnits,
                    )}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  // Validade definida (lote FIFO da entrada).
                  if (expiry != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.event_available_outlined,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${l10n.purchasesExpiryLabel} '
                            '${Formatters.date(expiry!)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: onClearExpiry,
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Icon(
                              Icons.close,
                              size: 13,
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.event_outlined, size: 18),
                      tooltip: l10n.purchasesExpiryAdd,
                      onPressed: onPickExpiry,
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
                          InkWell(
                            onTap: isWeight ? onEdit : null,
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 8,
                              ),
                              child: Text(
                                Quantity.format(
                                  quantity,
                                  unitLabel: isWeight ? product.unitLabel : null,
                                  language: Formatters.currentLanguage,
                                ),
                                textAlign: TextAlign.center,
                                style: theme.textTheme.labelLarge,
                              ),
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.add, size: 18),
                            onPressed: isWeight ? onAddFraction : onAdd,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
