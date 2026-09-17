import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/utils/app_clock.dart';
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
import '../../widgets/dialogs.dart';
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
        _cart[product.id] =
            current - (product.vendaPorFracao ? 100 : Quantity.milliFactor);
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
    final result = await showInputDialog(
      context,
      title: product.name,
      label: l10n.salesQuantityLabel,
      hintText: l10n.salesQuantityHint,
      suffixText: product.unitLabel,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      initialValue: Quantity.format(
        _cart[product.id] ?? 0,
        unitLabel: product.unitLabel,
        language: Formatters.currentLanguage,
      ).split(' ').first,
      confirmLabel: l10n.commonConfirm,
    );
    if (result == null) return;
    final milli = Quantity.parse(result);
    if (milli > 0) _setQuantity(product, milli);
  }

  /// Intercepta leituras de código de barras (scanner USB tipo teclado ou
  /// digitação manual) e preenche o carrinho:
  /// - `20PPPPPWWWWW` (balança etiquetadora) → busca o produto pelo PLU,
  /// deriva a fração de peso do valor total ÷ preço unitário;
  /// - outro código numérico → busca pelo campo `code` (PLU) e adiciona
  /// 1 unidade.
  Future<void> _handleBarcode(String raw) async {
    final l10n = context.l10n;
    final digits = raw.trim().replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return;

    // Só produtos ATIVOS são vendáveis (desativado some do PDV — o
    // servidor também nega via lock_products_or_raise).
    final products = (ref.read(productsProvider).value ?? const <Product>[])
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
          setState(
            () => _barcodeError = l10n.salesStockLimit(scaleProduct.name),
          );
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
      // Caixa que registrou a venda — base das comissões/metas do add-on
      // de funcionários (a coluna user_id do Supabase também é preenchida
      // pelo trigger set_tenant_user_id). Vazio = sem atribuição.
      userId: user?.id ?? '',
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
    // Resumo de hoje no cabeçalho (canvas V3): "Hoje · N vendas · total".
    // Mesmo critério do resumo da lista: vendas anuladas não contam.
    final salesAsync = ref.watch(salesListProvider);
    final now = AppClock.now();
    final today = DateTime(now.year, now.month, now.day);
    var todayCents = 0;
    var todayCount = 0;
    for (final sale in salesAsync.value ?? const <Sale>[]) {
      if (sale.status == SaleStatus.cancelled) continue;
      final day = DateTime(
        sale.dateTime.year,
        sale.dateTime.month,
        sale.dateTime.day,
      );
      if (day == today) {
        todayCents += sale.totalAmountCents;
        todayCount++;
      }
    }
    // Mantém o catálogo por id em sincronia com o provider (recarrega
    // junto com a lista — o carrinho continua válido).
    _productsById = {
      for (final product in productsAsync.value ?? const <Product>[])
        product.id: product,
    };

    // Fullscreen (V3): a sheet cobre o ecrã — o rodapé fica FIXO (total +
    // forma de pagamento + confirmar) e o corpo (zona de scanner + busca +
    // catálogo) rola num ÚNICO scroll. Em ecrãs baixos/paisagem o corpo
    // rola em vez de estourar — sem "bottom overflowed".
    final scannerZone = Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 10),
      child: _ScannerZone(
        barcodeController: _barcodeController,
        barcodeError: _barcodeError,
        onSubmitted: _handleBarcode,
        onScan: _supportsCameraScan ? _openScanner : null,
      ),
    );
    final searchField = Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      child: SearchField(
        controller: _searchController,
        hintText: l10n.salesSearchProducts,
        onChanged: (value) => setState(() => _query = value.trim()),
      ),
    );

    return Column(
      children: [
        AppSheetHeader(
          title: l10n.salesTitle,
          subtitle:
              '${l10n.periodToday} · '
              '${l10n.salesPdvCount(todayCount)} · '
              '${Formatters.currency(todayCents)}',
        ),
        Expanded(
          child: productsAsync.when(
            loading: () => ListView(
              children: [
                scannerZone,
                searchField,
                const SizedBox(height: 48),
                const Center(child: CircularProgressIndicator()),
              ],
            ),
            error: (_, _) => ListView(
              children: [
                scannerZone,
                searchField,
                const SizedBox(height: 48),
                Center(
                  child: Text(
                    l10n.productsLoadError,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            data: (all) {
              // Só produtos ATIVOS (desativado não pode ser vendido — o
              // servidor também nega via lock_products_or_raise).
              final active = all.where((product) => product.isActive).toList();
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

              // Corpo rolável único: scanner + busca + conteúdo (estado
              // vazio OU catálogo) — em ecrãs baixos tudo rola junto, o
              // rodapé fica fixo e nada estoura.
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: scannerZone),
                  SliverToBoxAdapter(child: searchField),
                  if (filtered.isEmpty)
                    // SliverFillRemaining: o estado vazio ocupa o espaço
                    // restante e fica centralizado — SEMPRE construído (não
                    // some por ser filho preguiçoso de uma lista) e sem
                    // overflow em ecrãs baixos.
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        icon: Icons.search_off,
                        title: l10n.salesNoProductsTitle,
                        subtitle: l10n.salesNoProductsSubtitle,
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildListDelegate([
                        // Pills do carrinho (canvas V3) — no topo do scroll
                        // com o catálogo: resumo visível sem altura fixa.
                        if (_cart.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 6),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    l10n.salesCartSection(_cart.length),
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                Flexible(
                                  child: SmartAmount(
                                    cents: _totalCents,
                                    alignment: Alignment.centerRight,
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          for (final entry in _cart.entries) ...[
                            if (_productById(entry.key)
                                case final product?) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                child: _CartPill(
                                  product: product,
                                  quantity: entry.value,
                                ),
                              ),
                              const SizedBox(height: 6),
                            ],
                          ],
                          const SizedBox(height: 10),
                        ],
                        for (final product in filtered) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: _CartProductRow(
                              product: product,
                              quantity: _cart[product.id] ?? 0,
                              onAdd: () => _add(product),
                              onAddFraction: () => _addFraction(product),
                              onRemove: () => _remove(product),
                              onEdit: () => _editFraction(product),
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                      ]),
                    ),
                ],
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
                onChanged: (method) => setState(() => _paymentMethod = method),
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
                  // Total do carrinho em destaque (22) — SmartAmount:
                  // o valor encolhe para SEMPRE caber, sem truncar nem
                  // estourar o rodapé em telas estreitas.
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
    );
  }

  /// Leitura por câmera disponível apenas onde o mobile_scanner suporta
  /// (Android/iOS/web — não há câmera confiável em desktop Windows).
  static bool get _supportsCameraScan =>
      !kIsWeb ? Platform.isAndroid || Platform.isIOS : true;
}

/// Zona de scanner (V3) — área destacada no topo do PDV: botão grande de
/// câmera + campo de código de barras manual (scanners USB tipo teclado
/// digitam direto e o Enter cai no [onSubmitted]).
class _ScannerZone extends StatelessWidget {
  const _ScannerZone({
    required this.barcodeController,
    required this.barcodeError,
    required this.onSubmitted,
    required this.onScan,
  });

  final TextEditingController barcodeController;
  final String? barcodeError;
  final ValueChanged<String> onSubmitted;
  final VoidCallback? onScan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // Ícone em container circular tingido — mesma linguagem dos
              // cards de alerta/módulo.
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.qr_code_scanner,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.salesBarcodeLabel,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.salesBarcodeHint,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (onScan != null) ...[
                const SizedBox(width: 8),
                // Botão grande de câmera (48px — alvo de toque confortável).
                IconButton.filled(
                  tooltip: l10n.salesBarcodeScan,
                  onPressed: onScan,
                  icon: const Icon(Icons.photo_camera_outlined, size: 20),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          AppTextField(
            controller: barcodeController,
            textInputAction: TextInputAction.done,
            onSubmitted: onSubmitted,
            isDense: true,
            label: l10n.salesBarcodeLabel,
            hintText: '20 12345 00175',
            prefixIcon: Icons.qr_code_scanner,
            errorText: barcodeError,
          ),
        ],
      ),
    );
  }
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

    // Card premium (estilo Apple): cantos 18 + superfície elevada — o
    // esgotado recebe fundo esmaecido via `color` (estado especial).
    return AppCard(
      elevated: true,
      borderRadius: const BorderRadius.all(Radius.circular(18)),
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: outOfStock ? theme.colorScheme.outline : null,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  outOfStock
                      ? l10n.commonSoldOut
                      : '${Formatters.currency(product.salePriceCents)} · '
                            '${Quantity.format(product.stockQuantity, unitLabel: isWeight ? product.unitLabel : null, language: Formatters.currentLanguage)}'
                            '${isWeight ? '' : ' ${l10n.commonUnits}'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
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
                        style: theme.textTheme.labelMedium,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.add, size: 18),
                    onPressed: soldOut
                        ? null
                        : (isWeight ? onAddFraction : onAdd),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Pill do carrinho (canvas V3) — resumo display-only: bubble de
/// quantidade, nome + preço unitário e total da linha. A interação
/// (steppers, edição de fração) continua nas linhas do catálogo.
class _CartPill extends StatelessWidget {
  const _CartPill({required this.product, required this.quantity});

  final Product product;
  final int quantity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isWeight = product.vendaPorFracao;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          // Bubble de quantidade: "2×" em unidades; "1,75 kg" por peso.
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              isWeight
                  ? Quantity.format(
                      quantity,
                      unitLabel: product.unitLabel,
                      language: Formatters.currentLanguage,
                    )
                  : '${Quantity.format(quantity, language: Formatters.currentLanguage)}×',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '${Formatters.currency(product.salePriceCents)} '
                  '${isWeight ? product.unitLabel : l10n.commonUnits}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: SmartAmount(
              cents: Quantity.lineTotal(quantity, product.salePriceCents),
              alignment: Alignment.centerRight,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
