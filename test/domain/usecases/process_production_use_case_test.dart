import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/core/utils/quantity.dart';
import 'package:tareqo/data/datasources/local/product_local_data_source_impl.dart';
import 'package:tareqo/data/datasources/local/production_local_data_source_impl.dart';
import 'package:tareqo/data/datasources/local/stock_lot_local_data_source_impl.dart';
import 'package:tareqo/data/repositories/product_repository_impl.dart';
import 'package:tareqo/data/repositories/production_repository_impl.dart';
import 'package:tareqo/data/repositories/stock_lot_repository_impl.dart';
import 'package:tareqo/domain/entities/product.dart';
import 'package:tareqo/domain/entities/recipe.dart';
import 'package:tareqo/domain/entities/stock_lot.dart';
import 'package:tareqo/domain/repositories/i_unit_of_work.dart';
import 'package:tareqo/domain/usecases/fifo_stock_use_case.dart';
import 'package:tareqo/domain/usecases/process_production_use_case.dart';
import 'package:tareqo/domain/usecases/production_use_cases.dart';
import 'package:tareqo/domain/usecases/update_product_stock_use_case.dart';

/// UnitOfWork direta (sem transação real — memória já é sequencial),
/// mesma dos demais testes de caso de uso.
class _DirectUnitOfWork implements IUnitOfWork {
  const _DirectUnitOfWork();

  @override
  Future<T> run<T>(Future<T> Function() action) => action();
}

