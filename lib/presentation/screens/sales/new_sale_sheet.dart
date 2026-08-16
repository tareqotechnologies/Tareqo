import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/ids.dart';
import '../../../core/utils/quantity.dart';
import '../../../core/utils/scale_barcode.dart';
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
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/barcode_scan_sheet.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/payment_method_picker.dart';
import '../../widgets/product_image.dart';
import '../../widgets/search_field.dart';
import '../../widgets/smart_amount.dart';
import '../../../core/observability/crash_reporting.dart';
import '../../../data/services/offline_sync_service.dart';

/// Carrinho de nova venda: seleciona produtos, define quantidades
/// (inteiras ou por peso, com decimais), lê códigos de barras (balanças
/// etiquetadoras 20PPPPPWWWWW e PLUs), escolhe a forma de pagamento e
/// confirma via [ProcessSaleUseCase].
///
/// W11: TODA quantidade no carrinho vive em MILÉSIMOS de unidade
/// (1000 = 1 unidade/kg) — mesma convenção do domínio e do banco.
class NewSaleSheet extends ConsumerStatefulWidget {
  const NewSaleSheet({super.key});

  @override
  ConsumerState<NewSaleSheet> createState() => _NewSaleSheetState();
}

class _NewSaleSheetState extends ConsumerState<NewSaleSheet> {
  final _searchController = TextEditingController();
  final _barcodeController = TextEditingController();
  String _query = '';
  String? _barcodeError;

  /// Carrinho: id do produto → quantidade em MILÉSIMOS.
  final Map<String, int> _cart = {};

  /// Catálogo por id — evita busca O(n) a cada interação do carrinho.
  Map<String, Product> _productsById = const {};

  // Padrão: M-Pesa (dinheiro móvel dominante em Moçambique).
  PaymentMethod _paymentMethod = PaymentMethod.mPesa;
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _searchController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  // Total do carrinho em CENTAVOS inteiros (W4 + W11): cada item é
  // `qtd(milésimos) × preço em centavos ~/ 1000` — soma exata.
  int get _totalCents => _cart.entries.fold<int>(
        0,
        (sum, entry) =>
            sum +
            Quantity.lineTotal(
              entry.value,
              _productById(entry.key)?.salePriceCents ?? 0,
            ),
      );

  /// Contagem de itens em UNIDADES (milésimos ÷ 1000) para exibição.
  int get _itemCount =>
      _cart.values.fold(0, (sum, quantity) => sum + quantity) ~/
      Quantity.milliFactor;

  Product? _productById(String id) => _productsById[id];

  void _add(Product product) {
    final current = _cart[product.id] ?? 0;
    if (current < product.stockQuantity) {
      setState(() {
        // 1 unidade inteira (1000 milésimos).
        _cart[product.id] = current + Quantity.milliFactor;
      });
    }
  }

  void _addFraction(Product product) {
    final current = _cart[product.id] ?? 0;
    if (current < product.stockQuantity) {
      setState(() {
        // Passo de 0,1 unidade (100 milésimos) para produtos por peso.
        _cart[product.id] = current + 100;
      });
    }
  }

  void _remove(Product product) {
    final current = _cart[product.id] ?? 0;
    if (current <= 0) return;
    setState(() {
      if (current <= (product.vendaPorFracao ? 100 : Quantity.milliFactor)) {
        _cart.remove(product.id);
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
      } else {
        _cart[product.id] = math.min(milli, product.stockQuantity);
      }
    });
  }

