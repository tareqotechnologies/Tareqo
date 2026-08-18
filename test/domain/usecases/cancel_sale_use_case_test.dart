import 'package:flutter_test/flutter_test.dart';

import 'package:dumbhanengue/core/utils/quantity.dart';
import 'package:dumbhanengue/domain/entities/financial_transaction.dart';
import 'package:dumbhanengue/domain/entities/product.dart';
import 'package:dumbhanengue/domain/entities/sale.dart';
import 'package:dumbhanengue/domain/entities/sale_item.dart';
import 'package:dumbhanengue/domain/entities/sale_lot_consumption.dart';
import 'package:dumbhanengue/domain/entities/stock_lot.dart';
import 'package:dumbhanengue/domain/repositories/i_financial_transaction_repository.dart';
import 'package:dumbhanengue/domain/repositories/i_product_repository.dart';
import 'package:dumbhanengue/domain/repositories/i_sale_processor.dart';
import 'package:dumbhanengue/domain/repositories/i_sale_repository.dart';
import 'package:dumbhanengue/domain/repositories/i_unit_of_work.dart';
import 'package:dumbhanengue/domain/usecases/cancel_sale_use_case.dart';
import 'package:dumbhanengue/domain/usecases/fifo_stock_use_case.dart';
import 'package:dumbhanengue/domain/usecases/update_product_stock_use_case.dart';

import '../../helpers/fake_stock_lot_repository.dart';

/// Fake do repositório de vendas — guarda o histórico e o consumo de lotes
/// (mesmo comportamento do datasource em memória).
class _FakeSaleRepository implements ISaleRepository {
 final List<Sale> sales = [];
 final Map<String, List<LotConsumption>> consumption = {};

 @override
 Future<void> registerSale(Sale sale) async => sales.add(sale);

 @override
 Future<Sale?> getById(String id, {required String storeId}) async {
 for (final sale in sales) {
 if (sale.id == id && sale.storeId == storeId) return sale;
 }
 return null;
 }

 @override
 Future<void> markCancelled(String id, {required String storeId}) async {
 final index = sales.indexWhere((s) => s.id == id && s.storeId == storeId);
 if (index == -1) throw StateError('Venda $id não encontrada.');
 sales[index] = sales[index].copyWith(
 status: SaleStatus.cancelled,
 cancelledAt: DateTime.now(),
 );
 }

 @override
 Future<List<LotConsumption>> getLotConsumption(
 String saleId, {
 required String storeId,
 }) async =>
 List.unmodifiable(consumption[saleId] ?? const []);

 @override
 Future<void> registerLotConsumption(
 String saleId,
 String storeId,
 List<LotConsumption> items,
 ) async {
 consumption[saleId] = [...items];
 }

 @override
 Future<List<Sale>> getAll({required String storeId}) async =>
 List.unmodifiable(sales);
}

class _FakeProductRepository implements IProductRepository {
 final Map<String, Product> products = {};

 @override
 Future<List<Product>> getAll({required String storeId}) async =>
 products.values.toList();

 @override
 Future<Product?> getById(String id, {required String storeId}) async =>
 products[id];

 @override
 Future<void> add(Product product) async => products[product.id] = product;

 @override
 Future<void> update(Product product) async {
 final current = products[product.id]!;
 // Preserva o estoque (a mutação de quantidade passa pelo FIFO).
 products[product.id] = current.copyWith(
 name: product.name,
 description: product.description,
 purchasePriceCents: product.purchasePriceCents,
 salePriceCents: product.salePriceCents,
 code: product.code,
 vendaPorFracao: product.vendaPorFracao,
 unitLabel: product.unitLabel,
 isActive: product.isActive,
 );
 }

 @override
 Future<void> updateStock(
 String id,
 int newQuantity, {
 required String storeId,
 }) async {
 products[id] = products[id]!.copyWith(stockQuantity: newQuantity);
 }
}

class _FakeTransactionRepository implements IFinancialTransactionRepository {
 final List<FinancialTransaction> transactions = [];

