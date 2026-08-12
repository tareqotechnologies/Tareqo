import '../../../domain/entities/sale.dart';
import '../../../domain/entities/sale_item.dart';
import '../../../domain/entities/sale_lot_consumption.dart';
import '../local/sale_local_data_source.dart';
import 'supabase_datasource_helpers.dart';

/// Implementação remota do [SaleLocalDataSource] sobre o Supabase.
///
/// A venda e seus itens são gravados em **uma única requisição** usando o
/// insert aninhado do PostgREST (a FK `sale_items.sale_id → sales.id` faz o
/// vínculo automaticamente; `defaultToNull: false` deixa o `id` serial e as
/// colunas com default no banco). O RLS isola os dados por tenant.
///
/// ⚠️ O método [add] não é atômico (cada chamada REST é uma transação
/// isolada). Por isso o caminho de vendas do Supabase usa [processSale],
/// que delega a função RPC `process_sale` (`SECURITY DEFINER`) — venda +
/// itens + baixa de estoque + entrada no caixa em UMA transação do banco.
final class SaleSupabaseDataSourceImpl implements SaleLocalDataSource {
  /// [rpc] injetável para testes — mesmo contrato do `SupabaseEmployeeProcessor`
  /// (`Future<dynamic> Function(String fn, Map<String, dynamic> params)`),
  /// que permite o teste de CONTRATO da RPC atômica `process_sale` sem
  /// inicializar o cliente real. `null` (padrão) → cliente global
  /// ([supabaseClient]).
  const SaleSupabaseDataSourceImpl({
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

  static const _table = 'sales';

  /// Processa a venda **atomicamente** no servidor (RPC `process_sale`).
  ///
  /// O RPC valida e trava o estoque (`FOR UPDATE`), grava venda + itens,
  /// baixa o estoque e lança a entrada no caixa — tudo em uma única
  /// transação, com `auth.uid()` no servidor. Lança exceção se o estoque
  /// for insuficiente ou se o total não corresponder aos itens.
  Future<void> processSale(Sale sale) async {
    _requireSessionOrTest();
    await _rpc(
      'process_sale',
      {
        'p_sale': {
          'id': sale.id,
          'store_id': sale.storeId,
          'total_amount': sale.totalAmountCents,
          'payment_method': sale.paymentMethod.name,
          'date_time': sale.dateTime.toUtc().toIso8601String(),
        },
        'p_items': [
          for (final item in sale.items)
            {
              'product_id': item.productId,
              'product_name': item.productName,
              'quantity': item.quantity,
              'unit_price': item.unitPriceCents,
            },
        ],
      },
    );
  }

  /// Anula a venda [saleId] da loja [storeId] atomicamente no servidor
  /// (RPC `cancel_sale`): estorna o estoque aos lotes exatos, cria o
  /// estorno de caixa e marca a venda como `cancelled` — tudo em UMA
  /// transação, com a guarda gerencial `is_manager_of_store` no servidor.
  Future<void> cancelSale(String saleId, {required String storeId}) async {
    _requireSessionOrTest();
    await _rpc('cancel_sale', {'p_sale_id': saleId, 'p_store_id': storeId});
  }

  @override
  Future<List<Sale>> getAll({required String storeId}) async {
    // Embedded resource: itens vêm junto na mesma resposta. Paginação
    // keyset (H2): lotes de pageSize pelo id, sem teto total de 1000.
    // A ordem final de exibição (data desc) é aplicada pelo provider.
    final rows = await fetchAllKeyset(
      supabaseClient
          .from(_table)
          .select('*, sale_items(*)')
          .eq('store_id', storeId),
    );
    return List.unmodifiable([for (final row in rows) _map(row)]);
  }

  @override
  Future<Sale?> getById(String id, {required String storeId}) async {
    final rows = await supabaseClient
        .from(_table)
        .select('*, sale_items(*)')
        .eq('id', id)
        .eq('store_id', storeId);
    if (rows.isEmpty) return null;
    return _map(rows.first);
  }

  @override
  Future<void> markCancelled(String id, {required String storeId}) async {
    // ⚠️ Fallback REST (não usado pelo app no modo SaaS — a anulação vai
    // pela RPC cancel_sale, que marca o status no servidor). Melhor
    // esforço para o caminho composto.
    await supabaseClient
        .from(_table)
        .update({'status': 'cancelled', 'cancelled_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', id)
        .eq('store_id', storeId);
  }

  @override
  Future<List<LotConsumption>> getLotConsumption(
    String saleId, {
    required String storeId,
  }) async {
    final rows = await supabaseClient
        .from('sale_lot_consumption')
        .select('lot_id, product_id, quantity')
        .eq('sale_id', saleId);
    return [
      for (final row in rows)
        LotConsumption(
          lotId: row['lot_id'] as String,
          productId: row['product_id'] as String,
          quantity: (row['quantity'] as num).toInt(),
        ),
    ];
  }

  @override
  Future<void> registerLotConsumption(
    String saleId,
    String storeId,
    List<LotConsumption> consumption,
  ) async {
    // ⚠️ Fallback REST (o caminho SaaS grava o consumo DENTRO da RPC
    // process_sale, na mesma transação). Melhor esforço: insert simples.
    if (consumption.isEmpty) return;
    await supabaseClient.from('sale_lot_consumption').insert([
      for (final consumed in consumption)
        {
          'sale_id': saleId,
          'lot_id': consumed.lotId,
          'product_id': consumed.productId,
          'quantity': consumed.quantity,
        },
    ]);
  }

  @override
  Future<void> add(Sale sale) async {
    final userId = requireCurrentUserId();
    // Fallback não-atômico (não usado pelo app no modo SaaS — as vendas
    // vão pela RPC process_sale, que numera no servidor). Melhor esforço:
    // lê o maior sale_number da loja e incrementa.
    final last = await supabaseClient
        .from(_table)
        .select('sale_number')
        .eq('store_id', sale.storeId)
        .order('sale_number', ascending: false)
        .limit(1);
    final nextNumber =
        last.isEmpty ? 1 : ((last.first['sale_number'] as num).toInt() + 1);
    await supabaseClient.from(_table).insert({
      'id': sale.id,
      'user_id': userId,
      'store_id': sale.storeId,
      'sale_number': nextNumber,
      'total_amount': sale.totalAmountCents,
      'payment_method': sale.paymentMethod.name,
      'date_time': sale.dateTime.toUtc().toIso8601String(),
      'sale_items': [
        for (final item in sale.items)
          {
            'user_id': userId,
            'product_id': item.productId,
            'product_name': item.productName,
            'quantity': item.quantity,
            'unit_price': item.unitPriceCents,
          },
      ],
    }, defaultToNull: false);
  }

  Sale _map(Map<String, dynamic> row) => Sale(
    id: row['id'] as String,
    storeId: row['store_id'] as String,
    number: (row['sale_number'] as num?)?.toInt() ?? 0,
    items: [
      for (final item in (row['sale_items'] as List<dynamic>? ?? const []))
        _mapItem(item as Map<String, dynamic>),
    ],
    totalAmountCents: (row['total_amount'] as num).toInt(),
    paymentMethod: PaymentMethod.values.byName(row['payment_method'] as String),
    dateTime: DateTime.parse(row['date_time'] as String).toLocal(),
    status: row['status'] == null
        ? SaleStatus.active
        : SaleStatus.values.byName(row['status'] as String),
    cancelledAt: row['cancelled_at'] == null
        ? null
        : DateTime.parse(row['cancelled_at'] as String).toLocal(),
  );

  SaleItem _mapItem(Map<String, dynamic> row) => SaleItem(
    productId: row['product_id'] as String,
    productName: row['product_name'] as String,
    quantity: (row['quantity'] as num).toInt(),
    unitPriceCents: (row['unit_price'] as num).toInt(),
  );
}
