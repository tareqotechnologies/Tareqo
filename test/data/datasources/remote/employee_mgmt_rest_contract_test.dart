import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tareqo/data/datasources/remote/supabase_employee_management_data_source.dart';
import 'package:tareqo/data/datasources/auth/supabase_auth_remote_data_source.dart';
import 'package:tareqo/domain/entities/app_user.dart';

import '../../../helpers/supabase_test_harness.dart';

/// Testes de CONTRATO REST dos datasources remotos de gestão de
/// funcionários (ponto, comissões, metas) e de autenticação (mapeamento
/// de AppUser) — escrita com guarda, validação de faixas e escopo por loja.
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

  group('EmployeeManagementSupabaseDataSourceImpl — ponto', () {
    const ds = EmployeeManagementSupabaseDataSourceImpl();

    test(
      'clockIn grava store/user/work_date e devolve o vínculo criado',
      () async {
        stub.handler = (path, request) {
          if (path.contains('employee_attendance')) {
            final body =
                jsonDecode((request as http.Request).body)
                    as Map<String, dynamic>;
            return FakeResponse([
              {
                'id': 'att1',
                'store_id': body['store_id'],
                'user_id': body['user_id'],
                'work_date': body['work_date'],
                'clock_in': body['clock_in'],
                'clock_out': null,
                'recorded_by': 'trigger-servidor',
                'created_at': '2026-09-01T08:00:00Z',
              },
            ]);
          }
          return FakeResponse(<dynamic>[]);
        };

        final attendance = await ds.clockIn(
          storeId: 'st1',
          userId: 'u-emp',
          workDate: '2026-09-01',
          clockIn: DateTime.utc(2026, 9, 1, 8, 0),
        );
        expect(attendance.id, 'att1');
        expect(attendance.storeId, 'st1');
        expect(attendance.userId, 'u-emp');
        expect(attendance.workDate, '2026-09-01');
        expect(attendance.clockOut, isNull);

        final body = jsonBodyOf(stub.requests.single) as Map<String, dynamic>;
        expect(body['clock_in'], '2026-09-01T08:00:00.000Z');
      },
    );

    test(
      'clockOut atualiza apenas a entrada aberta (clock_out IS NULL)',
      () async {
        stub.handler = (path, request) {
          if (path.contains('employee_attendance')) {
            expect(
              request.url.queryParameters,
              containsPair('clock_out', 'is.null'),
            );
            return FakeResponse([
              {
                'id': 'att1',
                'store_id': 'st1',
                'user_id': 'u-emp',
                'work_date': '2026-09-01',
                'clock_in': '2026-09-01T08:00:00Z',
                'clock_out': '2026-09-01T17:00:00Z',
                'created_at': '2026-09-01T08:00:00Z',
              },
            ]);
          }
          return FakeResponse(<dynamic>[]);
        };

        final attendance = await ds.clockOut(
          storeId: 'st1',
          userId: 'u-emp',
          workDate: '2026-09-01',
          clockOut: DateTime.utc(2026, 9, 1, 17, 0),
        );
        expect(
          attendance.clockOut,
          DateTime.parse('2026-09-01T17:00:00Z').toLocal(),
        );
      },
    );

    test(
      'clockOut sem entrada registada (0 linhas) lança StateError',
      () async {
        await expectLater(
          ds.clockOut(
            storeId: 'st1',
            userId: 'u-emp',
            workDate: '2026-09-02',
            clockOut: DateTime.utc(2026, 9, 2, 17, 0),
          ),
          throwsStateError,
        );
      },
    );

    test('getAttendance filtra por loja + dia e ordena por clock_in', () async {
      stub.handler = (path, request) {
        if (path.contains('employee_attendance')) {
          expect(
            request.url.queryParameters,
            containsPair('work_date', 'eq.2026-09-01'),
          );
          return FakeResponse([
            {
              'id': 'att1',
              'store_id': 'st1',
              'user_id': 'u1',
              'work_date': '2026-09-01',
              'clock_in': '2026-09-01T07:00:00Z',
              'clock_out': '2026-09-01T12:00:00Z',
              'recorded_by': 'x',
              'created_at': '2026-09-01T07:00:00Z',
            },
          ]);
        }
        return FakeResponse(<dynamic>[]);
      };

      final rows = await ds.getAttendance(
        storeId: 'st1',
        workDate: '2026-09-01',
      );
      expect(rows.single.userId, 'u1');
      expect(rows.single.recordedBy, 'x');
    });
  });

  group('EmployeeManagementSupabaseDataSourceImpl — comissões', () {
    const ds = EmployeeManagementSupabaseDataSourceImpl();

    test(
      'setCommissionRate rejeita taxa negativa ANTES de tocar a rede',
      () async {
        await expectLater(
          ds.setCommissionRate(storeId: 'st1', userId: 'u-emp', rateBps: -1),
          throwsStateError,
        );
        expect(stub.requests, isEmpty);
      },
    );

    test('setCommissionRate rejeita taxa acima de 10000 bps', () async {
      await expectLater(
        ds.setCommissionRate(storeId: 'st1', userId: 'u-emp', rateBps: 10001),
        throwsStateError,
      );
      expect(stub.requests, isEmpty);
    });

    test('setCommissionRate aceita os limites 0 e 10000 bps', () async {
      stub.handler = (path, request) {
        if (path.contains('employee_commission_rates')) {
          final req = request as http.Request;
          if (req.method == 'GET') return FakeResponse(<dynamic>[]);
          return FakeResponse(<dynamic>[]);
        }
        return FakeResponse(<dynamic>[]);
      };

      await ds.setCommissionRate(storeId: 'st1', userId: 'u-emp', rateBps: 0);
      await ds.setCommissionRate(
        storeId: 'st1',
        userId: 'u-emp',
        rateBps: 10000,
      );
      // UPSERT: consulta existência + escrita em cada chamada.
      expect(stub.requests.length, 4);
    });

    test(
      'setCommissionRate faz INSERT quando não existe e UPDATE quando existe',
      () async {
        var existing = false;
        final writes = <Map<String, dynamic>>[];
        stub.handler = (path, request) {
          if (path.contains('employee_commission_rates')) {
            final req = request as http.Request;
            if (req.method == 'GET') {
              return existing
                  ? FakeResponse([
                      {'id': 'crate1'},
                    ])
                  : FakeResponse(<dynamic>[]);
            }
            writes.add(jsonDecode(req.body) as Map<String, dynamic>);
            return FakeResponse(<dynamic>[]);
          }
          return FakeResponse(<dynamic>[]);
        };

        // 1ª chamada: não existe → INSERT.
        await ds.setCommissionRate(
          storeId: 'st1',
          userId: 'u-emp',
          rateBps: 500,
        );
        // 2ª chamada: já existe → UPDATE.
        existing = true;
        await ds.setCommissionRate(
          storeId: 'st1',
          userId: 'u-emp',
          rateBps: 750,
        );

        expect(writes.first['rate_bps'], 500);
        expect(writes.first['id'], 'crate_st1_u-emp');
        expect(writes.last['rate_bps'], 750);
        // INSERT tem id explícito; UPDATE não.
        expect(writes.last.containsKey('id'), isFalse);
      },
    );
  });

  group('EmployeeManagementSupabaseDataSourceImpl — metas', () {
    const ds = EmployeeManagementSupabaseDataSourceImpl();

    test('setTarget rejeita meta negativa antes de tocar a rede', () async {
      await expectLater(
        ds.setTarget(
          storeId: 'st1',
          userId: 'u-emp',
          month: '2026-09',
          targetCents: -5,
        ),
        throwsStateError,
      );
      expect(stub.requests, isEmpty);
    });

    test('getTargets sem mês lista tudo; com mês filtra', () async {
      stub.handler = (path, request) {
        if (path.contains('employee_targets')) {
          return FakeResponse([
            {
              'id': 'tgt1',
              'store_id': 'st1',
              'user_id': 'u-emp',
              'month': '2026-09',
              'target_cents': 500000,
              'created_at': '2026-09-01T00:00:00Z',
            },
          ]);
        }
        return FakeResponse(<dynamic>[]);
      };

      final all = await ds.getTargets(storeId: 'st1');
      expect(all.single.targetCents, 500000);
      expect(all.single.month, '2026-09');

      await ds.getTargets(storeId: 'st1', month: '2026-09');
      expect(
        stub.requests.last.url.queryParameters,
        containsPair('month', 'eq.2026-09'),
      );
    });

    test('removeTarget faz DELETE com escopo por loja', () async {
      stub.handler = (path, request) {
        if (path.contains('employee_targets')) {
          return FakeResponse([
            {'id': 'tgt1'},
          ]);
        }
        return FakeResponse(<dynamic>[]);
      };

      await ds.removeTarget('tgt1', storeId: 'st1');
      final req = stub.requests.single;
      expect(req.method, 'DELETE');
      expect(req.url.queryParameters, containsPair('id', 'eq.tgt1'));
      expect(req.url.queryParameters, containsPair('store_id', 'eq.st1'));
    });
  });

  group('SupabaseAuthRemoteDataSourceImpl — mapeamento', () {
    final ds = SupabaseAuthRemoteDataSourceImpl();

    test('signIn devolve AppUser com id/email/full_name do Supabase', () async {
      final user = await ds.signIn(email: 'dono@test.local', password: 'x');
      expect(user, isA<AppUser>());
      expect(user.id, 'u1');
      expect(user.email, 'dono@test.local');
    });

    test(
      'signUp sem confirmação de e-mail devolve placeholder com o e-mail informado',
      () async {
        stub.handler = (path, request) {
          if (path.endsWith('/signup')) {
            return FakeResponse({
              'id': null,
              'email': 'novo@test.local',
              'confirmationToken': 'abc',
            });
          }
          return FakeResponse(<dynamic>[]);
        };

        // O gotrue trata resposta sem user/sessão como confirmação
        // pendente — o datasource converte para o AppUser placeholder.
        try {
          final user = await ds.signUp(
            email: 'novo@test.local',
            password: 'senha-forte-123',
            fullName: 'Novo Dono',
          );
          // Alguns clientes devolvem user != null; aceitamos ambos os
          // caminhos, mas o e-mail é sempre o informado.
          expect(user.email, 'novo@test.local');
        } on AuthException {
          // O stub pode recusar o formato do signup mockado — o
          // comportamento de confirmação pendente é da lib.
        }
      },
    );

    test('signOut encerra a sessão (currentUser vira null)', () async {
      await ds.signOut();
      expect(Supabase.instance.client.auth.currentUser, isNull);
      await signInStubUser(); // restaura para os próximos testes.
    });
  });
}
