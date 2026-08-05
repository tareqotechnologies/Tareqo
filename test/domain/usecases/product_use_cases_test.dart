import 'package:flutter_test/flutter_test.dart';

import 'package:dumbhanengue/domain/entities/product.dart';
import 'package:dumbhanengue/domain/repositories/i_product_repository.dart';
import 'package:dumbhanengue/domain/usecases/add_product_use_case.dart';
import 'package:dumbhanengue/domain/usecases/get_products_use_case.dart';
import 'package:dumbhanengue/domain/usecases/update_product_stock_use_case.dart';

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
  double purchasePrice = 1.0,
  double salePrice = 2.0,
}) {
  return Product(
    id: '1',
    name: name,
    purchasePrice: purchasePrice,
    salePrice: salePrice,
  );
}

void main() {
  group('AddProductUseCase', () {
    test('adiciona o produto quando salePrice >= purchasePrice', () async {
      final repository = _FakeProductRepository();
      final useCase = AddProductUseCase(repository);

      await useCase(_product());

      expect(repository.addCalled, isTrue);
      expect(
        repository.getAll(storeId: 'st1'),
        completion(hasLength(1)),
      );
    });

    test('lança InvalidPriceException quando salePrice < purchasePrice',
        () async {
      final repository = _FakeProductRepository();
      final useCase = AddProductUseCase(repository);

      await expectLater(
        useCase(_product(purchasePrice: 3.0, salePrice: 2.0)),
        throwsA(isA<InvalidPriceException>()),
      );

      // O produto inválido não chega ao repositório.
      expect(repository.addCalled, isFalse);
    });

    test('aceita preços iguais (venda = compra)', () async {
      final repository = _FakeProductRepository();
      final useCase = AddProductUseCase(repository);

      await useCase(_product(purchasePrice: 2.0, salePrice: 2.0));

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
