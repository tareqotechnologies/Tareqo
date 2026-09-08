import '../../../domain/entities/purchase.dart';
import '../../../domain/entities/sale.dart' show PaymentMethod;
import '../local/purchase_local_data_source.dart';
import 'supabase_datasource_helpers.dart';

/// Implementação remota do [PurchaseLocalDataSource] sobre o Supabase.
///
/// A compra e seus itens são gravados em **uma única requisição** via insert
/// aninhado do PostgREST (FK `purchase_items.purchase_id → purchases.id`;
/// `defaultToNull: false` deixa o `id` serial no banco). O RLS isola os
/// dados por tenant.
///
/// Atenção: O caminho de compras do Supabase usa [processPurchase], que delega a
/// função RPC `process_purchase` (`SECURITY DEFINER`) — compra + itens +
/// entrada de estoque + saída no caixa em UMA transação do banco.
final class PurchaseSupabaseDataSourceImpl implements PurchaseLocalDataSource {
  /// [rpc] injetável para testes — mesmo contrato do `SupabaseEmployeeProcessor`
  /// (`Future<dynamic> Function(String fn, Map<String, dynamic> params)`),
  /// que permite o teste de CONTRATO da RPC atômica `process_purchase` sem
  /// inicializar o cliente real. `null` (padrão) → cliente global
  /// ([supabaseClient]).
  const PurchaseSupabaseDataSourceImpl({
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

  static const _table = 'purchases';

  /// Processa a compra **atomicamente** no servidor (RPC `process_purchase`).
  ///
  /// O RPC valida a existência dos produtos, grava compra + itens, aumenta
  /// o estoque e lança a saída no caixa — tudo em uma única transação, com
  /// `auth.uid()` no servidor.
  Future<void> processPurchase(Purchase purchase) async {
    _requireSessionOrTest();
    await _rpc('process_purchase', {
      'p_purchase': {
        'id': purchase.id,
        'store_id': purchase.storeId,
        'supplier_name': purchase.supplierName,
        'total_amount': purchase.totalAmountCents,
        'payment_method': purchase.paymentMethod.name,
        'date_time': purchase.dateTime.toUtc().toIso8601String(),
      },
      'p_items': [
        for (final item in purchase.items)
          {
            'product_id': item.productId,
            'product_name': item.productName,
            'quantity': item.quantity,
            'unit_price': item.unitPriceCents,
            // W11: validade opcional do lote FIFO criado no servidor.
            'expiry_date': item.expiryDate?.toUtc().toIso8601String(),
          },
      ],
    });
  }

  @override
  Future<List<Purchase>> getAll({required String storeId}) async {
    // Embedded resource: itens vêm junto na mesma resposta. Paginação
    // keyset (H2): lotes de pageSize pelo id, sem teto total de 1000.
    // A ordem final de exibição (data desc) é aplicada pelo provider.
    final rows = await fetchAllKeyset(
      supabaseClient
          .from(_table)
          .select('*, purchase_items(*)')
          .eq('store_id', storeId),
    );
    return List.unmodifiable([for (final row in rows) _map(row)]);
  }

  @override
  Future<void> add(Purchase purchase) async {
    final userId = requireCurrentUserId();
    // Fallback não-atômico (não usado pelo app no modo SaaS — as compras
    // vão pela RPC process_purchase, que numera no servidor). Melhor
    // esforço: lê o maior purchase_number da loja e incrementa.
    final last = await supabaseClient
        .from(_table)
        .select('purchase_number')
        .eq('store_id', purchase.storeId)
        .order('purchase_number', ascending: false)
        .limit(1);
    final nextNumber = last.isEmpty
        ? 1
        : ((last.first['purchase_number'] as num).toInt() + 1);
    await supabaseClient.from(_table).insert({
      'id': purchase.id,
      'user_id': userId,
      'store_id': purchase.storeId,
      'purchase_number': nextNumber,
      'supplier_name': purchase.supplierName,
      'total_amount': purchase.totalAmountCents,
      'payment_method': purchase.paymentMethod.name,
      'date_time': purchase.dateTime.toUtc().toIso8601String(),
      'purchase_items': [
        for (final item in purchase.items)
          {
            'user_id': userId,
            'product_id': item.productId,
            'product_name': item.productName,
            'quantity': item.quantity,
            'unit_price': item.unitPriceCents,
            'expiry_date': item.expiryDate?.toUtc().toIso8601String(),
          },
      ],
    }, defaultToNull: false);
  }

  Purchase _map(Map<String, dynamic> row) => Purchase(
    id: row['id'] as String,
    storeId: row['store_id'] as String,
    number: (row['purchase_number'] as num?)?.toInt() ?? 0,
    supplierName: row['supplier_name'] as String,
    items: [
      for (final item in (row['purchase_items'] as List<dynamic>? ?? const []))
        PurchaseItem(
          productId: (item as Map<String, dynamic>)['product_id'] as String,
          productName: item['product_name'] as String,
          quantity: (item['quantity'] as num).toInt(),
          unitPriceCents: (item['unit_price'] as num).toInt(),
          expiryDate: item['expiry_date'] == null
              ? null
              : DateTime.parse(item['expiry_date'] as String).toLocal(),
        ),
    ],
    totalAmountCents: (row['total_amount'] as num).toInt(),
    paymentMethod: PaymentMethod.values.byName(
      // Defensivo: linhas antigas sem a coluna (pré-migração) são
      // interpretadas como pagamento à vista.
      row['payment_method'] as String? ?? 'cash',
    ),
    dateTime: DateTime.parse(row['date_time'] as String).toLocal(),
  );
}
