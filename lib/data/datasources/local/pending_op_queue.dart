import 'dart:convert';

/// Operação pendente de sincronização (outbox offline do modo SaaS).
///
/// Representa uma escrita do caminho de dinheiro (venda, compra, fiado,
/// quitação, anulação) que não conseguiu chegar ao servidor por falta de
/// rede. O [payload] guarda o JSON do comando ORIGINAL (entidade +
/// parâmetros) — o replay reexecuta a RPC de forma idempotente (todas as
/// RPCs do schema são idempotentes por design: o id do registro é a chave).
class PendingOp {
 const PendingOp({
 this.id,
 required this.opType,
 required this.payload,
 required this.createdAt,
 this.attemptCount = 0,
 this.lastError,
 });

 /// Id no banco (`null` = ainda não persistido). AUTOINCREMENT = ordem
 /// FIFO de replay.
 final int? id;

 /// Tipo da operação (ex.: `process_sale`, `settle_debt`) — casa com o
 /// replayer registrado no [OfflineSyncService].
 final String opType;

 /// JSON do comando original (ex.: `{'sale': {...}}`).
 final Map<String, dynamic> payload;

 /// Momento em que a operação foi enfileirada.
 final DateTime createdAt;

 /// Tentativas de replay já feitas.
 final int attemptCount;

 /// Último erro (negócio) que impediu o replay — `null` enquanto nunca
 /// falhou após o enfileiramento.
 final String? lastError;

 String get payloadJson => jsonEncode(payload);

 /// Linha do banco (INSERT).
 List<Object?> toRow() => [
 opType,
 payloadJson,
 createdAt.millisecondsSinceEpoch,
 attemptCount,
 lastError,
 ];

 factory PendingOp.fromRow(Map<String, dynamic> row) => PendingOp(
 id: row['id'] as int,
 opType: row['op_type'] as String,
 payload:
 jsonDecode(row['payload'] as String) as Map<String, dynamic>,
 createdAt: DateTime.fromMillisecondsSinceEpoch(
 row['created_at'] as int,
 ),
 attemptCount: row['attempt_count'] as int,
 lastError: row['last_error'] as String?,
 );
}

/// Fila local de operações pendentes de sincronização (outbox).
///
/// Implementações: SQLite (`PendingOpQueueSqliteImpl` — nativo) e memória
/// (`PendingOpQueueMemoryImpl` — web/testes, sem persistência entre
/// sessões). O acesso é sempre via [OfflineSyncService], que orquestra o
/// enfileiramento e o replay.
abstract interface class IPendingOpQueue {
 /// Enfileira uma operação (anexa ao fim — FIFO).
 Future<void> add(PendingOp op);

 /// A operação MAIS ANTIGA pendente, ou `null` se a fila estiver vazia.
 Future<PendingOp?> next();

 /// Remove a operação (replay com sucesso).
 Future<void> remove(int id);

 /// Marca falha de NEGÓCIO no replay (incrementa tentativas e guarda o
 /// erro) — a operação permanece na fila.
 Future<void> markFailed(int id, String error);

 /// Quantidade de operações pendentes.
 Future<int> count();

 /// Todas as operações pendentes em ordem FIFO.
 Future<List<PendingOp>> list();
}
