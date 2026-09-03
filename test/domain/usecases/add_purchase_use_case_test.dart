import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/core/utils/quantity.dart';
import 'package:tareqo/domain/entities/financial_transaction.dart';
import 'package:tareqo/domain/entities/product.dart';
import 'package:tareqo/domain/entities/purchase.dart';
import 'package:tareqo/domain/entities/sale.dart' show PaymentMethod;
import 'package:tareqo/domain/repositories/i_financial_transaction_repository.dart';
import 'package:tareqo/domain/repositories/i_product_repository.dart';
import 'package:tareqo/domain/repositories/i_purchase_processor.dart';
import 'package:tareqo/domain/repositories/i_purchase_repository.dart';
import 'package:tareqo/domain/repositories/i_unit_of_work.dart';
import 'package:tareqo/domain/usecases/add_purchase_use_case.dart';
import 'package:tareqo/domain/usecases/fifo_stock_use_case.dart';
import 'package:tareqo/domain/usecases/update_product_stock_use_case.dart';

import '../../helpers/fake_stock_lot_repository.dart';

class _FakePurchaseRepository implements IPurchaseRepository {
 final List<Purchase> _purchases = [];

 @override
 Future<List<Purchase>> getAll({required String storeId}) async =>
 List.unmodifiable(_purchases);

 @override
 Future<void> add(Purchase purchase) async => _purchases.add(purchase);
}

class _FakeProductRepository implements IProductRepository {
 _FakeProductRepository(this._products);

 final List<Product> _products;

 @override
 Future<List<Product>> getAll({required String storeId}) async =>
 List.unmodifiable(_products);

 @override
 Future<Product?> getById(String id, {required String storeId}) async {
 for (final product in _products) {
 if (product.id == id && product.storeId == storeId) return product;
 }
 return null;
 }

 @override
 Future<void> add(Product product) async => _products.add(product);

 @override
 Future<void> update(Product product) async {
 final index = _products.indexWhere(
 (p) => p.id == product.id && p.storeId == product.storeId,
 );
 final current = _products[index];
 // Preserva o estoque (a mutação de quantidade passa pelo FIFO).
 _products[index] = current.copyWith(
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
 final index = _products.indexWhere(
 (product) => product.id == id && product.storeId == storeId,
 );
 _products[index] = _products[index].copyWith(stockQuantity: newQuantity);
 }
}

class _FakeTransactionRepository implements IFinancialTransactionRepository {
 final List<FinancialTransaction> _transactions = [];

 @override
 Future<List<FinancialTransaction>> getAll({required String storeId}) async =>
 List.unmodifiable(_transactions);

 @override
 Future<List<FinancialTransaction>> getByPeriod({
 required String storeId,
 required DateTime start,
 required DateTime end,
 }) async =>
 List.unmodifiable(_transactions);

 @override
 Future<void> add(FinancialTransaction transaction) async =>
 _transactions.add(transaction);

 @override
 Future<void> markAsPaid(String id, {required String storeId}) async {}
}

/// Unit of work real (sem transação de banco): executa a ação dentro de um
/// escopo — usado para verificar que a ação é chamada.
class _RecordingUnitOfWork implements IUnitOfWork {
 int runs = 0;

 @override
 Future<T> run<T>(Future<T> Function() action) async {
 runs++;
 return action();
 }
}

/// Fake do processador atômico (Supabase via RPC) — conta as chamadas.
class _FakePurchaseProcessor implements IPurchaseAtomicProcessor {
 int calls = 0;
 Purchase? lastPurchase;

