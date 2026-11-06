import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';
import '../../helpers/viewport.dart';
import '../../helpers/store_context.dart';

import 'package:tareqo/domain/entities/product.dart';
import 'package:tareqo/domain/entities/purchase.dart';
import 'package:tareqo/domain/entities/sale.dart' show PaymentMethod;
import 'package:tareqo/domain/repositories/i_purchase_processor.dart';
import 'package:tareqo/domain/usecases/add_purchase_use_case.dart';
import 'package:tareqo/domain/usecases/get_products_use_case.dart';
import 'package:tareqo/presentation/controllers/products_providers.dart';
import 'package:tareqo/presentation/controllers/purchases_providers.dart';
import 'package:tareqo/presentation/screens/purchases/add_purchase_sheet.dart';
import 'package:tareqo/presentation/widgets/app_sheet.dart';

class _FakeGetProductsUseCase implements GetProductsUseCase {
  _FakeGetProductsUseCase(this._products);

  final List<Product> _products;

  @override
  Future<List<Product>> call({required String storeId}) async => _products;
}

/// Fake do [ProcessPurchaseUseCase] — a sheet orquestra a compra sem tocar
/// em repositórios; o caso de uso real já é coberto por testes de domínio.
class _FakeProcessPurchaseUseCase implements ProcessPurchaseUseCase {
  int calls = 0;
  Purchase? lastPurchase;

  @override
  Future<void> call(Purchase purchase) async {
    calls++;
    lastPurchase = purchase;
  }

  @override
  IPurchaseAtomicProcessor? get processor => null;
}

