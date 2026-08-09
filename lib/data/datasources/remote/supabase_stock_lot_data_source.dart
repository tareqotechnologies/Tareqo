import '../../../domain/entities/stock_lot.dart';
import '../local/stock_lot_local_data_source.dart';
import 'supabase_datasource_helpers.dart';

/// Implementação remota do [StockLotLocalDataSource] sobre o Supabase.
///
/// Mesmo contrato dos demais datasources remotos: RLS isola por tenant
/// (`auth.uid() = user_id`) e o `user_id` é gravado explicitamente nos
/// INSERTs (o trigger do schema reforça com `auth.uid()`).
///
/// A **ordem FIFO** é pedida ao PostgREST: `expiry_date ASC NULLS LAST` e,
/// no desempate, `entry_date ASC, id ASC` (vencimento mais próximo
/// primeiro; lotes sem validade no fim, por data de entrada).
final class StockLotSupabaseDataSourceImpl implements StockLotLocalDataSource {
  const StockLotSupabaseDataSourceImpl();

  static const _table = 'stock_lots';

  static const _columns =
      'id, store_id, product_id, entry_date, expiry_date, initial_quantity, '
      'current_quantity, cost_price';

  @override
  Future<List<StockLot>> getActiveByProduct(
    String productId, {
    required String storeId,
  }) async {
    final rows = await fetchAllKeyset(
      supabaseClient
          .from(_table)
          .select(_columns)
          .eq('product_id', productId)
          .eq('store_id', storeId)
          .gt('current_quantity', 0),
    );
    // Ordenação FIFO client-side (mesma regra do SQLite — o keyset ordena
    // pelo cursor id, não pela validade).
    return List.unmodifiable(_fifoSort([for (final row in rows) _map(row)]));
  }

  @override
  Future<List<StockLot>> getByStore({required String storeId}) async {
    final rows = await fetchAllKeyset(
      supabaseClient
          .from(_table)
          .select(_columns)
          .eq('store_id', storeId)
          .gt('current_quantity', 0),
    );
    return List.unmodifiable(_fifoSort([for (final row in rows) _map(row)]));
  }

  /// Ordena em ordem FIFO de consumo: validade mais próxima primeiro;
  /// lotes sem validade no fim (por data de entrada; id como desempate).
  static List<StockLot> _fifoSort(List<StockLot> lots) {
    lots.sort((a, b) {
      final aExp = a.expiryDate;
      final bExp = b.expiryDate;
      if (aExp == null && bExp == null) {
        final byEntry = a.entryDate.compareTo(b.entryDate);
        return byEntry != 0 ? byEntry : a.id.compareTo(b.id);
      }
      if (aExp == null) return 1;
      if (bExp == null) return -1;
      final byExpiry = aExp.compareTo(bExp);
      if (byExpiry != 0) return byExpiry;
      final byEntry = a.entryDate.compareTo(b.entryDate);
      return byEntry != 0 ? byEntry : a.id.compareTo(b.id);
    });
    return lots;
  }

  @override
  Future<void> add(StockLot lot) async {
    await supabaseClient.from(_table).insert({
      'id': lot.id,
      'user_id': requireCurrentUserId(),
      'store_id': lot.storeId,
      'product_id': lot.productId,
      'entry_date': lot.entryDate.toUtc().toIso8601String(),
      'expiry_date': lot.expiryDate?.toUtc().toIso8601String(),
      'initial_quantity': lot.initialQuantity,
      'current_quantity': lot.currentQuantity,
      'cost_price': lot.costPriceCents,
    });
  }

  @override
  Future<void> updateQuantity(
    String lotId,
    int newQuantity, {
    required String storeId,
  }) async {
    // Escopo por loja: o filtro store_id impede mutar lote de outra loja
    // (defesa em profundidade além do RLS).
    final rows = await supabaseClient
        .from(_table)
        .update({'current_quantity': newQuantity})
        .eq('id', lotId)
        .eq('store_id', storeId)
        .select('id');
    if (rows.isEmpty) {
      throw StateError('Lote $lotId não encontrado para atualização.');
    }
  }

  StockLot _map(Map<String, dynamic> row) => StockLot(
    id: row['id'] as String,
    storeId: row['store_id'] as String,
    productId: row['product_id'] as String,
    entryDate: DateTime.parse(row['entry_date'] as String).toLocal(),
    expiryDate: row['expiry_date'] == null
        ? null
        : DateTime.parse(row['expiry_date'] as String).toLocal(),
    initialQuantity: (row['initial_quantity'] as num).toInt(),
    currentQuantity: (row['current_quantity'] as num).toInt(),
    costPriceCents: (row['cost_price'] as num).toInt(),
  );
}