 @override
 Future<List<FinancialTransaction>> getAll({required String storeId}) async =>
 List.unmodifiable(transactions);

 @override
 Future<List<FinancialTransaction>> getByPeriod({
 required String storeId,
 required DateTime start,
 required DateTime end,
 }) async =>
 List.unmodifiable(transactions);

 @override
 Future<void> add(FinancialTransaction transaction) async =>
 transactions.add(transaction);

 @override
 Future<void> markAsPaid(String id, {required String storeId}) async {}
}

class _DirectUnitOfWork implements IUnitOfWork {
 const _DirectUnitOfWork();

 @override
 Future<T> run<T>(Future<T> Function() action) => action();
}

/// Fake do processador atômico (Supabase via RPC cancel_sale).
class _FakeCancellationProcessor implements ISaleCancellationProcessor {
 int calls = 0;
 String? lastSaleId;
 String? lastStoreId;

 @override
 Future<void> cancel(String saleId, {required String storeId}) async {
 calls++;
 lastSaleId = saleId;
 lastStoreId = storeId;
 }
}

/// Estoque em MILÉSIMOS (W11): [units] unidades → 1000×units.
int _thousands(int units) => Quantity.fromUnits(units);

/// Semeia produto + lote (a invariante stock = Σ lotes exige ambos).
void _seedProductWithLot(
 _FakeProductRepository products,
 FakeStockLotRepository lots,
 String id, {
 int stockUnits = 10,
}) {
 products.add(
 Product(
 id: id,
 name: 'Produto $id',
 purchasePriceCents: 500,
 salePriceCents: 990,
 stockQuantity: _thousands(stockUnits),
 ),
 );
 lots.add(
 StockLot(
 id: 'lot-$id',
 storeId: 'st1',
 productId: id,
 entryDate: DateTime.utc(2026, 8, 1),
 expiryDate: null,
 initialQuantity: _thousands(stockUnits),
 currentQuantity: _thousands(stockUnits),
 costPriceCents: 500,
 ),
 );
}

CancelSaleUseCase _buildUseCase(
 _FakeSaleRepository saleRepository,
 _FakeProductRepository productRepository,
 FakeStockLotRepository lotRepository,
 _FakeTransactionRepository transactionRepository,
) {
 return CancelSaleUseCase(
 saleRepository,
 FifoStockUseCase(
 lotRepository,
 UpdateProductStockUseCase(productRepository),
 ),
 transactionRepository,
 const _DirectUnitOfWork(),
 );
}