Widget _buildApp({
  required List<Product> products,
  ProcessPurchaseUseCase? processPurchase,
}) {
  return ProviderScope(
    overrides: [
      ...storeContextOverrides(),
      getProductsUseCaseProvider.overrideWithValue(
        _FakeGetProductsUseCase(products),
      ),
      processPurchaseUseCaseProvider.overrideWithValue(
        processPurchase ?? _FakeProcessPurchaseUseCase(),
      ),
    ],
    child: testApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: FilledButton(
              onPressed: () => showAppSheet<void>(
                context,
                builder: (_) => const AddPurchaseSheet(),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('adiciona itens ao carrinho e registra a compra', (tester) async {
    final processPurchase = _FakeProcessPurchaseUseCase();

    await tester.pumpWidget(
      _buildApp(
        products: const [
          Product(
            id: 'p1',
            name: 'Caneta',
            purchasePriceCents: 50,
            salePriceCents: 200,
            stockQuantity: 10,
          ),
        ],
        processPurchase: processPurchase,
      ),
    );
    await _openSheet(tester);

    // Preenche o fornecedor e adiciona 2 unidades da Caneta.
    await tester.enterText(
      find.widgetWithText(TextField, 'Fornecedor'),
      'Distribuidora Central',
    );
    await tester.pumpAndSettle();

    // O produto aparece na lista com o stepper de quantidade.
    expect(find.text('Caneta'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();

    // Total = 2 × R$ 0,50 = R$ 1,00.
    expect(find.text('R\$ 1,00'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Confirmar compra'));
    await tester.pumpAndSettle();

    expect(processPurchase.calls, 1);
    expect(processPurchase.lastPurchase?.supplierName, 'Distribuidora Central');
    expect(processPurchase.lastPurchase?.items.length, 1);
    // W11: 2 unidades em MILÉSIMOS.
    expect(processPurchase.lastPurchase?.items.first.quantity, 2000);
    expect(processPurchase.lastPurchase?.totalAmountCents, 100);
    // Forma de pagamento padrão: M-Pesa (mesmo padrão do carrinho de vendas).
    expect(processPurchase.lastPurchase?.paymentMethod, PaymentMethod.mPesa);
  });

  testWidgets('permite escolher a forma de pagamento do fornecedor', (
    tester,
  ) async {
    final processPurchase = _FakeProcessPurchaseUseCase();

    await tester.pumpWidget(
      _buildApp(
        products: const [
          Product(
            id: 'p1',
            name: 'Caneta',
            purchasePriceCents: 50,
            salePriceCents: 200,
          ),
        ],
        processPurchase: processPurchase,
      ),
    );
    await _openSheet(tester);

    await tester.enterText(
      find.widgetWithText(TextField, 'Fornecedor'),
      'Distribuidora',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();

    // Troca o padrão (M-Pesa) para Dinheiro: o seletor fica RECOLHIDO no
    // rodapé (resumo de 48dp) — tocar no resumo expande as abas e a
    // seleção recolhe de volta (design system 2026).
    await tester.tap(find.text('M-Pesa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dinheiro'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Confirmar compra'));
    await tester.pumpAndSettle();

    expect(processPurchase.calls, 1);
    expect(processPurchase.lastPurchase?.paymentMethod, PaymentMethod.cash);
  });

  testWidgets('o botão de confirmar fica desabilitado sem itens no carrinho', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        products: const [
          Product(
            id: 'p1',
            name: 'Caneta',
            purchasePriceCents: 50,
            salePriceCents: 200,
          ),
        ],
      ),
    );
    await _openSheet(tester);

    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Confirmar compra'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('exibe erro quando o fornecedor não é informado', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        products: const [
          Product(
            id: 'p1',
            name: 'Caneta',
            purchasePriceCents: 50,
            salePriceCents: 200,
          ),
        ],
      ),
    );
    await _openSheet(tester);

    // Adiciona um item mas deixa o fornecedor vazio.
    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Confirmar compra'));
    await tester.pumpAndSettle();

    expect(find.text('Informe o fornecedor da compra.'), findsOneWidget);
  });

  // Rotação (UI): o sheet de nova compra (bottom sheet com maxHeight 90%)
  // em paisagem fica mais baixo — a lista de produtos (Expanded) precisa
  // encolher e o rodapé (forma de pagamento + total + confirmar) segue
  // acessível. Overflows de RenderFlex falham o teste via takeException.
  testWidgets('remover por stepper zera o item e o total', (tester) async {
    final processPurchase = _FakeProcessPurchaseUseCase();
    await tester.pumpWidget(
      _buildApp(
        products: const [
          Product(
            id: 'p1',
            name: 'Caneta',
            purchasePriceCents: 50,
            salePriceCents: 200,
            stockQuantity: 10,
          ),
        ],
        processPurchase: processPurchase,
      ),
    );
    await _openSheet(tester);

    // Adiciona 2 unidades.
    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();
    expect(find.text('R\$ 1,00'), findsOneWidget);

    // O botão − desabilita quando a quantidade volta a zero.
    await tester.tap(find.byIcon(Icons.remove).first);
    await tester.pumpAndSettle();
    expect(find.text('R\$ 0,50'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.remove).first);
    await tester.pumpAndSettle();
    expect(find.text('R\$ 0,00'), findsOneWidget);

    // O stepper não permite quantidade negativa (− desabilitado em zero).
    final removeButton = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.remove).first,
        matching: find.byType(IconButton),
      ),
    );
    expect(removeButton.onPressed, isNull);
    // Sem itens, o botão de confirmar volta a ficar desabilitado.
    await tester.tap(find.widgetWithText(FilledButton, 'Confirmar compra'));
    await tester.pumpAndSettle();
    expect(processPurchase.calls, 0);
  });

  testWidgets(
    'validade definida aparece na linha do item e vai para a compra',
    (tester) async {
      final processPurchase = _FakeProcessPurchaseUseCase();

      await tester.pumpWidget(
        _buildApp(
          products: const [
            Product(
              id: 'p1',
              name: 'Arroz',
              purchasePriceCents: 5000,
              salePriceCents: 6500,
              stockQuantity: 10,
            ),
          ],
          processPurchase: processPurchase,
        ),
      );
      await _openSheet(tester);

      await tester.enterText(
        find.widgetWithText(TextField, 'Fornecedor'),
        'Distribuidora Central',
      );
      await tester.pumpAndSettle();

      // Adiciona o Arroz.
      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pumpAndSettle();

      // Abre o seletor de datas e alterna para entrada por texto.
      await tester.tap(find.byIcon(Icons.event_outlined).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(Dialog),
          matching: find.byType(TextField),
        ),
        '15/09/2027',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.event_available_outlined), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Confirmar compra'));
      await tester.pumpAndSettle();
      expect(processPurchase.calls, 1);
      expect(
        processPurchase.lastPurchase?.items.first.expiryDate,
        DateTime(2027, 9, 15),
      );
    },
  );

  testWidgets('carrinho de compra sobrevive à rotação para paisagem', (
    tester,
  ) async {
    final processPurchase = _FakeProcessPurchaseUseCase();

    usePortraitViewport(tester);

    await tester.pumpWidget(
      _buildApp(
        products: const [
          Product(
            id: 'p1',
            name: 'Caneta',
            purchasePriceCents: 50,
            salePriceCents: 200,
            stockQuantity: 10,
          ),
        ],
        processPurchase: processPurchase,
      ),
    );
    await _openSheet(tester);

    // Retrato: produto no catálogo e rodapé com total + confirmar.
    expect(find.text('Caneta'), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, 'Confirmar compra'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    // Gira para paisagem com o sheet aberto.
    await rotateToLandscape(tester);

    // Sem overflow; o catálogo e o rodapé seguem presentes após o giro.
    expect(tester.takeException(), isNull);
    expect(find.text('Caneta'), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, 'Confirmar compra'),
      findsOneWidget,
    );

    // O carrinho continua funcional em paisagem: adiciona, preenche o
    // fornecedor e confirma.
    await tester.enterText(
      find.widgetWithText(TextField, 'Fornecedor'),
      'Distribuidora',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Confirmar compra'));
    await tester.pumpAndSettle();

    expect(processPurchase.calls, 1);
    expect(processPurchase.lastPurchase?.supplierName, 'Distribuidora');
    expect(processPurchase.lastPurchase?.totalAmountCents, 50);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'compras só mostram produtos de papel COMPRÁVEL (esconde produzido/composto)',
    (tester) async {
      await tester.pumpWidget(
        _buildApp(
          products: const [
            Product(
              id: 'p1',
              name: 'Farinha',
              purchasePriceCents: 100,
              salePriceCents: 200,
              type: ProductType.rawMaterial,
            ),
            Product(
              id: 'p2',
              name: 'Saco plástico',
              purchasePriceCents: 100,
              salePriceCents: 200,
              type: ProductType.packaging,
            ),
            Product(
              id: 'p3',
              name: 'Água',
              purchasePriceCents: 100,
              salePriceCents: 200,
              type: ProductType.resale,
            ),
            Product(
              id: 'p4',
              name: 'Pão',
              purchasePriceCents: 100,
              salePriceCents: 200,
              type: ProductType.manufactured,
            ),
            Product(
              id: 'p5',
              name: 'Hambúrguer',
              purchasePriceCents: 100,
              salePriceCents: 200,
              type: ProductType.composite,
            ),
          ],
        ),
      );
      await _openSheet(tester);

      // Compraveis: matéria-prima, revenda e embalagem.
      expect(find.text('Farinha'), findsOneWidget);
      expect(find.text('Água'), findsOneWidget);
      expect(find.text('Saco plástico'), findsOneWidget);
      // Não compraveis: produzido e composto (vêm da produção interna).
      expect(find.text('Pão'), findsNothing);
      expect(find.text('Hambúrguer'), findsNothing);

      // Selo do TIPO em TODAS as linhas das compras — inclui Revenda.
      expect(find.text('Matéria-prima'), findsOneWidget);
      expect(find.text('Embalagem'), findsOneWidget);
      expect(find.text('Revenda'), findsOneWidget);
    },
  );

  testWidgets(
    'compras sem produtos compráveis mostram estado vazio explicativo (por papel)',
    (tester) async {
      await tester.pumpWidget(
        _buildApp(
          products: const [
            Product(
              id: 'p1',
              name: 'Pão',
              purchasePriceCents: 100,
              salePriceCents: 200,
              type: ProductType.manufactured,
            ),
            Product(
              id: 'p2',
              name: 'Hambúrguer',
              purchasePriceCents: 100,
              salePriceCents: 200,
              type: ProductType.composite,
            ),
          ],
        ),
      );
      await _openSheet(tester);

      // Estado vazio ESPECÍFICO: há produtos, mas nenhum é comprável.
      expect(find.text('Nenhum produto comprável'), findsOneWidget);
      expect(find.text('Nenhum produto para comprar'), findsNothing);
      expect(find.text('Pão'), findsNothing);
    },
  );
}
