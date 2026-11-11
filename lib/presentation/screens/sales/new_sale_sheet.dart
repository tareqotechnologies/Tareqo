import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/ui/haptics.dart';
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
import '../../widgets/premium_decor.dart';
import '../../widgets/product_image.dart';
import '../../widgets/product_type_badge.dart';
import '../../widgets/search_field.dart';
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
  final _searchFocus = FocusNode();
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

  /// Modo foco (plano UI/UX — F4.1): a busca está focada — o catálogo
  /// recua (dim) e o carrinho, o conteúdo em progresso, fica em evidência.
  bool _searchFocused = false;

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(_onSearchFocusChanged);
  }

  void _onSearchFocusChanged() {
    if (!mounted) return;
    setState(() => _searchFocused = _searchFocus.hasFocus);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
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
      // Seleção relevante (Fase 3): toque de stepper confirma sem diálogo.
      Haptics.selection();
      setState(() {
        // 1 unidade inteira (1000 milésimos).
        _cart[product.id] = current + Quantity.milliFactor;
      });
    }
  }

  void _addFraction(Product product) {
    final current = _cart[product.id] ?? 0;
    if (current < product.stockQuantity) {
      Haptics.selection();
      setState(() {
        // Passo de 0,1 unidade (100 milésimos) para produtos por peso.
        _cart[product.id] = current + 100;
      });
    }
  }

  void _remove(Product product) {
    final current = _cart[product.id] ?? 0;
    if (current <= 0) return;
    Haptics.selection();
    final step = product.vendaPorFracao ? 100 : Quantity.milliFactor;
    final removingItem = current <= step;
    setState(() {
      if (removingItem) {
        _cart.remove(product.id);
      } else {
        _cart[product.id] = current - step;
      }
    });
    // Undo (plano UI/UX — Fase 1.3): esvaziar o item do carrinho é
    // destrutivo-REVERSÍVEL — o "Desfazer" devolve a quantidade exata
    // que havia antes do toque (respeitando o teto de estoque). Reduzir
    // 1 de N não abre undo (ação trivial, repita o "+").
    if (removingItem && mounted) {
      final l10n = context.l10n;
      showUndoSnackBar(
        context,
        message: l10n.salesCartItemRemoved(product.name),
        undoLabel: l10n.commonUndo,
        onUndo: () {
          if (!mounted) return;
          setState(() {
            _cart[product.id] = math.min(current, product.stockQuantity);
          });
        },
      );
    }
  }

  /// Define a quantidade exata (em milésimos) de um item do carrinho.
  void _setQuantity(Product product, int milli) {
    setState(() {
      if (milli <= 0) {
        _cart.remove(product.id);
      } else {
        // Produto por UNIDADE: fração não é vendável — arredonda para
        // baixo até unidades inteiras (digitar 1,5 numa caneta vende 1;
        // 0,4 remove o item). Produtos por peso aceitam a fração digitada.
        var value = milli;
        if (!product.vendaPorFracao) {
          value = (value ~/ Quantity.milliFactor) * Quantity.milliFactor;
        }
        if (value <= 0) {
          _cart.remove(product.id);
        } else {
          _cart[product.id] = math.min(value, product.stockQuantity);
        }
      }
    });
  }

  /// Abre o diálogo de quantidade digitada — atalho de balcão para TODOS
  /// os produtos (antes só os por peso tinham edição): vender 25 canetas
  /// são 2 toques (tap + Enter) em vez de 25 no "+". Produtos por peso
  /// usam teclado decimal; por unidade, teclado inteiro (fração é
  /// arredondada para baixo em [_setQuantity]).
  Future<void> _editQuantity(Product product) async {
    final l10n = context.l10n;
    final isWeight = product.vendaPorFracao;
    final result = await showInputDialog(
      context,
      title: product.name,
      label: l10n.salesQuantityLabel,
      hintText: l10n.salesQuantityHint,
      suffixText: product.unitLabel,
      keyboardType: TextInputType.numberWithOptions(decimal: isWeight),
      initialValue: Quantity.format(
        _cart[product.id] ?? 0,
        unitLabel: product.unitLabel,
        language: Formatters.currentLanguage,
      ).split(' ').first,
      confirmLabel: l10n.commonConfirm,
    );
    if (result == null) return;
    final milli = Quantity.parse(result, language: Formatters.currentLanguage);
    if (milli > 0) _setQuantity(product, milli);
    // Foco de volta na busca: digitação de PLU em sequência fica fluida
    // (atalho de balcão — Enter → adiciona → Enter → adiciona).
    if (mounted) _searchFocus.requestFocus();
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

    // Só produtos ATIVOS e de papel VENDÁVEL são vendáveis no PDV
    // (desativado some; matéria-prima/embalagem não vão ao balcão)
    // — o servidor também nega desativados via lock_products_or_raise.
    final products = (ref.read(productsProvider).value ?? const <Product>[])
        .where((product) => product.isActive && product.type.isSellable)
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

  /// Atalho de balcão: Enter no campo de BUSCA dá quick-add.
  ///
  /// Operador digita o PLU/código do produto e aperta Enter — sem tocar no
  /// catálogo. Reaproveita o pipeline COMPLETO de leitura de código ([_handleBarcode]):
  /// balança `20PPPPPWWWWW`, PLU com zeros à esquerda, caps de estoque e
  /// mensagens de erro — nada de regra duplicada. Texto que NÃO resolve
  /// produto é ignorado silenciosamente: quem digitou estava buscando por
  /// nome (o filtro em tempo real continua respondendo) e o Enter vira no-op
  /// em vez de lançar "produto não encontrado" para uma busca legítima.
  Future<void> _handleSearchSubmit(String raw) async {
    final digits = raw.trim();
    if (digits.isEmpty) return;
    // Candidate a código: só dígitos (PLU/EAN). Nome com letras nunca
    // dispara o pipeline de barcode.
    if (digits.contains(RegExp(r'\D'))) return;

    // Mesmo papel VENDÁVEL do catálogo: o quick-add por PLU nunca resolve
    // matéria-prima/embalagem (que não são vendidas no balcão).
    final active = (ref.read(productsProvider).value ?? const <Product>[])
        .where((product) => product.isActive && product.type.isSellable);
    // Resolve ANTES de delegar: se o texto não casa com nenhum produto
    // (nem por id, nem por código), é busca por nome — sai sem tocar nada.
    final digitsKey = ScaleBarcode.lookupKey(digits);
    final resolves = active.any(
      (p) =>
          p.id == digits ||
          p.code == digits ||
          ScaleBarcode.lookupKey(p.code) == digitsKey,
    );
    if (!resolves) return;

    await _handleBarcode(digits);
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
      // Confirmação tátil da conclusão (antes do pop: imediato, sem atraso).
      Haptics.success();

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
      Haptics.error();
      final product = _productById(error.productId);
      setState(() {
        final nameSuffix = product != null
            ? ' ${l10n.salesStockFor(product.name)}'
            : '';
        _error = l10n.salesInsufficientStock(nameSuffix, error.available);
      });
    } on ProductNotFoundException catch (error) {
      Haptics.error();
      setState(() {
        _error = l10n.salesProductNotFound(error.productId);
      });
    } catch (error, stackTrace) {
      Haptics.error();
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
    // Mesma margem de página das restantes telas (16 → 24 → 32 por largura).
    final hPad = AppSpacing.pagePaddingForWidth(
      MediaQuery.sizeOf(context).width,
    );
    final scannerZone = Padding(
      padding: EdgeInsets.fromLTRB(hPad, AppSpacing.md, hPad, AppSpacing.xs),
      child: _ScannerZone(
        barcodeController: _barcodeController,
        barcodeError: _barcodeError,
        onSubmitted: _handleBarcode,
        onScan: _supportsCameraScan ? _openScanner : null,
      ),
    );
    final searchField = Padding(
      padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 0),
      child: SearchField(
        controller: _searchController,
        focusNode: _searchFocus,
        hintText: l10n.salesSearchProducts,
        onChanged: (value) => setState(() => _query = value.trim()),
        // Enter no campo de busca: PLU/código → quick-add (atalho de
        // balcão); busca por nome → filtro em tempo real (já feito no
        // onChanged), Enter vira no-op.
        onSubmitted: _handleSearchSubmit,
      ),
    );

    // Modo foco (F4.1): com a busca focada, o que NÃO é o carrinho recua
    // 40% (dim) — deferência ao conteúdo: a venda em progresso é o
    // protagonista. O painel do carrinho fica a 100%; o estado vazio NÃO
    // escurece (é a resposta à busca). 240ms, e estático com movimento
    // reduzido.
    Widget focusDim(Widget child, {bool keepFocus = false}) {
      if (!_searchFocused) return child;
      const dimmedOpacity = 0.6;
      final opacity = keepFocus ? 1.0 : dimmedOpacity;
      if (MediaQuery.disableAnimationsOf(context)) {
        return Opacity(opacity: opacity, child: child);
      }
      return AnimatedOpacity(
        opacity: opacity,
        duration: AppDurations.normal,
        child: child,
      );
    }

    return Column(
      children: [
        SheetHeader(
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
                const SizedBox(height: AppSpacing.huge),
                const Center(child: CircularProgressIndicator()),
              ],
            ),
            error: (_, _) => ListView(
              children: [
                scannerZone,
                searchField,
                const SizedBox(height: AppSpacing.huge),
                Center(
                  child: Text(
                    l10n.productsLoadError,
                    style: AppTypography.bodyMedium.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            data: (all) {
              // Só produtos ATIVOS e de papel VENDÁVEL (desativado não pode
              // ser vendido; matéria-prima/embalagem não vão ao balcão — o
              // servidor também nega desativados via lock_products_or_raise).
              final active = all
                  .where(
                    (product) => product.isActive && product.type.isSellable,
                  )
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
              // Há produtos, mas NENHUM vendável (matéria-prima/embalagem)
              // → estado vazio explicativo em vez de "sem produtos".
              final roleOnly =
                  active.isEmpty && all.any((product) => product.isActive);

              // Corpo rolável único: scanner + busca + carrinho + catálogo —
              // em ecrãs baixos tudo rola junto, o rodapé fica fixo e nada
              // estoura. O carrinho vive ACIMA do catálogo e continua
              // visível mesmo quando a busca não devolve resultados (a venda
              // em progresso nunca desaparece por causa de um filtro).
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: focusDim(scannerZone)),
                  SliverToBoxAdapter(child: searchField),
                  // Venda em progresso: UM grupo (cabeçalho + linhas) lido
                  // como um recibo. Nunca esmaece no modo foco: é o que está
                  // a ser construído.
                  if (_cart.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          hPad,
                          AppSpacing.sm,
                          hPad,
                          0,
                        ),
                        child: _CartPanel(
                          entries: [
                            for (final entry in _cart.entries)
                              if (_productById(entry.key) case final product?)
                                (product: product, quantity: entry.value),
                          ],
                        ),
                      ),
                    ),
                  if (filtered.isEmpty)
                    // SliverFillRemaining: o estado vazio ocupa o espaço
                    // restante e fica centralizado — SEMPRE construído (não
                    // some por ser filho preguiçoso de uma lista) e sem
                    // overflow em ecrãs baixos.
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.md),
                        child: EmptyState(
                          icon: roleOnly
                              ? Icons.category_outlined
                              : Icons.search_off,
                          title: roleOnly
                              ? l10n.salesNoSellableTitle
                              : l10n.salesNoProductsTitle,
                          subtitle: roleOnly
                              ? l10n.salesNoSellableSubtitle
                              : l10n.salesNoProductsSubtitle,
                        ),
                      ),
                    )
                  else
                    // Catálogo em cartões separados: 8px entre linhas — o
                    // respiro que faltava (antes as linhas encostavam umas às
                    // outras e liam-se como um bloco único).
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        hPad,
                        AppSpacing.sm,
                        hPad,
                        AppSpacing.lg,
                      ),
                      sliver: SliverList.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.xs),
                        itemBuilder: (context, index) {
                          final product = filtered[index];
                          return focusDim(
                            _CartProductRow(
                              product: product,
                              quantity: _cart[product.id] ?? 0,
                              onAdd: () => _add(product),
                              onAddFraction: () => _addFraction(product),
                              onRemove: () => _remove(product),
                              onEdit: () => _editQuantity(product),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        // Rodapé: total + forma de pagamento + confirmar.
        _Footer(
          paymentMethod: _paymentMethod,
          onPaymentMethodChanged: (method) =>
              setState(() => _paymentMethod = method),
          totalCents: _totalCents,
          itemCount: _itemCount,
          isSubmitting: _isSubmitting,
          error: _error,
          onConfirm: _cart.isEmpty || _totalCents == 0 || _isSubmitting
              ? null
              : _confirm,
        ),
      ],
    );
  }

  /// Leitura por câmera disponível apenas onde o mobile_scanner suporta
  /// (Android/iOS/web — não há câmera confiável em desktop Windows).
  static bool get _supportsCameraScan =>
      !kIsWeb ? Platform.isAndroid || Platform.isIOS : true;
}

