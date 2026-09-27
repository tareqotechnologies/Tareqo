import '../../../domain/entities/production_order.dart';
import '../../../domain/entities/recipe.dart';
import '../local/production_local_data_source.dart';
import 'supabase_datasource_helpers.dart';

/// Implementação remota do [ProductionLocalDataSource] sobre o Supabase.
///
/// Fichas técnicas e histórico de produção usam o PostgREST com inserts
/// aninhados (FKs `recipe_items.recipe_id` / `production_order_items.
/// production_id`); o RLS isola por tenant.
///
/// A ORDEM DE PRODUÇÃO (consumo FIFO dos componentes + criação do lote do
/// produto acabado) NÃO passa por aqui no modo SaaS: usa [processProduction],
/// que delega à RPC `process_production` (`SECURITY DEFINER`) — tudo em UMA
/// transação no servidor.
final class ProductionSupabaseDataSourceImpl
    implements ProductionLocalDataSource {
  /// [rpc] injetável para testes — mesmo contrato do
  /// `PurchaseSupabaseDataSourceImpl` (permite o teste de contrato da RPC
  /// atómica sem inicializar o cliente real). `null` → cliente global.
  const ProductionSupabaseDataSourceImpl({
    Future<dynamic> Function(String fn, Map<String, dynamic> params)? rpc,
  }) : _rpcOverride = rpc;

  final Future<dynamic> Function(String fn, Map<String, dynamic> params)?
  _rpcOverride;

  Future<dynamic> _rpc(String fn, Map<String, dynamic> params) =>
      _rpcOverride != null
      ? _rpcOverride(fn, params)
      : supabaseClient.rpc(fn, params: params);

  void _requireSessionOrTest() {
    if (_rpcOverride == null) requireCurrentUserId();
  }

  static const _recipes = 'recipes';
  static const _orders = 'production_orders';

  /// Processa a produção **atomicamente** no servidor (RPC
  /// `process_production`): valida componentes/produto acabado, baixa os
  /// componentes em FIFO, grava a ordem + itens e cria o lote do produto
  /// acabado — uma única transação com `auth.uid()`.
  Future<void> processProduction(ProductionOrder order) async {
    _requireSessionOrTest();
    await _rpc('process_production', {
      'p_order': {
        'id': order.id,
        'store_id': order.storeId,
        'product_id': order.productId,
        'product_name': order.productName,
        'quantity': order.quantity,
        'recipe_id': order.recipeId,
        'cost_price': order.costPriceCents,
        'total_cost': order.totalCostCents,
        'date_time': order.dateTime.toUtc().toIso8601String(),
      },
      'p_items': [
        for (final item in order.items)
          {
            'product_id': item.productId,
            'product_name': item.productName,
            'quantity': item.quantity,
            'unit_cost': item.unitCostCents,
          },
      ],
    });
  }

  @override
  Future<List<Recipe>> getRecipes({required String storeId}) async {
    final rows = await fetchAllKeyset(
      supabaseClient
          .from(_recipes)
          .select('*, recipe_items(*)')
          .eq('store_id', storeId),
    );
    return List.unmodifiable([for (final row in rows) _mapRecipe(row)]);
  }

  @override
  Future<void> saveRecipe(Recipe recipe) async {
    final userId = requireCurrentUserId();
    // Substitui os itens da ficha (config, não documento): apaga os antigos
    // e faz upsert da ficha com o conjunto novo aninhado.
    await supabaseClient
        .from('recipe_items')
        .delete()
        .eq('recipe_id', recipe.id);
    await supabaseClient.from(_recipes).upsert({
      'id': recipe.id,
      'user_id': userId,
      'store_id': recipe.storeId,
      'product_id': recipe.productId,
      'yield_quantity': recipe.yieldQuantity,
      'is_active': recipe.isActive,
      'created_at': recipe.createdAt.toUtc().toIso8601String(),
      'updated_at': recipe.updatedAt?.toUtc().toIso8601String(),
      'recipe_items': [
        for (final item in recipe.items)
          {
            'user_id': userId,
            'product_id': item.productId,
            'quantity': item.quantity,
          },
      ],
    }, defaultToNull: false);
  }

  @override
  Future<void> deleteRecipe(String recipeId, {required String storeId}) async {
    // Itens em cascata pela FK; escopo por loja (defesa em profundidade).
    await supabaseClient
        .from(_recipes)
        .delete()
        .eq('id', recipeId)
        .eq('store_id', storeId);
  }

  @override
  Future<List<ProductionOrder>> getProductionOrders({
    required String storeId,
  }) async {
    final rows = await fetchAllKeyset(
      supabaseClient
          .from(_orders)
          .select('*, production_order_items(*)')
          .eq('store_id', storeId),
    );
    return List.unmodifiable([for (final row in rows) _mapOrder(row)]);
  }

  @override
  Future<void> addProductionOrder(ProductionOrder order) async {
    final userId = requireCurrentUserId();
    // Fallback não-atómico (não usado pelo app no modo SaaS — as ordens vão
    // pela RPC process_production).
    await supabaseClient.from(_orders).insert({
      'id': order.id,
      'user_id': userId,
      'store_id': order.storeId,
      'product_id': order.productId,
      'product_name': order.productName,
      'quantity': order.quantity,
      'recipe_id': order.recipeId,
      'cost_price': order.costPriceCents,
      'total_cost': order.totalCostCents,
      'date_time': order.dateTime.toUtc().toIso8601String(),
      'production_order_items': [
        for (final item in order.items)
          {
            'user_id': userId,
            'product_id': item.productId,
            'product_name': item.productName,
            'quantity': item.quantity,
            'unit_cost': item.unitCostCents,
          },
      ],
    }, defaultToNull: false);
  }

  Recipe _mapRecipe(Map<String, dynamic> row) => Recipe(
    id: row['id'] as String,
    storeId: row['store_id'] as String,
    productId: row['product_id'] as String,
    yieldQuantity: (row['yield_quantity'] as num).toInt(),
    items: [
      for (final item in (row['recipe_items'] as List<dynamic>? ?? const []))
        RecipeItem(
          productId: (item as Map<String, dynamic>)['product_id'] as String,
          quantity: (item['quantity'] as num).toInt(),
        ),
    ],
    isActive: row['is_active'] as bool? ?? true,
    createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
    updatedAt: row['updated_at'] == null
        ? null
        : DateTime.parse(row['updated_at'] as String).toLocal(),
  );

  ProductionOrder _mapOrder(Map<String, dynamic> row) => ProductionOrder(
    id: row['id'] as String,
    storeId: row['store_id'] as String,
    productId: row['product_id'] as String,
    productName: row['product_name'] as String,
    quantity: (row['quantity'] as num).toInt(),
    recipeId: row['recipe_id'] as String?,
    costPriceCents: (row['cost_price'] as num).toInt(),
    totalCostCents: (row['total_cost'] as num).toInt(),
    dateTime: DateTime.parse(row['date_time'] as String).toLocal(),
    items: [
      for (final item
          in (row['production_order_items'] as List<dynamic>? ?? const []))
        ProductionItem(
          productId: (item as Map<String, dynamic>)['product_id'] as String,
          productName: item['product_name'] as String,
          quantity: (item['quantity'] as num).toInt(),
          unitCostCents: (item['unit_cost'] as num).toInt(),
        ),
    ],
  );
}
