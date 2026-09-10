import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:tareqo/data/datasources/remote/supabase_plan_data_source.dart';
import 'package:tareqo/data/datasources/remote/supabase_plan_request_data_source.dart';
import 'package:tareqo/data/datasources/remote/supabase_admin_message_data_source.dart';
import 'package:tareqo/data/datasources/remote/supabase_addon_data_source.dart';
import 'package:tareqo/data/datasources/remote/supabase_audit_log_data_source.dart';
import 'package:tareqo/domain/entities/plan.dart';
import 'package:tareqo/domain/entities/plan_request.dart';
import 'package:tareqo/domain/entities/admin_message.dart';

import '../../../helpers/supabase_test_harness.dart';

/// Testes de CONTRATO REST dos datasources remotos administrativos:
/// planos, pedidos de upgrade, mensagens do admin e add-ons de tenant
/// (com filtragem de expirados e upsert idempotente).
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

  group('PlanSupabaseDataSourceImpl', () {
    const ds = PlanSupabaseDataSourceImpl();

    test('getActivePlans filtra is_active e mapeia plano completo', () async {
      stub.handler = (path, request) {
        if (path.contains('plans')) {
          expect(
            request.url.queryParameters,
            containsPair('is_active', 'eq.true'),
          );
          return FakeResponse([
            {
              'id': 'pl_starter',
              'name': 'Starter',
              'description': 'Plano inicial',
              'price_monthly': 150000,
              'max_stores': 1,
              'max_employees': 3,
              'is_active': true,
            },
          ]);
        }
        return FakeResponse(<dynamic>[]);
      };

      final plans = await ds.getActivePlans();
      final plan = plans.single;
      expect(plan.id, 'pl_starter');
      expect(plan.priceMonthlyCents, 150000);
      expect(plan.maxStores, 1);
      expect(plan.maxEmployees, 3);
      expect(plan.isActive, isTrue);
    });

    test('getById inexistente devolve null', () async {
      final plan = await ds.getById('pl-fantasma');
      expect(plan, isNull);
    });

    test('add grava preço em centavos e flags', () async {
      final bodies = <Map<String, dynamic>>[];
      stub.handler = (path, request) {
        if (path.contains('plans')) {
          bodies.add(
            jsonDecode((request as http.Request).body) as Map<String, dynamic>,
          );
          return FakeResponse(<dynamic>[]);
        }
        return FakeResponse(<dynamic>[]);
      };

      await ds.add(
        const Plan(
          id: 'pl_pro',
          name: 'Pro',
          description: 'Plano profissional',
          priceMonthlyCents: 450000,
          maxStores: 5,
          maxEmployees: 20,
        ),
      );
      expect(bodies.single, {
        'id': 'pl_pro',
        'name': 'Pro',
        'description': 'Plano profissional',
        'price_monthly': 450000,
        'max_stores': 5,
        'max_employees': 20,
        'is_active': true,
      });
    });

    test('update em plano inexistente (0 linhas) lança StateError', () async {
      await expectLater(
        ds.update(
          const Plan(id: 'pl-fantasma', name: 'X', priceMonthlyCents: 1),
        ),
        throwsStateError,
      );
    });
  });

  group('PlanRequestSupabaseDataSourceImpl', () {
    const ds = PlanRequestSupabaseDataSourceImpl();

    test('create grava status pending e devolve o pedido mapeado', () async {
      stub.handler = (path, request) {
        if (path.contains('plan_requests')) {
          final body =
              jsonDecode((request as http.Request).body)
                  as Map<String, dynamic>;
          return FakeResponse([
            {
              'id': body['id'],
              'tenant_id': body['tenant_id'],
              'current_plan_id': body['current_plan_id'],
              'requested_plan_id': body['requested_plan_id'],
              'status': body['status'],
              'decided_at': null,
              'created_at': '2026-09-01T00:00:00Z',
            },
          ]);
        }
        return FakeResponse(<dynamic>[]);
      };

      final request = await ds.create(
        tenantId: 'tn1',
        currentPlanId: 'pl_starter',
        requestedPlanId: 'pl_pro',
      );
      expect(request.id, startsWith('pr'));
      expect(request.status, PlanRequestStatus.pending);
      expect(request.requestedPlanId, 'pl_pro');
    });

    test('decide(approve: true) grava approved + decided_at', () async {
      final bodies = <Map<String, dynamic>>[];
      stub.handler = (path, request) {
        if (path.contains('plan_requests')) {
          bodies.add(
            jsonDecode((request as http.Request).body) as Map<String, dynamic>,
          );
          return FakeResponse([
            {'id': 'pr1'},
          ]);
        }
        return FakeResponse(<dynamic>[]);
      };

      await ds.decide('pr1', approve: true);
      final body = bodies.single;
      expect(body['status'], 'approved');
      expect(body['decided_at'], isNotNull);
    });

    test('decide(approve: false) grava rejected', () async {
      final bodies = <Map<String, dynamic>>[];
      stub.handler = (path, request) {
        if (path.contains('plan_requests')) {
          bodies.add(
            jsonDecode((request as http.Request).body) as Map<String, dynamic>,
          );
          return FakeResponse([
            {'id': 'pr2'},
          ]);
        }
        return FakeResponse(<dynamic>[]);
      };

      await ds.decide('pr2', approve: false);
      expect(bodies.single['status'], 'rejected');
    });

    test('decide em pedido inexistente lança StateError', () async {
      await expectLater(
        ds.decide('pr-fantasma', approve: true),
        throwsStateError,
      );
    });
  });

  group('AdminMessageSupabaseDataSourceImpl', () {
    const ds = AdminMessageSupabaseDataSourceImpl();

    test('create grava type pelo nome e devolve mensagem mapeada', () async {
      stub.handler = (path, request) {
        if (path.contains('admin_messages')) {
          final body =
              jsonDecode((request as http.Request).body)
                  as Map<String, dynamic>;
          return FakeResponse([
            {
              'id': body['id'],
              'tenant_id': body['tenant_id'],
              'type': body['type'],
              'title': body['title'],
              'body': body['body'],
              'is_read': false,
              'created_at': '2026-09-01T00:00:00Z',
              'read_at': null,
            },
          ]);
        }
        return FakeResponse(<dynamic>[]);
      };

      final message = await ds.create(
        AdminMessage(
          id: 'am1',
          tenantId: 'tn1',
          type: AdminMessageType.billingQuote,
          title: 'Proposta',
          body: 'Upgrade para Pro por 450.000 MZN/mês',
          createdAt: DateTime.utc(2026, 9, 1),
        ),
      );
      expect(message.type, AdminMessageType.billingQuote);
      expect(message.isRead, isFalse);
      expect(message.readAt, isNull);
    });

    test('getUnreadCount conta apenas não lidas do tenant', () async {
      stub.handler = (path, request) {
        if (path.contains('admin_messages')) {
          expect(
            request.url.queryParameters,
            containsPair('is_read', 'eq.false'),
          );
          return FakeResponse([
            {'id': 'am1'},
            {'id': 'am2'},
          ]);
        }
        return FakeResponse(<dynamic>[]);
      };

      expect(await ds.getUnreadCount('tn1'), 2);
    });

    test('markAsRead em mensagem inexistente lança StateError', () async {
      await expectLater(ds.markAsRead('am-fantasma'), throwsStateError);
    });

    test('markAllAsRead não exige retorno de linhas (bulk update)', () async {
      await ds.markAllAsRead('tn1');
      final req = stub.requests.single;
      expect(req.method, 'PATCH');
      expect(req.url.queryParameters, containsPair('tenant_id', 'eq.tn1'));
      expect(req.url.queryParameters, containsPair('is_read', 'eq.false'));
    });
  });

  group('SupabaseAddOnDataSourceImpl', () {
    const ds = SupabaseAddOnDataSourceImpl();

    test(
      'getActiveAddOnIds exclui add-ons expirados e mantém sem validade',
      () async {
        final now = DateTime.now().toUtc();
        stub.handler = (path, request) {
          if (path.contains('tenant_addons')) {
            return FakeResponse([
              {
                'id': 'ta1',
                'tenant_id': 'tn1',
                'add_on_id': 'ao_ativo',
                'activated_at': '2026-01-01T00:00:00Z',
                'expires_at': null,
                'is_active': true,
              },
              {
                'id': 'ta2',
                'tenant_id': 'tn1',
                'add_on_id': 'ao_valido',
                'activated_at': '2026-01-01T00:00:00Z',
                'expires_at': now
                    .add(const Duration(days: 30))
                    .toIso8601String(),
                'is_active': true,
              },
              {
                'id': 'ta3',
                'tenant_id': 'tn1',
                'add_on_id': 'ao_expirado',
                'activated_at': '2026-01-01T00:00:00Z',
                'expires_at': now
                    .subtract(const Duration(days: 1))
                    .toIso8601String(),
                'is_active': true,
              },
            ]);
          }
          return FakeResponse(<dynamic>[]);
        };

        final ids = await ds.getActiveAddOnIds('tn1');
        expect(ids, {'ao_ativo', 'ao_valido'});
        expect(ids.contains('ao_expirado'), isFalse);
      },
    );

    test('activate limpa expires_at antigo no upsert (re-ativação)', () async {
      final bodies = <Map<String, dynamic>>[];
      stub.handler = (path, request) {
        if (path.contains('tenant_addons')) {
          bodies.add(
            jsonDecode((request as http.Request).body) as Map<String, dynamic>,
          );
          return FakeResponse(<dynamic>[]);
        }
        return FakeResponse(<dynamic>[]);
      };

      await ds.activate('tn1', 'ao_advanced_reports');
      final body = bodies.single;
      expect(body['is_active'], isTrue);
      expect(body.containsKey('expires_at'), isTrue);
      expect(body['expires_at'], isNull);
      // Upsert pela chave composta.
      final req = stub.requests.single;
      expect(
        req.url.queryParameters,
        containsPair('on_conflict', 'tenant_id,add_on_id'),
      );
    });

    test('register grava a validade informada (renovação)', () async {
      final bodies = <Map<String, dynamic>>[];
      stub.handler = (path, request) {
        if (path.contains('tenant_addons')) {
          bodies.add(
            jsonDecode((request as http.Request).body) as Map<String, dynamic>,
          );
          return FakeResponse(<dynamic>[]);
        }
        return FakeResponse(<dynamic>[]);
      };

      final expires = DateTime.utc(2027, 6, 30);
      await ds.register(
        tenantId: 'tn1',
        addOnId: 'ao_advanced_reports',
        expiresAt: expires,
      );
      expect(bodies.single['expires_at'], '2027-06-30T00:00:00.000Z');
    });

    test('isActive devolve false para linha inativa', () async {
      stub.handler = (path, request) {
        if (path.contains('tenant_addons')) {
          return FakeResponse([
            {
              'id': 'ta1',
              'tenant_id': 'tn1',
              'add_on_id': 'ao_x',
              'activated_at': '2026-01-01T00:00:00Z',
              'expires_at': null,
              'is_active': false,
            },
          ]);
        }
        return FakeResponse(<dynamic>[]);
      };

      expect(await ds.isActive('tn1', 'ao_x'), isFalse);
    });

    test('isActive devolve true para linha ativa sem validade', () async {
      stub.handler = (path, request) {
        if (path.contains('tenant_addons')) {
          return FakeResponse([
            {
              'id': 'ta1',
              'tenant_id': 'tn1',
              'add_on_id': 'ao_x',
              'activated_at': '2026-01-01T00:00:00Z',
              'expires_at': null,
              'is_active': true,
            },
          ]);
        }
        return FakeResponse(<dynamic>[]);
      };

      expect(await ds.isActive('tn1', 'ao_x'), isTrue);
    });

    test('isActive devolve false quando expirou', () async {
      final past = DateTime.now().subtract(const Duration(days: 2));
      stub.handler = (path, request) {
        if (path.contains('tenant_addons')) {
          return FakeResponse([
            {
              'id': 'ta1',
              'tenant_id': 'tn1',
              'add_on_id': 'ao_x',
              'activated_at': '2026-01-01T00:00:00Z',
              'expires_at': past.toIso8601String(),
              'is_active': true,
            },
          ]);
        }
        return FakeResponse(<dynamic>[]);
      };

      expect(await ds.isActive('tn1', 'ao_x'), isFalse);
    });

    test('isActive devolve false para add-on nunca registrado', () async {
      // Resposta padrão [] → maybeSingle devolve null.
      expect(await ds.isActive('tn1', 'ao-desconhecido'), isFalse);
    });

    test('deactivateExpired devolve o número de linhas desativadas', () async {
      stub.handler = (path, request) {
        if (path.contains('tenant_addons')) {
          return FakeResponse([
            {'id': 'ta3'},
            {'id': 'ta4'},
          ]);
        }
        return FakeResponse(<dynamic>[]);
      };

      expect(await ds.deactivateExpired(), 2);
      final req = stub.requests.single;
      // O carimbo "agora" é gerado dentro do datasource — validamos o
      // formato e a presença do filtro (o instante exato é race-prone).
      expect(req.url.queryParameters['expires_at'], startsWith('lt.'));
      expect(req.url.queryParameters, containsPair('is_active', 'eq.true'));
    });

    test('getExpired lista apenas ativos com validade no passado', () async {
      final past = DateTime.now().toUtc().subtract(const Duration(days: 5));
      stub.handler = (path, request) {
        if (path.contains('tenant_addons')) {
          return FakeResponse([
            {
              'id': 'ta9',
              'tenant_id': 'tn1',
              'add_on_id': 'ao_old',
              'activated_at': '2026-01-01T00:00:00Z',
              'expires_at': past.toIso8601String(),
              'is_active': true,
            },
          ]);
        }
        return FakeResponse(<dynamic>[]);
      };

      final expired = await ds.getExpired();
      expect(expired.single.addOnId, 'ao_old');
      expect(expired.single.isActive, isTrue);
    });
  });

  group('SupabaseAuditLogDataSourceImpl', () {
    test(
      'getAuditLog chama a RPC get_audit_log com limit clamped [1, 1000]',
      () async {
        final bodies = <Map<String, dynamic>>[];
        stub.handler = (path, request) {
          if (path.contains('rpc/get_audit_log')) {
            bodies.add(
              jsonDecode((request as http.Request).body)
                  as Map<String, dynamic>,
            );
            return FakeResponse([
              {
                'id': 7,
                'actor_user_id': 'admin-uuid',
                'action': 'tenant_approved',
                'entity_type': 'tenant',
                'entity_id': 'tn1',
                'detail': {'status': 'approved'},
                'created_at': '2026-08-16T12:00:00Z',
              },
            ]);
          }
          return FakeResponse(<dynamic>[]);
        };

        final entries = await const SupabaseAuditLogDataSourceImpl()
            .getAuditLog(limit: 100);
        expect(bodies.single['p_limit'], 100);
        final entry = entries.single;
        expect(entry.id, 7);
        expect(entry.action, 'tenant_approved');
        expect(entry.detail, {'status': 'approved'});
      },
    );

    test('limit acima do teto é clamped para pageSize', () async {
      final bodies = <Map<String, dynamic>>[];
      stub.handler = (path, request) {
        if (path.contains('rpc/get_audit_log')) {
          bodies.add(
            jsonDecode((request as http.Request).body) as Map<String, dynamic>,
          );
          return FakeResponse(<dynamic>[]);
        }
        return FakeResponse(<dynamic>[]);
      };

      await const SupabaseAuditLogDataSourceImpl().getAuditLog(limit: 999999);
      expect(bodies.single['p_limit'], 1000);
    });

    test('limit abaixo de 1 é clamped para 1', () async {
      final bodies = <Map<String, dynamic>>[];
      stub.handler = (path, request) {
        if (path.contains('rpc/get_audit_log')) {
          bodies.add(
            jsonDecode((request as http.Request).body) as Map<String, dynamic>,
          );
          return FakeResponse(<dynamic>[]);
        }
        return FakeResponse(<dynamic>[]);
      };

      await const SupabaseAuditLogDataSourceImpl().getAuditLog(limit: 0);
      expect(bodies.single['p_limit'], 1);
    });
  });
}
