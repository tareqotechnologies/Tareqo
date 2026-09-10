import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/domain/entities/product.dart';
import 'package:tareqo/domain/repositories/i_product_repository.dart';
import 'package:tareqo/domain/usecases/update_product_stock_use_case.dart';

/// Fake do repositório de produtos — mesma semântica de escopo por loja
/// das implementações reais (SQLite/Supabase/memória).
class _FakeProductRepository implements IProductRepository {
  final List<Product> items;

  _FakeProductRepository(this.items);

  @override
  Future<List<Product>> getAll({required String storeId}) async =>
      items.where((p) => p.storeId == storeId).toList();

  @override
  Future<Product?> getById(String id, {required String storeId}) async {
    for (final product in items) {
      if (product.id == id && product.storeId == storeId) return product;
    }
    return null;
  }

  @override
  Future<void> add(Product product) async => items.add(product);

  @override
  Future<void> update(Product product) async {
    final index = items.indexWhere((p) => p.id == product.id);
    items[index] = product;
  }

  @override
  Future<void> updateStock(
    String id,
    int newQuantity, {
    required String storeId,
  }) async {
    final index = items.indexWhere((p) => p.id == id && p.storeId == storeId);
    if (index == -1) throw StateError('Produto $id não encontrado.');
    items[index] = items[index].copyWith(stockQuantity: newQuantity);
  }
}

Product _product(
  String id, {
  int stock = 100,
  bool active = true,
  String storeId = 'st1',
}) => Product(
  id: id,
  storeId: storeId,
  name: 'Prod $id',
  purchasePriceCents: 500,
  salePriceCents: 900,
  stockQuantity: stock,
  isActive: active,
);

void main() {
  group('UpdateProductStockUseCase — a única porta de mutação de estoque', () {
    test(
      'requireProduct lança ProductNotFoundException para inexistente',
      () async {
        final repository = _FakeProductRepository([]);
        final useCase = UpdateProductStockUseCase(repository);

        await expectLater(
          useCase.requireProduct('fantasma', storeId: 'st1'),
          throwsA(isA<ProductNotFoundException>()),
        );
      },
    );

    test('requireProduct acha o produto na loja certa', () async {
      final repository = _FakeProductRepository([_product('p1')]);
      final useCase = UpdateProductStockUseCase(repository);

      await expectLater(
        useCase.requireProduct('p1', storeId: 'st1'),
        completes,
      );
    });

    test(
      'requireActive lança InactiveProductException para desativado',
      () async {
        final repository = _FakeProductRepository([
          _product('p1', active: false),
        ]);
        final useCase = UpdateProductStockUseCase(repository);

        await expectLater(
          useCase.requireActive('p1', storeId: 'st1'),
          throwsA(isA<InactiveProductException>()),
        );
      },
    );

    test('requireActive passa para produto ativo', () async {
      final repository = _FakeProductRepository([_product('p1')]);
      final useCase = UpdateProductStockUseCase(repository);

      await expectLater(useCase.requireActive('p1', storeId: 'st1'), completes);
    });

    test(
      'deve rejeitar venda quando o estoque disponível é insuficiente',
      () async {
        final repository = _FakeProductRepository([
          _product('p1', stock: 3000),
        ]);
        final useCase = UpdateProductStockUseCase(repository);

        await expectLater(
          useCase.ensureSufficientStock('p1', 5000, storeId: 'st1'),
          throwsA(
            isA<InsufficientStockException>()
                .having((e) => e.available, 'available', 3000)
                .having((e) => e.requested, 'requested', 5000),
          ),
        );
      },
    );

    test('estoque exatamente igual ao pedido é SUFICIENTE (limite)', () async {
      final repository = _FakeProductRepository([_product('p1', stock: 5000)]);
      final useCase = UpdateProductStockUseCase(repository);

      await expectLater(
        useCase.ensureSufficientStock('p1', 5000, storeId: 'st1'),
        completes,
      );
    });

    test('decrease revalida e NUNCA deixa o estoque ficar negativo', () async {
      final repository = _FakeProductRepository([_product('p1', stock: 3000)]);
      final useCase = UpdateProductStockUseCase(repository);

      await expectLater(
        useCase.decrease('p1', 5000, storeId: 'st1'),
        throwsA(isA<InsufficientStockException>()),
      );
      // Defesa em profundidade: nada foi mutado.
      expect(
        (await repository.getById('p1', storeId: 'st1'))!.stockQuantity,
        3000,
      );
    });

    test('decrease válido grava o valor restante', () async {
      final repository = _FakeProductRepository([_product('p1', stock: 3000)]);
      final useCase = UpdateProductStockUseCase(repository);

      await useCase.decrease('p1', 2500, storeId: 'st1');

      expect(
        (await repository.getById('p1', storeId: 'st1'))!.stockQuantity,
        500,
      );
    });

    test('decrease de estoque ZERO rejeita qualquer quantidade', () async {
      final repository = _FakeProductRepository([_product('p1', stock: 0)]);
      final useCase = UpdateProductStockUseCase(repository);

      await expectLater(
        useCase.decrease('p1', 1, storeId: 'st1'),
        throwsA(isA<InsufficientStockException>()),
      );
    });

    test('increase soma ao estoque atual (entrada de mercadoria)', () async {
      final repository = _FakeProductRepository([_product('p1', stock: 1000)]);
      final useCase = UpdateProductStockUseCase(repository);

      await useCase.increase('p1', 2500, storeId: 'st1');

      expect(
        (await repository.getById('p1', storeId: 'st1'))!.stockQuantity,
        3500,
      );
    });

    test('escopo por loja: produto de outra loja não é encontrado', () async {
      final repository = _FakeProductRepository([
        _product('p1', storeId: 'st1'),
      ]);
      final useCase = UpdateProductStockUseCase(repository);

      await expectLater(
        useCase.increase('p1', 1, storeId: 'st2'),
        throwsA(isA<ProductNotFoundException>()),
      );
      await expectLater(
        useCase.ensureSufficientStock('p1', 1, storeId: 'st2'),
        throwsA(isA<ProductNotFoundException>()),
      );
    });

    test('mensagens das exceções de domínio são legíveis (UI)', () {
      // toString alimenta mensagens de erro na UI/snackbar.
      expect(const ProductNotFoundException('p1').toString(), contains('p1'));
      expect(
        const InactiveProductException('p1').toString(),
        contains('desativado'),
      );
      expect(
        const InsufficientStockException(
          productId: 'p1',
          available: 3,
          requested: 5,
        ).toString(),
        contains('insuficiente'),
      );
    });
  });
}
