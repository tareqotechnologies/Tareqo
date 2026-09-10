import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:tareqo/data/datasources/local/pending_op_queue_memory_impl.dart';
import 'package:tareqo/data/services/offline_aware_processors.dart';
import 'package:tareqo/data/services/offline_sync_service.dart';
import 'package:tareqo/domain/entities/debt.dart';
import 'package:tareqo/domain/entities/purchase.dart';
import 'package:tareqo/domain/entities/sale.dart';
import 'package:tareqo/domain/repositories/i_debt_processor.dart';
import 'package:tareqo/domain/repositories/i_purchase_processor.dart';
import 'package:tareqo/domain/repositories/i_sale_processor.dart';

Sale _sale(String id, {String storeId = 'st1'}) => Sale(
  id: id,
  storeId: storeId,
  number: 1,
  dateTime: DateTime(2026, 8, 16, 9),
  items: const [],
  totalAmountCents: 2500,
  paymentMethod: PaymentMethod.cash,
);

Purchase _purchase(String id) => Purchase(
  id: id,
  supplierName: 'Fornecedor',
  items: const [],
  totalAmountCents: 10000,
  dateTime: DateTime(2026, 8, 16, 10),
);

Debt _debt(String id) => Debt(
  id: id,
  personName: 'Cliente',
  amountCents: 3000,
  dueDate: DateTime(2026, 9, 1),
  isCustomerDebt: true,
);

