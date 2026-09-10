import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:tareqo/data/datasources/remote/supabase_cash_closing_data_source.dart';
import 'package:tareqo/domain/entities/cash_closing.dart';

import '../../../helpers/supabase_test_harness.dart';

/// Testes de CONTRATO REST do datasource remoto de fecho de caixa — as
/// LEITURAS por REST e o fallback de gravação (o registro real vai pela
/// RPC `close_cash_register`, já coberta pelo teste de RPC injetada).
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

  Map<String, dynamic> row() => {
    'id': 'cc-st1-20260810',
    'store_id': 'st1',
    'closing_date': '2026-08-10T00:00:00Z',
    'total_sales': 4050,
    'expected_cash': 1100,
    'counted_cash': 1100,
    'sales_by_method': {'cash': 1100, 'mPesa': 2950},
    'closed_at': '2026-08-10T19:00:00Z',
  };

  group('CashClosingSupabaseDataSourceImpl — leituras', () {
    const ds = CashClosingSupabaseDataSourceImpl();

    test(
      'getByDay normaliza o dia para o início do dia LOCAL em UTC',
      () async {
        stub.handler = (path, request) {
          if (path.contains('cash_closings')) {
            expect(
              request.url.queryParameters,
              containsPair('store_id', 'eq.st1'),
            );
            return FakeResponse([row()]);
          }
          return FakeResponse(<dynamic>[]);
        };

        final closing = await ds.getByDay(
          storeId: 'st1',
          day: DateTime(2026, 8, 10, 14, 30), // hora local irrelevante.
        );
        expect(closing, isNotNull);
        expect(closing!.id, 'cc-st1-20260810');
        expect(closing.totalSalesCents, 4050);
        expect(closing.salesByMethodCents, {'cash': 1100, 'mPesa': 2950});

        // O filtro de dia usa a MESMA normalização do datasource.
        final expectedDayUtc = DateTime(2026, 8, 10).toUtc().toIso8601String();
        expect(
          stub.requests.single.url.queryParameters,
          containsPair('closing_date', 'eq.$expectedDayUtc'),
        );
      },
    );

    test('getByDay sem fecho no dia devolve null', () async {
      final closing = await ds.getByDay(
        storeId: 'st1',
        day: DateTime(2026, 8, 11),
      );
      expect(closing, isNull);
    });

    test('getAll ordena por closing_date desc com escopo por loja', () async {
      stub.handler = (path, request) {
        if (path.contains('cash_closings')) {
          expect(
            request.url.queryParameters['order'],
            contains('closing_date.desc'),
          );
          expect(
            request.url.queryParameters,
            containsPair('store_id', 'eq.st1'),
          );
          return FakeResponse([row()]);
        }
        return FakeResponse(<dynamic>[]);
      };

      final closings = await ds.getAll(storeId: 'st1');
      expect(closings.single.countedCashCents, 1100);
    });

    test(
      'getAll aceita sales_by_method como String JSON (formato defensivo)',
      () async {
        stub.handler = (path, request) {
          if (path.contains('cash_closings')) {
            return FakeResponse([
              {...row(), 'sales_by_method': '{"cash": 1100, "mPesa": 2950}'},
            ]);
          }
          return FakeResponse(<dynamic>[]);
        };

        final closings = await ds.getAll(storeId: 'st1');
        expect(closings.single.salesByMethodCents, {
          'cash': 1100,
          'mPesa': 2950,
        });
      },
    );
  });

  group('CashClosingSupabaseDataSourceImpl.save — fallback REST', () {
    test('upsert grava sales_by_method como String JSON e user_id', () async {
      final bodies = <Map<String, dynamic>>[];
      stub.handler = (path, request) {
        if (path.contains('cash_closings')) {
          bodies.add(
            jsonDecode((request as http.Request).body) as Map<String, dynamic>,
          );
          return FakeResponse(<dynamic>[]);
        }
        return FakeResponse(<dynamic>[]);
      };

      await const CashClosingSupabaseDataSourceImpl().save(
        CashClosing(
          id: 'cc-st1-20260810',
          storeId: 'st1',
          day: DateTime(2026, 8, 10),
          totalSalesCents: 4050,
          expectedCashCents: 1100,
          countedCashCents: 1100,
          salesByMethodCents: const {'cash': 1100, 'mPesa': 2950},
          closedAt: DateTime.utc(2026, 8, 10, 19),
        ),
      );

      final req = stub.requests.single;
      expect(req.url.path, contains('cash_closings'));
      final body = bodies.single;
      expect(body['user_id'], 'u1');
      expect(body['total_sales'], 4050);
      expect(body['counted_cash'], 1100);
      // JSONB serializado como String (contrato do PostgREST).
      expect(body['sales_by_method'], '{"cash":1100,"mPesa":2950}');
      expect(
        body['closing_date'],
        DateTime(2026, 8, 10).toUtc().toIso8601String(),
      );
    });
  });
}