/// Barra de leitura do balcão — uma linha só: o campo de código de barras
/// (scanner USB digita direto e o Enter cai no [onSubmitted]) e a ação de
/// câmera. O peso descritivo ficou fora: o rótulo do campo já diz o que é,
/// e a busca de produtos vive logo abaixo.
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
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    // Barra de leitura sem caixa dentro de caixa: o campo já tem contorno
    // próprio — a moldura extra anterior duplicava bordas e pesava o topo
    // do balcão. A câmera fica ao lado, alinhada ao topo do campo (o erro
    // inline cresce para baixo sem deslocar a ação).
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: AppTextField(
            controller: barcodeController,
            textInputAction: TextInputAction.done,
            onSubmitted: onSubmitted,
            isDense: true,
            label: l10n.salesBarcodeLabel,
            hintText: '20 12345 00175',
            prefixIcon: Icons.qr_code_scanner,
            errorText: barcodeError,
          ),
        ),
        if (onScan != null) ...[
          const SizedBox(width: AppSpacing.xs),
          // 48dp de alvo de toque (androidTapTargetGuideline) — a ação
          // de câmera é o segundo caminho de entrada da venda. O estilo
          // explícito garante o glifo claro sobre o azul: o
          // `iconButtonTheme` global fixa `foregroundColor` em tinta e
          // sobrescreveria o `onPrimary` padrão do `IconButton.filled`.
          IconButton.filled(
            style: IconButton.styleFrom(
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
            ),
            tooltip: l10n.salesBarcodeScan,
            onPressed: onScan,
            icon: Icon(
              Icons.photo_camera_outlined,
              size: AppSizes.iconMd,
              color: scheme.onPrimary,
            ),
          ),
        ],
      ],
    );
  }
}