void main() {
 // Venda de 2 unidades de p1 (2000 milésimos × 200 centavos = 400).
 final sale = Sale(
 id: 's1',
 storeId: 'st1',
 items: const [
 SaleItem(
 productId: 'p1',
 productName: 'Caneta',
 quantity: 2000,
 unitPriceCents: 200,
 ),
 ],
 totalAmountCents: 400,
 paymentMethod: PaymentMethod.mPesa,
 dateTime: DateTime.utc(2026, 8, 3),
 );

 test('anula devolvendo o estoque aos lotes exatos + estorno no caixa + status', () async {
 final sales = _FakeSaleRepository();
 final products = _FakeProductRepository();
 final lots = FakeStockLotRepository();
 final transactions = _FakeTransactionRepository();

 _seedProductWithLot(products, lots, 'p1', stockUnits: 5);
 sales.sales.add(sale);
 // Consumo gravado na venda: 2000 do lote lot-p1 (estoque 5000→3000).
 sales.consumption['s1'] = const [
 LotConsumption(lotId: 'lot-p1', productId: 'p1', quantity: 2000),
 ];
 await lots.updateQuantity('lot-p1', 3000, storeId: 'st1');
 products.products['p1'] = products.products['p1']!
 .copyWith(stockQuantity: 3000);

 final useCase = _buildUseCase(sales, products, lots, transactions);
 await useCase.call('s1', storeId: 'st1');

 // Estoque devolvido ao lote EXATO e ao total do produto.
 expect(lots.getActiveByProduct('p1', storeId: 'st1'), isNotNull);
 final lot = (await lots.getActiveByProduct('p1', storeId: 'st1')).single;
 expect(lot.currentQuantity, 5000);
 expect(products.products['p1']!.stockQuantity, 5000);

 // Venda marcada como anulada (permanece no histórico).
 final cancelled = sales.sales.single;
 expect(cancelled.status, SaleStatus.cancelled);
 expect(cancelled.cancelledAt, isNotNull);

 // Estorno no caixa: saída de 400 na categoria de vendas (pago).
 expect(transactions.transactions, hasLength(1));
 final reversal = transactions.transactions.single;
 expect(reversal.type, TransactionType.expense);
 expect(reversal.amountCents, 400);
 expect(reversal.status, TransactionStatus.paid);
 expect(reversal.description, contains('Estorno de venda'));
 });

 test('venda inexistente lança SaleNotFoundException e não muta nada', () async {
 final sales = _FakeSaleRepository();
 final products = _FakeProductRepository();
 final lots = FakeStockLotRepository();
 final transactions = _FakeTransactionRepository();

 _seedProductWithLot(products, lots, 'p1');

 final useCase = _buildUseCase(sales, products, lots, transactions);
 expect(
 () => useCase.call('nao-existe', storeId: 'st1'),
 throwsA(isA<SaleNotFoundException>()),
 );
 expect(transactions.transactions, isEmpty);
 expect(lots.getActiveByProduct('p1', storeId: 'st1'), isNotNull);
 });

 test('venda já anulada é no-op (idempotência)', () async {
 final sales = _FakeSaleRepository();
 final products = _FakeProductRepository();
 final lots = FakeStockLotRepository();
 final transactions = _FakeTransactionRepository();

 _seedProductWithLot(products, lots, 'p1', stockUnits: 5);
 sales.sales.add(
 sale.copyWith(status: SaleStatus.cancelled, cancelledAt: DateTime.now()),
 );

 final useCase = _buildUseCase(sales, products, lots, transactions);
 await useCase.call('s1', storeId: 'st1');

 // Nenhum estorno extra, estoque intocado.
 expect(transactions.transactions, isEmpty);
 expect(products.products['p1']!.stockQuantity, 5000);
 });

 test('sem consumo registrado ainda marca anulada e estorna o caixa', () async {
 final sales = _FakeSaleRepository();
 final products = _FakeProductRepository();
 final lots = FakeStockLotRepository();
 final transactions = _FakeTransactionRepository();

 _seedProductWithLot(products, lots, 'p1', stockUnits: 5);
 sales.sales.add(sale);

 final useCase = _buildUseCase(sales, products, lots, transactions);
 await useCase.call('s1', storeId: 'st1');

 expect(sales.sales.single.status, SaleStatus.cancelled);
 expect(transactions.transactions, hasLength(1));
 // Sem consumo: estoque não é restaurado (nada foi abatido que se saiba).
 expect(products.products['p1']!.stockQuantity, 5000);
 });

 test('com processador atômico (Supabase) delega a RPC cancel_sale', () async {
 final sales = _FakeSaleRepository();
 final products = _FakeProductRepository();
 final lots = FakeStockLotRepository();
 final transactions = _FakeTransactionRepository();
 final processor = _FakeCancellationProcessor();

 final useCase = CancelSaleUseCase(
 sales,
 FifoStockUseCase(lots, UpdateProductStockUseCase(products)),
 transactions,
 const _DirectUnitOfWork(),
 processor: processor,
 );

 await useCase.call('s1', storeId: 'st1');

 expect(processor.calls, 1);
 expect(processor.lastSaleId, 's1');
 expect(processor.lastStoreId, 'st1');
 // Nada do caminho composto roda no modo atômico.
 expect(transactions.transactions, isEmpty);
 expect(sales.sales, isEmpty);
 });
}