  /// Abre o diálogo de quantidade decimal (produtos por peso — ex.: 1,75).
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
        content: AppTextField(
          controller: controller,
          autofocus: true,
          label: l10n.salesQuantityLabel,
          hintText: l10n.salesQuantityHint,
          suffixText: product.unitLabel,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonCancel),
          ),
          // AppButton (design system ultra-clean): altura 48, cantos 12,
          // texto w400 — a confirmação segue o padrão dos diálogos.
          AppButton.primary(
            onPressed: () => Navigator.of(context).pop(controller.text),
            label: l10n.commonConfirm,
          ),
        ],
      ),
    );
    if (result == null) return;
    final milli = Quantity.parse(result);
    if (milli > 0) _setQuantity(product, milli);
  }

  /// Intercepta leituras de código de barras (scanner USB tipo teclado ou
  /// digitação manual) e preenche o carrinho:
  /// - `20PPPPPWWWWW` (balança etiquetadora) → busca o produto pelo PLU,
  ///   deriva a fração de peso do valor total ÷ preço unitário;
  /// - outro código numérico → busca pelo campo `code` (PLU) e adiciona
  ///   1 unidade.
  Future<void> _handleBarcode(String raw) async {
    final l10n = context.l10n;
    final digits = raw.trim().replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return;

    // Só produtos ATIVOS são vendáveis (desativado some do PDV — o
    // servidor também nega via lock_products_or_raise).
    final products =
        (ref.read(productsProvider).value ?? const <Product>[])
            .where((product) => product.isActive)
            .toList();

    // 1) Formato de balança: 20 + 5 dígitos do produto + 5 dígitos do valor.
    final scale = ScaleBarcode.tryParse(digits);
    if (scale != null) {
      // Busca com chave NORMALIZADA: a balança imprime o PLU com 5 dígitos
      // ("00123") e o cadastro guarda como digitado ("123") — lookupKey
      // remove zeros à esquerda para casar as duas formas.
      final scaleKey = ScaleBarcode.lookupKey(scale.productCode);
      final scaleProduct = products
          .where((p) => ScaleBarcode.lookupKey(p.code) == scaleKey)
          .firstOrNull;
      // Só INTERCEPTA como pesagem quando o PLU resolve para um produto
      // venda_por_fracao. Se o produto não existe ou não vende por peso,
      // NÃO é um código de balança confiável (ex.: um EAN-12 comum que
      // por acaso comece com '20') — cai no fluxo normal de código abaixo
      // em vez de rejeitar a leitura.
      if (scaleProduct != null && scaleProduct.vendaPorFracao) {
        final quantityMilli = ScaleBarcode.weightMilliUnits(
          scale,
          scaleProduct.salePriceCents,
        );
        if (quantityMilli <= 0) {
          setState(() => _barcodeError = l10n.salesBarcodeInvalid);
          return;
        }
        // Nunca ultrapassa o estoque disponível.
        final current = _cart[scaleProduct.id] ?? 0;
        final capped = math.min(
          current + quantityMilli,
          scaleProduct.stockQuantity,
        );
        if (capped <= current) {
          setState(() => _barcodeError = l10n.salesStockLimit(scaleProduct.name));
          return;
        }
        setState(() {
          _cart[scaleProduct.id] = capped;
          _barcodeController.clear();
          _barcodeError = null;
        });
        return;
      }
    }

    // 2) Código simples (PLU ou id) — adiciona 1 unidade. Compara o PLU
    // também com a chave normalizada ("00123" lido ≡ "123" cadastrado).
    final digitsKey = ScaleBarcode.lookupKey(digits);
    final product = products
        .where(
          (p) =>
              p.id == raw.trim() ||
              p.code == digits ||
              ScaleBarcode.lookupKey(p.code) == digitsKey,
        )
        .firstOrNull;
    if (product == null) {
      // Um código de balança legítimo cujo PLU não casa com nenhum
      // produto de peso cai aqui sem produto — mensagem genérica.
      setState(() => _barcodeError = l10n.salesBarcodeNotFound);
      return;
    }
    final current = _cart[product.id] ?? 0;
    if (current >= product.stockQuantity) {
      setState(() => _barcodeError = l10n.salesStockLimit(product.name));
      return;
    }
    setState(() {
      _cart[product.id] = current + Quantity.milliFactor;
      _barcodeController.clear();
      _barcodeError = null;
    });
  }

  Future<void> _openScanner() async {
    final code = await showBarcodeScanner(context);
    if (code != null && code.isNotEmpty) await _handleBarcode(code);
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
      // O ProcessSaleUseCase registra a venda, baixa o estoque em FIFO por
      // lotes e lança a entrada no caixa — uma única porta para o fluxo.
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
    } on OfflineEnqueuedException {
      // Sem conexão: a venda foi ENFILEIRADA (outbox) — fecha o balcão e
      // avisa que será sincronizada (o banner do dashboard mostra a fila).
      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(l10n.syncOfflineSaved)));
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
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: SearchField(
              controller: _searchController,
              hintText: l10n.salesSearchProducts,
              onChanged: (value) => setState(() => _query = value.trim()),
            ),
          ),
          // Campo de código de barras: scanners USB tipo teclado digitam o
          // código e o Enter cai aqui (interceptado em _handleBarcode);
          // leitura por câmera via botão (mobile_scanner).
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
            child: Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _barcodeController,
                    textInputAction: TextInputAction.done,
                    onSubmitted: _handleBarcode,
                    isDense: true,
                    label: l10n.salesBarcodeLabel,
                    hintText: '20 12345 00175',
                    prefixIcon: Icons.qr_code_scanner,
                    errorText: _barcodeError,
                  ),
                ),
                if (_supportsCameraScan) ...[
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: l10n.salesBarcodeScan,
                    onPressed: _openScanner,
                    icon: const Icon(Icons.photo_camera_outlined),
                  ),
                ],
              ],
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
                // Só produtos ATIVOS (desativado não pode ser vendido — o
                // servidor também nega via lock_products_or_raise).
                final active = all
                    .where((product) => product.isActive)
                    .toList();
                // Query NORMALIZADO para minúsculas (mesmo padrão da busca
                // de Produtos): sem isso, digitar 'CANETA' não achava o
                // produto no balcão.
                final query = _query.toLowerCase();
                final filtered = _query.isEmpty
                    ? active
                    : active
                          .where(
                            (product) =>
                                product.name.toLowerCase().contains(query) ||
                                product.code.toLowerCase().contains(query),
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
                    onAddFraction: () => _addFraction(filtered[index]),
                    onRemove: () => _remove(filtered[index]),
                    onEdit: () => _editFraction(filtered[index]),
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
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 16),
            // O rodapé é COMPACTO (alturas calibradas) para caber junto com
            // o catálogo mesmo em sheets baixos/paisagem — o Expanded do
            // catálogo é o que encolhe primeiro.
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Forma de pagamento: abas segmentadas + lista com radio
                // (design system 2026 — igual ao app de referência).
                PaymentMethodPicker(
                  value: _paymentMethod,
                  onChanged: (method) =>
                      setState(() => _paymentMethod = method),
                ),
                const SizedBox(height: 8),
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
                    // Total do carrinho em destaque VERDE (22) — FittedBox
                    // defensivo: valores extremos ENCOLHEM para caber em vez
                    // de truncar/estourar o rodapé em telas estreitas.
                    // SmartAmount: o valor encolhe para SEMPRE caber.
                    Flexible(
                      child: SmartAmount(
                        cents: _totalCents,
                        alignment: Alignment.centerRight,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _error!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                // AppButton ultra-clean: altura 48, cantos 12, texto w400.
                AppButton.primary(
                  label: l10n.salesConfirm,
                  onPressed: _cart.isEmpty || _isSubmitting ? null : _confirm,
                  icon: _isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Leitura por câmera disponível apenas onde o mobile_scanner suporta
  /// (Android/iOS/web — não há câmera confiável em desktop Windows).
  static bool get _supportsCameraScan =>
      !kIsWeb ? Platform.isAndroid || Platform.isIOS : true;
}

/// Linha do produto no carrinho com stepper de quantidade.
///
/// Produtos por PESO ([Product.vendaPorFracao]) exibem a fração com a
/// unidade (ex.: "1,75 kg") e permitem edição decimal precisa; produtos
/// normais usam o stepper de unidades inteiras.
class _CartProductRow extends StatelessWidget {
  const _CartProductRow({
    required this.product,
    required this.quantity,
    required this.onAdd,
    required this.onAddFraction,
    required this.onRemove,
    required this.onEdit,
  });

  final Product product;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onAddFraction;
  final VoidCallback onRemove;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final outOfStock = product.stockQuantity == 0;
    final soldOut = quantity >= product.stockQuantity;
    final isWeight = product.vendaPorFracao;

    // AppCard (design system ultra-clean): radius 12, borda 0.5px, flat —
    // o esgotado recebe fundo esmaecido via `color` (estado especial).
    return AppCard(
      color: outOfStock
          ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
          : null,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
          children: [
            // Foto do produto (fallback: ícone) — imagem cadastrada,
            // URL do Supabase Storage ou arquivo local.
            ProductImage(imagePath: product.imagePath),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nome COMPLETO do produto no carrinho — quebra em
                  // linhas quando necessário (nada de truncar nomes).
                  Text(
                    product.name,
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
                              '${Quantity.format(product.stockQuantity, unitLabel: isWeight ? product.unitLabel : null, language: Formatters.currentLanguage)}'
                              '${isWeight ? '' : ' ${l10n.commonUnits}'}',
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
                      onPressed: soldOut ? null : (isWeight ? onAddFraction : onAdd),
                    ),
                  ],
                ),
            ),
        ],
      ),
    );
  }
}
