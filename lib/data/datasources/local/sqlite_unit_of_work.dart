import 'dart:async';

import 'package:sqlite3/sqlite3.dart';

import '../../../core/database/app_database_io.dart';
import '../../../domain/repositories/i_unit_of_work.dart';

/// Implementação SQLite do [IUnitOfWork]: uma única transação
/// (BEGIN IMMEDIATE → COMMIT/ROLLBACK) envolvendo todos os repositórios
/// que compartilham a mesma conexão.
///
/// O `BEGIN IMMEDIATE` adquire a trava de escrita no início, fechando a
/// janela TOCTOU entre a pré-validação de estoque e as gravações. A fila
/// interna serializa transações concorrentes no mesmo processo (a conexão
/// não aceita transações aninhadas de fluxos diferentes).
final class SqliteUnitOfWork implements IUnitOfWork {
  SqliteUnitOfWork(this._db);

  final Database _db;

  /// Cauda da fila de execução — garante que uma transação por vez rode na
  /// conexão (FIFO), evitando intercalação de gravações.
  Future<void> _tail = Future.value();

  @override
  Future<T> run<T>(Future<T> Function() action) {
    final done = Completer<void>();
    final previous = _tail;
    _tail = done.future;
    return previous
        .then((_) => _runInTransaction(action))
        .whenComplete(done.complete);
  }

  Future<T> _runInTransaction<T>(Future<T> Function() action) async {
    AppDatabase.beginTransaction(_db);
    try {
      final result = await action();
      AppDatabase.commitTransaction(_db);
      return result;
    } catch (_) {
      AppDatabase.rollbackTransaction(_db);
      rethrow;
    }
  }
}
