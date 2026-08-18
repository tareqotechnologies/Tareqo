import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:dumbhanengue/data/datasources/local/sale_sqlite_data_source_impl.dart';
import 'package:dumbhanengue/domain/entities/sale.dart';
import 'package:dumbhanengue/domain/entities/sale_item.dart';

import '../../../helpers/test_sqlite.dart';

void main() {
 late Database db;

 setUp(() => db = openTestDatabase());
 tearDown(() => db.close());

 Sale buildSale(String id) => Sale(
 id: id,
 items: const [
 SaleItem(
 productId: 'p1',
 productName: 'Caneta',
 quantity: 2,
 unitPriceCents: 200,
 ),
 SaleItem(
 productId: 'p2',
 productName: 'Caderno',
 quantity: 1,
 unitPriceCents: 990,
 ),
 ],
 totalAmountCents: 1390,
 paymentMethod: PaymentMethod.mPesa,
 dateTime: DateTime(2026, 8, 3, 14, 30),
 );

 test('add grava venda + itens e getAll reconstrói a venda completa',
 () async {
 final dataSource = SaleSqliteDataSourceImpl(db);

 await dataSource.add(buildSale('s1'));

 final sales = await dataSource.getAll(storeId: 'st1');

 expect(sales, hasLength(1));
 final sale = sales.first;
 expect(sale.id, 's1');
 expect(sale.number, 1); // primeira venda da loja
 expect(sale.paymentMethod, PaymentMethod.mPesa);
 expect(sale.totalAmountCents, 1390);
 expect(sale.dateTime, DateTime(2026, 8, 3, 14, 30));
 expect(sale.items, hasLength(2));
 expect(sale.items.first.productName, 'Caneta');
 expect(sale.items.last.quantity, 1);
 });

 test('getAll retorna da venda mais recente para a mais antiga', () async {
 final dataSource = SaleSqliteDataSourceImpl(db);

 await dataSource.add(buildSale('s1'));
 await dataSource.add(
 buildSale('s2').copyWith(dateTime: DateTime(2026, 8, 1)),
 );

 final sales = await dataSource.getAll(storeId: 'st1');

 expect(sales.map((s) => s.id).toList(), ['s1', 's2']);
 });

 test('numera sequencialmente por loja (S-00001, S-00002...)', () async {
 final dataSource = SaleSqliteDataSourceImpl(db);

 // A loja st1 recebe 1 e 2; a st2 recomeça em 1 (numeração é POR LOJA).
 await dataSource.add(buildSale('s1'));
 await dataSource.add(buildSale('s2'));
 await dataSource.add(buildSale('s3').copyWith(storeId: 'st2'));

 final st1 = await dataSource.getAll(storeId: 'st1');
 final st2 = await dataSource.getAll(storeId: 'st2');

 expect(st1.map((s) => s.number).toSet(), {1, 2});
 expect(st2.single.number, 1);
 });

 test('número é atribuído pelo banco (ignora o valor do objeto)', () async {
 final dataSource = SaleSqliteDataSourceImpl(db);

 // Mesmo que o objeto traga number: 999, o banco atribui o próximo.
 await dataSource.add(buildSale('s1').copyWith(number: 999));

 final sales = await dataSource.getAll(storeId: 'st1');
 expect(sales.single.number, 1);
 });
}

