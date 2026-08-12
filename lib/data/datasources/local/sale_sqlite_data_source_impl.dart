import 'package:sqlite3/sqlite3.dart';

import '../../../core/database/app_database_io.dart';
import '../../../domain/entities/sale.dart';
import '../../../domain/entities/sale_item.dart';
import '../../../domain/entities/sale_lot_consumption.dart';
import 'sale_local_data_source.dart';

/// Implementação SQLite do [SaleLocalDataSource].
///
/// A venda e seus itens são persistidos em uma **única transação**
/// (tabelas `sales` + `sale_items`) — ou grava tudo, ou não grava nada,
/// garantindo integridade referencial (nunca uma venda sem itens). O
/// consumo de lotes ([LotConsumption]) é gravado na MESMA transação — é o
/// que permite à anulação devolver o estoque aos lotes exatos.
final class SaleSqliteDataSourceImpl implements SaleLocalDataSource {
  const SaleSqliteDataSourceImpl(this._db);

  final Database _db;

  static const _saleColumns =
      'id, store_id, sale_number, total_amount, payment_method, date_time, '
      'status, cancelled_at';

  @override
  Future<List<Sale>> getAll({required String storeId}) async {
    final rows = _db.select(
      'SELECT $_saleColumns FROM sales WHERE store_id = ? '
      'ORDER BY date_time DESC',
      [storeId],
    );
    return [for (final row in rows) _mapSale(row)];
  }

  @override
  Future<Sale?> getById(String id, {required String storeId}) async {
    final rows = _db.select(
      'SELECT $_saleColumns FROM sales WHERE id = ? AND store_id = ?',
      [id, storeId],
    );
    if (rows.isEmpty) return null;
    return _mapSale(rows.first);
  }

  Sale _mapSale(Row row) => Sale(
    id: row['id'] as String,
    storeId: row['store_id'] as String,
    number: (row['sale_number'] as num).toInt(),
    items: _itemsOf(row['id'] as String),
    totalAmountCents: (row['total_amount'] as num).toInt(),
    paymentMethod: PaymentMethod.values.byName(row['payment_method'] as String),
    dateTime: DateTime.fromMillisecondsSinceEpoch(row['date_time'] as int),
    status: SaleStatus.values.byName(row['status'] as String),
    cancelledAt: row['cancelled_at'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(row['cancelled_at'] as int),
  );

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
          unitPriceCents: (row['unit_price'] as num).toInt(),
        ),
    ];
  }

  @override
  Future<void> add(Sale sale) async {
    AppDatabase.runInTransaction(_db, () {
      // Número SEQUENCIAL da venda na loja: MAX+1 calculado DENTRO da
      // mesma transação (BEGIN IMMEDIATE segura a escrita) — duas vendas
      // concorrentes nunca recebem o mesmo número. O valor enviado no
      // objeto é ignorado: o banco é a autoridade.
      final nextNumber = _db.select(
        'SELECT COALESCE(MAX(sale_number), 0) + 1 AS next '
        'FROM sales WHERE store_id = ?',
        [sale.storeId],
      ).first['next'] as int;

      _db.execute(
        'INSERT INTO sales '
        '(id, store_id, sale_number, total_amount, payment_method, '
        'date_time, status, cancelled_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        [
          sale.id,
          sale.storeId,
          nextNumber,
          sale.totalAmountCents,
          sale.paymentMethod.name,
          sale.dateTime.millisecondsSinceEpoch,
          sale.status.name,
          sale.cancelledAt?.millisecondsSinceEpoch,
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
            item.unitPriceCents,
          ],
        );
      }
    });
  }

  @override
  Future<void> markCancelled(String id, {required String storeId}) async {
    _db.execute(
      'UPDATE sales SET status = ?, cancelled_at = ? '
      'WHERE id = ? AND store_id = ?',
      [SaleStatus.cancelled.name, DateTime.now().millisecondsSinceEpoch, id, storeId],
    );
    if (_db.updatedRows == 0) {
      throw StateError('Venda $id não encontrada para anulação.');
    }
  }

  @override
  Future<List<LotConsumption>> getLotConsumption(
    String saleId, {
    required String storeId,
  }) async {
    final rows = _db.select(
      'SELECT lot_id, product_id, quantity FROM sale_lot_consumption '
      'WHERE sale_id = ? ORDER BY id',
      [saleId],
    );
    return [
      for (final row in rows)
        LotConsumption(
          lotId: row['lot_id'] as String,
          productId: row['product_id'] as String,
          quantity: row['quantity'] as int,
        ),
    ];
  }

  @override
  Future<void> registerLotConsumption(
    String saleId,
    String storeId,
    List<LotConsumption> consumption,
  ) async {
    AppDatabase.runInTransaction(_db, () {
      for (final consumed in consumption) {
        _db.execute(
          'INSERT INTO sale_lot_consumption '
          '(sale_id, lot_id, product_id, quantity) VALUES (?, ?, ?, ?)',
          [saleId, consumed.lotId, consumed.productId, consumed.quantity],
        );
      }
    });
  }
}
