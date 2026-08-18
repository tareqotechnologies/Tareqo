import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:dumbhanengue/core/database/app_database_io.dart';
import 'package:dumbhanengue/data/datasources/local/pending_op_queue.dart';
import 'package:dumbhanengue/data/datasources/local/pending_op_queue_sqlite_impl.dart';

void main() {
 late Directory tempDirectory;
 late Database db;
 late PendingOpQueueSqliteImpl queue;

 setUp(() async {
 tempDirectory = await Directory.systemTemp.createTemp('pending_ops_test');
 db = sqlite3.open(
 '${tempDirectory.path}${Platform.pathSeparator}test.db',
 );
 db.execute('PRAGMA foreign_keys = ON;');
 AppDatabase.initialize(db); // v2 cria a tabela pending_ops
 queue = PendingOpQueueSqliteImpl(db);
 });

 tearDown(() {
 db.close();
 if (tempDirectory.existsSync()) tempDirectory.deleteSync(recursive: true);
 });

 PendingOp makeOp(String opType, {String key = 'k'}) => PendingOp(
 opType: opType,
 payload: {'key': key},
 createdAt: DateTime(2026, 8, 16, 12),
 );

 test('add enfileira e next devolve a MAIS ANTIGA (FIFO)', () async {
 expect(await queue.count(), 0);
 expect(await queue.next(), isNull);

 await queue.add(makeOp('process_sale', key: 'v1'));
 await queue.add(makeOp('process_sale', key: 'v2'));
 await queue.add(makeOp('settle_debt', key: 'v3'));

 expect(await queue.count(), 3);

 final first = await queue.next();
 expect(first!.opType, 'process_sale');
 expect(first.payload['key'], 'v1');
 // next NÃO remove — a mesma op é devolvida até o remove.
 expect((await queue.next())!.payload['key'], 'v1');
 });

 test('remove apaga a operação (replay com sucesso)', () async {
 await queue.add(makeOp('process_sale'));
 final op = await queue.next();
 await queue.remove(op!.id!);
 expect(await queue.count(), 0);
 expect(await queue.next(), isNull);
 });

 test('markFailed incrementa tentativas e guarda o erro', () async {
 await queue.add(makeOp('register_debt'));
 final op = await queue.next();
 await queue.markFailed(op!.id!, 'erro de negócio');

 final updated = (await queue.list()).single;
 expect(updated.attemptCount, 1);
 expect(updated.lastError, 'erro de negócio');
 // Continua na fila (não foi removida).
 expect(await queue.count(), 1);
 });

 test('list devolve em ordem FIFO com payloads íntegros', () async {
 await queue.add(makeOp('process_sale', key: 'a'));
 await queue.add(makeOp('cancel_sale', key: 'b'));
 final ops = await queue.list();
 expect(ops.map((op) => op.payload['key']), ['a', 'b']);
 expect(ops.first.id, lessThan(ops.last.id!));
 });

 test('payload com acentos/JSON complexo sobrevive ao round-trip', () async {
 await queue.add(
 PendingOp(
 opType: 'register_debt',
 payload: {
 'debt': {
 'id': 'd1',
 'personName': 'João da Silva',
 'amountCents': 2500,
 },
 },
 createdAt: DateTime.now(),
 ),
 );
 final op = await queue.next();
 expect(
 (op!.payload['debt'] as Map<String, dynamic>)['personName'],
 'João da Silva',
 );
 });
}
