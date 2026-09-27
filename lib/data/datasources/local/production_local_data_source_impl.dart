import '../../../domain/entities/production_order.dart';
import '../../../domain/entities/recipe.dart';
import 'production_local_data_source.dart';

/// Implementação em MEMÓRIA do [ProductionLocalDataSource] (web/fallback e
/// testes). Mantém a mesma semântica do SQLite/Supabase: upsert por
/// `recipe.id`, escopo por loja e histórico de ordens append-only.
final class ProductionLocalDataSourceImpl implements ProductionLocalDataSource {
  ProductionLocalDataSourceImpl({
    List<Recipe> recipes = const [],
    List<ProductionOrder> orders = const [],
  }) : _recipes = [...recipes],
       _orders = [...orders];

  final List<Recipe> _recipes;
  final List<ProductionOrder> _orders;

  @override
  Future<List<Recipe>> getRecipes({required String storeId}) async {
    final result =
        _recipes.where((recipe) => recipe.storeId == storeId).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(result);
  }

  @override
  Future<void> saveRecipe(Recipe recipe) async {
    final index = _recipes.indexWhere((r) => r.id == recipe.id);
    if (index == -1) {
      _recipes.add(recipe);
    } else {
      _recipes[index] = recipe;
    }
  }

  @override
  Future<void> deleteRecipe(String recipeId, {required String storeId}) async {
    _recipes.removeWhere(
      (recipe) => recipe.id == recipeId && recipe.storeId == storeId,
    );
  }

  @override
  Future<List<ProductionOrder>> getProductionOrders({
    required String storeId,
  }) async {
    final result = _orders.where((order) => order.storeId == storeId).toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return List.unmodifiable(result);
  }

  @override
  Future<void> addProductionOrder(ProductionOrder order) async {
    _orders.add(order);
  }
}
