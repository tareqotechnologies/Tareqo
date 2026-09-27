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
  /// [rpc] injetável para testes — mesmo contrato do `SaleSupabaseDataSourceImpl`
  /// (`Future<dynamic> Function(String fn, Map<String, dynamic> params)`),
  /// que permite o teste de CONTRATO da RPC `adjust_product_stock` sem
  /// inicializar o cliente real. `null` (padrão) → cliente global
  /// ([supabaseClient]).
  const ProductSupabaseDataSourceImpl({
    Future<dynamic> Function(String fn, Map<String, dynamic> params)? rpc,
  }) : _rpcOverride = rpc;

  final Future<dynamic> Function(String fn, Map<String, dynamic> params)?
  _rpcOverride;

  Future<dynamic> _rpc(String fn, Map<String, dynamic> params) =>
      _rpcOverride != null
      ? _rpcOverride(fn, params)
      : supabaseClient.rpc(fn, params: params);

  /// Em modo de teste (rpc injetado), o guard de sessão é ignorado — o
  /// teste controla o contrato da RPC. Em produção, falha cedo sem sessão.
  void _requireSessionOrTest() {
    if (_rpcOverride == null) requireCurrentUserId();
  }

  static const _table = 'products';

  /// Ajusta manualmente o estoque do produto [productId] da loja [storeId]
  /// para [newQuantity] milésimos — atomicamente no servidor (RPC
  /// `adjust_product_stock`): cria/consome LOTES FIFO e define o total do
  /// produto em UMA transação, com a guarda gerencial
  /// `is_manager_of_store` no servidor (a invariante `stock = Σ lotes`
  /// nunca quebra).
  Future<void> adjustStock(
    String productId,
    int newQuantity, {
    required String storeId,
  }) async {
    _requireSessionOrTest();
    await _rpc('adjust_product_stock', {
      'p_product_id': productId,
      'p_store_id': storeId,
      'p_new_quantity': newQuantity,
    });
  }

  @override
  Future<List<Product>> getAll({required String storeId}) async {
    // Paginação keyset (H2): lotes de pageSize pelo id, sem teto total.
    // O provider de produtos NÃO reordena — mantemos a ordem por nome
    // (mesma do contrato anterior) com um sort local após a coleta.
    final rows =
        await fetchAllKeyset(
            supabaseClient
                .from(_table)
                .select(
                  'id, store_id, name, description, image_path, purchase_price, '
                  'sale_price, stock_quantity, code, venda_por_fracao, '
                  'unit_label, is_active, type',
                )
                .eq('store_id', storeId),
          )
          ..sort(
            (a, b) => (a['name'] as String).compareTo(b['name'] as String),
          );
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
          'id, store_id, name, description, image_path, purchase_price, '
          'sale_price, stock_quantity, code, venda_por_fracao, unit_label, '
          'is_active, type',
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
      'image_path': product.imagePath.isEmpty ? null : product.imagePath,
      'purchase_price': product.purchasePriceCents,
      'sale_price': product.salePriceCents,
      'stock_quantity': product.stockQuantity,
      'code': product.code.isEmpty ? null : product.code,
      'venda_por_fracao': product.vendaPorFracao,
      'unit_label': product.unitLabel,
      'is_active': product.isActive,
      'type': product.type.name,
    });
  }

  @override
  Future<void> update(Product product) async {
    // Atualiza apenas os campos EDITÁVEIS do catálogo — stock_quantity NÃO
    // entra no UPDATE (a mutação de estoque passa pelo FifoStockUseCase,
    // que mantém a invariante `stock = Σ lotes`). Escopo por loja.
    final rows = await supabaseClient
        .from(_table)
        .update({
          'name': product.name,
          'description': product.description,
          'image_path': product.imagePath.isEmpty ? null : product.imagePath,
          'purchase_price': product.purchasePriceCents,
          'sale_price': product.salePriceCents,
          'code': product.code.isEmpty ? null : product.code,
          'venda_por_fracao': product.vendaPorFracao,
          'unit_label': product.unitLabel,
          'is_active': product.isActive,
          'type': product.type.name,
        })
        .eq('id', product.id)
        .eq('store_id', product.storeId)
        .select('id');
    if (rows.isEmpty) {
      throw StateError(
        'Produto ${product.id} não encontrado para atualização.',
      );
    }
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
    imagePath: (row['image_path'] as String?) ?? '',
    purchasePriceCents: (row['purchase_price'] as num).toInt(),
    salePriceCents: (row['sale_price'] as num).toInt(),
    stockQuantity: (row['stock_quantity'] as num).toInt(),
    code: (row['code'] as String?) ?? '',
    vendaPorFracao: row['venda_por_fracao'] as bool? ?? false,
    unitLabel: (row['unit_label'] as String?) ?? 'un',
    // Default true: linhas criadas antes do campo preservam produtos como
    // ATIVOS (a coluna no schema tem DEFAULT true).
    isActive: row['is_active'] as bool? ?? true,
    // Fase 1: default resale — linhas criadas antes da coluna `type` (ou
    // com valor desconhecido) permanecem de revenda, como sempre foram.
    type: ProductType.values.firstWhere(
      (type) => type.name == row['type'] as String?,
      orElse: () => ProductType.resale,
    ),
  );
}