/// Linha do produto no catálogo com stepper de quantidade.
///
/// Produtos por PESO ([Product.vendaPorFracao]) exibem a fração com a
/// unidade (ex.: "1,75 kg") e permitem edição decimal precisa;
/// produtos normais usam o stepper de unidades inteiras.
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
    // Estado por TEXTO, não só pela cor (daltónicos e leitores de ecrã):
    // mesma mensagem do alerta do dashboard/estoque (dashboardLowStock).
    final lowStock =
        !outOfStock &&
        product.stockQuantity <
            Quantity.lowStockThresholdUnits * Quantity.milliFactor;

    final scheme = theme.colorScheme;
    final active = quantity > 0;
    final metaColor = scheme.onSurfaceVariant;

    // Cartão do catálogo: imagem + nome + preço + meta (papel · stock) e o
    // stepper à direita. O preço usa o papel monetário de linha
    // ([AppTypography.amountInRow]) — o mesmo das listas de negócio — e o
    // cartão com quantidade ganha um contorno azul discreto que o liga ao
    // carrinho. O esgotado recua para o fundo neutro.
    final stockLabel = Quantity.format(
      product.stockQuantity,
      unitLabel: isWeight ? product.unitLabel : null,
      language: Formatters.currentLanguage,
    );

    return AppCard(
      borderRadius: AppRadius.lgAll,
      borderColor: active ? scheme.primary.withValues(alpha: 0.35) : null,
      color: outOfStock
          ? scheme.surfaceContainerHighest.withValues(alpha: 0.5)
          : null,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Foto do produto (fallback: ícone) — imagem cadastrada,
          // URL do Supabase Storage ou arquivo local.
          ProductImage(imagePath: product.imagePath, size: 56, radius: 14),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelLarge.copyWith(
                    color: outOfStock ? scheme.outline : scheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.micro),
                // Preço em destaque — é o número que o operador lê em voz
                // alta ao balcão.
                Text(
                  Formatters.currency(product.salePriceCents),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.amountInRow(
                    outOfStock ? scheme.outline : scheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.micro),
                // Papel + stock numa única linha de metadados. Wrap: com
                // escala de texto 2.0 a linha cresce em vez de cortar.
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.micro,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      productTypeLabel(context, product.type),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(color: metaColor),
                    ),
                    const _MetaDot(),
                    if (outOfStock)
                      Text(
                        l10n.commonSoldOut,
                        style: AppTypography.bodySmall.copyWith(
                          color: metaColor,
                        ),
                      )
                    else ...[
                      Text(
                        l10n.salesStockAvailable(
                          isWeight
                              ? stockLabel
                              : '$stockLabel ${l10n.commonUnits}',
                        ),
                        style: AppTypography.bodySmall.copyWith(
                          color: metaColor,
                        ),
                      ),
                      if (lowStock) ...[
                        const _MetaDot(),
                        Text(
                          l10n.dashboardLowStock,
                          style: AppTypography.bodySmall.copyWith(
                            color: metaColor,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (!outOfStock)
            _Stepper(
              quantity: quantity,
              isWeight: isWeight,
              unitLabel: product.unitLabel,
              soldOut: soldOut,
              onAdd: onAdd,
              onAddFraction: onAddFraction,
              onRemove: onRemove,
              onEdit: onEdit,
            ),
        ],
      ),
    );
  }
}

