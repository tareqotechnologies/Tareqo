import 'package:sqlite3/sqlite3.dart';

import '../../../core/security/pending_op_payload_cipher.dart';
import 'pending_op_queue.dart';

/// Fila offline sobre SQLite (persistente — sobrevive a fechar o app).
///
/// A tabela `pending_ops` é criada pela migração v2 do schema
/// (`AppDatabase`); as colunas `next_retry_at`/`dead` entram na migração
/// v6 (backoff + dead-letter, auditoria A3). O id AUTOINCREMENT é a ordem
/// FIFO de replay; a fila é acessada por UMA conexão (a mesma do banco do
/// app) e cada operação é uma instrução autocommit — sem transação longa.
///
/// **Payload CIFRADO em repouso (P3 — auditoria forense):** o outbox
/// guarda o comando ORIGINAL do caminho de dinheiro (venda com itens e
/// valores, fiado com nome do cliente). Antes o JSON gravava em TEXTO
/// CLARO — o `PendingOpPayloadCipher` existia mas nunca era usado, e o
/// SECURITY.md alegava "payloads cifrados" sem que a cifra rodisse. Agora
/// todo payload passa pelo `PendingOpPayloadCipher` (AES-256-GCM, chave
/// mestra no Keystore/Keychain via `SecureStorageService`) no `add`, e é
/// decifrado ao ler (`next`/`list`). Linhas legadas em texto claro
/// (gravadas por versões anteriores) são migradas na primeira leitura:
/// decifradas com fallback para JSON puro e regravadas cifradas.
final class PendingOpQueueSqliteImpl implements IPendingOpQueue {
  PendingOpQueueSqliteImpl(this._db, {PendingOpPayloadCipher? cipher})
    : _payloadCipher = cipher;

  final Database _db;

  /// Cifra do payload (opcional para testes que não precisam da
  /// plataforma). Sem cifra (web/testes), o JSON é gravado como antes —
  /// a fila em memória não persiste e a web não tem Keystore (mesma
  /// limitação documentada do armazenamento de sessão).
  final PendingOpPayloadCipher? _payloadCipher;

  static const _columns =
      'id, op_type, payload, created_at, attempt_count, last_error, '
      'next_retry_at, dead';

  /// Grava o payload CIFRADO (base64 de nonce||ciphertext||mac).
  Future<String> _encodePayload(Map<String, dynamic> payload) async {
    final cipher = _payloadCipher;
    if (cipher == null) return PendingOp.payloadToJson(payload);
    return cipher.encrypt(PendingOp.payloadToJson(payload));
  }

  /// Lê e decifra o payload. Linhas legadas em TEXTO CLARO (versões
  /// anteriores da app) são reconhecidas porque a decifração falha
  /// (base64 inválido ou MAC não bate) — nesses casos o JSON puro é
  /// aceito e a linha é REGRAVADA cifrada (migração transparente).
  Future<Map<String, dynamic>> _decodePayload(int id, String stored) async {
    final cipher = _payloadCipher;
    if (cipher == null) return PendingOp.payloadFromJsonString(stored);
    try {
      return PendingOp.payloadFromJsonString(await cipher.decrypt(stored));
    } on Object {
      // Legado em texto claro: migra para cifrado na mesma conexão.
      final plain = PendingOp.payloadFromJsonString(stored);
      final encrypted = await _encodePayload(plain);
      _db.execute('UPDATE pending_ops SET payload = ? WHERE id = ?', [
        encrypted,
        id,
      ]);
      return plain;
    }
  }

  @override
  Future<void> add(PendingOp op) async {
    _db.execute(
      'INSERT INTO pending_ops '
      '(op_type, payload, created_at, attempt_count, last_error, '
      'next_retry_at, dead) '
      'VALUES (?, ?, ?, ?, ?, ?, ?)',
      [
        op.opType,
        await _encodePayload(op.payload),
        op.createdAt.millisecondsSinceEpoch,
        op.attemptCount,
        op.lastError,
        op.nextRetryAt?.millisecondsSinceEpoch,
        op.dead ? 1 : 0,
      ],
    );
  }

  @override
  Future<PendingOp?> next() async {
    final rows = _db.select(
      'SELECT $_columns FROM pending_ops WHERE dead = 0 ORDER BY id LIMIT 1',
    );
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
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
      await _fromRow(row),
  ];

  Future<PendingOp> _fromRow(Map<String, dynamic> row) async {
    final payload = await _decodePayload(
      row['id'] as int,
      row['payload'] as String,
    );
    return PendingOp(
      id: row['id'] as int,
      opType: row['op_type'] as String,
      payload: payload,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      attemptCount: row['attempt_count'] as int,
      lastError: row['last_error'] as String?,
      nextRetryAt: row['next_retry_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row['next_retry_at'] as int),
      dead: (row['dead'] as int) == 1,
    );
  }
}
