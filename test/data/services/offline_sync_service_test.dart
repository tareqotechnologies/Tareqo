import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:tareqo/data/datasources/local/pending_op_queue.dart';
import 'package:tareqo/data/datasources/local/pending_op_queue_memory_impl.dart';
import 'package:tareqo/data/services/offline_sync_service.dart';

void main() {
  late PendingOpQueueMemoryImpl queue;
  late OfflineSyncService sync;

  setUp(() {
    queue = PendingOpQueueMemoryImpl();
    sync = OfflineSyncService(queue);
  });

  test('run com sucesso NÃO enfileira e drena a fila', () async {
    // Fila com pendências antigas (ex.: de uma sessão offline anterior).
    await queue.add(
      PendingOp(
        opType: 'process_sale',
        payload: {
          'sale': {'id': 's0'},
        },
        createdAt: DateTime(2026, 8, 16),
      ),
    );
    sync.registerReplayer('process_sale', (_) async {});

    var rpcCalls = 0;
    await sync.run(
      opType: 'process_sale',
      payload: {
        'sale': {'id': 's1'},
      },
      rpc: () async => rpcCalls++,
    );

    expect(rpcCalls, 1);
    // A op pendente antiga foi sincronizada no dreno pós-sucesso.
    expect(await queue.count(), 0);
  });

  test(
    'run com erro de REDE enfileira e lança OfflineEnqueuedException',
    () async {
      await expectLater(
        sync.run(
          opType: 'process_sale',
          payload: {
            'sale': {'id': 's1'},
          },
          rpc: () async => throw http.ClientException('conexão recusada'),
        ),
        throwsA(isA<OfflineEnqueuedException>()),
      );

      expect(await queue.count(), 1);
      final op = await queue.next();
      expect(op!.opType, 'process_sale');
      expect((op.payload['sale'] as Map)['id'], 's1');
    },
  );

  test('run com timeout também enfileira (rede)', () async {
    await expectLater(
      sync.run(
        opType: 'process_purchase',
        payload: {
          'purchase': {'id': 'pc1'},
        },
        rpc: () async => throw TimeoutException('timeout'),
      ),
      throwsA(isA<OfflineEnqueuedException>()),
    );
    expect(await queue.count(), 1);
  });

  test('run com erro de NEGÓCIO re-lança e NÃO enfileira', () async {
    await expectLater(
      sync.run(
        opType: 'process_sale',
        payload: {
          'sale': {'id': 's1'},
        },
        rpc: () async => throw StateError('estoque insuficiente (servidor)'),
      ),
      throwsA(isA<StateError>()),
    );
    expect(await queue.count(), 0);
  });

  test('drain reenvia em FIFO e remove as sincronizadas', () async {
    final replayed = <String>[];
    sync.registerReplayer(
      'process_sale',
      (payload) async => replayed.add((payload['sale'] as Map)['id'] as String),
    );

    await queue.add(
      PendingOp(
        opType: 'process_sale',
        payload: {
          'sale': {'id': 'a'},
        },
        createdAt: DateTime(2026, 8, 16, 10),
      ),
    );
    await queue.add(
      PendingOp(
        opType: 'process_sale',
        payload: {
          'sale': {'id': 'b'},
        },
        createdAt: DateTime(2026, 8, 16, 11),
      ),
    );

    final synced = await sync.drain();
    expect(synced, 2);
    expect(replayed, ['a', 'b']); // FIFO estrito
    expect(await queue.count(), 0);
  });

  test('drain para em erro de REDE e mantém o restante', () async {
    var calls = 0;
    sync.registerReplayer('process_sale', (_) async {
      calls++;
      if (calls == 2) throw http.ClientException('offline de novo');
    });

    await queue.add(_op('process_sale', 'a'));
    await queue.add(_op('process_sale', 'b'));
    await queue.add(_op('process_sale', 'c'));

    final synced = await sync.drain();
    expect(synced, 1); // 'a' foi; 'b' falhou por rede → para
    expect(await queue.count(), 2); // b e c permanecem
  });

  test('drain marca erro de NEGÓCIO e SEGUE (não bloqueia a fila)', () async {
    sync.registerReplayer('process_sale', (payload) async {
      if ((payload['sale'] as Map)['id'] == 'bad') {
        throw StateError('venda inválida no servidor');
      }
    });

    await queue.add(_op('process_sale', 'bad'));
    await queue.add(_op('process_sale', 'good'));

    final synced = await sync.drain();
    expect(synced, 1); // 'good' sincronizou mesmo com 'bad' com erro
    final remaining = (await queue.list()).single;
    expect(remaining.lastError, contains('venda inválida'));
    expect(remaining.attemptCount, 1);
  });

  test('drain respeita o backoff — não reenvia op não vencida (A3)', () async {
    var calls = 0;
    sync.registerReplayer('process_sale', (_) async {
      calls++;
      throw StateError('venda inválida no servidor');
    });

    await queue.add(_op('process_sale', 'bad'));

    // 1º drain: tenta e falha por negócio → agenda backoff (não vencida).
    final first = await sync.drain();
    expect(first, 0);
    expect(calls, 1);
    final failed = (await queue.list()).single;
    expect(failed.attemptCount, 1);
    expect(failed.nextRetryAt, isNotNull);

    // 2º drain imediato: op ainda não vencida → NÃO é reenviada (A3: a
    // falha de negócio deixa de martelar o servidor a cada dreno).
    final second = await sync.drain();
    expect(second, 0);
    expect(calls, 1);
  });

  test('drain ignora dead-letter (A3)', () async {
    var calls = 0;
    sync.registerReplayer('process_sale', (_) async => calls++);

    await queue.add(_op('process_sale', 'stuck'));
    final op = await queue.next();
    for (var i = 0; i < pendingOpMaxAttempts; i++) {
      await queue.markFailed(op!.id!, 'erro $i');
    }

    final synced = await sync.drain();
    expect(synced, 0);
    expect(calls, 0); // nunca mais tentada
    // Sai da contagem (banner), permanece no banco para auditoria.
    expect(await queue.count(), 0);
    expect((await queue.list()).length, 1);
  });

  test('drain remove op de tipo desconhecido (app antigo)', () async {
    await queue.add(_op('operacao_futura', 'x'));
    final synced = await sync.drain();
    expect(synced, 0);
    expect(await queue.count(), 0);
  });

  test('countChanges emite a contagem após enfileirar e drenar', () async {
    final emissions = <int>[];
    final sub = sync.countChanges.listen(emissions.add);

    // Pendência antiga direto na fila (count 1) + run com falha de rede
    // enfileira a segunda (count 2) — o serviço emite nas suas mutações.
    await queue.add(_op('process_sale', 'a'));
    // O run enfileira e LANÇA — o teste captura para seguir.
    await expectLater(
      sync.run(
        opType: 'process_sale',
        payload: {
          'sale': {'id': 'b'},
        },
        rpc: () async => throw http.ClientException('offline'),
      ),
      throwsA(isA<OfflineEnqueuedException>()),
    );
    await Future<void>.delayed(Duration.zero);
    expect(emissions, [2]);

    sync.registerReplayer('process_sale', (_) async {});
    await sync.drain();
    await Future<void>.delayed(Duration.zero);
    expect(emissions, [2, 0]);

    await sub.cancel();
  });

  group('startAutoDrain (backoff adaptativo M5 — timers fake)', () {
    test(
      'fila vazia: sonda UMA vez no intervalo e vai a idle (não martela a rede)',
      () {
        fakeAsync((async) {
          final counting = _CountingQueue(queue);
          final service = OfflineSyncService(counting);
          service.startAutoDrain(
            interval: const Duration(seconds: 45),
            idleInterval: const Duration(minutes: 5),
          );

          // 1ª sonda em t=45s (fila vazia → reagenda para idle).
          async.elapse(const Duration(seconds: 45));
          expect(counting.countCalls, 1);

          // Entre t=45s e t=285s NÃO há nova sonda (economia de bateria).
          async.elapse(const Duration(minutes: 4));
          expect(counting.countCalls, 1);

          // 2ª sonda em t=45s + 5min.
          async.elapse(const Duration(minutes: 1));
          expect(counting.countCalls, 2);

          service.stopAutoDrain();
        });
      },
    );

    test('com pendência: drena automaticamente no intervalo e sincroniza', () {
      fakeAsync((async) {
        final localQueue = PendingOpQueueMemoryImpl();
        final localSync = OfflineSyncService(localQueue);
        final replayed = <String>[];
        localSync.registerReplayer(
          'process_sale',
          (payload) async =>
              replayed.add((payload['sale'] as Map)['id'] as String),
        );
        // add muta a fila sincronicamente — visível para o dreno agendado.
        unawaited(localQueue.add(_op('process_sale', 'off-1')));
        localSync.startAutoDrain(interval: const Duration(seconds: 45));
        async.elapse(const Duration(seconds: 45));

        expect(replayed, ['off-1']);
        var countAfter = -1;
        localQueue.count().then<void>((c) => countAfter = c);
        async.flushMicrotasks();
        expect(countAfter, 0);

        // Fila vazia → idle: nenhum replay extra no período.
        async.elapse(const Duration(minutes: 10));
        expect(replayed, ['off-1']);

        localSync.stopAutoDrain();
      });
    });

    test(
      'falha de rede consecutiva dobra o backoff (45s → 90s → 180s, cap 8min)',
      () {
        fakeAsync((async) {
          final localQueue = PendingOpQueueMemoryImpl();
          final localSync = OfflineSyncService(localQueue);
          localSync.registerReplayer(
            'process_sale',
            (_) async => throw http.ClientException('rede fora'),
          );
          unawaited(localQueue.add(_op('process_sale', 'x')));

          localSync.startAutoDrain(
            interval: const Duration(seconds: 45),
            maxInterval: const Duration(minutes: 8),
          );

          int count() {
            var value = -1;
            localQueue.count().then<void>((c) => value = c);
            async.flushMicrotasks();
            return value;
          }

          // t=45s: 1ª tentativa → backoff 45×2^1 = 90s (vence em t=135s).
          async.elapse(const Duration(seconds: 45));
          expect(count(), 1);

          // t=90s: ainda dentro do backoff → nada acontece.
          async.elapse(const Duration(seconds: 45));
          expect(count(), 1);

          // t=135s: 2ª tentativa → backoff 45×2^2 = 180s (vence em t=315s).
          async.elapse(const Duration(seconds: 45));
          expect(count(), 1);

          // t=225s: ainda em backoff (não venceu).
          async.elapse(const Duration(seconds: 90));
          expect(count(), 1);

          // t=315s: 3ª tentativa acontece (op segue na fila — rede fora).
          async.elapse(const Duration(seconds: 95));
          expect(count(), 1);

          localSync.stopAutoDrain();
        });
      },
    );

    test('stopAutoDrain cancela o timer (nada acontece depois)', () {
      fakeAsync((async) {
        sync.startAutoDrain(interval: const Duration(seconds: 45));
        sync.stopAutoDrain();

        async.elapse(const Duration(minutes: 30));

        // Nenhuma exceção/efeito — apenas o cancelamento limpo.
        var value = -1;
        queue.count().then<void>((c) => value = c);
        async.flushMicrotasks();
        expect(value, 0);
      });
    });

    test('OfflineEnqueuedException.toString nomeia a operação', () {
      expect(
        const OfflineEnqueuedException('process_sale').toString(),
        contains('process_sale'),
      );
    });

    test('isNetworkError distingue REDE de NEGÓCIO', () {
      expect(isNetworkError(TimeoutException('t')), isTrue);
      expect(isNetworkError(http.ClientException('c')), isTrue);
      expect(isNetworkError(StateError('negócio')), isFalse);
    });
  });
}

class _CountingQueue implements IPendingOpQueue {
  _CountingQueue(this._inner);

  final IPendingOpQueue _inner;
  int countCalls = 0;

  @override
  Future<int> count() async {
    countCalls++;
    return _inner.count();
  }

  @override
  Future<void> add(PendingOp op) => _inner.add(op);

  @override
  Future<PendingOp?> next() => _inner.next();

  @override
  Future<void> remove(int id) => _inner.remove(id);

  @override
  Future<void> markFailed(int id, String error) => _inner.markFailed(id, error);

  @override
  Future<List<PendingOp>> list() => _inner.list();
}

PendingOp _op(String opType, String id) => PendingOp(
  opType: opType,
  payload: {
    'sale': {'id': id},
  },
  createdAt: DateTime(2026, 8, 16),
);
