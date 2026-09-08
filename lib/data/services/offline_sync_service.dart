import 'dart:async';

import 'package:http/http.dart' as http;

import '../datasources/local/pending_op_queue.dart';

/// Lançada quando a operação foi ENFILEIRADA porque o servidor está
/// inalcançável (sem conexão/timeout). A UI captura ANTES do catch
/// genérico e mostra \"salvo offline\" em vez de erro — a operação será
/// reenviada pelo [OfflineSyncService] quando a rede voltar.
final class OfflineEnqueuedException implements Exception {
  const OfflineEnqueuedException(this.opType);

  /// Tipo da operação enfileirada (ex.: `process_sale`).
  final String opType;

  @override
  String toString() =>
      'OfflineEnqueuedException: $opType enfileirada para sincronização';
}

/// Erro de REDE/transporte (servidor inalcançável, timeout) — distingue de
/// erro de NEGÓCIO (validação rejeitada pelo servidor), que NUNCA é
/// enfileirado (é um erro real do dado/operação).
///
/// Cobertos: timeout global do `TimeoutRetryHttpClient` e falhas de
/// transporte do `package:http` (`ClientException` — o IOClient embrulha
/// SocketException; no web o BrowserClient lança ClientException também).
bool isNetworkError(Object error) =>
    error is TimeoutException || error is http.ClientException;

/// Serviço central da fila offline (outbox) do modo SaaS.
///
/// Fluxo de escrita: [run] tenta a RPC; em falha de REDE enfileira o
/// comando original (payload JSON) e lança [OfflineEnqueuedException]; em
/// falha de NEGÓCIO re-lança (erro real). Após qualquer sucesso, [drain]
/// reenvia o que ficou pendente (FIFO).
///
/// Replay: cada `opType` tem um replayer registrado (mesma RPC do caminho
/// normal) — todas as RPCs do schema são idempotentes por design (o id do
/// registro é a chave), então reenviar uma operação que já chegou ao
/// servidor (resposta perdida no caminho) é um no-op seguro.
class OfflineSyncService {
  OfflineSyncService(this._queue);

  final IPendingOpQueue _queue;

  /// Replayers por tipo de operação (registrados no bootstrap do modo
  /// SaaS — mesma RPC do caminho normal, reconstruindo a entidade do
  /// payload).
  final Map<String, Future<void> Function(Map<String, dynamic> payload)>
  _replayers = {};

  /// Stream de mudanças na contagem — alimenta o banner do dashboard.
  final _countController = StreamController<int>.broadcast();

  Timer? _timer;

  Stream<int> get countChanges => _countController.stream;

  /// Contagem ATUAL de operações pendentes.
  Future<int> count() => _queue.count();

  void registerReplayer(
    String opType,
    Future<void> Function(Map<String, dynamic> payload) replayer,
  ) {
    _replayers[opType] = replayer;
  }

  /// Tenta a RPC; em falha de REDE enfileira e lança
  /// [OfflineEnqueuedException]. Em falha de NEGÓCIO re-lança.
  Future<void> run({
    required String opType,
    required Map<String, dynamic> payload,
    required Future<void> Function() rpc,
  }) async {
    try {
      await rpc();
      // Sucesso — operações pendentes podem ter sido bloqueadas por rede.
      await drain();
    } on Object catch (error) {
      if (isNetworkError(error)) {
        await _queue.add(
          PendingOp(
            opType: opType,
            payload: payload,
            createdAt: DateTime.now(),
          ),
        );
        await _emitCount();
        throw OfflineEnqueuedException(opType);
      }
      rethrow;
    }
  }

  /// Reenvia as operações pendentes em FIFO.
  ///
  /// Iteração sobre um SNAPSHOT (`list()` — ordem de id): falha de
  /// NEGÓCIO marca a operação com erro e SEGUE para a próxima — se o
  /// `next()` (sempre o head) fosse usado no laço, uma operação inválida
  /// no topo faria o drain nunca avançar (loop infinito).
  ///
  /// - Sucesso → remove da fila.
  /// - Falha de REDE → para (retenta depois — a rede continua fora).
  /// - Falha de NEGÓCIO → marca com erro, agenda `next_retry_at` com
  ///   backoff exponencial e SEGUE (uma operação inválida não bloqueia a
  ///   fila e deixa de martelar o servidor a cada dreno — auditoria A3).
  /// - Dead-letter → esgotou [pendingOpMaxAttempts] tentativas: não é
  ///   mais reenviada (fica no banco para auditoria, fora da contagem).
  /// - Não vencida → `next_retry_at` no futuro (backoff): pula.
  /// - Tipo desconhecido (app antigo) → remove (não trava a fila).
  ///
  /// Retorna quantas operações foram sincronizadas.
  Future<int> drain() async {
    var synced = 0;
    final now = DateTime.now();
    for (final op in await _queue.list()) {
      if (op.dead) continue;
      final nextRetry = op.nextRetryAt;
      if (nextRetry != null && nextRetry.isAfter(now)) continue;
      final replayer = _replayers[op.opType];
      if (replayer == null) {
        await _queue.remove(op.id!);
        continue;
      }
      try {
        await replayer(op.payload);
        await _queue.remove(op.id!);
        synced++;
      } on Object catch (error) {
        if (isNetworkError(error)) break;
        await _queue.markFailed(op.id!, error.toString());
      }
    }
    if (synced > 0) await _emitCount();
    return synced;
  }

  /// Dreno automático periódico (startup do modo SaaS): tenta reenviar as
  /// pendentes a cada [interval] enquanto o app estiver aberto.
  void startAutoDrain({Duration interval = const Duration(seconds: 45)}) {
    _timer ??= Timer.periodic(interval, (_) => drain());
  }

  void stopAutoDrain() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _emitCount() async {
    if (_countController.isClosed) return;
    _countController.add(await _queue.count());
  }
}
