import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tareqo/data/datasources/remote/supabase_plan_request_data_source.dart';
import 'package:tareqo/domain/entities/plan_request.dart';

import '../../../helpers/supabase_test_harness.dart';

/// CONTRATO REST do datasource remoto de pedidos de plano: colunas
/// consultadas, guarda de status na decisão e mapeamento centavo/enum.
/// Roda sobre o stub HTTP do Supabase — nenhuma rede real.
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
    'id': 'pr1',
    'tenant_id': 'tn1',
    'current_plan_id': 'pl1',
    'requested_plan_id': 'pl2',
    'status': 'pending',
    'decided_at': null,
    'created_at': '2026-09-01T10:00:00Z',
  };

  group('PlanRequestSupabaseDataSourceImpl', () {
    const ds = PlanRequestSupabaseDataSourceImpl();

    test(
      'create grava tenant/planos/status pending e devolve a linha',
      () async {
        stub.handler = (path, request) {
          expect(path, contains('plan_requests'));
          final body = jsonBodyOf(request) as Map<String, dynamic>;
          expect(body['tenant_id'], 'tn1');
          expect(body['current_plan_id'], 'pl1');
          expect(body['requested_plan_id'], 'pl2');
          expect(body['status'], 'pending');
          expect((body['id'] as String), startsWith('pr'));
          return FakeResponse([row()]);
        };

        final created = await ds.create(
          tenantId: 'tn1',
          currentPlanId: 'pl1',
          requestedPlanId: 'pl2',
        );

        expect(created.id, 'pr1');
        expect(created.status, PlanRequestStatus.pending);
        expect(created.decidedAt, isNull);
      },
    );

    test('getByTenant filtra por tenant_id e ordena created_at desc', () async {
      stub.handler = (path, request) {
        expect(request.url.queryParameters['tenant_id'], 'eq.tn1');
        expect(
          request.url.queryParameters['order'],
          'created_at.desc.nullslast',
        );
        return FakeResponse([row()]);
      };

      final list = await ds.getByTenant('tn1');

      expect(list, hasLength(1));
      expect(list.single.tenantId, 'tn1');
    });

    test('getPending filtra status pending em ordem crescente', () async {
      stub.handler = (path, request) {
        expect(request.url.queryParameters['status'], 'eq.pending');
        expect(
          request.url.queryParameters['order'],
          'created_at.asc.nullslast',
        );
        return FakeResponse([row()]);
      };

      final pending = await ds.getPending();

      expect(pending.single.status, PlanRequestStatus.pending);
    });

    test('getById devolve null para id inexistente (maybeSingle)', () async {
      stub.handler = (path, request) => FakeResponse(<dynamic>[]);

      expect(await ds.getById('pr-missing'), isNull);
    });

    test('getById mapeia a linha existente', () async {
      stub.handler = (path, request) {
        expect(request.url.queryParameters['id'], 'eq.pr1');
        return FakeResponse(row());
      };

      final got = await ds.getById('pr1');

      expect(got!.currentPlanId, 'pl1');
      expect(got.requestedPlanId, 'pl2');
    });

    test('decide com approve grava status approved e decided_at', () async {
      stub.handler = (path, request) {
        expect(request.method, 'PATCH');
        final body = jsonBodyOf(request) as Map<String, dynamic>;
        expect(body['status'], 'approved');
        expect(body['decided_at'], isNotNull);
        return FakeResponse([
          {'id': 'pr1'},
        ]);
      };

      await ds.decide('pr1', approve: true);
    });

    test('decide com rejeição grava status rejected', () async {
      stub.handler = (path, request) {
        final body = jsonBodyOf(request) as Map<String, dynamic>;
        expect(body['status'], 'rejected');
        return FakeResponse([
          {'id': 'pr1'},
        ]);
      };

      await ds.decide('pr1', approve: false);
    });

    test(
      'decide lança StateError quando o pedido não existe (guarda)',
      () async {
        stub.handler = (path, request) => FakeResponse(<dynamic>[]);

        await expectLater(
          ds.decide('pr-missing', approve: true),
          throwsStateError,
        );
      },
    );

    test('decide lança PostgrestException em erro do servidor', () async {
      stub.handler = (path, request) =>
          FakeResponse({'message': 'row not found'}, status: 406);

      await expectLater(
        ds.decide('pr1', approve: true),
        throwsA(isA<PostgrestException>()),
      );
    });

    test('decide com falha de rede propaga a exceção ao chamador', () async {
      stub.failNext = 1;

      await expectLater(
        ds.decide('pr1', approve: true),
        throwsA(isA<http.ClientException>()),
      );
    });

    test('mapeia decided_at para horário local e status por nome', () async {
      stub.handler = (path, request) => FakeResponse([
        {...row(), 'status': 'approved', 'decided_at': '2026-09-02T12:00:00Z'},
      ]);

      final approved = (await ds.getByTenant('tn1')).single;

      expect(approved.status, PlanRequestStatus.approved);
      expect(
        approved.decidedAt,
        DateTime.parse('2026-09-02T12:00:00Z').toLocal(),
      );
    });

    test(
      'getByTenant devolve lista imutável (contrato somente-leitura)',
      () async {
        stub.handler = (path, request) => FakeResponse([row()]);

        final list = await ds.getByTenant('tn1');

        expect(() => list.add(_anyRequest()), throwsUnsupportedError);
      },
    );
  });
}

PlanRequest _anyRequest() => PlanRequest(
  id: 'prX',
  tenantId: 'tn1',
  currentPlanId: 'pl1',
  requestedPlanId: 'pl2',
  status: PlanRequestStatus.pending,
  createdAt: DateTime(2026, 9, 1),
);