 @override
 Future<void> process(Purchase purchase) async {
 calls++;
 lastPurchase = purchase;
 }
}

void main() {
 late _FakeProductRepository productRepository;
 late _FakePurchaseRepository purchaseRepository;
 late _FakeTransactionRepository transactionRepository;
 late _RecordingUnitOfWork unitOfWork;
 late FakeStockLotRepository lotRepository;
 late ProcessPurchaseUseCase useCase;

 setUp(() {
 // W11: estoque em MILÉSIMOS (10 unidades = 10000).
 productRepository = _FakeProductRepository([
 const Product(
 id: 'p1',
 name: 'Caneta',
 purchasePriceCents: 100,
 salePriceCents: 200,
 stockQuantity: 10000,
 ),
 ]);
 purchaseRepository = _FakePurchaseRepository();
 transactionRepository = _FakeTransactionRepository();
 unitOfWork = _RecordingUnitOfWork();
 lotRepository = FakeStockLotRepository();
 useCase = ProcessPurchaseUseCase(
 purchaseRepository,
 FifoStockUseCase(
 lotRepository,
 UpdateProductStockUseCase(productRepository),
 ),
 transactionRepository,
 unitOfWork,
 );
 });

 Purchase buildPurchase({
 List<PurchaseItem>? items,
 int? totalAmountCents,
 String supplier = 'Distribuidora',
 PaymentMethod paymentMethod = PaymentMethod.cash,
 }) {
 final effectiveItems = items ??
 const [
 PurchaseItem(
 productId: 'p1',
 productName: 'Caneta',
 quantity: 5000, // 5 unidades em MILÉSIMOS (W11)
 unitPriceCents: 100,
 ),
 ];
 return Purchase(
 id: 'pc1',
 supplierName: supplier,
 items: effectiveItems,
 totalAmountCents: totalAmountCents ?? effectiveItems.fold<int>(
 0,
 (sum, item) =>
 sum + Quantity.lineTotal(item.quantity, item.unitPriceCents),
 ),
 paymentMethod: paymentMethod,
 dateTime: DateTime(2026, 8, 4, 10),
 );
 }

 test('registra compra, aumenta o estoque e lança a saída no caixa', () async {
 await useCase(buildPurchase());

 // Compra registrada.
 expect(
 purchaseRepository.getAll(storeId: 'st1'),
 completion(hasLength(1)),
 );

 // Estoque aumentou (W11: 10000 + 5000 = 15000 milésimos = 15 unidades).
 expect(
 (await productRepository.getById('p1', storeId: 'st1'))?.stockQuantity,
 15000,
 );

 // Lote FIFO criado com a quantidade e o custo da compra.
 final lots = await lotRepository.getActiveByProduct('p1', storeId: 'st1');
 expect(lots, hasLength(1));
 expect(lots.first.currentQuantity, 5000);
 expect(lots.first.costPriceCents, 100);

 // Saída no caixa (categoria Compras, paga).
 final transactions = await transactionRepository.getAll(storeId: 'st1');
 expect(transactions, hasLength(1));
 expect(transactions.first.type, TransactionType.expense);
 expect(transactions.first.category, 'Compras');
 expect(transactions.first.status, TransactionStatus.paid);
 expect(transactions.first.amountCents, 500);

 // Tudo rodou dentro do unit of work.
 expect(unitOfWork.runs, 1);
 });

 test('lança InvalidPurchaseException para compra sem itens', () async {
 await expectLater(
 useCase(buildPurchase(items: const [])),
 throwsA(isA<InvalidPurchaseException>()),
 );

 expect(
 purchaseRepository.getAll(storeId: 'st1'),
 completion(isEmpty),
 );
 });

 test('lança InvalidPurchaseException para total divergente', () async {
 await expectLater(
 useCase(buildPurchase(totalAmountCents: 9900)),
 throwsA(isA<InvalidPurchaseException>()),
 );

 expect(
 purchaseRepository.getAll(storeId: 'st1'),
 completion(isEmpty),
 );
 expect(
 transactionRepository.getAll(storeId: 'st1'),
 completion(isEmpty),
 );
 });

 test('lança InactiveProductException para produto DESATIVADO (nada muda)',
 () async {
 productRepository._products[0] =
 productRepository._products[0].copyWith(isActive: false);

 await expectLater(
 useCase(buildPurchase()),
 throwsA(
 isA<InactiveProductException>()
 .having((e) => e.productId, 'productId', 'p1'),
 ),
 );

 expect(
 purchaseRepository.getAll(storeId: 'st1'),
 completion(isEmpty),
 );
 expect(
 transactionRepository.getAll(storeId: 'st1'),
 completion(isEmpty),
 );
 });

 test('lança ProductNotFoundException para produto inexistente', () async {
 await expectLater(
 useCase(
 buildPurchase(
 items: const [
 PurchaseItem(
 productId: 'nope',
 productName: 'Inexistente',
 quantity: 1000,
 unitPriceCents: 100,
 ),
 ],
 ),
 ),
 throwsA(isA<ProductNotFoundException>()),
 );
 });

 test('delega para o processador atômico quando fornecido (Supabase)',
 () async {
 final processor = _FakePurchaseProcessor();
 final atomicUseCase = ProcessPurchaseUseCase(
 purchaseRepository,
 FifoStockUseCase(
 lotRepository,
 UpdateProductStockUseCase(productRepository),
 ),
 transactionRepository,
 unitOfWork,
 processor: processor,
 );

 final purchase = buildPurchase(paymentMethod: PaymentMethod.mPesa);
 await atomicUseCase(purchase);

 // O caminho composto NÃO roda — a compra inteira é do servidor.
 expect(processor.calls, 1);
 expect(processor.lastPurchase?.id, purchase.id);
 // A forma de pagamento chega intacta ao processador atômico.
 expect(processor.lastPurchase?.paymentMethod, PaymentMethod.mPesa);
 expect(
 purchaseRepository.getAll(storeId: 'st1'),
 completion(isEmpty),
 );
 expect(unitOfWork.runs, 0);
 });

 test('validação continua valendo com processador atômico', () async {
 final processor = _FakePurchaseProcessor();
 final atomicUseCase = ProcessPurchaseUseCase(
 purchaseRepository,
 FifoStockUseCase(
 lotRepository,
 UpdateProductStockUseCase(productRepository),
 ),
 transactionRepository,
 unitOfWork,
 processor: processor,
 );

 // Total divergente → inválido antes de qualquer chamada ao servidor.
 await expectLater(
 atomicUseCase(buildPurchase(totalAmountCents: 9900)),
 throwsA(isA<InvalidPurchaseException>()),
 );
 expect(processor.calls, 0);
 });
}
