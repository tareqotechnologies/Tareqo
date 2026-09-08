import 'dart:convert';

import 'package:sqlite3/sqlite3.dart';

import '../../../domain/entities/cash_closing.dart';
import 'cash_closing_local_data_source.dart';

/// Implementação SQLite do [CashClosingLocalDataSource].
///
/// Persistido em `cash_closings` com unicidade `(store_id, closing_date)`
/// (índice único criado no schema): [save] usa `INSERT ... ON CONFLICT DO
/// UPDATE` — refazer o fecho do mesmo dia atualiza o registro, nunca
/// duplica. O dia é gravado como época (ms) do início do dia local;
/// `sales_by_method` como JSON (`method.name → centavos`).
final class CashClosingSqliteDataSourceImpl
    implements CashClosingLocalDataSource {
  const CashClosingSqliteDataSourceImpl(this._db);

  final Database _db;

  static const _columns =
      'id, store_id, closing_date, total_sales, expected_cash, '
      'counted_cash, sales_by_method, closed_at';

  @override
  Future<CashClosing?> getByDay({
    required String storeId,
    required DateTime day,
  }) async {
    final rows = _db.select(
      'SELECT $_columns FROM cash_closings '
      'WHERE store_id = ? AND closing_date = ?',
      [storeId, _dayMillis(day)],
    );
    if (rows.isEmpty) return null;
    return _map(rows.first);
  }

  @override
  Future<void> save(CashClosing closing) async {
    _db.execute(
      'INSERT INTO cash_closings '
      '(id, store_id, closing_date, total_sales, expected_cash, '
      ' counted_cash, sales_by_method, closed_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?) '
      'ON CONFLICT(store_id, closing_date) DO UPDATE SET '
      ' id = excluded.id, '
      ' total_sales = excluded.total_sales, '
      ' expected_cash = excluded.expected_cash, '
      ' counted_cash = excluded.counted_cash, '
      ' sales_by_method = excluded.sales_by_method, '
      ' closed_at = excluded.closed_at',
      [
        closing.id,
        closing.storeId,
        _dayMillis(closing.day),
        closing.totalSalesCents,
        closing.expectedCashCents,
        closing.countedCashCents,
        jsonEncode(closing.salesByMethodCents),
        closing.closedAt.millisecondsSinceEpoch,
      ],
    );
  }

  @override
  Future<List<CashClosing>> getAll({required String storeId}) async {
    final rows = _db.select(
      'SELECT $_columns FROM cash_closings WHERE store_id = ? '
      'ORDER BY closing_date DESC',
      [storeId],
    );
    return List.unmodifiable([for (final row in rows) _map(row)]);
  }

  static int _dayMillis(DateTime day) =>
      DateTime(day.year, day.month, day.day).millisecondsSinceEpoch;

  CashClosing _map(Row row) => CashClosing(
    id: row['id'] as String,
    storeId: row['store_id'] as String,
    day: DateTime.fromMillisecondsSinceEpoch(row['closing_date'] as int),
    totalSalesCents: (row['total_sales'] as num).toInt(),
    expectedCashCents: (row['expected_cash'] as num).toInt(),
    countedCashCents: (row['counted_cash'] as num).toInt(),
    salesByMethodCents: Map<String, int>.from(
      jsonDecode(row['sales_by_method'] as String) as Map<String, dynamic>,
    ),
    closedAt: DateTime.fromMillisecondsSinceEpoch(row['closed_at'] as int),
  );
}
