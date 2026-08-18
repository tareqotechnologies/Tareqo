import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:dumbhanengue/core/utils/quantity.dart';
import 'package:dumbhanengue/data/datasources/local/financial_transaction_sqlite_data_source_impl.dart';
import 'package:dumbhanengue/data/datasources/local/product_sqlite_data_source_impl.dart';
import 'package:dumbhanengue/data/datasources/local/sale_sqlite_data_source_impl.dart';
import 'package:dumbhanengue/data/datasources/local/sqlite_unit_of_work.dart';
import 'package:dumbhanengue/data/datasources/local/stock_lot_sqlite_data_source_impl.dart';
import 'package:dumbhanengue/data/repositories/financial_transaction_repository_impl.dart';
import 'package:dumbhanengue/data/repositories/product_repository_impl.dart';
import 'package:dumbhanengue/data/repositories/sale_repository_impl.dart';
import 'package:dumbhanengue/data/repositories/stock_lot_repository_impl.dart';
import 'package:dumbhanengue/domain/entities/financial_transaction.dart';
import 'package:dumbhanengue/domain/entities/product.dart';
import 'package:dumbhanengue/domain/entities/sale.dart';
import 'package:dumbhanengue/domain/entities/sale_item.dart';
import 'package:dumbhanengue/domain/entities/stock_lot.dart';
import 'package:dumbhanengue/domain/repositories/i_financial_transaction_repository.dart';
import 'package:dumbhanengue/domain/usecases/fifo_stock_use_case.dart';
import 'package:dumbhanengue/domain/usecases/process_sale_use_case.dart';
import 'package:dumbhanengue/domain/usecases/update_product_stock_use_case.dart';

import '../../helpers/test_sqlite.dart';

/// Decorador que falha no passo do caixa — força o rollback do restante da
/// transação (venda + estoque) sem depender do formato do id gerado.
class _ThrowingTransactionRepository implements IFinancialTransactionRepository {
 _ThrowingTransactionRepository(this._inner);

 final IFinancialTransactionRepository _inner;

 @override
 Future<List<FinancialTransaction>> getAll({required String storeId}) =>
 _inner.getAll(storeId: storeId);

 @override
 Future<List<FinancialTransaction>> getByPeriod({
 required String storeId,
 required DateTime start,
 required DateTime end,
 }) =>
 _inner.getByPeriod(storeId: storeId, start: start, end: end);

 @override
 Future<void> add(FinancialTransaction transaction) async {
 throw StateError('falha simulada no passo do caixa');
 }

 @override
 Future<void> markAsPaid(String id, {required String storeId}) =>
 _inner.markAsPaid(id, storeId: storeId);
}

