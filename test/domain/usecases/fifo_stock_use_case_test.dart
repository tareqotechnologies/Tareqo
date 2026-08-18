import 'package:flutter_test/flutter_test.dart';

import 'package:dumbhanengue/domain/entities/product.dart';
import 'package:dumbhanengue/domain/entities/stock_lot.dart';
import 'package:dumbhanengue/domain/repositories/i_product_repository.dart';
import 'package:dumbhanengue/domain/usecases/fifo_stock_use_case.dart';
import 'package:dumbhanengue/domain/usecases/update_product_stock_use_case.dart';

import '../../helpers/fake_stock_lot_repository.dart';

/// Fake do [IProductRepository] com mutação de estoque em memória.
class _FakeProductRepository implements IProductRepository {
 _FakeProductRepository(this._products);

 final Map<String, Product> _products;

 @override
 Future<List<Product>> getAll({required String storeId}) async =>
 _products.values.toList();

 @override
 Future<Product?> getById(String id, {required String storeId}) async =>
 _products[id];

 @override
 Future<void> add(Product product) async => _products[product.id] = product;

 @override
 Future<void> update(Product product) async {
 final current = _products[product.id];
 if (current == null) throw StateError('Produto ${product.id} não existe.');
 // Preserva o estoque (a mutação de quantidade passa pelo FIFO).
 _products[product.id] = current.copyWith(
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
 final product = _products[id];
 if (product == null) throw StateError('Produto $id não existe.');
 _products[id] = product.copyWith(stockQuantity: newQuantity);
 }
}

void main() {
 late FakeStockLotRepository lots;
 late _FakeProductRepository products;
 late FifoStockUseCase fifo;

 Product buildProduct(String id, int stockQuantity) => Product(
 id: id,
 storeId: 'st1',
 name: 'Produto $id',
 purchasePriceCents: 100,
 salePriceCents: 200,
 stockQuantity: stockQuantity,
 );

 StockLot buildLot(
 String id, {
 required int current,
 DateTime? expiry,
 DateTime? entry,
 String storeId = 'st1',
 }) =>
 StockLot(
 id: id,
 storeId: storeId,
 productId: 'p1',
 entryDate: entry ?? DateTime(2026, 1, 1),
 expiryDate: expiry,
 initialQuantity: current,
 currentQuantity: current,
 costPriceCents: 500,
 );

 setUp(() {
 lots = FakeStockLotRepository();
 // Invariante central (W11): product.stock = Σ lotes ativos. Cada teste
 // de baixa semeia produto e lotes com totais CASADOS (o produto começa
 // zerado nos testes de entrada, que criam o lote).
 products = _FakeProductRepository({
 'p1': buildProduct('p1', 0),
 });
 fifo = FifoStockUseCase(lots, UpdateProductStockUseCase(products));
 });

 /// Alinha o estoque do produto à soma dos lotes (invariante W11).
 Future<void> seedLots(List<StockLot> seed) async {
 for (final lot in seed) {
 await lots.add(lot);
 }
 final total = seed.fold<int>(0, (sum, lot) => sum + lot.currentQuantity);
 await products.updateStock('p1', total, storeId: 'st1');
 }

 group('decrease (baixa FIFO)', () {
 test('abate do lote com validade mais próxima primeiro', () async {
 await seedLots([
 buildLot('l1', current: 1000, expiry: DateTime(2026, 6, 1)),
 buildLot('l2', current: 1000, expiry: DateTime(2026, 3, 1)),
 buildLot('l3', current: 1000, expiry: DateTime(2026, 9, 1)),
 ]);

 await fifo.decrease('p1', 500, storeId: 'st1');

 // Lote l2 (vence primeiro) abatido; l1 e l3 intactos.
 final after = await lots.getActiveByProduct('p1', storeId: 'st1');
 final byId = {for (final lot in after) lot.id: lot.currentQuantity};
 expect(byId['l1'], 1000);
 expect(byId['l2'], 500);
 expect(byId['l3'], 1000);
 // Total do produto acompanha os lotes (invariante central).
 expect((await products.getById('p1', storeId: 'st1'))!.stockQuantity, 2500);
 });

 test('lotes sem validade são consumidos por data de entrada (depois dos com validade)',
 () async {
 // l1 sem validade e ANTIGO; l2 sem validade e NOVO; l3 com validade próxima.
 await seedLots([
 buildLot('l1', current: 1000, entry: DateTime(2026, 1, 1)),
 buildLot('l2', current: 1000, entry: DateTime(2026, 5, 1)),
 buildLot('l3', current: 1000, expiry: DateTime(2026, 2, 1)),
 ]);

 // Baixa maior que o lote com validade: o excedente vai para o lote
 // sem validade MAIS ANTIGO (FIFO por entrada).
 await fifo.decrease('p1', 1500, storeId: 'st1');

 final after = await lots.getActiveByProduct('p1', storeId: 'st1');
 final byId = {for (final lot in after) lot.id: lot.currentQuantity};
 // Lote zerado saiu da lista ativa (não está mais no mapa).
 expect(byId.containsKey('l3'), isFalse); // consumido por completo
 expect(byId['l1'], 500); // excedente abatido do mais antigo
 expect(byId['l2'], 1000);
 });

 test('abate de múltiplos lotes em sequência quando a quantidade excede', () async {
 await seedLots([
 buildLot('l1', current: 500, expiry: DateTime(2026, 3, 1)),
 buildLot('l2', current: 300, expiry: DateTime(2026, 4, 1)),
 buildLot('l3', current: 900, expiry: DateTime(2026, 5, 1)),
 ]);

 await fifo.decrease('p1', 1000, storeId: 'st1');

 final after = await lots.getActiveByProduct('p1', storeId: 'st1');
 final byId = {for (final lot in after) lot.id: lot.currentQuantity};
 // l1 e l2 zerados saíram da lista ativa; excedente (200) do l3.
 expect(byId.containsKey('l1'), isFalse);
 expect(byId.containsKey('l2'), isFalse);
 expect(byId['l3'], 700);
 expect(after, hasLength(1));
 });

 test('lança InsufficientStockException quando os lotes não cobrem', () async {
 await seedLots([buildLot('l1', current: 200)]);

 expect(
 () => fifo.decrease('p1', 300, storeId: 'st1'),
 throwsA(
 isA<InsufficientStockException>()
 .having((e) => e.available, 'available', 200)
 .having((e) => e.requested, 'requested', 300),
 ),
 );
 // Nada foi mutado (pré-validação atômica antes de abater).
 final after = await lots.getActiveByProduct('p1', storeId: 'st1');
 expect(after.single.currentQuantity, 200);
 });

 test('lança ProductNotFoundException para produto inexistente', () async {
 expect(
 () => fifo.decrease('fantasma', 100, storeId: 'st1'),
 throwsA(isA<ProductNotFoundException>()),
 );
 });
 });

 group('increase (entrada cria lote)', () {
 test('cria lote novo com quantidade inicial = atual e aumenta o total', () async {
 await fifo.increase('p1', 1750, storeId: 'st1', costPriceCents: 800);

 final after = await lots.getActiveByProduct('p1', storeId: 'st1');
 expect(after, hasLength(1));
 expect(after.single.initialQuantity, 1750);
 expect(after.single.currentQuantity, 1750);
 expect(after.single.costPriceCents, 800);
 expect(after.single.expiryDate, isNull);
 expect((await products.getById('p1', storeId: 'st1'))!.stockQuantity, 1750);
 });

 test('registra a data de validade quando fornecida', () async {
 final expiry = DateTime(2026, 12, 31);
 await fifo.increase('p1', 1000, storeId: 'st1', expiryDate: expiry);

 final after = await lots.getActiveByProduct('p1', storeId: 'st1');
 expect(after.single.expiryDate, expiry);
 });
 });

 group('ensureSufficientStock', () {
 test('passa quando a soma dos lotes cobre a quantidade', () async {
 await lots.add(buildLot('l1', current: 800));
 await lots.add(buildLot('l2', current: 700));

 await fifo.ensureSufficientStock('p1', 1500, storeId: 'st1');
 // Não lançou → sucesso.
 });

 test('lança com a soma real dos lotes quando falta', () async {
 await lots.add(buildLot('l1', current: 800));

 expect(
 () => fifo.ensureSufficientStock('p1', 1000, storeId: 'st1'),
 throwsA(
 isA<InsufficientStockException>()
 .having((e) => e.available, 'available', 800),
 ),
 );
 });
 });
}
