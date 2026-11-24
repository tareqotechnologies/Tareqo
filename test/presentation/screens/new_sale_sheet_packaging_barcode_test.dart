import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/store_context.dart';
import '../../helpers/test_app.dart';

import 'package:tareqo/domain/entities/product.dart';
import 'package:tareqo/domain/entities/product_barcode.dart';
import 'package:tareqo/domain/entities/sale.dart';
import 'package:tareqo/domain/entities/sale_lot_consumption.dart';
import 'package:tareqo/domain/repositories/i_sale_processor.dart';
import 'package:tareqo/domain/repositories/i_sale_repository.dart';
import 'package:tareqo/domain/usecases/get_products_use_case.dart';
import 'package:tareqo/domain/usecases/process_sale_use_case.dart';
import 'package:tareqo/domain/usecases/product_barcode_use_cases.dart';
import 'package:tareqo/presentation/controllers/products_providers.dart';
import 'package:tareqo/presentation/controllers/sales_providers.dart';
import 'package:tareqo/presentation/screens/sales/new_sale_sheet.dart';
import 'package:tareqo/presentation/widgets/app_card.dart';

const _caldo = Product(
  id: 'p-caldo',
  name: 'Caldo Knorr',
  purchasePriceCents: 50,
  salePriceCents: 100, // R$ 1,00 por unidade
  stockQuantity: 300000, // 300 unidades
  barcode: '987654321',
);

const _box = ProductBarcode(
  id: 'pb-box',
  productId: 'p-caldo',
  barcode: '123456789',
  qtyFactor: 30,
  description: 'Caixa 30 un',
);

class _FakeGetProducts implements GetProductsUseCase {
  const _FakeGetProducts(this.product);
  final Product product;

  @override
  Future<List<Product>> call({required String storeId}) async => [product];
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

class _FakeProcessSale implements ProcessSaleUseCase {
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

class _FakeSalesRepository implements ISaleRepository {
  const _FakeSalesRepository();

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
  Future<List<Sale>> getAll({required String storeId}) async => const [];
}

Finder _barcodeField() => find.byWidgetPredicate(
  (widget) =>
      widget is TextField && widget.textInputAction == TextInputAction.done,
);

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
  await tester.pumpAndSettle();
}

Future<_FakeProcessSale> _pumpSheet(
  WidgetTester tester, {
  Product product = _caldo,
  List<ProductBarcode> barcodes = const [_box],
}) async {
  final sale = _FakeProcessSale();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...storeContextOverrides(),
        getProductsUseCaseProvider.overrideWithValue(_FakeGetProducts(product)),
        getProductBarcodesUseCaseProvider.overrideWithValue(
          _FakeGetBarcodes(barcodes),
        ),
        processSaleUseCaseProvider.overrideWithValue(sale),
        salesRepositoryProvider.overrideWithValue(const _FakeSalesRepository()),
      ],
      child: testApp(home: const Scaffold(body: NewSaleSheet())),
    ),
  );
  await tester.pumpAndSettle();
  return sale;
}

Finder _cartRow() => find.widgetWithText(AppCard, 'Caldo Knorr');

void main() {
  testWidgets('caixa fator 30 baixa 30 unidades e grava 30.000 milésimos', (
    tester,
  ) async {
    final sale = await _pumpSheet(tester);

    await _scan(tester, '123456789');

    await tester.scrollUntilVisible(
      _cartRow(),
      80,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: _cartRow(), matching: find.text('30')),
      findsOneWidget,
    );

    await tester.tap(find.text('Confirmar venda'));
    await tester.pumpAndSettle();

    expect(sale.calls, 1);
    expect(sale.lastSale!.items.single.productId, 'p-caldo');
    expect(sale.lastSale!.items.single.quantity, 30000);
    expect(sale.lastSale!.items.single.unitPriceCents, 100);
    expect(sale.lastSale!.totalAmountCents, 3000);
  });

  testWidgets('caixa não cabe no stock: recusa e não deixa vender a menos', (
    tester,
  ) async {
    final sale = await _pumpSheet(
      tester,
      product: _caldo.copyWith(stockQuantity: 29000),
    );

    await _scan(tester, '123456789');

    expect(
      find.text('Limite de stock atingido para Caldo Knorr.'),
      findsOneWidget,
    );
    expect(sale.calls, 0);
  });

  testWidgets('unidade + caixa somam na mesma linha em milésimos', (
    tester,
  ) async {
    final sale = await _pumpSheet(
      tester,
      barcodes: const [
        ProductBarcode(
          id: 'pb-unit',
          productId: 'p-caldo',
          barcode: '987654321',
        ),
        _box,
      ],
    );

    await _scan(tester, '987654321');
    await _scan(tester, '123456789');

    await tester.tap(find.text('Confirmar venda'));
    await tester.pumpAndSettle();

    expect(sale.lastSale!.items.single.quantity, 31000);
    expect(sale.lastSale!.totalAmountCents, 3100);
  });
}
