import '../../../domain/entities/purchase.dart';
import '../local/purchase_local_data_source.dart';
import 'supabase_datasource_helpers.dart';

/// Implementação remota do [PurchaseLocalDataSource] sobre o Supabase.
///
/// A compra e seus itens são gravados em **uma única requisição** via insert
/// aninhado do PostgREST (FK `purchase_items.purchase_id → purchases.id`;
/// `defaultToNull: false` deixa o `id` serial no banco). O RLS isola os
/// dados por tenant.
///
/// ⚠️ O caminho de compras do Supabase usa [processPurchase], que delega a
/// função RPC `process_purchase` (`SECURITY DEFINER`) — compra + itens +
/// entrada de estoque + saída no caixa em UMA transação do banco.
final class PurchaseSupabaseDataSourceImpl implements PurchaseLocalDataSource {
  const PurchaseSupabaseDataSourceImpl();

  static const _table = 'purchases';

  /// Processa a compra **atomicamente** no servidor (RPC `process_purchase`).
  ///
  /// O RPC valida a existência dos produtos, grava compra + itens, aumenta
  /// o estoque e lança a saída no caixa — tudo em uma única transação, com
  /// `auth.uid()` no servidor.
  Future<void> processPurchase(Purchase purchase) async {
    requireCurrentUserId(); // Falha cedo (cliente) se não houver sessão.
    await supabaseClient.rpc(
      'process_purchase',
      params: {
        'p_purchase': {
          'id': purchase.id,
          'store_id': purchase.storeId,
          'supplier_name': purchase.supplierName,
          'total_amount': purchase.totalAmountCents,
          'date_time': purchase.dateTime.toUtc().toIso8601String(),
        },
        'p_items': [
          for (final item in purchase.items)
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
    await supabaseClient.from(_table).insert({
      'id': purchase.id,
      'user_id': userId,
      'store_id': purchase.storeId,
      'supplier_name': purchase.supplierName,
      'total_amount': purchase.totalAmountCents,
      'date_time': purchase.dateTime.toUtc().toIso8601String(),
      'purchase_items': [
        for (final item in purchase.items)
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

  Purchase _map(Map<String, dynamic> row) => Purchase(
    id: row['id'] as String,
    storeId: row['store_id'] as String,
    supplierName: row['supplier_name'] as String,
    items: [
      for (final item in (row['purchase_items'] as List<dynamic>? ?? const []))
        PurchaseItem(
          productId: (item as Map<String, dynamic>)['product_id'] as String,
          productName: item['product_name'] as String,
          quantity: (item['quantity'] as num).toInt(),
          unitPriceCents: (item['unit_price'] as num).toInt(),
        ),
    ],
    totalAmountCents: (row['total_amount'] as num).toInt(),
    dateTime: DateTime.parse(row['date_time'] as String).toLocal(),
  );
}
