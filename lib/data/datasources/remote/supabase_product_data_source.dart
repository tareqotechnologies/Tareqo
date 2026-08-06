import '../../../domain/entities/product.dart';
import '../local/product_local_data_source.dart';
import 'supabase_datasource_helpers.dart';

/// Implementação remota do [ProductLocalDataSource] sobre o Supabase.
///
/// Todas as consultas levam o JWT do usuário (sessão do `supabase_flutter`);
/// o RLS (`auth.uid() = user_id`) isola os dados por tenant no banco. O
/// `user_id` é gravado explicitamente nos INSERTs (o trigger do schema
/// reforça com `auth.uid()`).
///
/// Registrado no ServiceLocator quando `SupabaseConfig.isConfigured` —
/// mesmo contrato dos datasources SQLite/memória, então o domínio, os casos
/// de uso e a UI não mudam.
final class ProductSupabaseDataSourceImpl implements ProductLocalDataSource {
  const ProductSupabaseDataSourceImpl();

  static const _table = 'products';

  @override
  Future<List<Product>> getAll({required String storeId}) async {
    // Paginação keyset (H2): lotes de pageSize pelo id, sem teto total.
    // O provider de produtos NÃO reordena — mantemos a ordem por nome
    // (mesma do contrato anterior) com um sort local após a coleta.
    final rows = await fetchAllKeyset(
      supabaseClient
          .from(_table)
          .select(
            'id, store_id, name, description, purchase_price, sale_price, '
            'stock_quantity',
          )
          .eq('store_id', storeId),
    )..sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
    return List.unmodifiable([for (final row in rows) _map(row)]);
  }

  @override
  Future<Product?> getById(String id, {required String storeId}) async {
    // Escopo por loja: além do RLS, filtra a loja — um id de outra loja
    // não é visível mesmo que o RLS permita a linha (defesa em
    // profundidade).
    final row = await supabaseClient
        .from(_table)
        .select(
          'id, store_id, name, description, purchase_price, sale_price, '
          'stock_quantity',
        )
        .eq('id', id)
        .eq('store_id', storeId)
        .maybeSingle();
    return row == null ? null : _map(row);
  }

  @override
  Future<void> add(Product product) async {
    await supabaseClient.from(_table).insert({
      'id': product.id,
      'user_id': requireCurrentUserId(),
      'store_id': product.storeId,
      'name': product.name,
      'description': product.description,
      'purchase_price': product.purchasePriceCents,
      'sale_price': product.salePriceCents,
      'stock_quantity': product.stockQuantity,
    });
  }

  @override
  Future<void> updateStock(
    String id,
    int newQuantity, {
    required String storeId,
  }) async {
    // Escopo por loja: o filtro store_id impede mutar produto de outra
    // loja (defesa em profundidade além do RLS).
    final rows = await supabaseClient
        .from(_table)
        .update({'stock_quantity': newQuantity})
        .eq('id', id)
        .eq('store_id', storeId)
        .select('id');
    if (rows.isEmpty) {
      throw StateError(
        'Produto $id não encontrado para atualização de estoque.',
      );
    }
  }

  Product _map(Map<String, dynamic> row) => Product(
    id: row['id'] as String,
    storeId: row['store_id'] as String,
    name: row['name'] as String,
    description: (row['description'] as String?) ?? '',
    purchasePriceCents: (row['purchase_price'] as num).toInt(),
    salePriceCents: (row['sale_price'] as num).toInt(),
    stockQuantity: (row['stock_quantity'] as num).toInt(),
  );
}