/// Separador discreto entre metadados ("Revenda · 10 un.").
///
/// Excluído da semântica: é pontuação visual, não conteúdo para o leitor
/// de ecrã (que anuncia cada texto separadamente).
class _MetaDot extends StatelessWidget {
  const _MetaDot();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Text(
        '·',
        style: AppTypography.bodySmall.copyWith(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }
}

/// Stepper da linha do catálogo — cápsula neutra em repouso e tingida de
/// azul quando o produto já está no carrinho: o estado da venda fica
/// óbvio sem gritar. Alvos de 48dp; tocar na quantidade abre a edição
/// digitada.
class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.quantity,
    required this.isWeight,
    required this.unitLabel,
    required this.soldOut,
    required this.onAdd,
    required this.onAddFraction,
    required this.onRemove,
    required this.onEdit,
  });

  final int quantity;
  final bool isWeight;
  final String unitLabel;
  final bool soldOut;
  final VoidCallback onAdd;
  final VoidCallback onAddFraction;
  final VoidCallback onRemove;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final active = quantity > 0;

    return Container(
      decoration: BoxDecoration(
        color: active ? scheme.primaryContainer : scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: active
              ? scheme.primary.withValues(alpha: 0.28)
              : PremiumDecor.hairline(scheme),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Sem visualDensity.compact: o alvo de toque efetivo tem que ser
          // ≥ 48dp (WCAG/androidTapTargetGuideline).
          IconButton(
            icon: const Icon(Icons.remove, size: 18),
            tooltip: l10n.a11yDecreaseQuantity,
            color: active ? scheme.primary : scheme.onSurfaceVariant,
            onPressed: quantity == 0 ? null : onRemove,
          ),
          InkWell(
            // Toque na quantidade: edição digitada para TODOS os produtos
            // (por peso: fração decimal; por unidade: inteiro). Atalho de
            // balcão — 25 canetas em 2 toques.
            onTap: onEdit,
            borderRadius: BorderRadius.circular(AppRadius.xs),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xxs,
                vertical: AppSpacing.xs,
              ),
              child: Text(
                Quantity.format(
                  quantity,
                  unitLabel: isWeight ? unitLabel : null,
                  language: Formatters.currentLanguage,
                ),
                textAlign: TextAlign.center,
                // O estado ativo já é lido na cápsula tingida e no "+";
                // o número fica na escala (12/500) nos dois estados.
                style: AppTypography.labelMedium.copyWith(
                  color: scheme.onSurface,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            tooltip: isWeight
                ? l10n.a11yAddFraction
                : l10n.a11yIncreaseQuantity,
            color: scheme.primary,
            onPressed: soldOut ? null : (isWeight ? onAddFraction : onAdd),
          ),
        ],
      ),
    );
  }
}

