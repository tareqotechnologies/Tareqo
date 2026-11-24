import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sqlite3/sqlite3.dart';

import 'package:tareqo/core/database/app_database_io.dart';
import 'package:tareqo/core/security/pending_op_payload_cipher.dart';
import 'package:tareqo/core/security/secure_storage_service.dart';
import 'package:tareqo/data/datasources/local/pending_op_queue.dart';
import 'package:tareqo/data/datasources/local/pending_op_queue_memory_impl.dart';
import 'package:tareqo/data/datasources/local/pending_op_queue_sqlite_impl.dart';
import 'package:tareqo/data/services/offline_sync_service.dart';

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
  group('OfflineSyncService & Outbox — Testes de Stress e Alta Concorrência', () {
    test(
      '50 operações concorrentes enfileiradas e drenadas sob conexão instável (in-memory)',
      () async {
        final queue = PendingOpQueueMemoryImpl();
        final sync = OfflineSyncService(queue);
        final syncedIds = <String>[];
        var failureToggle = 0;

        sync.registerReplayer('process_sale', (payload) async {
          final id = (payload['sale'] as Map)['id'] as String;
          // Simula falha intermitente a cada 5 chamadas (simulando instabilidade)
          failureToggle++;
          if (failureToggle % 7 == 0) {
            throw http.ClientException('oscilação temporária de rede');
          }
          syncedIds.add(id);
        });

        // 1. Simula 50 operações concorrentes falhando por rede e caindo no outbox
        final enqueueFutures = List.generate(50, (index) async {
          try {
            await sync.run(
              opType: 'process_sale',
              payload: {
                'sale': {'id': 'sale-$index'},
              },
              rpc: () async => throw http.ClientException('offline'),
            );
          } on OfflineEnqueuedException {
            // Esperado quando enfileirado
          }
        });

        await Future.wait(enqueueFutures);
        expect(await queue.count(), 50);

        // 2. Drena em loop até esvaziar (comportamento sob reconexão progressiva)
        var totalCycles = 0;
        while (await queue.count() > 0 && totalCycles < 20) {
          totalCycles++;
          await sync.drain();
        }

        expect(await queue.count(), 0);
        expect(syncedIds.length, 50);

        // Confere unicidade e que todas as 50 foram sincronizadas
        final uniqueSynced = syncedIds.toSet();
        expect(uniqueSynced.length, 50);
      },
    );

    test(
      'Escrita concorrente no SQLite durante execução ativa de drain()',
      () async {
        final tempDir = await Directory.systemTemp.createTemp('sync_stress_');
        final db = sqlite3.open(
          '${tempDir.path}${Platform.pathSeparator}stress.db',
        );
        db.execute('PRAGMA foreign_keys = ON;');
        AppDatabase.initialize(db);

        final backend = _InMemoryBackend();
        final cipher = PendingOpPayloadCipher(
          SecureStorageService(backend: backend),
        );
        final queue = PendingOpQueueSqliteImpl(db, cipher: cipher);
        final sync = OfflineSyncService(queue);

        final processed = <String>[];

        sync.registerReplayer('process_sale', (payload) async {
          final id = (payload['sale'] as Map)['id'] as String;
          processed.add(id);
          // Atraso intencional para permitir escrita concorrente durante o dreno
          await Future<void>.delayed(const Duration(milliseconds: 10));
        });

        // Pré-carrega 10 itens
        for (var i = 0; i < 10; i++) {
          await queue.add(
            PendingOp(
              opType: 'process_sale',
              payload: {
                'sale': {'id': 'initial-$i'},
              },
              createdAt: DateTime.now(),
            ),
          );
        }

        // Inicia o drain em background
        final drainFuture = sync.drain();

        // Concorrentemente adiciona mais 10 itens enquanto o drain está processando
        final concurrentAdd = List.generate(10, (i) async {
          await Future<void>.delayed(const Duration(milliseconds: 15));
          await queue.add(
            PendingOp(
              opType: 'process_sale',
              payload: {
                'sale': {'id': 'concurrent-$i'},
              },
              createdAt: DateTime.now(),
            ),
          );
        });

        await Future.wait([drainFuture, ...concurrentAdd]);

        // Executa um segundo drain para processar os itens inseridos concorrentemente
        await sync.drain();

        expect(await queue.count(), 0);
        expect(processed.length, 20);

        db.close();
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      },
    );

    test('Preservação de ordem FIFO estrita sob carga massiva', () async {
      final queue = PendingOpQueueMemoryImpl();
      final sync = OfflineSyncService(queue);
      final executionOrder = <int>[];

      sync.registerReplayer('ordered_op', (payload) async {
        executionOrder.add(payload['seq'] as int);
      });

      const totalOps = 100;
      for (var i = 0; i < totalOps; i++) {
        await queue.add(
          PendingOp(
            opType: 'ordered_op',
            payload: {'seq': i},
            createdAt: DateTime.now().add(Duration(milliseconds: i)),
          ),
        );
      }

      await sync.drain();

      expect(executionOrder.length, totalOps);
      for (var i = 0; i < totalOps; i++) {
        expect(executionOrder[i], i, reason: 'Ordem FIFO violada no índice $i');
      }
    });

    test(
      'Mistura heterogênea de erros de negócio e erros de rede com 40 transações',
      () async {
        final queue = PendingOpQueueMemoryImpl();
        final sync = OfflineSyncService(queue);
        final successfulIds = <String>[];

        sync.registerReplayer('multi_type', (payload) async {
          final id = payload['id'] as String;
          final type = payload['type'] as String;

          if (type == 'business_error') {
            throw StateError('erro de validação');
          } else if (type == 'network_error') {
            throw http.ClientException('falha de conexão');
          }

          successfulIds.add(id);
        });

        // Enfileira:
        // - 10 válidos
        // - 1 de rede (para travar o dreno temporariamente)
        // - 5 de negócio (marcam falha com backoff e continuam)
        // - 10 válidos
        for (var i = 0; i < 10; i++) {
          await queue.add(
            PendingOp(
              opType: 'multi_type',
              payload: {'id': 'good-1-$i', 'type': 'ok'},
              createdAt: DateTime.now(),
            ),
          );
        }
        await queue.add(
          PendingOp(
            opType: 'multi_type',
            payload: {'id': 'net-stop', 'type': 'network_error'},
            createdAt: DateTime.now(),
          ),
        );
        for (var i = 0; i < 5; i++) {
          await queue.add(
            PendingOp(
              opType: 'multi_type',
              payload: {'id': 'biz-$i', 'type': 'business_error'},
              createdAt: DateTime.now(),
            ),
          );
        }
        for (var i = 0; i < 10; i++) {
          await queue.add(
            PendingOp(
              opType: 'multi_type',
              payload: {'id': 'good-2-$i', 'type': 'ok'},
              createdAt: DateTime.now(),
            ),
          );
        }

        // 1º dreno: processa os primeiros 10 e para no de rede
        final firstDrain = await sync.drain();
        expect(firstDrain, 10);
        expect(successfulIds.length, 10);

        // Remove o de rede para simular restabelecimento
        final remainingOps = await queue.list();
        final netOp = remainingOps.firstWhere(
          (o) => o.payload['id'] == 'net-stop',
        );
        await queue.remove(netOp.id!);

        // 2º dreno: processa os 5 de negócio (marca erro e continua) e sincroniza os 10 válidos seguintes
        final secondDrain = await sync.drain();
        expect(secondDrain, 10);
        expect(successfulIds.length, 20);

        // Os 5 de negócio devem permanecer na fila com erro registrado
        final failedBiz = await queue.list();
        expect(failedBiz.length, 5);
        for (final op in failedBiz) {
          expect(op.lastError, contains('erro de validação'));
          expect(op.attemptCount, 1);
        }
      },
    );
  });
}
