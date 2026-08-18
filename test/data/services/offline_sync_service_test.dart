import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:dumbhanengue/data/datasources/local/pending_op_queue.dart';
import 'package:dumbhanengue/data/datasources/local/pending_op_queue_memory_impl.dart';
import 'package:dumbhanengue/data/services/offline_sync_service.dart';

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
 payload: {'sale': {'id': 's0'}},
 createdAt: DateTime(2026, 8, 16),
 ),
 );
 sync.registerReplayer('process_sale', (_) async {});

 var rpcCalls = 0;
 await sync.run(
 opType: 'process_sale',
 payload: {'sale': {'id': 's1'}},
 rpc: () async => rpcCalls++,
 );

 expect(rpcCalls, 1);
 // A op pendente antiga foi sincronizada no dreno pós-sucesso.
 expect(await queue.count(), 0);
 });

 test('run com erro de REDE enfileira e lança OfflineEnqueuedException', (
 ) async {
 await expectLater(
 sync.run(
 opType: 'process_sale',
 payload: {'sale': {'id': 's1'}},
 rpc: () async => throw http.ClientException('conexão recusada'),
 ),
 throwsA(isA<OfflineEnqueuedException>()),
 );

 expect(await queue.count(), 1);
 final op = await queue.next();
 expect(op!.opType, 'process_sale');
 expect((op.payload['sale'] as Map)['id'], 's1');
 });

 test('run com timeout também enfileira (rede)', () async {
 await expectLater(
 sync.run(
 opType: 'process_purchase',
 payload: {'purchase': {'id': 'pc1'}},
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
 payload: {'sale': {'id': 's1'}},
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
 payload: {'sale': {'id': 'a'}},
 createdAt: DateTime(2026, 8, 16, 10),
 ),
 );
 await queue.add(
 PendingOp(
 opType: 'process_sale',
 payload: {'sale': {'id': 'b'}},
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
 payload: {'sale': {'id': 'b'}},
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
}

PendingOp _op(String opType, String id) => PendingOp(
 opType: opType,
 payload: {'sale': {'id': id}},
 createdAt: DateTime(2026, 8, 16),
);
