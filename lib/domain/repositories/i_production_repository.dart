import '../entities/production_order.dart';
import '../entities/recipe.dart';

/// Contrato de persistência da PRODUÇÃO (ficha técnica + ordens).
///
/// Declara apenas *o que* o sistema precisa — **não** *como* é feito.
/// Implementações: memória, SQLite e Supabase (RLS por tenant). Tudo
/// escopado pela loja.
abstract interface class IProductionRepository {
  /// Fichas técnicas da loja [storeId] (mais recentes primeiro).
  Future<List<Recipe>> getRecipes({required String storeId});

  /// Grava (upsert) a ficha [recipe] e os seus itens.
  Future<void> saveRecipe(Recipe recipe);

  /// Remove a ficha [recipeId] da loja [storeId].
  Future<void> deleteRecipe(String recipeId, {required String storeId});

  /// Ordens de produção da loja [storeId] (mais recentes primeiro).
  Future<List<ProductionOrder>> getProductionOrders({required String storeId});

  /// Registra uma ordem de produção concluída.
  Future<void> addProductionOrder(ProductionOrder order);
}
