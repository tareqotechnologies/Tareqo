import 'package:sqlite3/sqlite3.dart';

import '../../../domain/entities/production_order.dart';
import '../../../domain/entities/recipe.dart';
import 'production_local_data_source.dart';

/// Implementação SQLite do [ProductionLocalDataSource] (Fase 2).
///
/// Guarda datas em `millisecondsSinceEpoch` (mesma convenção das demais
/// tabelas). O `saveRecipe` substitui a ficha e os itens juntos (upsert por
/// `recipe.id`); o escopo por loja está em TODAS as consultas e mutações.
///
/// Roda dentro da transação do chamador ([IUnitOfWork] no caminho composto),
/// garantindo que a ordem de produção + baixa/criação de lotes sejam
/// atómicas.
final class ProductionSqliteDataSourceImpl
    implements ProductionLocalDataSource {
  const ProductionSqliteDataSourceImpl(this._db);

  final Database _db;

  static const _recipeColumns =
      'id, store_id, product_id, yield_quantity, is_active, created_at, '
      'updated_at';
  static const _recipeItemColumns = 'recipe_id, product_id, quantity';
  static const _orderColumns =
      'id, store_id, product_id, product_name, quantity, recipe_id, '
      'cost_price, total_cost, date_time';
  static const _orderItemColumns =
      'production_id, product_id, product_name, quantity, unit_cost';

  @override
  Future<List<Recipe>> getRecipes({required String storeId}) async {
    final rows = _db.select(
      'SELECT $_recipeColumns FROM recipes WHERE store_id = ? '
      'ORDER BY created_at DESC',
      [storeId],
    );
    return [for (final row in rows) _mapRecipe(row)];
  }

  @override
  Future<void> saveRecipe(Recipe recipe) async {
    _db.execute(
      'INSERT OR REPLACE INTO recipes ($_recipeColumns) '
      'VALUES (?, ?, ?, ?, ?, ?, ?)',
      [
        recipe.id,
        recipe.storeId,
        recipe.productId,
        recipe.yieldQuantity,
        recipe.isActive ? 1 : 0,
        recipe.createdAt.millisecondsSinceEpoch,
        recipe.updatedAt?.millisecondsSinceEpoch,
      ],
    );
    _db.execute('DELETE FROM recipe_items WHERE recipe_id = ?', [recipe.id]);
    for (final item in recipe.items) {
      _db.execute(
        'INSERT INTO recipe_items ($_recipeItemColumns) VALUES (?, ?, ?)',
        [recipe.id, item.productId, item.quantity],
      );
    }
  }

  @override
  Future<void> deleteRecipe(String recipeId, {required String storeId}) async {
    // Escopo por loja: o WHERE com store_id impede remover ficha de outra.
    _db.execute('DELETE FROM recipe_items WHERE recipe_id = ?', [recipeId]);
    _db.execute('DELETE FROM recipes WHERE id = ? AND store_id = ?', [
      recipeId,
      storeId,
    ]);
  }

  @override
  Future<List<ProductionOrder>> getProductionOrders({
    required String storeId,
  }) async {
    final rows = _db.select(
      'SELECT $_orderColumns FROM production_orders WHERE store_id = ? '
      'ORDER BY date_time DESC',
      [storeId],
    );
    return [for (final row in rows) _mapOrder(row)];
  }

  @override
  Future<void> addProductionOrder(ProductionOrder order) async {
    _db.execute(
      'INSERT INTO production_orders ($_orderColumns) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        order.id,
        order.storeId,
        order.productId,
        order.productName,
        order.quantity,
        order.recipeId,
        order.costPriceCents,
        order.totalCostCents,
        order.dateTime.millisecondsSinceEpoch,
      ],
    );
    for (final item in order.items) {
      _db.execute(
        'INSERT INTO production_order_items ($_orderItemColumns) '
        'VALUES (?, ?, ?, ?, ?)',
        [
          order.id,
          item.productId,
          item.productName,
          item.quantity,
          item.unitCostCents,
        ],
      );
    }
  }

  Recipe _mapRecipe(Row row) => Recipe(
    id: row['id'] as String,
    storeId: row['store_id'] as String,
    productId: row['product_id'] as String,
    yieldQuantity: row['yield_quantity'] as int,
    items: _itemsOf(row['id'] as String),
    isActive: (row['is_active'] as int? ?? 1) == 1,
    createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
    updatedAt: row['updated_at'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int),
  );

  List<RecipeItem> _itemsOf(String recipeId) {
    final rows = _db.select(
      'SELECT $_recipeItemColumns FROM recipe_items WHERE recipe_id = ? '
      'ORDER BY id ASC',
      [recipeId],
    );
    return [
      for (final row in rows)
        RecipeItem(
          productId: row['product_id'] as String,
          quantity: row['quantity'] as int,
        ),
    ];
  }

  ProductionOrder _mapOrder(Row row) => ProductionOrder(
    id: row['id'] as String,
    storeId: row['store_id'] as String,
    productId: row['product_id'] as String,
    productName: row['product_name'] as String,
    quantity: row['quantity'] as int,
    recipeId: row['recipe_id'] as String?,
    costPriceCents: row['cost_price'] as int,
    totalCostCents: row['total_cost'] as int,
    dateTime: DateTime.fromMillisecondsSinceEpoch(row['date_time'] as int),
    items: _orderItemsOf(row['id'] as String),
  );

  List<ProductionItem> _orderItemsOf(String productionId) {
    final rows = _db.select(
      'SELECT $_orderItemColumns FROM production_order_items '
      'WHERE production_id = ? ORDER BY id ASC',
      [productionId],
    );
    return [
      for (final row in rows)
        ProductionItem(
          productId: row['product_id'] as String,
          productName: row['product_name'] as String,
          quantity: row['quantity'] as int,
          unitCostCents: row['unit_cost'] as int,
        ),
    ];
  }
}
