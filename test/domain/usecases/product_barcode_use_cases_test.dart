import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/data/datasources/local/product_barcode_local_data_source_impl.dart';
import 'package:tareqo/data/repositories/product_barcode_repository_impl.dart';
import 'package:tareqo/domain/entities/product_barcode.dart';
import 'package:tareqo/domain/usecases/product_barcode_use_cases.dart';

void main() {
  late ProductBarcodeLocalDataSourceImpl dataSource;
  late SaveProductBarcodesUseCase save;
  late GetProductBarcodesUseCase get;

  setUp(() {
    dataSource = ProductBarcodeLocalDataSourceImpl();
    final repository = ProductBarcodeRepositoryImpl(dataSource);
    save = SaveProductBarcodesUseCase(repository);
    get = GetProductBarcodesUseCase(repository);
  });

  test(
    'cria unidade, caixa e fardo com ids gerados e fator preservado',
    () async {
      final saved = await save(
        productId: 'p1',
        storeId: 'st1',
        original: const [],
        desired: const [
          ProductBarcode(
            id: '',
            storeId: '',
            productId: '',
            barcode: '987654321',
            qtyFactor: 1,
          ),
          ProductBarcode(
            id: '',
            storeId: '',
            productId: '',
            barcode: '123456789',
            qtyFactor: 30,
            description: 'Caixa 30 un',
          ),
          ProductBarcode(
            id: '',
            storeId: '',
            productId: '',
            barcode: '555555555',
            qtyFactor: 180,
          ),
        ],
      );

      expect(saved, hasLength(3));
      expect(saved.every((item) => item.id.startsWith('pb')), isTrue);
      expect(saved.every((item) => item.productId == 'p1'), isTrue);
      expect(saved.every((item) => item.storeId == 'st1'), isTrue);
      expect(saved[1].baseQuantityMilli, 30000);
      expect(saved[2].baseQuantityMilli, 180000);

      final persisted = await get(storeId: 'st1', productId: 'p1');
      expect(persisted, hasLength(3));
    },
  );

  test('código repetido (mesmo normalizado) é rejeitado', () async {
    await expectLater(
      save(
        productId: 'p1',
        storeId: 'st1',
        original: const [],
        desired: const [
          ProductBarcode(id: '', productId: 'p1', barcode: 'ABC 123'),
          ProductBarcode(
            id: '',
            productId: 'p1',
            barcode: 'abc123',
            qtyFactor: 30,
          ),
        ],
      ),
      throwsA(isA<InvalidProductBarcodeException>()),
    );
  });

  test('fator zero é rejeitado antes de persistir', () async {
    await expectLater(
      save(
        productId: 'p1',
        storeId: 'st1',
        original: const [],
        desired: const [
          ProductBarcode(id: '', productId: 'p1', barcode: '123', qtyFactor: 0),
        ],
      ),
      throwsA(isA<InvalidProductBarcodeException>()),
    );
    expect(await get(storeId: 'st1'), isEmpty);
  });

  test('diff atualiza existentes, remove ausentes e adiciona novos', () async {
    final initial = await save(
      productId: 'p1',
      storeId: 'st1',
      original: const [],
      desired: const [
        ProductBarcode(id: '', productId: 'p1', barcode: '111'),
        ProductBarcode(id: '', productId: 'p1', barcode: '222', qtyFactor: 12),
      ],
    );

    final saved = await save(
      productId: 'p1',
      storeId: 'st1',
      original: initial,
      desired: [
        initial.first.copyWith(description: 'Código alternativo'),
        const ProductBarcode(
          id: '',
          productId: 'p1',
          barcode: '333',
          qtyFactor: 6,
        ),
      ],
    );

    expect(saved, hasLength(2));
    final rows = await get(storeId: 'st1', productId: 'p1');
    expect(rows.map((item) => item.barcode), containsAll(['111', '333']));
    expect(rows.map((item) => item.barcode), isNot(contains('222')));
    expect(
      rows.firstWhere((item) => item.barcode == '111').description,
      'Código alternativo',
    );
  });
}
