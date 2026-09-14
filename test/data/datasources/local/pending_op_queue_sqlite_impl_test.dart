import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:tareqo/core/database/app_database_io.dart';
import 'package:tareqo/core/security/pending_op_payload_cipher.dart';
import 'package:tareqo/core/security/secure_storage_service.dart';
import 'package:tareqo/data/datasources/local/pending_op_queue.dart';
import 'package:tareqo/data/datasources/local/pending_op_queue_sqlite_impl.dart';

/// Backend em memória (mesmo padrão dos testes de core/security).
class _InMemoryBackend implements SecureStorageBackend {
  final Map<String, String> store = {};

  @override
  Future<String?> read(String key) async => store[key];

  @override
  Future<void> write(String key, String value) async => store[key] = value;

  @override
  Future<void> delete(String key) async => store.remove(key);
}

void main() {
  late Directory tempDirectory;
  late Database db;
  late PendingOpQueueSqliteImpl queue;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('pending_ops_test');
    db = sqlite3.open('${tempDirectory.path}${Platform.pathSeparator}test.db');
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

  test('markFailed agenda backoff exponencial (A3)', () async {
    await queue.add(makeOp('register_debt'));
    final op = await queue.next();
    await queue.markFailed(op!.id!, 'erro de negócio');

    final updated = (await queue.list()).single;
    expect(updated.attemptCount, 1);
    expect(updated.lastError, 'erro de negócio');
    // Próxima tentativa agendada para o futuro (30s + margem), não imediata.
    expect(updated.dead, isFalse);
    expect(updated.nextRetryAt, isNotNull);
    expect(
      updated.nextRetryAt!.isAfter(
        DateTime.now().add(const Duration(seconds: 20)),
      ),
      isTrue,
    );
  });

  test('dead-letter após esgotar tentativas (A3)', () async {
    await queue.add(makeOp('register_debt'));
    final op = await queue.next();
    for (var i = 0; i < pendingOpMaxAttempts; i++) {
      await queue.markFailed(op!.id!, 'erro $i');
    }

    final dead = (await queue.list()).single;
    expect(dead.dead, isTrue);
    expect(dead.attemptCount, pendingOpMaxAttempts);
    // Sai da contagem e do next (nunca mais reenviada), mas permanece no
    // banco para auditoria.
    expect(await queue.count(), 0);
    expect(await queue.next(), isNull);
    expect((await queue.list()).length, 1);
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

  group('P3 — payload do outbox CIFRADO em repouso', () {
    late SecureStorageService storage;
    late PendingOpPayloadCipher cipher;
    late PendingOpQueueSqliteImpl encryptedQueue;

    setUp(() {
      storage = SecureStorageService(backend: _InMemoryBackend());
      cipher = PendingOpPayloadCipher(storage);
      encryptedQueue = PendingOpQueueSqliteImpl(db, cipher: cipher);
    });

    String rawPayloadOf(int id) =>
        db
                .select('SELECT payload FROM pending_ops WHERE id = $id')
                .first['payload']
            as String;

    test(
      'add grava o payload cifrado — NÃO contém o JSON em texto claro',
      () async {
        await encryptedQueue.add(
          PendingOp(
            opType: 'process_sale',
            payload: {
              'sale': {
                'id': 's1',
                'totalAmountCents': 99900,
                'items': [
                  {'productName': 'Açúcar', 'unitPriceCents': 999},
                ],
              },
            },
            createdAt: DateTime.now(),
          ),
        );

        final raw = rawPayloadOf(1);
        // O valor financeiro e o nome do cliente NÃO podem estar legíveis.
        expect(raw.contains('99900'), isFalse);
        expect(raw.contains('Açúcar'), isFalse);
        expect(raw.contains('totalAmountCents'), isFalse);
        // Formato do cipher: base64(nonce || ciphertext || mac).
        expect(() => base64Decode(raw), returnsNormally);
      },
    );

    test(
      'round-trip: next/list decifram exatamente o payload gravado',
      () async {
        final original = PendingOp(
          opType: 'settle_debt',
          payload: {'debtId': 'd9', 'storeId': 'st1'},
          createdAt: DateTime(2026, 9, 13, 8),
        );
        await encryptedQueue.add(original);

        final read = await encryptedQueue.next();
        expect(read!.opType, 'settle_debt');
        expect(read.payload, original.payload);

        final listed = await encryptedQueue.list();
        expect(listed.single.payload, original.payload);
      },
    );

    test(
      'linha legada em TEXTO CLARO é migrada para cifrado na leitura',
      () async {
        // Simula uma op gravada por versão anterior (payload em claro).
        db.execute(
          'INSERT INTO pending_ops '
          '(op_type, payload, created_at, attempt_count, last_error, '
          'next_retry_at, dead) VALUES (?, ?, ?, 0, NULL, NULL, 0)',
          [
            'register_debt',
            jsonEncode({
              'debt': {'id': 'd2', 'personName': 'Maria', 'amountCents': 1000},
            }),
            DateTime.now().millisecondsSinceEpoch,
          ],
        );

        // A leitura decifra/aceita o legado E regrava a linha cifrada.
        final op = await encryptedQueue.next();
        expect(
          (op!.payload['debt'] as Map<String, dynamic>)['personName'],
          'Maria',
        );
        final raw = rawPayloadOf(op.id!);
        expect(raw.contains('Maria'), isFalse);
        expect(raw.contains('amountCents'), isFalse);
      },
    );

    test(
      'payload adulterado (MAC inválido) não decifra como dado falso',
      () async {
        await encryptedQueue.add(
          PendingOp(
            opType: 'process_sale',
            payload: {
              'sale': {'id': 's3'},
            },
            createdAt: DateTime.now(),
          ),
        );
        // Adultera o ciphertext no banco (independente da chave).
        db.execute(
          "UPDATE pending_ops SET payload = 'AAAA' || payload WHERE id = 1",
        );

        // A leitura trata como legado — e o "legado" corrompido falha o
        // jsonDecode (lança). Nunca devolve um payload inventado.
        await expectLater(encryptedQueue.next(), throwsA(anything));
      },
    );
  });
}
