import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';
import '../../helpers/store_context.dart';

import 'package:dumbhanengue/domain/entities/product.dart';
import 'package:dumbhanengue/domain/entities/purchase.dart';
import 'package:dumbhanengue/domain/repositories/i_purchase_processor.dart';
import 'package:dumbhanengue/domain/usecases/add_purchase_use_case.dart';
import 'package:dumbhanengue/domain/usecases/get_products_use_case.dart';
import 'package:dumbhanengue/presentation/controllers/products_providers.dart';
import 'package:dumbhanengue/presentation/controllers/purchases_providers.dart';
import 'package:dumbhanengue/presentation/screens/purchases/add_purchase_sheet.dart';
import 'package:dumbhanengue/presentation/widgets/app_sheet.dart';

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
  testWidgets('adiciona itens ao carrinho e registra a compra',
      (tester) async {
    final processPurchase = _FakeProcessPurchaseUseCase();

    await tester.pumpWidget(
      _buildApp(
        products: const [
          Product(
            id: 'p1',
            name: 'Caneta',
            purchasePrice: 0.5,
            salePrice: 2.0,
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
    expect(processPurchase.lastPurchase?.items.first.quantity, 2);
    expect(processPurchase.lastPurchase?.totalAmount, 1.0);
  });

  testWidgets('o botão de confirmar fica desabilitado sem itens no carrinho',
      (tester) async {
    await tester.pumpWidget(
      _buildApp(
        products: const [
          Product(
            id: 'p1',
            name: 'Caneta',
            purchasePrice: 0.5,
            salePrice: 2.0,
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

  testWidgets('exibe erro quando o fornecedor não é informado',
      (tester) async {
    await tester.pumpWidget(
      _buildApp(
        products: const [
          Product(
            id: 'p1',
            name: 'Caneta',
            purchasePrice: 0.5,
            salePrice: 2.0,
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
}