/// Linha do carrinho — produto que já está na venda: bolha de quantidade
/// (azul), nome, preço unitário + papel e total da linha em tinta.
class _CartPill extends StatelessWidget {
  const _CartPill({required this.product, required this.quantity});

  final Product product;
  final int quantity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isWeight = product.vendaPorFracao;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          // Bolha de quantidade: "2×" em unidades; "1,75 kg" por peso —
          // largura mínima fixa para os dois formatos alinharem em coluna.
          Container(
            constraints: const BoxConstraints(minWidth: 40, minHeight: 32),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              isWeight
                  ? Quantity.format(
                      quantity,
                      unitLabel: product.unitLabel,
                      language: Formatters.currentLanguage,
                    )
                  : '${Quantity.format(quantity, language: Formatters.currentLanguage)}×',
              textAlign: TextAlign.center,
              style: AppTypography.labelMedium.copyWith(
                color: scheme.onPrimary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelLarge.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.micro),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.micro,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      productTypeLabel(context, product.type),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const _MetaDot(),
                    Text(
                      Formatters.currency(product.salePriceCents),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            Formatters.currency(
              Quantity.lineTotal(quantity, product.salePriceCents),
            ),
            textAlign: TextAlign.right,
            style: AppTypography.amountInRow(scheme.onSurface),
          ),
        ],
      ),
    );
  }
}