void main() {
  late ProductLocalDataSourceImpl productDs;
  late StockLotLocalDataSourceImpl lotDs;
  late ProductionLocalDataSourceImpl productionDs;
  late ProductionRepositoryImpl productionRepo;
  late FifoStockUseCase fifo;
  late ProcessProductionUseCase processProduction;

  setUp(() {
    productDs = ProductLocalDataSourceImpl();
    lotDs = StockLotLocalDataSourceImpl();
    productionDs = ProductionLocalDataSourceImpl();
    productionRepo = ProductionRepositoryImpl(productionDs);
    final productRepo = ProductRepositoryImpl(productDs);
    final lotRepo = StockLotRepositoryImpl(lotDs);
    fifo = FifoStockUseCase(lotRepo, UpdateProductStockUseCase(productRepo));
    processProduction = ProcessProductionUseCase(
      productionRepo,
      fifo,
      const _DirectUnitOfWork(),
    );
  });

  /// Semeia um produto ATIVO com estoque (produto + lote alinhados —
  /// invariante `stock = Σ lotes`).
  Future<Product> seedProduct({
    required String id,
    required String name,
    required ProductType type,
    required int stock,
    required int purchasePriceCents,
    bool isActive = true,
  }) async {
    final product = Product(
      id: id,
      name: name,
      purchasePriceCents: purchasePriceCents,
      salePriceCents: purchasePriceCents + 100,
      stockQuantity: stock,
      type: type,
      isActive: isActive,
    );
    await ProductRepositoryImpl(productDs).add(product);
    await lotDs.add(
      StockLot(
        id: 'lot-$id',
        productId: id,
        entryDate: DateTime(2026, 1, 1),
        initialQuantity: stock,
        currentQuantity: stock,
        costPriceCents: purchasePriceCents,
      ),
    );
    return product;
  }

  Recipe recipeOf({
    required String productId,
    List<RecipeItem> items = const [],
    int yieldQuantity = 1000,
  }) => Recipe(
    id: 'r1',
    productId: productId,
    yieldQuantity: yieldQuantity,
    items: items,
    createdAt: DateTime(2026, 1, 1),
  );

  test(
    'consome componentes em FIFO, produz o lote e calcula o custo',
    () async {
      final flour = await seedProduct(
        id: 'p-flour',
        name: 'Farinha',
        type: ProductType.rawMaterial,
        stock: 10000,
        purchasePriceCents: 200,
      );
      final sugar = await seedProduct(
        id: 'p-sugar',
        name: 'Açúcar',
        type: ProductType.rawMaterial,
        stock: 5000,
        purchasePriceCents: 300,
      );
      final bread = await seedProduct(
        id: 'p-bread',
        name: 'Pão',
        type: ProductType.manufactured,
        stock: 0,
        purchasePriceCents: 0,
      );

      final recipe = recipeOf(
        productId: bread.id,
        yieldQuantity: 1000,
        items: const [
          RecipeItem(productId: 'p-flour', quantity: 500),
          RecipeItem(productId: 'p-sugar', quantity: 1000),
        ],
      );

      final order = await processProduction.call(
        recipe: recipe,
        finishedProduct: bread,
        components: {flour.id: flour, sugar.id: sugar},
        batches: 2,
        dateTime: DateTime(2026, 2, 1),
      );

      // Consumo: 2 bases → 1000 farinha + 2000 açúcar.
      final flourAfter = await productDs.getById('p-flour', storeId: 'st1');
      final sugarAfter = await productDs.getById('p-sugar', storeId: 'st1');
      final breadAfter = await productDs.getById('p-bread', storeId: 'st1');
      expect(flourAfter!.stockQuantity, 9000);
      expect(sugarAfter!.stockQuantity, 3000);
      // Produzido: 2 × 1000 = 2000 milésimos.
      expect(breadAfter!.stockQuantity, 2000);

      // Custo: (1000×200 + 2000×300)/1000 = 200 + 600 = 800; por unidade
      // 800×1000/2000 = 400.
      expect(order.totalCostCents, 800);
      expect(order.costPriceCents, 400);
      expect(order.quantity, 2000);
      expect(order.items.length, 2);

      // O lote do produto acabado nasce com o custo calculado.
      final lots = await lotDs.getActiveByProduct('p-bread', storeId: 'st1');
      expect(lots.single.currentQuantity, 2000);
      expect(lots.single.costPriceCents, 400);

      // A ordem fica no histórico.
      final orders = await productionRepo.getProductionOrders(storeId: 'st1');
      expect(orders.single.id, order.id);
      expect(orders.single.productName, 'Pão');
    },
  );

  test('estoque insuficiente não muta nada (nem grava a ordem)', () async {
    final flour = await seedProduct(
      id: 'p-flour',
      name: 'Farinha',
      type: ProductType.rawMaterial,
      stock: 1000,
      purchasePriceCents: 200,
    );
    final bread = await seedProduct(
      id: 'p-bread',
      name: 'Pão',
      type: ProductType.manufactured,
      stock: 0,
      purchasePriceCents: 0,
    );
    final recipe = recipeOf(
      productId: bread.id,
      yieldQuantity: 1000,
      items: const [RecipeItem(productId: 'p-flour', quantity: 500)],
    );

    await expectLater(
      processProduction.call(
        recipe: recipe,
        finishedProduct: bread,
        components: {flour.id: flour},
        batches: 4, // precisa 2000, tem 1000
      ),
      throwsA(isA<InsufficientStockException>()),
    );

    final flourAfter = await productDs.getById('p-flour', storeId: 'st1');
    expect(flourAfter!.stockQuantity, 1000);
    expect(await productionRepo.getProductionOrders(storeId: 'st1'), isEmpty);
  });

  test(
    'produto acabado precisa ser produzível (manufactured/composite)',
    () async {
      final bread = await seedProduct(
        id: 'p-water',
        name: 'Água',
        type: ProductType.resale,
        stock: 0,
        purchasePriceCents: 0,
      );
      final recipe = recipeOf(
        productId: bread.id,
        items: const [RecipeItem(productId: 'p-flour', quantity: 100)],
      );

      await expectLater(
        processProduction.call(
          recipe: recipe,
          finishedProduct: bread,
          components: const {},
          batches: 1,
        ),
        throwsA(isA<InvalidProductionException>()),
      );
    },
  );

  test('o produto acabado não pode ser componente da própria ficha', () async {
    final bread = await seedProduct(
      id: 'p-bread',
      name: 'Pão',
      type: ProductType.manufactured,
      stock: 5000,
      purchasePriceCents: 100,
    );
    final recipe = recipeOf(
      productId: bread.id,
      items: const [RecipeItem(productId: 'p-bread', quantity: 100)],
    );

    await expectLater(
      processProduction.call(
        recipe: recipe,
        finishedProduct: bread,
        components: {bread.id: bread},
        batches: 1,
      ),
      throwsA(isA<InvalidProductionException>()),
    );
  });

  test('componente desativado é rejeitado', () async {
    final flour = await seedProduct(
      id: 'p-flour',
      name: 'Farinha',
      type: ProductType.rawMaterial,
      stock: 5000,
      purchasePriceCents: 200,
      isActive: false,
    );
    final bread = await seedProduct(
      id: 'p-bread',
      name: 'Pão',
      type: ProductType.manufactured,
      stock: 0,
      purchasePriceCents: 0,
    );
    final recipe = recipeOf(
      productId: bread.id,
      items: const [RecipeItem(productId: 'p-flour', quantity: 500)],
    );

    await expectLater(
      processProduction.call(
        recipe: recipe,
        finishedProduct: bread,
        components: {flour.id: flour},
        batches: 1,
      ),
      throwsA(isA<InvalidProductionException>()),
    );
  });

  group('SaveRecipeUseCase', () {
    late SaveRecipeUseCase saveRecipe;

    setUp(() {
      saveRecipe = SaveRecipeUseCase(productionRepo, const _DirectUnitOfWork());
    });

    test('grava ficha válida e substitui os itens ao regravar', () async {
      final recipe = recipeOf(
        productId: 'p-bread',
        items: const [RecipeItem(productId: 'p-flour', quantity: 500)],
      );
      await saveRecipe.call(recipe);

      await saveRecipe.call(
        recipe.copyWith(
          items: const [RecipeItem(productId: 'p-sugar', quantity: 250)],
        ),
      );

      final saved = await productionRepo.getRecipes(storeId: 'st1');
      expect(saved.single.items.single.productId, 'p-sugar');
      expect(saved.single.items.single.quantity, 250);
    });

    test('rejeita ficha sem itens, rendimento zero e autocomposição', () async {
      await expectLater(
        saveRecipe.call(recipeOf(productId: 'p-bread')),
        throwsA(isA<InvalidRecipeException>()),
      );
      await expectLater(
        saveRecipe.call(
          recipeOf(
            productId: 'p-bread',
            yieldQuantity: 0,
            items: const [RecipeItem(productId: 'p-flour', quantity: 500)],
          ),
        ),
        throwsA(isA<InvalidRecipeException>()),
      );
      await expectLater(
        saveRecipe.call(
          recipeOf(
            productId: 'p-bread',
            items: const [RecipeItem(productId: 'p-bread', quantity: 500)],
          ),
        ),
        throwsA(isA<InvalidRecipeException>()),
      );
    });

    test('rejeita componente repetido e quantidade zero', () async {
      await expectLater(
        saveRecipe.call(
          recipeOf(
            productId: 'p-bread',
            items: const [
              RecipeItem(productId: 'p-flour', quantity: 500),
              RecipeItem(productId: 'p-flour', quantity: 200),
            ],
          ),
        ),
        throwsA(isA<InvalidRecipeException>()),
      );
      await expectLater(
        saveRecipe.call(
          recipeOf(
            productId: 'p-bread',
            items: const [RecipeItem(productId: 'p-flour', quantity: 0)],
          ),
        ),
        throwsA(isA<InvalidRecipeException>()),
      );
    });

    test('DeleteRecipeUseCase remove só a ficha da loja', () async {
      final deleteRecipe = DeleteRecipeUseCase(productionRepo);
      await saveRecipe.call(
        recipeOf(
          productId: 'p-bread',
          items: const [RecipeItem(productId: 'p-flour', quantity: 500)],
        ),
      );
      await deleteRecipe.call('r1', storeId: 'st1');
      expect(await productionRepo.getRecipes(storeId: 'st1'), isEmpty);
    });
  });

  test('Quantity helpers batem com a aritmética de custo usada', () {
    // Guarda contra regressão: 1000 milésimos × 200 centavos = 200 centavos.
    expect(Quantity.lineTotal(1000, 200), 200);
  });
}
