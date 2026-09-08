import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/domain/entities/product.dart';
import 'package:tareqo/domain/entities/stock_lot.dart';
import 'package:tareqo/domain/repositories/i_product_repository.dart';
import 'package:tareqo/domain/repositories/i_stock_adjustment_processor.dart';
import 'package:tareqo/domain/repositories/i_unit_of_work.dart';
import 'package:tareqo/domain/usecases/add_product_use_case.dart';
import 'package:tareqo/domain/usecases/fifo_stock_use_case.dart';
import 'package:tareqo/domain/usecases/update_product_stock_use_case.dart';
import 'package:tareqo/domain/usecases/update_product_use_case.dart';

import '../../helpers/fake_stock_lot_repository.dart';

/// Fake em memória do [IProductRepository] — edição preserva o estoque
/// (a mutação de quantidade passa pelo FIFO).
class _FakeProductRepository implements IProductRepository {
  final List<Product> _products = [];

  @override
  Future<List<Product>> getAll({required String storeId}) async =>
      List.unmodifiable(_products.where((p) => p.storeId == storeId));

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
    if (index == -1) {
      throw StateError('Produto ${product.id} não encontrado.');
    }
    final current = _products[index];
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
      (p) => p.id == id && p.storeId == storeId,
    );
    _products[index] = _products[index].copyWith(stockQuantity: newQuantity);
  }
}

/// Unit of work no-op (a atomicidade real é coberta pelos testes SQLite).
class _DirectUnitOfWork implements IUnitOfWork {
  const _DirectUnitOfWork();

  @override
  Future<T> run<T>(Future<T> Function() action) => action();
}

/// Fake do processador atômico (Supabase via RPC adjust_product_stock).
class _FakeStockAdjustmentProcessor implements IStockAdjustmentProcessor {
  int calls = 0;
  String? lastProductId;
  int? lastQuantity;
  String? lastStoreId;

  @override
  Future<void> adjustStock(
    String productId,
    int newQuantity, {
    required String storeId,
  }) async {
    calls++;
    lastProductId = productId;
    lastQuantity = newQuantity;
    lastStoreId = storeId;
  }
}

Product _product({
  String id = '1',
  String name = 'Caneta',
  int purchasePriceCents = 100,
  int salePriceCents = 200,
  int stockMilli = 0,
  bool isActive = true,
}) {
  return Product(
    id: id,
    name: name,
    purchasePriceCents: purchasePriceCents,
    salePriceCents: salePriceCents,
    // W11: estoque em MILÉSIMOS.
    stockQuantity: stockMilli,
    isActive: isActive,
  );
}

/// Monta o cenário padrão: produto '1' com estoque coberto por um lote
/// (invariante W11 — o ajuste para baixo consome lotes).
(_FakeProductRepository, FakeStockLotRepository, UpdateProductUseCase) _build({
  int stockMilli = 5000,
}) {
  final repository = _FakeProductRepository();
  final lots = FakeStockLotRepository();
  repository.add(_product(stockMilli: stockMilli));
  if (stockMilli > 0) {
    lots.add(
      StockLot(
        id: 'lot-1',
        productId: '1',
        entryDate: DateTime(2026, 1, 1),
        expiryDate: null,
        initialQuantity: stockMilli,
        currentQuantity: stockMilli,
        costPriceCents: 100,
      ),
    );
  }
  final useCase = UpdateProductUseCase(
    repository,
    FifoStockUseCase(lots, UpdateProductStockUseCase(repository)),
    const _DirectUnitOfWork(),
  );
  return (repository, lots, useCase);
}

