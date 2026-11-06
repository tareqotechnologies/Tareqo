import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

import 'package:tareqo/domain/entities/product.dart';
import 'package:tareqo/domain/entities/sale.dart';
import 'package:tareqo/domain/entities/sale_lot_consumption.dart';
import 'package:tareqo/domain/repositories/i_sale_processor.dart';
import 'package:tareqo/domain/repositories/i_sale_repository.dart';
import 'package:tareqo/domain/usecases/get_products_use_case.dart';
import 'package:tareqo/domain/usecases/process_sale_use_case.dart';
import 'package:tareqo/presentation/controllers/products_providers.dart';
import 'package:tareqo/presentation/controllers/sales_providers.dart';
import 'package:tareqo/presentation/screens/sales/new_sale_sheet.dart';
import 'package:tareqo/presentation/widgets/app_button.dart';
import 'package:tareqo/presentation/widgets/app_card.dart';

import '../../helpers/store_context.dart';

// Catálogo W11 usado nos cenários de código de barras:
// - Arroz: produto por PESO com PLU cadastrado SEM zeros à esquerda ('123')
// — a balança imprime o PLU com 5 dígitos ('00123'), a busca normaliza;
// - Biscoito: produto normal cujo código é um EAN-12 que começa com '20'
// (não é balança — deve cair no fluxo normal por código exato);
// - Sal: produto normal com PLU próprio — usado para provar que um código
// com formato de balança cujo PLU NÃO é por peso NÃO vira pesagem.
const _arroz = Product(
  id: 'p-arroz',
  name: 'Arroz',
  purchasePriceCents: 15000,
  salePriceCents: 20000, // 200,00 / kg
  stockQuantity: 10000, // 10 kg em milésimos
  code: '123', // PLU cadastrado sem zeros à esquerda
  vendaPorFracao: true,
  unitLabel: 'kg',
);

const _biscoito = Product(
  id: 'p-biscoito',
  name: 'Biscoito',
  purchasePriceCents: 10000,
  salePriceCents: 15000,
  stockQuantity: 5000, // 5 unidades
  code: '201234567890', // EAN-12 que começa com '20' (não é balança)
);

const _sal = Product(
  id: 'p-sal',
  name: 'Sal',
  purchasePriceCents: 3000,
  salePriceCents: 5000,
  stockQuantity: 3000, // 3 unidades
  code: '77777', // PLU de produto NÃO por peso
);

// Produto ATIVO com id CONTENDO dígitos — prova o casamento por ID
// (p.id == raw.trim()), caminho de leitura por id numérico/alfanumérico.
const _servico = Product(
  id: 'p555',
  name: 'Entrega',
  purchasePriceCents: 0,
  salePriceCents: 1000,
  stockQuantity: 2000, // 2 unidades
  code: '55555',
);

// Produto DESATIVADO — some do PDV (a leitura do código dele é erro de
// busca, mesmo com o código cadastrado).
const _inativo = Product(
  id: 'p-inativo',
  name: 'Disco Vinil',
  purchasePriceCents: 5000,
  salePriceCents: 9000,
  stockQuantity: 1000,
  code: '88888',
  isActive: false,
);

class _FakeGetProductsUseCase implements GetProductsUseCase {
  @override
  Future<List<Product>> call({required String storeId}) async => const [
    _arroz,
    _biscoito,
    _sal,
    _servico,
    _inativo,
  ];
}

/// Registra a venda sem tocar em infraestrutura — aqui validamos apenas a
/// interceptação de código e a montagem dos itens no carrinho.
class _FakeProcessSaleUseCase implements ProcessSaleUseCase {
  int calls = 0;
  Sale? lastSale;

  @override
  Future<void> call(Sale sale) async {
    calls++;
    lastSale = sale;
  }

  @override
  ISaleAtomicProcessor? get processor => null;
}

/// Lista de vendas do cabeçalho ("Hoje · N vendas · total") sem tocar em
/// infraestrutura.
class _FakeSalesRepository implements ISaleRepository {
  _FakeSalesRepository(this._sales);

  final List<Sale> _sales;

  @override
  Future<void> registerSale(Sale sale) async {}

  @override
  Future<Sale?> getById(String id, {required String storeId}) async => null;

  @override
  Future<void> markCancelled(String id, {required String storeId}) async {}

  @override
  Future<List<LotConsumption>> getLotConsumption(
    String saleId, {
    required String storeId,
  }) async => const [];