/// Grupo do carrinho — cabeçalho e linhas no mesmo cartão tingido: a venda
/// em progresso lê-se como um recibo e distingue-se do catálogo.
class _CartPanel extends StatelessWidget {
  const _CartPanel({required this.entries});

  final List<({Product product, int quantity})> entries;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: AppRadius.lgAll,
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.18),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CartSummary(itemCount: entries.length),
          const SizedBox(height: AppSpacing.xs),
          // Fio de separação entre o rótulo e as linhas — o painel lê-se
          // como um recibo, não como uma pilha de widgets.
          Container(height: 1, color: scheme.primary.withValues(alpha: 0.12)),
          const SizedBox(height: AppSpacing.xxs),
          for (final entry in entries)
            _CartPill(product: entry.product, quantity: entry.quantity),
        ],
      ),
    );
  }
}

/// Cabeçalho do carrinho — contador de produtos distintos.
class _CartSummary extends StatelessWidget {
  const _CartSummary({required this.itemCount});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    return Row(
      children: [
        Icon(
          Icons.shopping_cart_outlined,
          size: AppSizes.iconSm,
          color: scheme.primary,
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            l10n.salesCartSection(itemCount),
            style: AppTypography.labelMedium.copyWith(color: scheme.onSurface),
          ),
        ),
      ],
    );
  }
}

/// Rodapé do PDV — total + forma de pagamento + confirmar.
///
/// Minimalista e profissional: separa a seleção (pagamento) do ação
/// final (confirmar), mantendo o total sempre visível e alinhado.
class _Footer extends StatelessWidget {
  const _Footer({
    required this.paymentMethod,
    required this.onPaymentMethodChanged,
    required this.totalCents,
    required this.itemCount,
    required this.isSubmitting,
    required this.error,
    required this.onConfirm,
  });

  final PaymentMethod paymentMethod;
  final ValueChanged<PaymentMethod> onPaymentMethodChanged;
  final int totalCents;
  final int itemCount;
  final bool isSubmitting;
  final String? error;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    final scheme = theme.colorScheme;
    final hPad = AppSpacing.pagePaddingForWidth(
      MediaQuery.sizeOf(context).width,
    );
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          top: BorderSide(color: PremiumDecor.hairline(scheme), width: 0.5),
        ),
      ),
      padding: EdgeInsets.fromLTRB(hPad, AppSpacing.sm, hPad, AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Forma de pagamento: seleção compacta e clara.
          PaymentMethodPicker(
            value: paymentMethod,
            onChanged: onPaymentMethodChanged,
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Padding(
                  // Alinha a contagem com a base do valor, sem competir
                  // com o número que fecha a venda.
                  padding: const EdgeInsets.only(bottom: AppSpacing.micro),
                  child: Text(
                    l10n.dashboardSaleItems(itemCount),
                    style: AppTypography.bodySmall.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Total em tinta (AA nos dois temas); o azul fica para a
              // ação de confirmar. É o número que fecha a venda.
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.commonTotal,
                    style: AppTypography.eyebrow(scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.micro),
                  Text(
                    Formatters.currency(totalCents),
                    style: AppTypography.heroAmount(scheme.onSurface),
                  ),
                ],
              ),
            ],
          ),
          if (error != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              error!,
              // Variante de TEXTO do erro (AA no escuro; `scheme.error`
              // é o tom base, para preenchimentos).
              style: AppTypography.bodySmall.copyWith(color: theme.expense),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          // Botão confirmar: sólido no azul oficial (sem gradiente) —
          // uma única ação primária no rodapé. Um spinner substitui o
          // check durante o envio.
          AppButton.primary(
            expanded: true,
            onPressed: totalCents == 0 || isSubmitting ? null : onConfirm,
            label: l10n.salesConfirm,
            icon: isSubmitting
                ? SizedBox(
                    height: AppSizes.iconMd,
                    width: AppSizes.iconMd,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: scheme.onPrimary,
                    ),
                  )
                : const Icon(Icons.check, size: AppSizes.iconMd),
          ),
        ],
      ),
    );
  }
}
