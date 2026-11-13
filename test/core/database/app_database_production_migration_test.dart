import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:tareqo/core/database/app_database_io.dart';
import 'package:tareqo/data/datasources/local/production_sqlite_data_source_impl.dart';
import 'package:tareqo/domain/entities/production_order.dart';
import 'package:tareqo/domain/entities/recipe.dart';

/// Fase 2 — migração v8 (ficha técnica + produção):
/// - banco novo nasce com as 4 tabelas (recipes/recipe_items/
///   production_orders/production_order_items);
/// - banco legado (v7) recebe as tabelas ao migrar;
/// - round-trip de fichas (upsert substitui itens) e ordens (com itens).
void main() {
  group('migração v8 — ficha técnica + produção', () {
    test('banco novo cria as 4 tabelas e versiona 8', () {
      final db = sqlite3.openInMemory();
      addTearDown(db.close);

      AppDatabase.initialize(db);

      for (final table in const [
        'recipes',
        'recipe_items',
        'production_orders',
        'production_order_items',
      ]) {
        expect(
          db.select(
            "SELECT name FROM sqlite_master WHERE type='table' AND name = ?",
            [table],
          ),
          isNotEmpty,
          reason: 'tabela $table',
        );
      }
      expect(
        db.select('PRAGMA user_version').first['user_version'],
        AppDatabase.currentSchemaVersion,
      );
    });

    test('banco legado v7 recebe as tabelas ao reabrir', () {
      final db = sqlite3.openInMemory();
      addTearDown(db.close);

      AppDatabase.initialize(db);
      // Simula um banco da era v7: schema completo SEM as tabelas de produção.
      db.execute('PRAGMA user_version = 7');
      for (final table in const [
        'production_order_items',
        'production_orders',
        'recipe_items',
        'recipes',
      ]) {
        db.execute('DROP TABLE IF EXISTS $table');
      }

      // when — reabrir: roda APENAS a v8.
      AppDatabase.initialize(db);

      expect(
        db.select(
          "SELECT name FROM sqlite_master WHERE type='table' AND name = 'recipes'",
        ),
        isNotEmpty,
      );
      expect(
        db.select('PRAGMA user_version').first['user_version'],
        AppDatabase.currentSchemaVersion,
      );

      // Idempotência: re-inicializar não quebra.
      AppDatabase.initialize(db);
      expect(
        db.select('PRAGMA user_version').first['user_version'],
        AppDatabase.currentSchemaVersion,
      );
    });

    test('round-trip de ficha técnica (upsert substitui os itens)', () async {
      final db = sqlite3.openInMemory();
      addTearDown(db.close);
      AppDatabase.initialize(db);
      final dataSource = ProductionSqliteDataSourceImpl(db);

      await dataSource.saveRecipe(
        Recipe(
          id: 'r1',
          productId: 'p-bread',
          yieldQuantity: 1000,
          items: const [
            RecipeItem(productId: 'p-flour', quantity: 500),
            RecipeItem(productId: 'p-sugar', quantity: 250),
          ],
          createdAt: DateTime(2026, 1, 1),
        ),
      );

      var recipes = await dataSource.getRecipes(storeId: 'st1');
      expect(recipes.single.items.length, 2);
      expect(recipes.single.yieldQuantity, 1000);

      // Regravar substitui os itens (não acumula).
      await dataSource.saveRecipe(
        recipes.single.copyWith(
          items: const [RecipeItem(productId: 'p-sugar', quantity: 400)],
          updatedAt: DateTime(2026, 2, 1),
        ),
      );
      recipes = await dataSource.getRecipes(storeId: 'st1');
      expect(recipes.single.items.single.productId, 'p-sugar');
      expect(recipes.single.items.single.quantity, 400);
      expect(recipes.single.updatedAt, isNotNull);

      await dataSource.deleteRecipe('r1', storeId: 'st1');
      expect(await dataSource.getRecipes(storeId: 'st1'), isEmpty);
    });

    test('round-trip de ordem de produção com itens', () async {
      final db = sqlite3.openInMemory();
      addTearDown(db.close);
      AppDatabase.initialize(db);
      final dataSource = ProductionSqliteDataSourceImpl(db);

      await dataSource.addProductionOrder(
        ProductionOrder(
          id: 'prod1',
          productId: 'p-bread',
          productName: 'Pão',
          quantity: 2000,
          recipeId: 'r1',
          costPriceCents: 400,
          totalCostCents: 800,
          dateTime: DateTime(2026, 2, 1),
          items: const [
            ProductionItem(
              productId: 'p-flour',
              productName: 'Farinha',
              quantity: 1000,
              unitCostCents: 200,
            ),
          ],
        ),
      );

      final orders = await dataSource.getProductionOrders(storeId: 'st1');
      expect(orders.single.id, 'prod1');
      expect(orders.single.quantity, 2000);
      expect(orders.single.costPriceCents, 400);
      expect(orders.single.items.single.productName, 'Farinha');

      // Escopo por loja: outra loja não vê a ordem.
      expect(await dataSource.getProductionOrders(storeId: 'st2'), isEmpty);
    });
  });
}