  @override
  Future<void> registerLotConsumption(
    String saleId,
    String storeId,
    List<LotConsumption> consumption,
  ) async {}

  @override
  Future<List<Sale>> getAll({required String storeId}) async =>
      List.unmodifiable(_sales);
}

/// O campo de código de barras é o único TextField do PDV com
/// `textInputAction == done` (o SearchField usa `search`).
Finder _barcodeField() => find.byWidgetPredicate(
  (widget) =>
      widget is TextField && widget.textInputAction == TextInputAction.done,
);

/// Digita [code] no campo de código e dispara o `onSubmitted` — o mesmo
/// caminho de um scanner USB tipo teclado (ou digitação manual + Enter).
///
/// O corpo do balcão é um scroll único (V3): depois de rolar até uma linha
/// do catálogo, o campo de código sai da viewport e é destruído pelo sliver
/// lazy — rola de volta ao topo antes de digitar.
Future<void> _scan(WidgetTester tester, String code) async {
  if (_barcodeField().evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      _barcodeField(),
      -60,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }
  await tester.enterText(_barcodeField(), code);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pump();
}

/// Monta o PDV com o catálogo fake e devolve o fake de venda para asserções.
Future<_FakeProcessSaleUseCase> _pumpSheet(WidgetTester tester) async {
  final processSale = _FakeProcessSaleUseCase();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...storeContextOverrides(),
        getProductsUseCaseProvider.overrideWithValue(_FakeGetProductsUseCase()),
        processSaleUseCaseProvider.overrideWithValue(processSale),
        // Resumo de hoje no cabeçalho (sem vendas no fake).
        salesRepositoryProvider.overrideWithValue(
          _FakeSalesRepository(const []),
        ),
      ],
      child: testApp(home: const Scaffold(body: NewSaleSheet())),
    ),
  );
  await tester.pumpAndSettle();
  return processSale;
}

