import 'package:sqlite3/sqlite3.dart';

import 'pending_op_queue.dart';

/// Fila offline sobre SQLite (persistente — sobrevive a fechar o app).
///
/// A tabela `pending_ops` é criada pela migração v2 do schema
/// (`AppDatabase`); as colunas `next_retry_at`/`dead` entram na migração
/// v6 (backoff + dead-letter, auditoria A3). O id AUTOINCREMENT é a ordem
/// FIFO de replay; a fila é acessada por UMA conexão (a mesma do banco do
/// app) e cada operação é uma instrução autocommit — sem transação longa.
final class PendingOpQueueSqliteImpl implements IPendingOpQueue {
  PendingOpQueueSqliteImpl(this._db);

  final Database _db;

  static const _columns =
      'id, op_type, payload, created_at, attempt_count, last_error, '
      'next_retry_at, dead';

  @override
  Future<void> add(PendingOp op) async {
    _db.execute(
      'INSERT INTO pending_ops '
      '(op_type, payload, created_at, attempt_count, last_error, '
      'next_retry_at, dead) '
      'VALUES (?, ?, ?, ?, ?, ?, ?)',
      op.toRow(),
    );
  }

  @override
  Future<PendingOp?> next() async {
    final rows = _db.select(
      'SELECT $_columns FROM pending_ops WHERE dead = 0 ORDER BY id LIMIT 1',
    );
    if (rows.isEmpty) return null;
    return PendingOp.fromRow(rows.first);
  }

  @override
  Future<void> remove(int id) async {
    _db.execute('DELETE FROM pending_ops WHERE id = ?', [id]);
  }

  @override
  Future<void> markFailed(int id, String error) async {
    final rows = _db.select(
      'SELECT attempt_count FROM pending_ops WHERE id = ?',
      [id],
    );
    if (rows.isEmpty) return;
    final currentAttempts = rows.first['attempt_count'] as int;
    // Backoff exponencial + dead-letter (auditoria A3): falha de NEGÓCIO
    // agenda a próxima tentativa para `now + backoff`; ao esgotar
    // pendingOpMaxAttempts a operação vira dead-letter (dead = 1) e deixa
    // de ser reenviada (permanece no banco para auditoria).
    final nextAttempt = currentAttempts + 1;
    final isDead = nextAttempt >= pendingOpMaxAttempts;
    _db.execute(
      'UPDATE pending_ops '
      'SET attempt_count = ?, last_error = ?, next_retry_at = ?, dead = ? '
      'WHERE id = ?',
      [
        nextAttempt,
        error,
        isDead
            ? null
            : DateTime.now()
                  .add(pendingOpBackoffFor(nextAttempt))
                  .millisecondsSinceEpoch,
        isDead ? 1 : 0,
        id,
      ],
    );
  }

  @override
  Future<int> count() async =>
      _db
              .select('SELECT COUNT(*) AS c FROM pending_ops WHERE dead = 0')
              .first['c']
          as int;

  @override
  Future<List<PendingOp>> list() async => [
    for (final row in _db.select(
      'SELECT $_columns FROM pending_ops ORDER BY id',
    ))
      PendingOp.fromRow(row),
  ];
}