void main() {
  group('UpdateProductUseCase.updateDetails', () {
    test('atualiza nome/preços/status e PRESERVA o estoque', () async {
      final (repository, _, useCase) = _build();
      final original = await repository.getById('1', storeId: 'st1');

      await useCase.updateDetails(
        original!.copyWith(
          name: 'Caneta Azul',
          salePriceCents: 250,
          isActive: false,
        ),
      );

      final updated = await repository.getById('1', storeId: 'st1');
      expect(updated?.name, 'Caneta Azul');
      expect(updated?.salePriceCents, 250);
      expect(updated?.isActive, isFalse);
      // O estoque NÃO é tocado por esta porta (invariante stock = Σ lotes).
      expect(updated?.stockQuantity, original.stockQuantity);
    });

    test(
      'lança InvalidPriceException quando venda < compra (nada muda)',
      () async {
        final (repository, _, useCase) = _build();
        final original = await repository.getById('1', storeId: 'st1');

        await expectLater(
          useCase.updateDetails(
            original!.copyWith(salePriceCents: 50, name: 'NaoDeve'),
          ),
          throwsA(isA<InvalidPriceException>()),
        );

        final after = await repository.getById('1', storeId: 'st1');
        expect(after?.name, 'Caneta'); // inalterado
      },
    );
  });

  group('UpdateProductUseCase.setActive', () {
    test('desativa e reativa o produto', () async {
      final (repository, _, useCase) = _build();

      await useCase.setActive('1', storeId: 'st1', isActive: false);
      expect(
        (await repository.getById('1', storeId: 'st1'))?.isActive,
        isFalse,
      );

      await useCase.setActive('1', storeId: 'st1', isActive: true);
      expect((await repository.getById('1', storeId: 'st1'))?.isActive, isTrue);
    });

    test('é no-op quando o status já é o desejado', () async {
      final (repository, _, useCase) = _build();

      await useCase.setActive('1', storeId: 'st1', isActive: true);
      // Sem exceção — nada foi gravado (sem atualização redundante).
      expect((await repository.getById('1', storeId: 'st1'))?.isActive, isTrue);
    });

    test('lança ProductNotFoundException para produto inexistente', () async {
      final (_, _, useCase) = _build();

      await expectLater(
        useCase.setActive('nope', storeId: 'st1', isActive: false),
        throwsA(isA<ProductNotFoundException>()),
      );
    });
  });

  group('UpdateProductUseCase.adjustStock', () {
    test('valor igual é no-op (nada é gravado)', () async {
      final (repository, lots, useCase) = _build(stockMilli: 5000);

      await useCase.adjustStock('1', 5000, storeId: 'st1');

      // Sem lote novo e estoque intacto.
      final lotList = await lots.getByStore(storeId: 'st1');
      expect(lotList, hasLength(1));
      expect(
        (await repository.getById('1', storeId: 'st1'))?.stockQuantity,
        5000,
      );
    });

    test(
      'aumento cria lote novo e define o total (invariante stock = Σ lotes)',
      () async {
        final (repository, lots, useCase) = _build(stockMilli: 5000);

        await useCase.adjustStock('1', 7500, storeId: 'st1');

        final product = await repository.getById('1', storeId: 'st1');
        expect(product?.stockQuantity, 7500);
        final lotList = await lots.getByStore(storeId: 'st1');
        expect(lotList, hasLength(2));
        // O lote novo nasce com a quantidade e o custo do catálogo.
        final sum = lotList.fold<int>(
          0,
          (acc, lot) => acc + lot.currentQuantity,
        );
        expect(sum, 7500);
        expect(lotList.last.costPriceCents, 100);
        expect(lotList.last.expiryDate, isNull);
      },
    );

    test('redução consome os lotes em ordem FIFO e define o total', () async {
      final repository = _FakeProductRepository();
      final lots = FakeStockLotRepository();
      // Dois lotes com validades diferentes (FIFO: o mais próximo primeiro).
      repository.add(_product(stockMilli: 3000));
      lots.add(
        StockLot(
          id: 'l1',
          productId: '1',
          entryDate: DateTime(2026, 1, 1),
          expiryDate: DateTime(2026, 6, 1),
          initialQuantity: 1000,
          currentQuantity: 1000,
          costPriceCents: 100,
        ),
      );
      lots.add(
        StockLot(
          id: 'l2',
          productId: '1',
          entryDate: DateTime(2026, 1, 1),
          expiryDate: DateTime(2026, 3, 1),
          initialQuantity: 2000,
          currentQuantity: 2000,
          costPriceCents: 100,
        ),
      );
      final useCase = UpdateProductUseCase(
        repository,
        FifoStockUseCase(lots, UpdateProductStockUseCase(repository)),
        const _DirectUnitOfWork(),
      );

      // 3000 → 1500: abate 1500 — o lote l2 (vence primeiro) é consumido.
      await useCase.adjustStock('1', 1500, storeId: 'st1');

      expect(
        (await repository.getById('1', storeId: 'st1'))?.stockQuantity,
        1500,
      );
      final after = await lots.getActiveByProduct('1', storeId: 'st1');
      final byId = {for (final lot in after) lot.id: lot.currentQuantity};
      expect(byId['l1'], 1000);
      expect(byId['l2'], 500);
    });

    test('lança ProductNotFoundException para produto inexistente', () async {
      final (_, _, useCase) = _build();

      await expectLater(
        useCase.adjustStock('nope', 1000, storeId: 'st1'),
        throwsA(isA<ProductNotFoundException>()),
      );
    });

    test(
      'produto inexistente tem precedência sobre quantidade negativa',
      () async {
        final (_, _, useCase) = _build();

        // Id inexistente + valor negativo → ProductNotFoundException (e não
        // ArgumentError): o erro de existência é mais informativo.
        await expectLater(
          useCase.adjustStock('nope', -100, storeId: 'st1'),
          throwsA(isA<ProductNotFoundException>()),
        );
      },
    );

    test('rejeita quantidade negativa', () async {
      final (_, _, useCase) = _build();

      await expectLater(
        useCase.adjustStock('1', -100, storeId: 'st1'),
        throwsArgumentError,
      );
    });

    test(
      'delega para o processador atômico quando fornecido (Supabase)',
      () async {
        final repository = _FakeProductRepository();
        final lots = FakeStockLotRepository();
        repository.add(_product(stockMilli: 5000));
        final processor = _FakeStockAdjustmentProcessor();

        final useCase = UpdateProductUseCase(
          repository,
          FifoStockUseCase(lots, UpdateProductStockUseCase(repository)),
          const _DirectUnitOfWork(),
          stockAdjustmentProcessor: processor,
        );

        await useCase.adjustStock('1', 9000, storeId: 'st1');

        // Tudo do caminho composto fica para o servidor.
        expect(processor.calls, 1);
        expect(processor.lastProductId, '1');
        expect(processor.lastQuantity, 9000);
        expect(processor.lastStoreId, 'st1');
        expect(await lots.getByStore(storeId: 'st1'), isEmpty);
        expect(
          (await repository.getById('1', storeId: 'st1'))?.stockQuantity,
          5000,
        );
      },
    );
  });
}
