import 'package:sqlite3/sqlite3.dart';

import '../../../core/database/app_database_io.dart';
import '../../../domain/entities/employee_management.dart';
import 'employee_management_local_data_source.dart';

/// Implementação SQLite do [EmployeeManagementLocalDataSource].
///
/// Tabelas `employee_attendance`, `employee_commission_rates` e
/// `employee_targets` (v5) — uma linha por funcionário por dia/mês, com
/// unicidade garantida por índice UNIQUE. As COMISSÕES são CALCULADAS das
/// vendas REAIS da loja (`sales.user_id` = caixa, status 'active' e mês
/// do `date_time`) — nunca armazenadas, nunca inventadas: venda sem
/// `user_id` (legada) não conta para ninguém.
final class EmployeeManagementSqliteDataSourceImpl
    implements EmployeeManagementLocalDataSource {
  const EmployeeManagementSqliteDataSourceImpl(this._db);

  final Database _db;

  // ── Ponto ────────────────────────────────────────────────────────────
  @override
  Future<List<EmployeeAttendance>> getAttendance({
    required String storeId,
    required String workDate,
  }) async {
    final rows = _db.select(
      'SELECT id, store_id, user_id, work_date, clock_in, clock_out, '
      'recorded_by, created_at FROM employee_attendance '
      'WHERE store_id = ? AND work_date = ? ORDER BY clock_in',
      [storeId, workDate],
    );
    return List.unmodifiable([for (final row in rows) _mapAttendance(row)]);
  }

  @override
  Future<EmployeeAttendance> clockIn({
    required String storeId,
    required String userId,
    required String workDate,
    required DateTime clockIn,
    String? recordedBy,
  }) async {
    var persisted = EmployeeAttendance(
      id: 'att_${storeId}_${userId}_$workDate',
      storeId: storeId,
      userId: userId,
      workDate: workDate,
      clockIn: clockIn,
      recordedBy: recordedBy ?? '',
      createdAt: DateTime.now(),
    );
    AppDatabase.runInTransaction(_db, () {
      final open = _db.select(
        'SELECT 1 FROM employee_attendance '
        'WHERE store_id = ? AND user_id = ? AND work_date = ? '
        'AND clock_out IS NULL',
        [storeId, userId, workDate],
      );
      if (open.isNotEmpty) {
        throw StateError('Ponto já registado para $userId em $workDate.');
      }
      _db.execute(
        'INSERT INTO employee_attendance '
        '(id, store_id, user_id, work_date, clock_in, clock_out, '
        'recorded_by, created_at) VALUES (?, ?, ?, ?, ?, NULL, ?, ?)',
        [
          persisted.id,
          persisted.storeId,
          persisted.userId,
          persisted.workDate,
          persisted.clockIn.millisecondsSinceEpoch,
          persisted.recordedBy,
          persisted.createdAt.millisecondsSinceEpoch,
        ],
      );
    });
    return persisted;
  }

  @override
  Future<EmployeeAttendance> clockOut({
    required String storeId,
    required String userId,
    required String workDate,
    required DateTime clockOut,
  }) async {
    String? id;
    AppDatabase.runInTransaction(_db, () {
      final rows = _db.select(
        'SELECT id, clock_in FROM employee_attendance '
        'WHERE store_id = ? AND user_id = ? AND work_date = ? '
        'AND clock_out IS NULL',
        [storeId, userId, workDate],
      );
      if (rows.isEmpty) {
        throw StateError('Sem entrada registada para $userId em $workDate.');
      }
      id = rows.first['id'] as String;
      _db.execute('UPDATE employee_attendance SET clock_out = ? WHERE id = ?', [
        clockOut.millisecondsSinceEpoch,
        id,
      ]);
    });
    final recordId = id;
    final updated = _db.select(
      'SELECT id, store_id, user_id, work_date, clock_in, clock_out, '
      'recorded_by, created_at FROM employee_attendance WHERE id = ?',
      [recordId],
    );
    return _mapAttendance(updated.first);
  }

  // ── Taxas de comissão ────────────────────────────────────────────────
  @override
  Future<List<EmployeeCommissionRate>> getCommissionRates({
    required String storeId,
  }) async {
    final rows = _db.select(
      'SELECT id, store_id, user_id, rate_bps, created_at '
      'FROM employee_commission_rates WHERE store_id = ?',
      [storeId],
    );
    return List.unmodifiable([for (final row in rows) _mapRate(row)]);
  }

  @override
  Future<void> setCommissionRate({
    required String storeId,
    required String userId,
    required int rateBps,
  }) async {
    if (rateBps < 0 || rateBps > 10000) {
      throw StateError('Taxa de comissão inválida: $rateBps bps.');
    }
    _db.execute(
      'INSERT INTO employee_commission_rates '
      '(id, store_id, user_id, rate_bps, created_at) VALUES (?, ?, ?, ?, ?) '
      'ON CONFLICT (store_id, user_id) DO UPDATE SET rate_bps = excluded.rate_bps',
      [
        'crate_${storeId}_$userId',
        storeId,
        userId,
        rateBps,
        DateTime.now().millisecondsSinceEpoch,
      ],
    );
  }

  // ── Metas ────────────────────────────────────────────────────────────
  @override
  Future<List<EmployeeTarget>> getTargets({
    required String storeId,
    String? month,
  }) async {
    final rows = month == null
        ? _db.select(
            'SELECT id, store_id, user_id, month, target_cents, created_at '
            'FROM employee_targets WHERE store_id = ? ORDER BY month',
            [storeId],
          )
        : _db.select(
            'SELECT id, store_id, user_id, month, target_cents, created_at '
            'FROM employee_targets WHERE store_id = ? AND month = ? '
            'ORDER BY created_at',
            [storeId, month],
          );
    return List.unmodifiable([for (final row in rows) _mapTarget(row)]);
  }

  @override
  Future<void> setTarget({
    required String storeId,
    required String userId,
    required String month,
    required int targetCents,
  }) async {
    if (targetCents < 0) {
      throw StateError('Meta inválida: $targetCents.');
    }
    _db.execute(
      'INSERT INTO employee_targets '
      '(id, store_id, user_id, month, target_cents, created_at) '
      'VALUES (?, ?, ?, ?, ?, ?) '
      'ON CONFLICT (store_id, user_id, month) '
      'DO UPDATE SET target_cents = excluded.target_cents',
      [
        'tgt_${storeId}_${userId}_$month',
        storeId,
        userId,
        month,
        targetCents,
        DateTime.now().millisecondsSinceEpoch,
      ],
    );
  }

  @override
  Future<void> removeTarget(String id, {required String storeId}) async {
    _db.execute('DELETE FROM employee_targets WHERE id = ? AND store_id = ?', [
      id,
      storeId,
    ]);
  }

  EmployeeAttendance _mapAttendance(Row row) => EmployeeAttendance(
    id: row['id'] as String,
    storeId: row['store_id'] as String,
    userId: row['user_id'] as String,
    workDate: row['work_date'] as String,
    clockIn: DateTime.fromMillisecondsSinceEpoch(row['clock_in'] as int),
    clockOut: row['clock_out'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(row['clock_out'] as int),
    recordedBy: row['recorded_by'] as String? ?? '',
    createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
  );

  EmployeeCommissionRate _mapRate(Row row) => EmployeeCommissionRate(
    id: row['id'] as String,
    storeId: row['store_id'] as String,
    userId: row['user_id'] as String,
    rateBps: row['rate_bps'] as int,
    createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
  );

  EmployeeTarget _mapTarget(Row row) => EmployeeTarget(
    id: row['id'] as String,
    storeId: row['store_id'] as String,
    userId: row['user_id'] as String,
    month: row['month'] as String,
    targetCents: row['target_cents'] as int,
    createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
  );
}
