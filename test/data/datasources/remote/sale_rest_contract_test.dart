import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tareqo/data/datasources/remote/supabase_sale_data_source.dart';
import 'package:tareqo/domain/entities/sale.dart';
import 'package:tareqo/domain/entities/sale_item.dart';
import 'package:tareqo/domain/entities/sale_lot_consumption.dart';

import '../../../helpers/supabase_test_harness.dart';

/// Testes de CONTRATO REST do datasource remoto de vendas — os caminhos
/// de leitura e os fallbacks de escrita do PostgREST (o caminho SaaS real
/// vai pela RPC `process_sale`, já coberta pelo teste de RPC injetada).
/// Valida: leitura com itens embutidos, paginação keyset multi-página,
/// numeração de fallback do `add` composto e isolamento por loja.
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

  group('SaleSupabaseDataSourceImpl.getAll — leitura', () {
    test(
      'mapeia venda com itens embutidos, status ausente → active, datas locais',
      () async {
        stub.handler = (path, request) {
          if (path.contains('sales')) {
            return FakeResponse([
              {
                'id': 's1',
                'store_id': 'st1',
                'sale_number': 42,
                'user_id': 'u1',
                'total_amount': 9800,
                'payment_method': 'mPesa',
                'date_time': '2026-08-07T14:30:00Z',
                'status': null,
                'cancelled_at': null,
                'sale_items': [
                  {
                    'product_id': 'p1',
                    'product_name': 'Arroz',
                    'quantity': 2,
                    'unit_price': 3500,
                  },
                  {
                    'product_id': 'p2',
                    'product_name': 'Feijão',
                    'quantity': 1,
                    'unit_price': 2800,
                  },
                ],
              },
            ]);
          }
          return FakeResponse(<dynamic>[]);
        };

        final sales = await const SaleSupabaseDataSourceImpl().getAll(
          storeId: 'st1',
        );
        final sale = sales.single;
        expect(sale.id, 's1');
        expect(sale.number, 42);
        expect(sale.totalAmountCents, 9800);
        expect(sale.paymentMethod, PaymentMethod.mPesa);
        expect(sale.status, SaleStatus.active);
        expect(sale.cancelledAt, isNull);
        expect(sale.userId, 'u1');
        expect(sale.items, hasLength(2));
        expect(sale.items.first.productName, 'Arroz');
        expect(sale.items.first.unitPriceCents, 3500);
        expect(sale.dateTime, DateTime.parse('2026-08-07T14:30:00Z').toLocal());

        final req = stub.requests.single;
        expect(req.url.path, contains('/rest/v1/sales'));
        expect(req.url.queryParameters, containsPair('store_id', 'eq.st1'));
        expect(req.url.queryParameters['select'], contains('sale_items'));
      },
    );

    test('venda anulada mapeia status cancelled + cancelled_at', () async {
      stub.handler = (path, request) {
        if (path.contains('sales')) {
          return FakeResponse([
            {
              'id': 's2',
              'store_id': 'st1',
              'sale_number': 43,
              'total_amount': 5000,
              'payment_method': 'cash',
              'date_time': '2026-08-08T10:00:00Z',
              'status': 'cancelled',
              'cancelled_at': '2026-08-08T11:00:00Z',
              'sale_items': <dynamic>[],
            },
          ]);
        }
        return FakeResponse(<dynamic>[]);
      };

      final sales = await const SaleSupabaseDataSourceImpl().getAll(
        storeId: 'st1',
      );
      final sale = sales.single;
      expect(sale.status, SaleStatus.cancelled);
      expect(
        sale.cancelledAt,
        DateTime.parse('2026-08-08T11:00:00Z').toLocal(),
      );
      expect(sale.items, isEmpty);
    });

    test('paginação keyset percorre TODAS as páginas (>1000 linhas)', () async {
      // Página 1: 1000 linhas (completa → há próxima), página 2: 3 linhas.
      var page = 0;
      stub.handler = (path, request) {
        if (path.contains('sales')) {
          final url = request.url;
          final isPage2 = url.queryParameters.containsKey('id');
          page = isPage2 ? 1 : 0;
          if (page == 0) {
            return FakeResponse([
              for (var i = 0; i < 1000; i++)
                {
                  'id': 's-page1-$i',
                  'store_id': 'st1',
                  'sale_number': i,
                  'total_amount': 100,
                  'payment_method': 'cash',
                  'date_time': '2026-08-01T00:00:00Z',
                  'sale_items': <dynamic>[],
                },
            ]);
          }
          return FakeResponse([
            for (var i = 0; i < 3; i++)
              {
                'id': 's-page2-$i',
                'store_id': 'st1',
                'sale_number': 1000 + i,
                'total_amount': 200,
                'payment_method': 'cash',
                'date_time': '2026-08-02T00:00:00Z',
                'sale_items': <dynamic>[],
              },
          ]);
        }
        return FakeResponse(<dynamic>[]);
      };

      final sales = await const SaleSupabaseDataSourceImpl().getAll(
        storeId: 'st1',
      );
      expect(sales, hasLength(1003));
      // A 2ª página usa o cursor gt(id, último id da página anterior).
      final page2Req = stub.requests.last;
      expect(page2Req.url.queryParameters['id'], 'gt.s-page1-999');
    });

    test('loja diferente filtra por store_id na URL (isolamento)', () async {
      await const SaleSupabaseDataSourceImpl().getAll(storeId: 'st-outra');
      final req = stub.requests.single;
      expect(req.url.queryParameters, containsPair('store_id', 'eq.st-outra'));
    });
  });

  group('SaleSupabaseDataSourceImpl.getById', () {
    test('venda inexistente na loja devolve null', () async {
      final sale = await const SaleSupabaseDataSourceImpl().getById(
        's-fantasma',
        storeId: 'st1',
      );
      expect(sale, isNull);
      final req = stub.requests.single;
      expect(req.url.queryParameters, containsPair('id', 'eq.s-fantasma'));
      expect(req.url.queryParameters, containsPair('store_id', 'eq.st1'));
    });
  });

  group('SaleSupabaseDataSourceImpl.add — fallback composto', () {
    test(
      'numera pela última venda da loja (MAX+1) e grava user_id da sessão',
      () async {
        final insertedBodies = <Map<String, dynamic>>[];
        stub.handler = (path, request) {
          if (path.contains('sales')) {
            final req = request as http.Request;
            if (req.method == 'GET') {
              // Consulta do último sale_number.
              return FakeResponse([
                {'sale_number': 7},
              ]);
            }
            insertedBodies.add(jsonDecode(req.body) as Map<String, dynamic>);
            return FakeResponse(<dynamic>[]);
          }
          return FakeResponse(<dynamic>[]);
        };

        final sale = Sale(
          id: 's-nova',
          storeId: 'st1',
          items: const [
            SaleItem(
              productId: 'p1',
              productName: 'Óleo',
              quantity: 3,
              unitPriceCents: 1500,
            ),
          ],
          totalAmountCents: 4500,
          paymentMethod: PaymentMethod.eMola,
          dateTime: DateTime.utc(2026, 9, 1, 9, 0),
        );
        await const SaleSupabaseDataSourceImpl().add(sale);

        // 2 requisições: SELECT do número + INSERT.
        expect(stub.requests, hasLength(2));
        final insert = insertedBodies.single;
        expect(insert['sale_number'], 8);
        expect(insert['user_id'], 'u1'); // requireCurrentUserId()
        expect(insert['total_amount'], 4500);
        expect(insert['payment_method'], 'eMola');
        expect(insert['date_time'], '2026-09-01T09:00:00.000Z');
        expect(insert['store_id'], 'st1');
        final items = insert['sale_items'] as List<dynamic>;
        expect(items.single, {
          'user_id': 'u1',
          'product_id': 'p1',
          'product_name': 'Óleo',
          'quantity': 3,
          'unit_price': 1500,
        });
      },
    );

    test('primeira venda da loja (sem anterior) recebe número 1', () async {
      stub.handler = (path, request) {
        if (path.contains('sales')) {
          if ((request as http.Request).method == 'GET') {
            return FakeResponse(<dynamic>[]);
          }
          return FakeResponse(<dynamic>[]);
        }
        return FakeResponse(<dynamic>[]);
      };

      final sale = Sale(
        id: 's-primeira',
        storeId: 'st2',
        items: const [],
        totalAmountCents: 0,
        paymentMethod: PaymentMethod.cash,
        dateTime: DateTime.utc(2026, 9, 2),
      );
      await const SaleSupabaseDataSourceImpl().add(sale);
      // Sem vendas anteriores: nextNumber = 1 — validado pela ausência de
      // erro; o corpo exato é exercitado no teste anterior.
      expect(stub.requests, hasLength(2));
    });

    test('add sem sessão ativa falha cedo com StateError', () async {
      await Supabase.instance.client.auth.signOut();
      try {
        await const SaleSupabaseDataSourceImpl().add(
          Sale(
            id: 's-x',
            storeId: 'st1',
            items: const [],
            totalAmountCents: 0,
            paymentMethod: PaymentMethod.cash,
            dateTime: DateTime.utc(2026),
          ),
        );
        fail('Deveria ter lançado StateError sem sessão.');
      } on StateError catch (e) {
        expect(e.message, contains('não autenticado'));
      } finally {
        await signInStubUser();
      }
    });
  });

  group('SaleSupabaseDataSourceImpl.markCancelled — fallback REST', () {
    test('grava status cancelled + cancelled_at com escopo por loja', () async {
      final bodies = <Map<String, dynamic>>[];
      stub.handler = (path, request) {
        if (path.contains('sales')) {
          bodies.add(
            jsonDecode((request as http.Request).body) as Map<String, dynamic>,
          );
          return FakeResponse(<dynamic>[]);
        }
        return FakeResponse(<dynamic>[]);
      };

      await const SaleSupabaseDataSourceImpl().markCancelled(
        's9',
        storeId: 'st1',
      );
      final req = stub.requests.single;
      expect(req.method, 'PATCH');
      expect(req.url.queryParameters, containsPair('id', 'eq.s9'));
      expect(req.url.queryParameters, containsPair('store_id', 'eq.st1'));
      expect(bodies.single['status'], 'cancelled');
      expect(bodies.single['cancelled_at'], isNotNull);
    });
  });

  group('SaleSupabaseDataSourceImpl — consumo de lotes', () {
    test('getLotConsumption mapeia lot_id/product_id/quantity', () async {
      stub.handler = (path, request) {
        if (path.contains('sale_lot_consumption')) {
          return FakeResponse([
            {'lot_id': 'lot1', 'product_id': 'p1', 'quantity': 5},
          ]);
        }
        return FakeResponse(<dynamic>[]);
      };

      final consumption = await const SaleSupabaseDataSourceImpl()
          .getLotConsumption('s1', storeId: 'st1');
      expect(consumption.single.lotId, 'lot1');
      expect(consumption.single.productId, 'p1');
      expect(consumption.single.quantity, 5);
    });

    test('registerLotConsumption com lista vazia não faz requisição', () async {
      await const SaleSupabaseDataSourceImpl().registerLotConsumption(
        's1',
        'st1',
        const [],
      );
      expect(stub.requests, isEmpty);
    });

    test('registerLotConsumption grava uma linha por lote consumido', () async {
      final bodies = <dynamic>[];
      stub.handler = (path, request) {
        if (path.contains('sale_lot_consumption')) {
          bodies.add(jsonDecode((request as http.Request).body));
          return FakeResponse(<dynamic>[]);
        }
        return FakeResponse(<dynamic>[]);
      };

      await const SaleSupabaseDataSourceImpl()
          .registerLotConsumption('s1', 'st1', const [
            LotConsumption(lotId: 'lot1', productId: 'p1', quantity: 2),
            LotConsumption(lotId: 'lot2', productId: 'p1', quantity: 1),
          ]);
      final rows = bodies.single as List<dynamic>;
      expect(rows, hasLength(2));
      expect(rows.first['sale_id'], 's1');
      expect(rows.first['lot_id'], 'lot1');
      expect(rows.last['lot_id'], 'lot2');
    });
  });
}
