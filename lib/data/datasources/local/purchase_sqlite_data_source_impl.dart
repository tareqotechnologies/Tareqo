import 'package:sqlite3/sqlite3.dart';

import '../../../core/database/app_database_io.dart';
import '../../../domain/entities/purchase.dart';
import 'purchase_local_data_source.dart';

/// Implementação SQLite do [PurchaseLocalDataSource].
///
/// A compra e seus itens são persistidos em uma **única transação**
/// (tabelas `purchases` + `purchase_items`) — ou grava tudo, ou não grava
/// nada.
final class PurchaseSqliteDataSourceImpl implements PurchaseLocalDataSource {
  const PurchaseSqliteDataSourceImpl(this._db);

  final Database _db;

  @override
  Future<List<Purchase>> getAll({required String storeId}) async {
    final rows = _db.select(
      'SELECT id, store_id, supplier_name, total_amount, date_time '
      'FROM purchases WHERE store_id = ? ORDER BY date_time DESC',
      [storeId],
    );
    return [
      for (final row in rows)
        Purchase(
          id: row['id'] as String,
          storeId: row['store_id'] as String,
          supplierName: row['supplier_name'] as String,
          items: _itemsOf(row['id'] as String),
          totalAmount: row['total_amount'] as double,
          dateTime: DateTime.fromMillisecondsSinceEpoch(
            row['date_time'] as int,
          ),
        ),
    ];
  }

  List<PurchaseItem> _itemsOf(String purchaseId) {
    final rows = _db.select(
      'SELECT product_id, product_name, quantity, unit_price '
      'FROM purchase_items WHERE purchase_id = ? ORDER BY id',
      [purchaseId],
    );
    return [
      for (final row in rows)
        PurchaseItem(
          productId: row['product_id'] as String,
          productName: row['product_name'] as String,
          quantity: row['quantity'] as int,
          unitPrice: row['unit_price'] as double,
        ),
    ];
  }

  @override
  Future<void> add(Purchase purchase) async {
    AppDatabase.runInTransaction(_db, () {
      _db.execute(
        'INSERT INTO purchases (id, store_id, supplier_name, total_amount, '
        'date_time) VALUES (?, ?, ?, ?, ?)',
        [
          purchase.id,
          purchase.storeId,
          purchase.supplierName,
          purchase.totalAmount,
          purchase.dateTime.millisecondsSinceEpoch,
        ],
      );
      for (final item in purchase.items) {
        _db.execute(
          'INSERT INTO purchase_items '
          '(purchase_id, product_id, product_name, quantity, unit_price) '
          'VALUES (?, ?, ?, ?, ?)',
          [
            purchase.id,
            item.productId,
            item.productName,
            item.quantity,
            item.unitPrice,
          ],
        );
      }
    });
  }
}
