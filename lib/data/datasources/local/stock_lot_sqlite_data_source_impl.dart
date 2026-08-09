import 'package:sqlite3/sqlite3.dart';

import '../../../domain/entities/stock_lot.dart';
import 'stock_lot_local_data_source.dart';

/// Implementação SQLite do [StockLotLocalDataSource].
///
/// A **ordem FIFO** é garantida aqui na consulta (contrato do domínio):
/// `expiry_date ASC NULLS LAST` (vencimento mais próximo primeiro) e, no
/// desempate, `entry_date ASC, id ASC` — lotes sem validade são consumidos
/// por ordem de entrada, depois dos com validade. O SQLite ordena NULLs
/// primeiro em ASC, por isso o `CASE` explicito: NULLs vão para o fim.
final class StockLotSqliteDataSourceImpl implements StockLotLocalDataSource {
  const StockLotSqliteDataSourceImpl(this._db);

  final Database _db;

  static const _columns =
      'id, store_id, product_id, entry_date, expiry_date, initial_quantity, '
      'current_quantity, cost_price';

  /// Ordem FIFO: validade mais próxima primeiro; sem validade no fim (FIFO
  /// por data de entrada). `id` é o desempate final (estável).
  static const _fifoOrder = '''
    ORDER BY CASE WHEN expiry_date IS NULL THEN 1 ELSE 0 END,
             expiry_date ASC, entry_date ASC, id ASC
  ''';

  @override
  Future<List<StockLot>> getActiveByProduct(
    String productId, {
    required String storeId,
  }) async {
    final rows = _db.select(
      'SELECT $_columns FROM stock_lots '
      'WHERE product_id = ? AND store_id = ? AND current_quantity > 0 '
      '$_fifoOrder',
      [productId, storeId],
    );
    return [for (final row in rows) _map(row)];
  }

  @override
  Future<List<StockLot>> getByStore({required String storeId}) async {
    final rows = _db.select(
      'SELECT $_columns FROM stock_lots '
      'WHERE store_id = ? AND current_quantity > 0 '
      '$_fifoOrder',
      [storeId],
    );
    return [for (final row in rows) _map(row)];
  }

  @override
  Future<void> add(StockLot lot) async {
    _db.execute(
      'INSERT INTO stock_lots ($_columns) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      [
        lot.id,
        lot.storeId,
        lot.productId,
        lot.entryDate.millisecondsSinceEpoch,
        lot.expiryDate?.millisecondsSinceEpoch,
        lot.initialQuantity,
        lot.currentQuantity,
        lot.costPriceCents,
      ],
    );
  }

  @override
  Future<void> updateQuantity(
    String lotId,
    int newQuantity, {
    required String storeId,
  }) async {
    // Escopo por loja: o WHERE com store_id impede mutar lote de outra loja.
    _db.execute(
      'UPDATE stock_lots SET current_quantity = ? '
      'WHERE id = ? AND store_id = ?',
      [newQuantity, lotId, storeId],
    );
    if (_db.updatedRows == 0) {
      throw StateError('Lote $lotId não encontrado para atualização.');
    }
  }

  StockLot _map(Row row) => StockLot(
    id: row['id'] as String,
    storeId: row['store_id'] as String,
    productId: row['product_id'] as String,
    entryDate: DateTime.fromMillisecondsSinceEpoch(row['entry_date'] as int),
    expiryDate: row['expiry_date'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(row['expiry_date'] as int),
    initialQuantity: row['initial_quantity'] as int,
    currentQuantity: row['current_quantity'] as int,
    costPriceCents: (row['cost_price'] as num).toInt(),
  );
}
