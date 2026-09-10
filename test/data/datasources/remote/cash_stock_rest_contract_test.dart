import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:tareqo/data/datasources/remote/supabase_financial_transaction_data_source.dart';
import 'package:tareqo/data/datasources/remote/supabase_stock_lot_data_source.dart';
import 'package:tareqo/domain/entities/financial_transaction.dart';
import 'package:tareqo/domain/entities/stock_lot.dart';

import '../../../helpers/supabase_test_harness.dart';

/// Testes de CONTRATO REST dos datasources remotos de caixa (transações
/// financeiras) e estoque FIFO (lotes) — leitura, escrita com `user_id` da
/// sessão, guarda de linhas afetadas e escopo por loja.
void main() {
  late StubSupabaseHttp stub;

  setUpAll(() async {
    stub = await initStubbedSupabase();
    await signInStubUser();
  });

  setUp(() {
    stub.handler = null;
    stub.requests.clear();
    stub.failNext = null;
  });

  StockLot lot(
    String id, {
    String storeId = 'st1',
    int current = 10,
    DateTime? entry,
    DateTime? expiry,
  }) => StockLot(
    id: id,
    storeId: storeId,
    productId: 'p1',
    entryDate: entry ?? DateTime.utc(2026, 1, 1),
    expiryDate: expiry,
    initialQuantity: current,
    currentQuantity: current,
    costPriceCents: 500,
  );

  group('FinancialTransactionSupabaseDataSourceImpl', () {
    const ds = FinancialTransactionSupabaseDataSourceImpl();

    test('getAll mapeia transação completa com escopo por loja', () async {
      stub.handler = (path, request) {
        if (path.contains('financial_transactions')) {
          return FakeResponse([
            {
              'id': 't1',
              'store_id': 'st1',
              'description': 'Energia elétrica',
              'amount': 18000,
              'type': 'expense',
              'category': 'Contas',
              'date': '2026-08-03T09:15:00Z',
              'status': 'pending',
              'debt_id': null,
            },
          ]);
        }
        return FakeResponse(<dynamic>[]);
      };

      final txs = await ds.getAll(storeId: 'st1');
      final tx = txs.single;
      expect(tx.id, 't1');
      expect(tx.description, 'Energia elétrica');
      expect(tx.amountCents, 18000);
      expect(tx.type, TransactionType.expense);
      expect(tx.status, TransactionStatus.pending);
      expect(tx.date, DateTime.parse('2026-08-03T09:15:00Z').toLocal());

      final req = stub.requests.single;
      expect(req.url.path, contains('financial_transactions'));
      expect(req.url.queryParameters, containsPair('store_id', 'eq.st1'));
    });

    test('getAll resolve dívida vinculada (debt_id presente)', () async {
      stub.handler = (path, request) {
        if (path.contains('financial_transactions')) {
          return FakeResponse([
            {
              'id': 't2',
              'store_id': 'st1',
              'description': 'Fiado da Ana',
              'amount': 3000,
              'type': 'income',
              'category': 'Vendas',
              'date': '2026-08-04T10:00:00Z',
              'status': 'paid',
              'debt_id': 'd1',
            },
          ]);
        }
        return FakeResponse(<dynamic>[]);
      };

      final tx = (await ds.getAll(storeId: 'st1')).single;
      expect(tx.debtId, 'd1');
      expect(tx.type, TransactionType.income);
    });

    test('add grava user_id da sessão, enums pelo nome e data UTC', () async {
      final bodies = <Map<String, dynamic>>[];
      stub.handler = (path, request) {
        if (path.contains('financial_transactions')) {
          bodies.add(
            jsonDecode((request as http.Request).body) as Map<String, dynamic>,
          );
          return FakeResponse(<dynamic>[]);
        }
        return FakeResponse(<dynamic>[]);
      };

      await ds.add(
        FinancialTransaction(
          id: 't-nova',
          description: 'Recebimento fiado',
          amountCents: 3000,
          type: TransactionType.income,
          category: 'Vendas',
          date: DateTime.utc(2026, 9, 1, 8, 0),
          status: TransactionStatus.pending,
          debtId: 'd9',
        ),
      );
      final body = bodies.single;
      expect(body['id'], 't-nova');
      expect(body['user_id'], 'u1');
      expect(body['type'], 'income');
      expect(body['status'], 'pending');
      expect(body['debt_id'], 'd9');
      expect(body['date'], '2026-09-01T08:00:00.000Z');
    });

    test('add sem debt_id omite a coluna (não grava null)', () async {
      final bodies = <Map<String, dynamic>>[];
      stub.handler = (path, request) {
        if (path.contains('financial_transactions')) {
          bodies.add(
            jsonDecode((request as http.Request).body) as Map<String, dynamic>,
          );
          return FakeResponse(<dynamic>[]);
        }
        return FakeResponse(<dynamic>[]);
      };

      await ds.add(
        FinancialTransaction(
          id: 't-sem-dívida',
          description: 'Compra de estoque',
          amountCents: 5000,
          type: TransactionType.expense,
          category: 'Estoque',
          date: DateTime.utc(2026, 9, 1),
        ),
      );
      expect(bodies.single.containsKey('debt_id'), isFalse);
    });

    test('markAsPaid carimba paid + data e valida linhas afetadas', () async {
      final bodies = <Map<String, dynamic>>[];
      stub.handler = (path, request) {
        if (path.contains('financial_transactions')) {
          bodies.add(
            jsonDecode((request as http.Request).body) as Map<String, dynamic>,
          );
          return FakeResponse([
            {'id': 't1'},
          ]);
        }
        return FakeResponse(<dynamic>[]);
      };

      await ds.markAsPaid('t1', storeId: 'st1');
      final req = stub.requests.single;
      expect(req.method, 'PATCH');
      expect(req.url.queryParameters, containsPair('id', 'eq.t1'));
      expect(req.url.queryParameters, containsPair('store_id', 'eq.st1'));
      final body = bodies.single;
      expect(body['status'], 'paid');
      expect(body['date'], isNotNull); // Data de realização carimbada.
    });

    test('markAsPaid em transação inexistente lança StateError', () async {
      await expectLater(
        ds.markAsPaid('t-fantasma', storeId: 'st1'),
        throwsStateError,
      );
    });
  });

  group('StockLotSupabaseDataSourceImpl — leitura FIFO', () {
    const ds = StockLotSupabaseDataSourceImpl();

    test(
      'getActiveByProduct ordena FIFO: validade → entrada → id (nulo no fim)',
      () async {
        stub.handler = (path, request) {
          if (path.contains('stock_lots')) {
            // Servidor devolve em ordem de id (keyset) — o datasource
            // reordena client-side pela regra FIFO.
            return FakeResponse([
              row('lot-z-nulo', entry: '2026-02-01T00:00:00Z', expiry: null),
              row(
                'lot-b-fev',
                entry: '2026-01-05T00:00:00Z',
                expiry: '2026-12-01T00:00:00Z',
              ),
              row(
                'lot-c-jan',
                entry: '2026-01-10T00:00:00Z',
                expiry: '2026-11-01T00:00:00Z',
              ),
              row(
                'lot-a-empate',
                entry: '2026-01-11T00:00:00Z',
                expiry: '2026-11-01T00:00:00Z',
              ),
            ]);
          }
          return FakeResponse(<dynamic>[]);
        };

        final lots = await ds.getActiveByProduct('p1', storeId: 'st1');
        expect(
          lots.map((l) => l.id).toList(),
          ['lot-c-jan', 'lot-a-empate', 'lot-b-fev', 'lot-z-nulo'],
          reason: 'mesma validade → desempate por entrada; sem validade → fim',
        );
      },
    );

    test(
      'lotes com quantidade 0 ou negativa NÃO vêm na listagem ativa',
      () async {
        stub.handler = (path, request) {
          if (path.contains('stock_lots')) {
            // O filtro gt(current_quantity, 0) está na URL; o stub responde
            // apenas linhas ativas.
            expect(
              request.url.queryParameters,
              containsPair('current_quantity', 'gt.0'),
            );
            return FakeResponse([
              row('lot-ativo', entry: '2026-01-01T00:00:00Z', expiry: null),
            ]);
          }
          return FakeResponse(<dynamic>[]);
        };

        final lots = await ds.getActiveByProduct('p1', storeId: 'st1');
        expect(lots.single.id, 'lot-ativo');
      },
    );

    test('getByStore usa paginação keyset em múltiplas páginas', () async {
      var page = 0;
      stub.handler = (path, request) {
        if (path.contains('stock_lots')) {
          final isPage2 = request.url.queryParameters.containsKey('id');
          page = isPage2 ? 1 : 0;
          if (page == 0) {
            return FakeResponse([
              for (var i = 0; i < 1000; i++)
                row('lot-p1-$i', entry: '2026-01-01T00:00:00Z', expiry: null),
            ]);
          }
          return FakeResponse([
            row('lot-p2-0', entry: '2026-01-02T00:00:00Z', expiry: null),
          ]);
        }
        return FakeResponse(<dynamic>[]);
      };

      final lots = await ds.getByStore(storeId: 'st1');
      expect(lots, hasLength(1001));
      expect(stub.requests.last.url.queryParameters['id'], 'gt.lot-p1-999');
    });
  });

  group('StockLotSupabaseDataSourceImpl — escritas', () {
    test('add grava user_id da sessão e datas em UTC', () async {
      final bodies = <Map<String, dynamic>>[];
      stub.handler = (path, request) {
        if (path.contains('stock_lots')) {
          bodies.add(
            jsonDecode((request as http.Request).body) as Map<String, dynamic>,
          );
          return FakeResponse(<dynamic>[]);
        }
        return FakeResponse(<dynamic>[]);
      };

      await const StockLotSupabaseDataSourceImpl().add(
        lot(
          'lot-novo',
          entry: DateTime.utc(2026, 3, 1),
          expiry: DateTime.utc(2027, 3, 1),
        ),
      );
      final body = bodies.single;
      expect(body['user_id'], 'u1');
      expect(body['entry_date'], '2026-03-01T00:00:00.000Z');
      expect(body['expiry_date'], '2027-03-01T00:00:00.000Z');
      expect(body['cost_price'], 500);
    });

    test('add com lote sem validade grava expiry_date null', () async {
      final bodies = <Map<String, dynamic>>[];
      stub.handler = (path, request) {
        if (path.contains('stock_lots')) {
          bodies.add(
            jsonDecode((request as http.Request).body) as Map<String, dynamic>,
          );
          return FakeResponse(<dynamic>[]);
        }
        return FakeResponse(<dynamic>[]);
      };

      await const StockLotSupabaseDataSourceImpl().add(lot('lot-s/val'));
      expect(bodies.single['expiry_date'], isNull);
    });

    test('updateQuantity com escopo por loja e guarda de linhas', () async {
      final bodies = <Map<String, dynamic>>[];
      stub.handler = (path, request) {
        if (path.contains('stock_lots')) {
          bodies.add(
            jsonDecode((request as http.Request).body) as Map<String, dynamic>,
          );
          return FakeResponse([
            {'id': 'lot1'},
          ]);
        }
        return FakeResponse(<dynamic>[]);
      };

      await const StockLotSupabaseDataSourceImpl().updateQuantity(
        'lot1',
        42,
        storeId: 'st1',
      );
      final req = stub.requests.single;
      expect(req.url.queryParameters, containsPair('id', 'eq.lot1'));
      expect(req.url.queryParameters, containsPair('store_id', 'eq.st1'));
      expect(bodies.single['current_quantity'], 42);
    });

    test(
      'updateQuantity em lote de OUTRA loja (0 linhas) lança StateError',
      () async {
        await expectLater(
          const StockLotSupabaseDataSourceImpl().updateQuantity(
            'lot-alheio',
            1,
            storeId: 'st1',
          ),
          throwsStateError,
        );
      },
    );

    test(
      'increaseQuantity lê o atual e soma (fallback melhor esforço)',
      () async {
        stub.handler = (path, request) {
          if (path.contains('stock_lots')) {
            final req = request as http.Request;
            if (req.method == 'GET') {
              return FakeResponse([
                {'current_quantity': 30},
              ]);
            }
            return FakeResponse([
              {'id': 'lot1'},
            ]);
          }
          return FakeResponse(<dynamic>[]);
        };

        await const StockLotSupabaseDataSourceImpl().increaseQuantity(
          'lot1',
          12,
          storeId: 'st1',
        );
        // 2 requisições: leitura + update com 42.
        expect(stub.requests, hasLength(2));
        final updateReq = stub.requests.last;
        expect(jsonBodyOf(updateReq), {'current_quantity': 42});
      },
    );

    test('increaseQuantity em lote inexistente lança StateError', () async {
      await expectLater(
        const StockLotSupabaseDataSourceImpl().increaseQuantity(
          'lot-fantasma',
          1,
          storeId: 'st1',
        ),
        throwsStateError,
      );
    });
  });
}

Map<String, dynamic> row(String id, {required String entry, String? expiry}) =>
    {
      'id': id,
      'store_id': 'st1',
      'product_id': 'p1',
      'entry_date': entry,
      'expiry_date': expiry,
      'initial_quantity': 10,
      'current_quantity': 5,
      'cost_price': 500,
    };
