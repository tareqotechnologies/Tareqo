import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:tareqo/data/datasources/local/customer_sqlite_data_source_impl.dart';
import 'package:tareqo/data/datasources/local/debt_sqlite_data_source_impl.dart';
import 'package:tareqo/data/datasources/local/financial_transaction_sqlite_data_source_impl.dart';
import 'package:tareqo/data/datasources/local/product_sqlite_data_source_impl.dart';
import 'package:tareqo/data/datasources/local/purchase_sqlite_data_source_impl.dart';
import 'package:tareqo/data/datasources/local/sale_sqlite_data_source_impl.dart';
import 'package:tareqo/domain/entities/customer.dart';
import 'package:tareqo/domain/entities/debt.dart';
import 'package:tareqo/domain/entities/financial_transaction.dart';
import 'package:tareqo/domain/entities/product.dart';
import 'package:tareqo/domain/entities/purchase.dart';
import 'package:tareqo/domain/entities/sale.dart';
import 'package:tareqo/domain/entities/sale_item.dart';

import '../../../helpers/test_sqlite.dart';

/// Isolamento por loja (Fase 2 do multi-tenancy): dados gravados para uma
/// loja NUNCA aparecem na leitura de outra loja — o filtro `store_id`
/// dos datasources SQLite é a garantia de que o estoque/vendas/caixa da
/// Loja Centro (st1) não vazam para a Loja Shopping (st2), e vice-versa.
void main() {
 late Database db;

 setUp(() => db = openTestDatabase());
 tearDown(() => db.close());

 group('isolamento por loja no SQLite — st1 nunca vaza para st2', () {
 test('products: getAll(st1) retorna só produtos de st1 e vice-versa',
 () async {
 final dataSource = ProductSqliteDataSourceImpl(db);
 await dataSource.add(Product(
 id: 'p-centro',
 storeId: 'st1',
 name: 'Caneta Centro',
 description: '',
 purchasePriceCents: 100,
 salePriceCents: 200,
 stockQuantity: 10,
 ));
 await dataSource.add(Product(
 id: 'p-shopping',
 storeId: 'st2',
 name: 'Café Shopping',
 description: '',
 purchasePriceCents: 1000,
 salePriceCents: 1500,
 stockQuantity: 10,
 ));

 final fromSt1 = await dataSource.getAll(storeId: 'st1');
 final fromSt2 = await dataSource.getAll(storeId: 'st2');

 expect(fromSt1.map((p) => p.id), ['p-centro']);
 expect(fromSt1.map((p) => p.name), ['Caneta Centro']);
 expect(fromSt2.map((p) => p.id), ['p-shopping']);
 expect(fromSt2.map((p) => p.name), ['Café Shopping']);
 });

 test('sales: getAll(st1) retorna só vendas de st1 e vice-versa', () async {
 final dataSource = SaleSqliteDataSourceImpl(db);
 await dataSource.add(Sale(
 id: 's-centro',
 storeId: 'st1',
 items: const [
 SaleItem(productId: 'p1', productName: 'Caneta', quantity: 2, unitPriceCents: 200),
 ],
 totalAmountCents: 400,
 paymentMethod: PaymentMethod.cash,
 dateTime: DateTime.now(),
 ));
 await dataSource.add(Sale(
 id: 's-shopping',
 storeId: 'st2',
 items: const [
 SaleItem(productId: 'p6', productName: 'Café', quantity: 1, unitPriceCents: 1500),
 ],
 totalAmountCents: 1500,
 paymentMethod: PaymentMethod.mPesa,
 dateTime: DateTime.now(),
 ));

 final fromSt1 = await dataSource.getAll(storeId: 'st1');
 final fromSt2 = await dataSource.getAll(storeId: 'st2');

 expect(fromSt1.map((s) => s.id), ['s-centro']);
 expect(fromSt1.single.totalAmountCents, 400);
 expect(fromSt2.map((s) => s.id), ['s-shopping']);
 expect(fromSt2.single.totalAmountCents, 1500);
 });

 test('financial_transactions: getAll(st1) retorna só movimentos de st1',
 () async {
 final dataSource = FinancialTransactionSqliteDataSourceImpl(db);
 await dataSource.add(FinancialTransaction(
 id: 't-centro',
 storeId: 'st1',
 description: 'Venda Centro',
 amountCents: 10000,
 type: TransactionType.income,
 category: 'Vendas',
 date: DateTime.now(),
 ));
 await dataSource.add(FinancialTransaction(
 id: 't-shopping',
 storeId: 'st2',
 description: 'Venda Shopping',
 amountCents: 5000,
 type: TransactionType.income,
 category: 'Vendas',
 date: DateTime.now(),
 ));

 final fromSt1 = await dataSource.getAll(storeId: 'st1');
 final fromSt2 = await dataSource.getAll(storeId: 'st2');

 expect(fromSt1.map((t) => t.id), ['t-centro']);
 expect(fromSt2.map((t) => t.id), ['t-shopping']);
 // O caixa de uma loja não enxerga a pendência/entrada da outra.
 expect(fromSt1.any((t) => t.id == 't-shopping'), isFalse);
 });

 test('debts: getAll(st1) retorna só fiado de st1 e vice-versa', () async {
 final dataSource = DebtSqliteDataSourceImpl(db);
 await dataSource.add(Debt(
 id: 'd-centro',
 storeId: 'st1',
 personName: 'Cliente Centro',
 amountCents: 2500,
 dueDate: DateTime.now(),
 isCustomerDebt: true,
 ));
 await dataSource.add(Debt(
 id: 'd-shopping',
 storeId: 'st2',
 personName: 'Cliente Shopping',
 amountCents: 4000,
 dueDate: DateTime.now(),
 isCustomerDebt: true,
 ));

 final fromSt1 = await dataSource.getAll(storeId: 'st1');
 final fromSt2 = await dataSource.getAll(storeId: 'st2');

 expect(fromSt1.map((d) => d.id), ['d-centro']);
 expect(fromSt1.single.personName, 'Cliente Centro');
 expect(fromSt2.map((d) => d.id), ['d-shopping']);
 expect(fromSt2.single.personName, 'Cliente Shopping');
 });

 test('customers: getAll(st1) retorna só clientes de st1 e vice-versa',
 () async {
 final dataSource = CustomerSqliteDataSourceImpl(db);
 await dataSource.add(Customer(
 id: 'c-centro',
 storeId: 'st1',
 name: 'Ana Centro',
 ));
 await dataSource.add(Customer(
 id: 'c-shopping',
 storeId: 'st2',
 name: 'Bia Shopping',
 ));

 final fromSt1 = await dataSource.getAll(storeId: 'st1');
 final fromSt2 = await dataSource.getAll(storeId: 'st2');

 expect(fromSt1.map((c) => c.id), ['c-centro']);
 expect(fromSt1.single.name, 'Ana Centro');
 expect(fromSt2.map((c) => c.id), ['c-shopping']);
 expect(fromSt2.single.name, 'Bia Shopping');
 });

 test('purchases: getAll(st1) retorna só compras de st1 e vice-versa',
 () async {
 final dataSource = PurchaseSqliteDataSourceImpl(db);
 await dataSource.add(Purchase(
 id: 'pc-centro',
 storeId: 'st1',
 supplierName: 'Fornecedor Centro',
 items: const [
 PurchaseItem(productId: 'p3', productName: 'Arroz', quantity: 10, unitPriceCents: 500),
 ],
 totalAmountCents: 5000,
 dateTime: DateTime.now(),
 ));
 await dataSource.add(Purchase(
 id: 'pc-shopping',
 storeId: 'st2',
 supplierName: 'Fornecedor Shopping',
 items: const [
 PurchaseItem(productId: 'p6', productName: 'Café', quantity: 5, unitPriceCents: 1000),
 ],
 totalAmountCents: 5000,
 dateTime: DateTime.now(),
 ));

 final fromSt1 = await dataSource.getAll(storeId: 'st1');
 final fromSt2 = await dataSource.getAll(storeId: 'st2');

 expect(fromSt1.map((p) => p.id), ['pc-centro']);
 expect(fromSt1.single.supplierName, 'Fornecedor Centro');
 expect(fromSt2.map((p) => p.id), ['pc-shopping']);
 expect(fromSt2.single.supplierName, 'Fornecedor Shopping');
 });

 test('produtos de ambas as lojas coexistem; a leitura nunca os mistura',
 () async {
 final dataSource = ProductSqliteDataSourceImpl(db);

 // Seed com dados intercalados (prova que o filtro não depende de
 // ordem de inserção nem de ids).
 for (var i = 0; i < 3; i++) {
 await dataSource.add(Product(
 id: 'p-st1-$i',
 storeId: 'st1',
 name: 'Centro $i',
 description: '',
 purchasePriceCents: 100,
 salePriceCents: 200,
 stockQuantity: i,
 ));
 await dataSource.add(Product(
 id: 'p-st2-$i',
 storeId: 'st2',
 name: 'Shopping $i',
 description: '',
 purchasePriceCents: 100,
 salePriceCents: 200,
 stockQuantity: i,
 ));
 }

 final fromSt1 = await dataSource.getAll(storeId: 'st1');
 final fromSt2 = await dataSource.getAll(storeId: 'st2');

 expect(fromSt1, hasLength(3));
 expect(fromSt2, hasLength(3));
 expect(fromSt1.every((p) => p.storeId == 'st1'), isTrue);
 expect(fromSt2.every((p) => p.storeId == 'st2'), isTrue);
 expect(
 fromSt1.map((p) => p.id).toSet().intersection(
 fromSt2.map((p) => p.id).toSet(),
 ),
 isEmpty,
 );
 });
 });

 group('guarda de loja nos métodos POR ID — id de outra loja não alcança',
 () {
 test('getById de produto: id de st1 lido com storeId st2 retorna null',
 () async {
 final dataSource = ProductSqliteDataSourceImpl(db);
 await dataSource.add(Product(
 id: 'p-centro',
 storeId: 'st1',
 name: 'Caneta Centro',
 description: '',
 purchasePriceCents: 100,
 salePriceCents: 200,
 stockQuantity: 10,
 ));

 // Leitura correta: visível na loja dona.
 expect(
 (await dataSource.getById('p-centro', storeId: 'st1'))?.name,
 'Caneta Centro',
 );
 // Guarda: o MESMO id não é visível pela loja errada.
 expect(await dataSource.getById('p-centro', storeId: 'st2'), isNull);
 });

 test('updateStock de produto: id de st1 não é mutável pela loja st2',
 () async {
 final dataSource = ProductSqliteDataSourceImpl(db);
 await dataSource.add(Product(
 id: 'p-centro',
 storeId: 'st1',
 name: 'Caneta Centro',
 description: '',
 purchasePriceCents: 100,
 salePriceCents: 200,
 stockQuantity: 10,
 ));

 // Mutação pela loja errada falha (0 linhas atualizadas).
 await expectLater(
 dataSource.updateStock('p-centro', 99, storeId: 'st2'),
 throwsStateError,
 );
 // E o estoque original permanece intocado.
 expect(
 (await dataSource.getById('p-centro', storeId: 'st1'))
 ?.stockQuantity,
 10,
 );

 // Pela loja correta, funciona.
 await dataSource.updateStock('p-centro', 5, storeId: 'st1');
 expect(
 (await dataSource.getById('p-centro', storeId: 'st1'))
 ?.stockQuantity,
 5,
 );
 });

 test('markAsPaid de dívida: id de st1 não é baixável pela loja st2',
 () async {
 final dataSource = DebtSqliteDataSourceImpl(db);
 await dataSource.add(Debt(
 id: 'd-centro',
 storeId: 'st1',
 personName: 'Cliente Centro',
 amountCents: 2500,
 dueDate: DateTime.now(),
 isCustomerDebt: true,
 ));

 // Baixa pela loja errada falha (0 linhas atualizadas).
 await expectLater(
 dataSource.markAsPaid('d-centro', storeId: 'st2'),
 throwsStateError,
 );
 // E a dívida continua pendente.
 expect(
 (await dataSource.getAll(storeId: 'st1')).single.isPaid,
 isFalse,
 );

 // Pela loja correta, funciona.
 await dataSource.markAsPaid('d-centro', storeId: 'st1');
 expect(
 (await dataSource.getAll(storeId: 'st1')).single.isPaid,
 isTrue,
 );
 });

 test('markAsPaid de transação: id de st1 não é baixável pela loja st2',
 () async {
 final dataSource = FinancialTransactionSqliteDataSourceImpl(db);
 await dataSource.add(FinancialTransaction(
 id: 't-centro',
 storeId: 'st1',
 description: 'Venda fiado Centro',
 amountCents: 10000,
 type: TransactionType.income,
 category: 'Fiado',
 date: DateTime.now(),
 status: TransactionStatus.pending,
 ));

 // Baixa pela loja errada falha (0 linhas atualizadas).
 await expectLater(
 dataSource.markAsPaid('t-centro', storeId: 'st2'),
 throwsStateError,
 );
 // E a transação continua pendente.
 expect(
 (await dataSource.getAll(storeId: 'st1')).single.status,
 TransactionStatus.pending,
 );

 // Pela loja correta, funciona.
 await dataSource.markAsPaid('t-centro', storeId: 'st1');
 expect(
 (await dataSource.getAll(storeId: 'st1')).single.status,
 TransactionStatus.paid,
 );
 });
 });
}