void main() {
  late PendingOpQueueMemoryImpl queue;
  late OfflineSyncService sync;

  setUp(() {
    queue = PendingOpQueueMemoryImpl();
    sync = OfflineSyncService(queue);
  });

  group('OfflineAwareSaleProcessor (venda offline-aware)', () {
    test('com rede: delega à RPC e NÃO enfileira nada', () async {
      var innerCalls = 0;
      final inner = _FakeSaleProcessor(() async => innerCalls++);
      final processor = OfflineAwareSaleProcessor(inner, sync);

      await processor.process(_sale('s1'));

      expect(innerCalls, 1);
      expect(await queue.count(), 0);
    });

    test(
      'sem rede (ClientException): enfileira process_sale e lança OfflineEnqueuedException',
      () async {
        final inner = _FakeSaleProcessor(
          () async => throw Exception('não deve ser exceção de rede'),
        );
        // RPC que falha com erro de REDE:
        final failing = _FakeSaleProcessor(
          () async => throw http.ClientException('offline'),
        );
        final processor = OfflineAwareSaleProcessor(failing, sync);

        await expectLater(
          processor.process(_sale('s1')),
          throwsA(isA<OfflineEnqueuedException>()),
        );

        expect(await queue.count(), 1);
        final op = await queue.next();
        expect(op!.opType, 'process_sale');
        expect((op.payload['sale'] as Map)['id'], 's1');
        // ignore: unnecessary_statements
        inner; // RPC saudável nunca foi chamada neste cenário
      },
    );

    test(
      'timeout também é REDE: enfileira em vez de propagar o erro',
      () async {
        final failing = _FakeSaleProcessor(
          () async => throw TimeoutException('timeout global'),
        );
        final processor = OfflineAwareSaleProcessor(failing, sync);

        await expectLater(
          processor.process(_sale('s2')),
          throwsA(isA<OfflineEnqueuedException>()),
        );
        expect(await queue.count(), 1);
      },
    );

    test('erro de NEGÓCIO (ex.: estoque) NÃO é enfileirado', () async {
      final failing = _FakeSaleProcessor(
        () async => throw StateError('estoque insuficiente'),
      );
      final processor = OfflineAwareSaleProcessor(failing, sync);

      await expectLater(
        processor.process(_sale('s3')),
        throwsA(isA<StateError>()),
      );
      expect(await queue.count(), 0);
    });
  });

  group('OfflineAwarePurchaseProcessor (compra offline-aware)', () {
    test(
      'com rede: processa direto; sem rede: enfileira process_purchase',
      () async {
        var calls = 0;
        final ok = OfflineAwarePurchaseProcessor(
          _FakePurchaseProcessor(() async => calls++),
          sync,
        );
        await ok.process(_purchase('pc1'));
        expect(calls, 1);

        final failing = OfflineAwarePurchaseProcessor(
          _FakePurchaseProcessor(
            () async => throw http.ClientException('offline'),
          ),
          sync,
        );
        await expectLater(
          failing.process(_purchase('pc2')),
          throwsA(isA<OfflineEnqueuedException>()),
        );
        expect(await queue.count(), 1);
        final op = await queue.next();
        expect(op!.opType, 'process_purchase');
        expect((op.payload['purchase'] as Map)['id'], 'pc2');
      },
    );
  });

  group('OfflineAwareDebtProcessor (fiado offline-aware)', () {
    test(
      'register sem rede enfileira register_debt com o payload da dívida',
      () async {
        final failing = OfflineAwareDebtProcessor(
          _FakeDebtProcessor(
            onRegister: () async => throw http.ClientException('offline'),
          ),
          sync,
        );

        await expectLater(
          failing.register(_debt('d1')),
          throwsA(isA<OfflineEnqueuedException>()),
        );

        final op = await queue.next();
        expect(op!.opType, 'register_debt');
        expect((op.payload['debt'] as Map)['id'], 'd1');
      },
    );

    test('settle sem rede enfileira settle_debt com dívida e loja', () async {
      final failing = OfflineAwareDebtProcessor(
        _FakeDebtProcessor(
          onSettle: () async => throw http.ClientException('offline'),
        ),
        sync,
      );

      await expectLater(
        failing.settle('d9', storeId: 'st7'),
        throwsA(isA<OfflineEnqueuedException>()),
      );

      final op = await queue.next();
      expect(op!.opType, 'settle_debt');
      expect(op.payload['debtId'], 'd9');
      expect(op.payload['storeId'], 'st7');
    });

    test('erro de negócio no register propaga SEM enfileirar', () async {
      final failing = OfflineAwareDebtProcessor(
        _FakeDebtProcessor(
          onRegister: () async => throw StateError('cliente inexistente'),
        ),
        sync,
      );

      await expectLater(
        failing.register(_debt('d2')),
        throwsA(isA<StateError>()),
      );
      expect(await queue.count(), 0);
    });
  });

  group('OfflineAwareSaleCancellationProcessor (anulação offline-aware)', () {
    test('com rede: cancela direto', () async {
      var calls = 0;
      final ok = OfflineAwareSaleCancellationProcessor(
        _FakeCancellationProcessor(() async => calls++),
        sync,
      );

      await ok.cancel('s1', storeId: 'st1');

      expect(calls, 1);
      expect(await queue.count(), 0);
    });

    test(
      'sem rede: enfileira cancel_sale e lança OfflineEnqueuedException',
      () async {
        final failing = OfflineAwareSaleCancellationProcessor(
          _FakeCancellationProcessor(
            () async => throw http.ClientException('offline'),
          ),
          sync,
        );

        await expectLater(
          failing.cancel('s1', storeId: 'st1'),
          throwsA(isA<OfflineEnqueuedException>()),
        );

        final op = await queue.next();
        expect(op!.opType, 'cancel_sale');
        expect(op.payload['saleId'], 's1');
        expect(op.payload['storeId'], 'st1');
      },
    );
  });

  group('Replay de ponta a ponta (fila → replayer → sucesso)', () {
    test(
      'fluxo offline completo: enfileira, registra replayer e drena',
      () async {
        final processed = <String>[];
        final failing = OfflineAwareSaleProcessor(
          _FakeSaleProcessor(() async => throw http.ClientException('offline')),
          sync,
        );

        // Venda feita SEM rede: enfileirada e avisada como "salvo offline".
        await expectLater(
          failing.process(_sale('s-off')),
          throwsA(isA<OfflineEnqueuedException>()),
        );
        expect(await queue.count(), 1);

        // Rede volta: o app registra o replayer (mesma RPC) e drena.
        sync.registerReplayer('process_sale', (payload) async {
          processed.add((payload['sale'] as Map)['id'] as String);
        });
        final synced = await sync.drain();

        expect(synced, 1);
        expect(processed, ['s-off']);
        expect(await queue.count(), 0);
      },
    );

    test(
      'replay falha por NEGÓCIO: op marcada com erro e NÃO duplica venda',
      () async {
        final failing = OfflineAwareSaleProcessor(
          _FakeSaleProcessor(() async => throw http.ClientException('offline')),
          sync,
        );
        await expectLater(
          failing.process(_sale('s-bad')),
          throwsA(isA<OfflineEnqueuedException>()),
        );

        // Servidor rejeita (ex.: venda já processada / estoque insuficiente).
        sync.registerReplayer(
          'process_sale',
          (payload) async => throw StateError('estoque insuficiente'),
        );
        await sync.drain();

        // A op PERMANECE (com erro/backoff) — não é nem enviada de novo já
        // (nextRetryAt futuro), nem removida como se tivesse sucesso.
        final ops = await queue.list();
        expect(ops.single.lastError, contains('estoque insuficiente'));
        expect(ops.single.attemptCount, 1);
        expect(ops.single.nextRetryAt, isNotNull);
      },
    );
  });
}

class _FakeSaleProcessor implements ISaleAtomicProcessor {
  _FakeSaleProcessor(this._onProcess);

  final Future<void> Function() _onProcess;

  @override
  Future<void> process(Sale sale) => _onProcess();
}

class _FakePurchaseProcessor implements IPurchaseAtomicProcessor {
  _FakePurchaseProcessor(this._onProcess);

  final Future<void> Function() _onProcess;

  @override
  Future<void> process(Purchase purchase) => _onProcess();
}

class _FakeDebtProcessor implements IDebtAtomicProcessor {
  _FakeDebtProcessor({this.onRegister, this.onSettle});

  final Future<void> Function()? onRegister;
  final Future<void> Function()? onSettle;

  @override
  Future<void> register(Debt debt) async => await onRegister?.call();

  @override
  Future<void> settle(String debtId, {required String storeId}) async =>
      await onSettle?.call();
}

class _FakeCancellationProcessor implements ISaleCancellationProcessor {
  _FakeCancellationProcessor(this._onCancel);

  final Future<void> Function() _onCancel;

  @override
  Future<void> cancel(String saleId, {required String storeId}) => _onCancel();
}
