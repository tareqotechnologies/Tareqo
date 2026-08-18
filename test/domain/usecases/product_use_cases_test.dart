import 'package:flutter_test/flutter_test.dart';

import 'package:dumbhanengue/core/utils/quantity.dart';
import 'package:dumbhanengue/domain/entities/product.dart';
import 'package:dumbhanengue/domain/repositories/i_product_repository.dart';
import 'package:dumbhanengue/domain/repositories/i_unit_of_work.dart';
import 'package:dumbhanengue/domain/usecases/add_product_use_case.dart';
import 'package:dumbhanengue/domain/usecases/get_products_use_case.dart';
import 'package:dumbhanengue/domain/usecases/update_product_stock_use_case.dart';

import '../../helpers/fake_stock_lot_repository.dart';

/// Fake em memória do [IProductRepository] — sem rede nem banco,
/// demonstrando a testabilidade que os contratos garantem.
class _FakeProductRepository implements IProductRepository {
 final List<Product> _products = [];
 bool addCalled = false;

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
 Future<void> add(Product product) async {
 addCalled = true;
 _products.add(product);
 }

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

Product _product({
 String name = 'Caneta',
 int purchasePriceCents = 100,
 int salePriceCents = 200,
 int stockUnits = 0,
}) {
 return Product(
 id: '1',
 name: name,
 purchasePriceCents: purchasePriceCents,
 salePriceCents: salePriceCents,
 // W11: estoque em MILÉSIMOS.
 stockQuantity: Quantity.fromUnits(stockUnits),
 );
}

/// Unit of work no-op (o caminho composto é coberto pelos testes SQLite).
class _DirectUnitOfWork implements IUnitOfWork {
 const _DirectUnitOfWork();

 @override
 Future<T> run<T>(Future<T> Function() action) => action();
}

void main() {
 group('AddProductUseCase', () {
 test('adiciona o produto quando salePrice >= purchasePrice', () async {
 final repository = _FakeProductRepository();
 final lots = FakeStockLotRepository();
 final useCase = AddProductUseCase(
 repository,
 lots,
 const _DirectUnitOfWork(),
 );

 await useCase(_product());

 expect(repository.addCalled, isTrue);
 expect(
 repository.getAll(storeId: 'st1'),
 completion(hasLength(1)),
 );
 });

 test('cria lote inicial quando o cadastro informa estoque', () async {
 final repository = _FakeProductRepository();
 final lots = FakeStockLotRepository();
 final useCase = AddProductUseCase(
 repository,
 lots,
 const _DirectUnitOfWork(),
 );

 await useCase(_product(stockUnits: 5));

 // Lote criado sem validade, com a quantidade e o custo do cadastro
 // (invariante W11: estoque do produto = Σ lotes).
 final lotList = await lots.getByStore(storeId: 'st1');
 expect(lotList, hasLength(1));
 expect(lotList.first.currentQuantity, 5000);
 expect(lotList.first.expiryDate, isNull);
 expect(lotList.first.costPriceCents, 100);
 });

 test('carimba a validade no lote inicial quando informada', () async {
 final repository = _FakeProductRepository();
 final lots = FakeStockLotRepository();
 final useCase = AddProductUseCase(
 repository,
 lots,
 const _DirectUnitOfWork(),
 );

 final expiry = DateTime(2026, 12, 31);
 await useCase(_product(stockUnits: 5), expiryDate: expiry);

 // O lote inicial nasce com a validade do cadastro — é ela que
 // alimenta os alertas do dashboard (Vermelho: vencido; Amarelo:
 // vence em < 30 dias).
 final lotList = await lots.getByStore(storeId: 'st1');
 expect(lotList, hasLength(1));
 expect(lotList.first.currentQuantity, 5000);
 expect(lotList.first.expiryDate, expiry);
 });

 test('lança InvalidPriceException quando salePrice < purchasePrice',
 () async {
 final repository = _FakeProductRepository();
 final lots = FakeStockLotRepository();
 final useCase = AddProductUseCase(
 repository,
 lots,
 const _DirectUnitOfWork(),
 );

 await expectLater(
 useCase(_product(purchasePriceCents: 300, salePriceCents: 200)),
 throwsA(isA<InvalidPriceException>()),
 );

 // O produto inválido não chega ao repositório.
 expect(repository.addCalled, isFalse);
 });

 test('aceita preços iguais (venda = compra)', () async {
 final repository = _FakeProductRepository();
 final lots = FakeStockLotRepository();
 final useCase = AddProductUseCase(
 repository,
 lots,
 const _DirectUnitOfWork(),
 );

 await useCase(_product(purchasePriceCents: 200, salePriceCents: 200));

 expect(repository.addCalled, isTrue);
 });
 });

 group('GetProductsUseCase', () {
 test('retorna a lista de produtos do repositório', () async {
 final repository = _FakeProductRepository();
 await repository.add(_product(name: 'Caderno'));

 final result =
 await GetProductsUseCase(repository)(storeId: 'st1');

 expect(result, hasLength(1));
 expect(result.first.name, 'Caderno');
 });
 });

 group('UpdateProductStockUseCase.increase', () {
 test('aumenta o estoque pelo valor absoluto novo', () async {
 final repository = _FakeProductRepository();
 await repository.add(_product());
 final useCase = UpdateProductStockUseCase(repository);

 await useCase.increase('1', 4, storeId: 'st1'); // estoque default 0 + 4

 expect((await repository.getById('1', storeId: 'st1'))?.stockQuantity, 4);
 });

 test('lança ProductNotFoundException para produto inexistente', () async {
 final repository = _FakeProductRepository();
 final useCase = UpdateProductStockUseCase(repository);

 await expectLater(
 useCase.increase('nope', 1, storeId: 'st1'),
 throwsA(isA<ProductNotFoundException>()),
 );
 });
 });
}
