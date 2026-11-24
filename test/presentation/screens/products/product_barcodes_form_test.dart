import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';
import '../../../helpers/store_context.dart';

import 'package:tareqo/data/services/product_image_store_noop.dart';
import 'package:tareqo/domain/entities/product.dart';
import 'package:tareqo/domain/entities/product_barcode.dart';
import 'package:tareqo/domain/repositories/i_stock_adjustment_processor.dart';
import 'package:tareqo/domain/usecases/get_products_use_case.dart';
import 'package:tareqo/domain/usecases/product_barcode_use_cases.dart';
import 'package:tareqo/domain/usecases/update_product_use_case.dart';
import 'package:tareqo/presentation/controllers/products_providers.dart';
import 'package:tareqo/presentation/screens/products/product_form_sheets.dart';

const _product = Product(
  id: 'p1',
  name: 'Caldo Knorr',
  purchasePriceCents: 50,
  salePriceCents: 100,
  stockQuantity: 300000,
  barcode: '987654321',
);

class _FakeProducts implements GetProductsUseCase {
  const _FakeProducts(this.products);
  final List<Product> products;

  @override
  Future<List<Product>> call({required String storeId}) async => products;
}

class _FakeGetBarcodes implements GetProductBarcodesUseCase {
  const _FakeGetBarcodes(this.rows);
  final List<ProductBarcode> rows;

  @override
  Future<List<ProductBarcode>> call({
    required String storeId,
    String? productId,
  }) async => rows;
}

class _FakeSaveBarcodes implements SaveProductBarcodesUseCase {
  List<ProductBarcode>? saved;

  @override
  Future<List<ProductBarcode>> call({
    required String productId,
    required String storeId,
    required List<ProductBarcode> original,
    required List<ProductBarcode> desired,
  }) async {
    saved = desired;
    return desired;
  }
}

class _FakeUpdateProduct implements UpdateProductUseCase {
  @override
  IStockAdjustmentProcessor? get stockAdjustmentProcessor => null;

  @override
  Future<void> updateDetails(Product product) async {}

  @override
  Future<void> adjustStock(
    String productId,
    int newQuantity, {
    required String storeId,
  }) async {}

  @override
  Future<void> setActive(
    String productId, {
    required String storeId,
    required bool isActive,
  }) async {}
}

void main() {
  testWidgets('edição adiciona caixa 30 e guarda a embalagem no produto', (
    tester,
  ) async {
    final save = _FakeSaveBarcodes();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...storeContextOverrides(),
          getProductsUseCaseProvider.overrideWithValue(
            const _FakeProducts([_product]),
          ),
          getProductBarcodesUseCaseProvider.overrideWithValue(
            const _FakeGetBarcodes([]),
          ),
          saveProductBarcodesUseCaseProvider.overrideWithValue(save),
          updateProductUseCaseProvider.overrideWithValue(_FakeUpdateProduct()),
          productImageStoreProvider.overrideWithValue(
            const ProductImageStoreNoop(),
          ),
        ],
        child: testApp(
          home: const Scaffold(body: EditProductSheet(product: _product)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Adicionar embalagem'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adicionar embalagem'));
    await tester.pumpAndSettle();

    final dialog = find.byType(AlertDialog);
    await tester.enterText(
      find.descendant(
        of: dialog,
        matching: find.widgetWithText(TextFormField, 'Código de barras'),
      ),
      '123456789',
    );
    await tester.enterText(
      find.descendant(
        of: dialog,
        matching: find.widgetWithText(TextFormField, 'Unidades por embalagem'),
      ),
      '30',
    );
    await tester.enterText(
      find.descendant(
        of: dialog,
        matching: find.widgetWithText(TextFormField, 'Descrição (opcional)'),
      ),
      'Caixa 30 un',
    );
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Caixa 30 un'), findsOneWidget);
    expect(find.textContaining('30 un. · 123456789'), findsOneWidget);

    await tester.ensureVisible(find.text('Guardar alterações'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar alterações'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(save.saved, hasLength(1));
    expect(save.saved!.single.barcode, '123456789');
    expect(save.saved!.single.qtyFactor, 30);
  });
}
