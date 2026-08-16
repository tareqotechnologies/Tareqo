import 'pending_op_queue.dart';

/// Fila offline em memória — usada quando o SQLite não está disponível
/// (web) ou em testes. ⚠️ Não persiste entre sessões: no modo SaaS web,
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
      ),
    );
  }

  @override
  Future<PendingOp?> next() async =>
      _ops.isEmpty ? null : _ops.first;

  @override
  Future<void> remove(int id) async {
    _ops.removeWhere((op) => op.id == id);
  }

  @override
  Future<void> markFailed(int id, String error) async {
    final index = _ops.indexWhere((op) => op.id == id);
    if (index < 0) return;
    final op = _ops[index];
    _ops[index] = PendingOp(
      id: op.id,
      opType: op.opType,
      payload: op.payload,
      createdAt: op.createdAt,
      attemptCount: op.attemptCount + 1,
      lastError: error,
    );
  }

  @override
  Future<int> count() async => _ops.length;

  @override
  Future<List<PendingOp>> list() async => List.unmodifiable(_ops);
}
