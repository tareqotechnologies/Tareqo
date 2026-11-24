import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:tareqo/data/datasources/local/product_barcode_sqlite_data_source_impl.dart';
import 'package:tareqo/data/datasources/local/product_sqlite_data_source_impl.dart';
import 'package:tareqo/domain/entities/product.dart';
import 'package:tareqo/domain/entities/product_barcode.dart';

import '../../../helpers/test_sqlite.dart';

void main() {
  late Database db;
  late ProductBarcodeSqliteDataSourceImpl dataSource;

  setUp(() {
    db = openTestDatabase();
    dataSource = ProductBarcodeSqliteDataSourceImpl(db);
  });
  tearDown(() => db.close());

  Future<void> seedProduct(String id, {String storeId = 'st1'}) {
    return ProductSqliteDataSourceImpl(db).add(
      Product(
        id: id,
        storeId: storeId,
        name: 'Caldo $id',
        purchasePriceCents: 100,
        salePriceCents: 200,
        stockQuantity: 300000,
      ),
    );
  }

  test('add/getForProduct persiste caixa e fardo com fatores', () async {
    await seedProduct('p1');
    await dataSource.add(
      const ProductBarcode(
        id: 'pb-box',
        productId: 'p1',
        barcode: '123456789',
        qtyFactor: 30,
        description: 'Caixa 30 un',
      ),
    );
    await dataSource.add(
      const ProductBarcode(
        id: 'pb-fardo',
        productId: 'p1',
        barcode: '555555555',
        qtyFactor: 180,
      ),
    );

    final rows = await dataSource.getForProduct('p1', storeId: 'st1');
    expect(rows, hasLength(2));
    expect(rows.first.barcode, '123456789');
    expect(rows.first.qtyFactor, 30);
    expect(rows.first.baseQuantityMilli, 30000);
    expect(rows.last.qtyFactor, 180);
    expect(rows.last.baseQuantityMilli, 180000);
  });

  test('getAll isola a loja e getForProduct devolve lista vazia', () async {
    await seedProduct('p1');
    await seedProduct('p2', storeId: 'st2');
    await dataSource.add(
      const ProductBarcode(id: 'pb1', productId: 'p1', barcode: '111'),
    );
    await dataSource.add(
      const ProductBarcode(
        id: 'pb2',
        storeId: 'st2',
        productId: 'p2',
        barcode: '222',
        qtyFactor: 12,
      ),
    );

    expect(await dataSource.getAll(storeId: 'st1'), hasLength(1));
    expect(await dataSource.getAll(storeId: 'st2'), hasLength(1));
    expect(await dataSource.getForProduct('p2', storeId: 'st1'), isEmpty);
  });

  test('barcode repetido na mesma loja é rejeitado pelo UNIQUE', () async {
    await seedProduct('p1');
    await seedProduct('p2');
    await dataSource.add(
      const ProductBarcode(id: 'pb1', productId: 'p1', barcode: '123'),
    );

    expect(
      () => dataSource.add(
        const ProductBarcode(id: 'pb2', productId: 'p2', barcode: '123'),
      ),
      throwsA(isA<SqliteException>()),
    );
  });

  test('fator zero é rejeitado pelo CHECK', () async {
    await seedProduct('p1');

    expect(
      () => dataSource.add(
        const ProductBarcode(
          id: 'pb1',
          productId: 'p1',
          barcode: '123',
          qtyFactor: 0,
        ),
      ),
      throwsA(isA<SqliteException>()),
    );
  });

  test('update altera fator/descrição e delete remove', () async {
    await seedProduct('p1');
    await dataSource.add(
      const ProductBarcode(
        id: 'pb1',
        productId: 'p1',
        barcode: '123',
        qtyFactor: 12,
      ),
    );

    await dataSource.update(
      const ProductBarcode(
        id: 'pb1',
        productId: 'p1',
        barcode: '123',
        qtyFactor: 24,
        description: 'Pacote 24 un',
      ),
    );
    final updated = (await dataSource.getForProduct(
      'p1',
      storeId: 'st1',
    )).single;
    expect(updated.qtyFactor, 24);
    expect(updated.description, 'Pacote 24 un');

    await dataSource.delete('pb1', storeId: 'st1');
    expect(await dataSource.getAll(storeId: 'st1'), isEmpty);
  });
}
