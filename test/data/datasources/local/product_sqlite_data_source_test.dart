import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:dumbhanengue/data/datasources/local/product_sqlite_data_source_impl.dart';
import 'package:dumbhanengue/domain/entities/product.dart';

import '../../../helpers/test_sqlite.dart';

void main() {
  late Database db;

  setUp(() => db = openTestDatabase());
  tearDown(() => db.dispose());

  Product buildProduct(String id) => Product(
        id: id,
        name: 'Caneta $id',
        description: 'Azul',
        purchasePrice: 1.0,
        salePrice: 2.0,
        stockQuantity: 10,
      );

  test('add persiste e getAll retorna os produtos ordenados por nome',
      () async {
    final dataSource = ProductSqliteDataSourceImpl(db);

    await dataSource.add(buildProduct('p2'));
    await dataSource.add(buildProduct('p1'));

    final products = await dataSource.getAll(storeId: 'st1');

    expect(products, hasLength(2));
    expect(products.first.id, 'p1');
    expect(products.first.stockQuantity, 10);
  });

  test('getById retorna o produto existente ou null (escopado pela loja)',
      () async {
    final dataSource = ProductSqliteDataSourceImpl(db);
    await dataSource.add(buildProduct('p1'));

    expect((await dataSource.getById('p1', storeId: 'st1'))?.name, 'Caneta p1');
    expect(await dataSource.getById('inexistente', storeId: 'st1'), isNull);
    // Guarda por loja: mesmo id em outra loja não é visível aqui.
    expect(await dataSource.getById('p1', storeId: 'st2'), isNull);
  });

  test('updateStock substitui a quantidade em estoque', () async {
    final dataSource = ProductSqliteDataSourceImpl(db);
    await dataSource.add(buildProduct('p1'));

    await dataSource.updateStock('p1', 7, storeId: 'st1');

    expect((await dataSource.getById('p1', storeId: 'st1'))?.stockQuantity, 7);
  });

  test('updateStock lança StateError para produto inexistente', () async {
    final dataSource = ProductSqliteDataSourceImpl(db);

    expect(
      () => dataSource.updateStock('fantasma', 1, storeId: 'st1'),
      throwsStateError,
    );
  });

  test('CHECK do banco rejeita estoque negativo (salvaguarda final)',
      () async {
    // A regra de negócio vive no domínio; o CHECK protege contra bugs.
    expect(
      () => db.execute(
        'INSERT INTO products '
        '(id, name, description, purchase_price, sale_price, stock_quantity) '
        'VALUES (?, ?, ?, ?, ?, ?)',
        ['x', 'X', '', 1.0, 2.0, -5],
      ),
      throwsA(isA<SqliteException>()),
    );
  });
}