void main() {
 late Database db;

 setUp(() => db = openTestDatabase());
 tearDown(() => db.close());

 ProcessSaleUseCase buildUseCase(Database database) {
 final productDs = ProductSqliteDataSourceImpl(database);
 final saleDs = SaleSqliteDataSourceImpl(database);
 final transactionDs = FinancialTransactionSqliteDataSourceImpl(database);
 final lotDs = StockLotSqliteDataSourceImpl(database);
 return ProcessSaleUseCase(
 SaleRepositoryImpl(saleDs),
 FifoStockUseCase(
 StockLotRepositoryImpl(lotDs),
 UpdateProductStockUseCase(ProductRepositoryImpl(productDs)),
 ),
 FinancialTransactionRepositoryImpl(transactionDs),
 SqliteUnitOfWork(database),
 );
 }

 /// Adiciona o produto + o lote que cobre o estoque (invariante W11).
 Future<void> seedProductWithLot(
 Database database,
 String id, {
 int stockUnits = 10,
 String storeId = 'st1',
 }) async {
 await ProductSqliteDataSourceImpl(database).add(
 Product(
 id: id,
 storeId: storeId,
 name: 'Caneta',
 purchasePriceCents: 100,
 salePriceCents: 200,
 stockQuantity: Quantity.fromUnits(stockUnits),
 ),
 );
 await StockLotSqliteDataSourceImpl(database).add(
 StockLot(
 id: 'lot-$id',
 storeId: storeId,
 productId: id,
 entryDate: DateTime.utc(2026, 8, 1),
 expiryDate: null,
 initialQuantity: Quantity.fromUnits(stockUnits),
 currentQuantity: Quantity.fromUnits(stockUnits),
 costPriceCents: 100,
 ),
 );
 }

 Sale buildSale() => Sale(
 id: 's1',
 items: const [
 SaleItem(
 productId: 'p1',
 productName: 'Caneta',
 quantity: 2000, // 2 unidades em MILÉSIMOS (W11)
 unitPriceCents: 200,
 ),
 ],
 totalAmountCents: 400,
 paymentMethod: PaymentMethod.mPesa,
 dateTime: DateTime.utc(2026, 8, 3),
 );

 test('venda + estoque + caixa são gravados juntos no sucesso', () async {
 await seedProductWithLot(db, 'p1');

 await buildUseCase(db)(buildSale());

 // Venda com itens persistida.
 final sales = await SaleSqliteDataSourceImpl(db).getAll(storeId: 'st1');
 expect(sales, hasLength(1));
 expect(sales.first.totalAmountCents, 400);
 expect(sales.first.items, hasLength(1));

 // Estoque baixado (W11: 10000 - 2000 = 8000 milésimos).
 expect(
 (await ProductSqliteDataSourceImpl(db).getById('p1', storeId: 'st1'))
 ?.stockQuantity,
 8000,
 );

 // Lote abatido em FIFO (mesma quantidade).
 final lots =
 await StockLotSqliteDataSourceImpl(db).getActiveByProduct(
 'p1',
 storeId: 'st1',
 );
 expect(lots.single.currentQuantity, 8000);

 // Entrada no caixa registrada.
 final transactions =
 await FinancialTransactionSqliteDataSourceImpl(db)
 .getAll(storeId: 'st1');
 expect(transactions, hasLength(1));
 expect(transactions.first.amountCents, 400);
 expect(transactions.first.status, TransactionStatus.paid);
 });

 test('venda da loja st2 não alcança o estoque da loja st1', () async {
 // Produto cadastrado APENAS na loja st1 (com lote).
 await seedProductWithLot(db, 'p1');

 // Venda na loja st2 referenciando o produto de st1: a guarda por loja
 // faz o produto/lotes de st1 ficarem invisíveis →
 // ProductNotFoundException, e NADA é persistido.
 await expectLater(
 buildUseCase(db)(
 buildSale().copyWith(storeId: 'st2'),
 ),
 throwsA(isA<ProductNotFoundException>()),
 );

 expect(await SaleSqliteDataSourceImpl(db).getAll(storeId: 'st2'), isEmpty);
 // O estoque e o lote de st1 permanecem intocados.
 expect(
 (await ProductSqliteDataSourceImpl(db).getById('p1', storeId: 'st1'))
 ?.stockQuantity,
 10000,
 );
 expect(
 await FinancialTransactionSqliteDataSourceImpl(db)
 .getAll(storeId: 'st2'),
 isEmpty,
 );
 });

 test('falha no caixa desfaz a venda, o estoque e o LOTE (ROLLBACK total)',
 () async {
 await seedProductWithLot(db, 'p1');

 final failingTransactions = _ThrowingTransactionRepository(
 FinancialTransactionRepositoryImpl(
 FinancialTransactionSqliteDataSourceImpl(db),
 ),
 );
 final useCase = ProcessSaleUseCase(
 SaleRepositoryImpl(SaleSqliteDataSourceImpl(db)),
 FifoStockUseCase(
 StockLotRepositoryImpl(StockLotSqliteDataSourceImpl(db)),
 UpdateProductStockUseCase(
 ProductRepositoryImpl(ProductSqliteDataSourceImpl(db)),
 ),
 ),
 failingTransactions,
 SqliteUnitOfWork(db),
 );

 await expectLater(
 useCase(buildSale()),
 throwsA(isA<StateError>()),
 );

 // NADA foi gravado: venda, estoque e lote foram desfeitos pelo rollback.
 expect(
 await SaleSqliteDataSourceImpl(db).getAll(storeId: 'st1'),
 isEmpty,
 );
 expect(
 (await ProductSqliteDataSourceImpl(db).getById('p1', storeId: 'st1'))
 ?.stockQuantity,
 10000,
 );
 final lots =
 await StockLotSqliteDataSourceImpl(db).getActiveByProduct(
 'p1',
 storeId: 'st1',
 );
 expect(lots.single.currentQuantity, 10000);
 expect(
 await FinancialTransactionSqliteDataSourceImpl(db)
 .getAll(storeId: 'st1'),
 isEmpty,
 );
 });
}
