import 'package:sqlite3/sqlite3.dart';

import '../../../core/database/app_database_io.dart';
import '../../../domain/entities/sale.dart';
import '../../../domain/entities/sale_item.dart';
import 'sale_local_data_source.dart';

/// Implementação SQLite do [SaleLocalDataSource].
///
/// A venda e seus itens são persistidos em uma **única transação**
/// (tabelas `sales` + `sale_items`) — ou grava tudo, ou não grava nada,
/// garantindo integridade referencial (nunca uma venda sem itens).
final class SaleSqliteDataSourceImpl implements SaleLocalDataSource {
  const SaleSqliteDataSourceImpl(this._db);

  final Database _db;

  @override
  Future<List<Sale>> getAll({required String storeId}) async {
    final rows = _db.select(
      'SELECT id, store_id, total_amount, payment_method, date_time '
      'FROM sales WHERE store_id = ? ORDER BY date_time DESC',
      [storeId],
    );
    return [
      for (final row in rows)
        Sale(
          id: row['id'] as String,
          storeId: row['store_id'] as String,
          items: _itemsOf(row['id'] as String),
          totalAmount: row['total_amount'] as double,
          paymentMethod:
              PaymentMethod.values.byName(row['payment_method'] as String),
          dateTime: DateTime.fromMillisecondsSinceEpoch(
            row['date_time'] as int,
          ),
        ),
    ];
  }

  List<SaleItem> _itemsOf(String saleId) {
    final rows = _db.select(
      'SELECT product_id, product_name, quantity, unit_price '
      'FROM sale_items WHERE sale_id = ? ORDER BY id',
      [saleId],
    );
    return [
      for (final row in rows)
        SaleItem(
          productId: row['product_id'] as String,
          productName: row['product_name'] as String,
          quantity: row['quantity'] as int,
          unitPrice: row['unit_price'] as double,
        ),
    ];
  }

  @override
  Future<void> add(Sale sale) async {
    AppDatabase.runInTransaction(_db, () {
      _db.execute(
        'INSERT INTO sales (id, store_id, total_amount, payment_method, '
        'date_time) VALUES (?, ?, ?, ?, ?)',
        [
          sale.id,
          sale.storeId,
          sale.totalAmount,
          sale.paymentMethod.name,
          sale.dateTime.millisecondsSinceEpoch,
        ],
      );
      for (final item in sale.items) {
        _db.execute(
          'INSERT INTO sale_items '
          '(sale_id, product_id, product_name, quantity, unit_price) '
          'VALUES (?, ?, ?, ?, ?)',
          [
            sale.id,
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
