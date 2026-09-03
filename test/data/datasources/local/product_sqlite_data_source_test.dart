import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:tareqo/data/datasources/local/product_sqlite_data_source_impl.dart';
import 'package:tareqo/domain/entities/product.dart';

import '../../../helpers/test_sqlite.dart';

void main() {
 late Database db;

 setUp(() => db = openTestDatabase());
 tearDown(() => db.close());

 Product buildProduct(String id) => Product(
 id: id,
 name: 'Caneta $id',
 description: 'Azul',
 purchasePriceCents: 100,
 salePriceCents: 200,
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

 test('update persiste os campos editáveis e PRESERVA o estoque', () async {
 final dataSource = ProductSqliteDataSourceImpl(db);
 await dataSource.add(buildProduct('p1'));

 await dataSource.update(
 (await dataSource.getById('p1', storeId: 'st1'))!.copyWith(
 name: 'Caneta Premium',
 description: 'Azul metalizada',
 salePriceCents: 250,
 code: '12345',
 vendaPorFracao: true,
 unitLabel: 'kg',
 // O stock_quantity NÃO entra no UPDATE (invariante stock = Σ lotes).
 stockQuantity: 99999,
 ),
 );

 final updated = await dataSource.getById('p1', storeId: 'st1');
 expect(updated?.name, 'Caneta Premium');
 expect(updated?.description, 'Azul metalizada');
 expect(updated?.salePriceCents, 250);
 expect(updated?.code, '12345');
 expect(updated?.vendaPorFracao, isTrue);
 expect(updated?.unitLabel, 'kg');
 // Estoque preservado apesar do valor divergente no objeto.
 expect(updated?.stockQuantity, 10);
 });

 test('update muda o status ativo (desativar/reativar)', () async {
 final dataSource = ProductSqliteDataSourceImpl(db);
 await dataSource.add(buildProduct('p1'));
 expect((await dataSource.getById('p1', storeId: 'st1'))?.isActive, isTrue);

 await dataSource.update(
 (await dataSource.getById('p1', storeId: 'st1'))!
 .copyWith(isActive: false),
 );
 expect((await dataSource.getById('p1', storeId: 'st1'))?.isActive, isFalse);

 await dataSource.update(
 (await dataSource.getById('p1', storeId: 'st1'))!
 .copyWith(isActive: true),
 );
 expect((await dataSource.getById('p1', storeId: 'st1'))?.isActive, isTrue);
 });

 test('update lança StateError para produto inexistente ou de outra loja',
 () async {
 final dataSource = ProductSqliteDataSourceImpl(db);
 await dataSource.add(buildProduct('p1'));

 // Produto que não existe na loja.
 expect(
 () => dataSource.update(buildProduct('fantasma')),
 throwsStateError,
 );
 // Mesmo id em OUTRA loja não é alcançável (escopo por loja).
 expect(
 () => dataSource.update(
 buildProduct('p1').copyWith(storeId: 'st2', name: 'Outra loja'),
 ),
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
