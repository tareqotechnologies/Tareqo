import '../../domain/entities/production_order.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/repositories/i_production_repository.dart';
import '../datasources/local/production_local_data_source.dart';

/// Implementação de [IProductionRepository] sobre um
/// [ProductionLocalDataSource] — não sabe se os dados vêm da memória, do
/// SQLite ou do Supabase.
final class ProductionRepositoryImpl implements IProductionRepository {
  const ProductionRepositoryImpl(this._localDataSource);

  final ProductionLocalDataSource _localDataSource;

  @override
  Future<List<Recipe>> getRecipes({required String storeId}) =>
      _localDataSource.getRecipes(storeId: storeId);

  @override
  Future<void> saveRecipe(Recipe recipe) => _localDataSource.saveRecipe(recipe);

  @override
  Future<void> deleteRecipe(String recipeId, {required String storeId}) =>
      _localDataSource.deleteRecipe(recipeId, storeId: storeId);

  @override
  Future<List<ProductionOrder>> getProductionOrders({
    required String storeId,
  }) => _localDataSource.getProductionOrders(storeId: storeId);

  @override
  Future<void> addProductionOrder(ProductionOrder order) =>
      _localDataSource.addProductionOrder(order);
}