void main() {
  testWidgets(
    'balança 20PPPPPWWWWW preenche a fração derivada e a venda grava milésimos',
    (tester) async {
      final processSale = await _pumpSheet(tester);
      expect(find.text('Arroz'), findsOneWidget);

      // 20 + PLU '00123' (com zeros, cadastrado como '123') + valor '20000'
      // centavos → peso derivado = 20000 × 1000 ~/ 20000 = 1000 milésimos (1 kg).
      await _scan(tester, '200012320000');

      // A pill do carrinho ocupa o topo da lista — rola até a linha do
      // Arroz (Card) antes de verificar a fração no stepper.
      await tester.scrollUntilVisible(
        find.widgetWithText(AppCard, 'Arroz'),
        60,
        // O corpo do balcão é um CustomScrollView único (V3) — o primeiro
        // Scrollable da árvore é o dele (o campo de código tem Scrollable
        // próprio, por isso `.first`).
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Fração exibida no stepper do item por peso (escopado à linha do
      // catálogo — a pill do carrinho repete o texto na árvore).
      expect(
        find.descendant(
          of: find.widgetWithText(AppCard, 'Arroz'),
          matching: find.text('1 kg'),
        ),
        findsOneWidget,
      );

      // Confirma a venda e valida o item em MILÉSIMOS + preço por unidade.
      await tester.tap(find.text('Confirmar venda'));
      await tester.pumpAndSettle();

      expect(processSale.calls, 1);
      final sale = processSale.lastSale!;
      expect(sale.items, hasLength(1));
      expect(sale.items.single.productId, 'p-arroz');
      expect(sale.items.single.quantity, 1000);
      expect(sale.items.single.unitPriceCents, 20000);
      expect(sale.totalAmountCents, 20000);
    },
  );

  testWidgets('PLU com zeros à esquerda resolve para o produto cadastrado', (
    tester,
  ) async {
    final processSale = await _pumpSheet(tester);

    // '00123' não é formato de balança (não começa com '20') → fluxo normal;
    // a busca normaliza os zeros e casa com o PLU '123' do Arroz (+1 unidade).
    await _scan(tester, '00123');

    // A pill do carrinho ocupa o topo da lista — rola até a linha do
    // Arroz (Card) antes de verificar a fração no stepper.
    await tester.scrollUntilVisible(
      find.widgetWithText(AppCard, 'Arroz'),
      60,
      // O corpo do balcão é um CustomScrollView único (V3) — o primeiro
      // Scrollable da árvore é o dele (o campo de código tem Scrollable
      // próprio, por isso `.first`).
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.widgetWithText(AppCard, 'Arroz'),
        matching: find.text('1 kg'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Confirmar venda'));
    await tester.pumpAndSettle();

    final sale = processSale.lastSale!;
    expect(sale.items.single.productId, 'p-arroz');
    expect(sale.items.single.quantity, 1000);
  });

  testWidgets('fallback EAN-12: código de 12 dígitos iniciado em 20 vira '
      'unidade de produto normal', (tester) async {
    final processSale = await _pumpSheet(tester);

    // '201234567890' casa com o formato de balança (20+12345+67890), mas o
    // PLU '12345' não resolve para nenhum produto por peso → cai no fluxo
    // normal e casa com o código exato do Biscoito (EAN-12), adicionando
    // 1 UNIDADE (não uma pesagem).
    await _scan(tester, '201234567890');

    // O rodapé do design system 2026 (seletor de pagamento + total +
    // confirmar) encolheu o catálogo no viewport de teste — o Biscoito
    // (2º item) nasce fora da área visível e só é construído ao rolar.
    await tester.scrollUntilVisible(
      find.widgetWithText(AppCard, 'Biscoito'),
      100,
      // O corpo do balcão é um CustomScrollView único (V3) — o primeiro
      // Scrollable da árvore é o dele (o campo de código tem Scrollable
      // próprio, por isso `.first`).
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    // Stepper do Biscoito em unidades inteiras (escopado à linha para não
    // colidir com outros textos "1" que possam surgir na UI).
    expect(
      find.descendant(
        of: find.widgetWithText(AppCard, 'Biscoito'),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Confirmar venda'));
    await tester.pumpAndSettle();

    final sale = processSale.lastSale!;
    expect(sale.items.single.productId, 'p-biscoito');
    expect(sale.items.single.quantity, 1000);
    expect(sale.items.single.unitPriceCents, 15000);
  });

  testWidgets(
    'código de balança cujo PLU é de produto NÃO por peso não vira pesagem',
    (tester) async {
      await _pumpSheet(tester);

      // '207777700100' = 20 + PLU '77777' (Sal — NÃO é venda_por_fracao) +
      // valor '00100'. A balança só é interceptada quando o PLU resolve para
      // um produto por peso; caso contrário o código completo é procurado
      // como um código comum ('207777700100' não é código de ninguém → erro).
      await _scan(tester, '207777700100');

      expect(
        find.text('Produto não encontrado para este código.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('código de balança com PLU inexistente mostra erro de busca', (
    tester,
  ) async {
    await _pumpSheet(tester);

    // '209999900100' = 20 + PLU '99999' (não existe) + valor '00100'.
    await _scan(tester, '209999900100');

    expect(
      find.text('Produto não encontrado para este código.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'leituras sucessivas de balança respeitam o stock e disparam o limite',
    (tester) async {
      final processSale = await _pumpSheet(tester);

      // '200012399999' = 20 + PLU '00123' + valor '99999' → peso derivado
      // = 99999 × 1000 ~/ 20000 = 4999 milésimos (máx. por etiqueta).
      // Três leituras acumulam 4999+4999+4999 → estoura o stock (10000) e
      // o carrinho é limitado ao disponível (capped).
      await _scan(tester, '200012399999');
      // A pill do carrinho ocupa o topo da lista — rola até a linha do
      // Arroz (Card) antes de verificar a fração no stepper.
      await tester.scrollUntilVisible(
        find.widgetWithText(AppCard, 'Arroz'),
        60,
        // O corpo do balcão é um CustomScrollView único (V3) — o primeiro
        // Scrollable da árvore é o dele (o campo de código tem Scrollable
        // próprio, por isso `.first`).
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.widgetWithText(AppCard, 'Arroz'),
          matching: find.text('4,999 kg'),
        ),
        findsOneWidget,
      );
      await _scan(tester, '200012399999');
      expect(
        find.descendant(
          of: find.widgetWithText(AppCard, 'Arroz'),
          matching: find.text('9,998 kg'),
        ),
        findsOneWidget,
      );
      await _scan(tester, '200012399999');
      expect(
        find.descendant(
          of: find.widgetWithText(AppCard, 'Arroz'),
          matching: find.text('10 kg'),
        ),
        findsOneWidget,
      );

      // Campo limpo após leituras bem-sucedidas (scanners não acumulam
      // caracteres entre leituras).
      final field = tester.widget<TextField>(_barcodeField());
      expect(field.controller?.text, isEmpty);

      // A quarta leitura não cabe no stock → erro de limite.
      await _scan(tester, '200012399999');
      expect(find.text('Limite de stock atingido para Arroz.'), findsOneWidget);

      // Nada além do stock entra no carrinho.
      await tester.tap(find.text('Confirmar venda'));
      await tester.pumpAndSettle();
      expect(processSale.lastSale?.items.single.quantity, 10000);
    },
  );

  testWidgets(
    'código exato de produto por UNIDADE adiciona 1 e limpa o campo',
    (tester) async {
      await _pumpSheet(tester);

      // '77777' casa com o código EXATO do Sal (p.code == digits) — +1
      // unidade pelo caminho de código simples (sem normalização necessária).
      await _scan(tester, '77777');

      // Campo limpo após leitura bem-sucedida — verificado ANTES de rolar:
      // ao rolar até o catálogo, o campo lazy sai da viewport e é destruído.
      final field = tester.widget<TextField>(_barcodeField());
      expect(field.controller?.text, isEmpty);

      await tester.scrollUntilVisible(
        find.widgetWithText(AppCard, 'Sal'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.widgetWithText(AppCard, 'Sal'),
          matching: find.text('1'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('leitura por ID do produto resolve quando o id contém dígitos', (
    tester,
  ) async {
    await _pumpSheet(tester);

    // 'p555' = id do produto Entrega (p.id == raw.trim()) — o caminho de id
    // atende códigos alfanuméricos; os dígitos restantes ('555') não casam
    // com nenhum código, mas o id resolve antes.
    await _scan(tester, 'p555');

    await tester.scrollUntilVisible(
      find.widgetWithText(AppCard, 'Entrega'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.widgetWithText(AppCard, 'Entrega'),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('código de produto INATIVO é erro de busca (some do PDV)', (
    tester,
  ) async {
    await _pumpSheet(tester);

    // '88888' está cadastrado no Disco Vinil, mas ele está inativo — o PDV
    // filtra isActive e a leitura vira "produto não encontrado" (o servidor
    // também nega na venda).
    await _scan(tester, '88888');

    expect(
      find.text('Produto não encontrado para este código.'),
      findsOneWidget,
    );
  });

  testWidgets('entrada SEM dígitos é no-op silencioso (nem erro mostra)', (
    tester,
  ) async {
    final processSale = await _pumpSheet(tester);

    // QR/texto sem nenhum dígito: digits.isEmpty → return ANTES de qualquer
    // busca — não mostra "produto não encontrado" (não foi tentativa de
    // código) e o carrinho segue vazio.
    await _scan(tester, 'QR SEM NÚMEROS');

    expect(find.text('Produto não encontrado para este código.'), findsNothing);
    final confirmButton = tester.widget<AppButton>(
      find.ancestor(
        of: find.text('Confirmar venda'),
        matching: find.byType(AppButton),
      ),
    );
    expect(confirmButton.onPressed, isNull);
    expect(processSale.calls, 0);
  });

  testWidgets(
    'etiqueta de balança com valor 00000 → peso ≤ 0 mostra erro de balança',
    (tester) async {
      final processSale = await _pumpSheet(tester);

      // '200012300000' = 20 + PLU '00123' (Arroz por peso) + valor '00000'
      // → peso derivado = 0 → inválido (não entra nada no carrinho).
      await _scan(tester, '200012300000');

      expect(find.text('Código de balança inválido.'), findsOneWidget);

      await tester.tap(find.text('Confirmar venda'));
      await tester.pumpAndSettle();
      expect(processSale.calls, 0);
    },
  );

  testWidgets(
    'limite de stock também vale no caminho de +1 unidade (código simples)',
    (tester) async {
      final processSale = await _pumpSheet(tester);

      // Sal tem 3 unidades: três leituras de '77777' enchem o stock e a
      // quarta dispara o limite — sem exceder o disponível.
      await _scan(tester, '77777');
      await _scan(tester, '77777');
      await _scan(tester, '77777');

      await tester.scrollUntilVisible(
        find.widgetWithText(AppCard, 'Sal'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.widgetWithText(AppCard, 'Sal'),
          matching: find.text('3'),
        ),
        findsOneWidget,
      );

      await _scan(tester, '77777');
      expect(find.text('Limite de stock atingido para Sal.'), findsOneWidget);

      await tester.tap(find.text('Confirmar venda'));
      await tester.pumpAndSettle();
      expect(processSale.lastSale?.items.single.productId, 'p-sal');
      expect(processSale.lastSale?.items.single.quantity, 3000);
    },
  );
}
