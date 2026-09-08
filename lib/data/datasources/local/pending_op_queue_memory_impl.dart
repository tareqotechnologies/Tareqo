import 'pending_op_queue.dart';

/// Fila offline em memória — usada quando o SQLite não está disponível
/// (web) ou em testes. Atenção: Não persiste entre sessões: no modo SaaS web,
/// operações enfileiradas offline se perdem ao fechar o app (limitação
/// documentada — mesma do armazenamento de sessão na web).
final class PendingOpQueueMemoryImpl implements IPendingOpQueue {
  final List<PendingOp> _ops = [];

  @override
  Future<void> add(PendingOp op) async {
    _ops.add(
      PendingOp(
        id: _ops.length + 1,
        opType: op.opType,
        payload: op.payload,
        createdAt: op.createdAt,
        attemptCount: op.attemptCount,
        lastError: op.lastError,
        nextRetryAt: op.nextRetryAt,
        dead: op.dead,
      ),
    );
  }

  @override
  Future<PendingOp?> next() async {
    final due = _ops.where((op) => !op.dead).toList();
    return due.isEmpty ? null : due.first;
  }

  @override
  Future<void> remove(int id) async {
    _ops.removeWhere((op) => op.id == id);
  }

  @override
  Future<void> markFailed(int id, String error) async {
    final index = _ops.indexWhere((op) => op.id == id);
    if (index < 0) return;
    final op = _ops[index];
    // Backoff exponencial + dead-letter (auditoria A3): uma operação que
    // falha por NEGÓCIO só volta a ser tentada depois de nextRetryAt; ao
    // esgotar pendingOpMaxAttempts vira dead-letter (sai da contagem/replay).
    final nextAttempt = op.attemptCount + 1;
    final isDead = nextAttempt >= pendingOpMaxAttempts;
    _ops[index] = PendingOp(
      id: op.id,
      opType: op.opType,
      payload: op.payload,
      createdAt: op.createdAt,
      attemptCount: nextAttempt,
      lastError: error,
      nextRetryAt: isDead
          ? null
          : DateTime.now().add(pendingOpBackoffFor(nextAttempt)),
      dead: isDead,
    );
  }

  @override
  Future<int> count() async => _ops.where((op) => !op.dead).length;

  @override
  Future<List<PendingOp>> list() async => List.unmodifiable(_ops);
}
