import '../../../domain/entities/production_order.dart';
import '../../../domain/entities/recipe.dart';

/// Contrato de armazenamento local da PRODUÇÃO (Fase 2 — ficha técnica).
///
/// Declara apenas *o que* a persistência precisa fazer — não *como*.
/// Implementações: memória, SQLite e Supabase (RLS por tenant).
///
/// Cobre os dois agregados do módulo:
///  - **fichas técnicas** ([Recipe]) — configuração editável (upsert/delete);
///  - **ordens de produção** ([ProductionOrder]) — histórico append-only.
///
/// Tudo escopado pela loja [storeId] (Fase 2 do multi-tenancy).
abstract interface class ProductionLocalDataSource {
  /// Fichas técnicas da loja [storeId] (mais recentes primeiro).
  Future<List<Recipe>> getRecipes({required String storeId});

  /// Grava (insere ou atualiza) [recipe] — a ficha e os seus itens são
  /// substituídos juntos (upsert idempotente por `recipe.id`).
  Future<void> saveRecipe(Recipe recipe);

  /// Remove a ficha [recipeId] da loja [storeId] (itens em cascata).
  Future<void> deleteRecipe(String recipeId, {required String storeId});

  /// Ordens de produção da loja [storeId] (mais recentes primeiro).
  Future<List<ProductionOrder>> getProductionOrders({required String storeId});

  /// Registra uma ordem de produção concluída (ordem + itens snapshot).
  Future<void> addProductionOrder(ProductionOrder order);
}
