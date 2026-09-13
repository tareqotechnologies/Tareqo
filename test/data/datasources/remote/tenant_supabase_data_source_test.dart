import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tareqo/data/datasources/remote/supabase_tenant_data_source.dart';
import 'package:tareqo/domain/entities/tenant.dart';
import 'package:tareqo/domain/usecases/request_tenant_access_use_case.dart';

import '../../../helpers/supabase_test_harness.dart';

/// Testes de CONTRATO REST do datasource remoto de tenants — valida a
/// consulta do dono, a resolução via vínculo de funcionário, o mapeamento
/// completo de colunas (incluindo defaults para bancos antigos), as
/// escritas com guarda de linhas afetadas e a conversão do erro de
/// unicidade (23505) em mensagem amigável — tudo sobre HTTP stubado.
void main() {
  late StubSupabaseHttp stub;
  const ds = TenantSupabaseDataSourceImpl();

  setUpAll(() async {
    stub = await initStubbedSupabase();
  });

  setUp(() {
    stub.handler = null;
    stub.requests.clear();
    stub.failNext = null;
  });

  group('TenantSupabaseDataSourceImpl.getMyTenant', () {
    test(
      'consulta o dono pela coluna owner_user_id e resolve via store_employees',
      () async {
        // Resposta padrão: sem tenant e sem vínculo → null, mas AMBAS as
        // consultas acontecem (dono → funcionário).
        final tenant = await ds.getMyTenant('u1');
        expect(tenant, isNull);
        expect(stub.requests, hasLength(2));
        expect(stub.requests.first.url.path, contains('/rest/v1/tenants'));
        expect(
          stub.requests.first.url.queryParameters,
          containsPair('owner_user_id', 'eq.u1'),
        );
        expect(
          stub.requests.last.url.path,
          contains('/rest/v1/store_employees'),
        );
        expect(
          stub.requests.last.url.queryParameters,
          containsPair('user_id', 'eq.u1'),
        );
      },
    );

    test(
      'funcionário sem tenant próprio resolve o tenant pelo vínculo na loja',
      () async {
        stub.handler = (path, request) {
          if (path.contains('store_employees')) {
            return FakeResponse([
              {'tenant_id': 'tn9'},
            ]);
          }
          if (path.contains('tenants')) {
            // 1ª consulta (owner) → vazia; 2ª (id do vínculo) → linha.
            if (request.url.queryParameters.containsKey('owner_user_id')) {
              return FakeResponse(<dynamic>[]);
            }
            return FakeResponse([
              {
                'id': 'tn9',
                'owner_user_id': 'u-dono',
                'business_name': 'Loja Via Vínculo',
                'plan_id': 'pl_pro',
                'status': 'approved',
                'currency_code': 'USD',
                'language': 'en',
                'created_at': '2026-02-01T00:00:00Z',
              },
            ]);
          }
          return FakeResponse(<dynamic>[]);
        };

        final tenant = await ds.getMyTenant('u-emp');
        expect(tenant, isNotNull);
        expect(tenant!.id, 'tn9');
        expect(tenant.businessName, 'Loja Via Vínculo');
        expect(tenant.status, TenantStatus.approved);
        expect(tenant.currencyCode, 'USD');
        expect(tenant.language, 'en');
        // 3 consultas: tenants(owner) → store_employees → tenants(id).
        expect(stub.requests, hasLength(3));
      },
    );

    test(
      'vínculo de funcionário sem tenant correspondente devolve null',
      () async {
        stub.handler = (path, request) {
          if (path.contains('store_employees')) {
            return FakeResponse([
              {'tenant_id': 'tn-órfão'},
            ]);
          }
          return FakeResponse(<dynamic>[]);
        };

        final tenant = await ds.getMyTenant('u-emp');
        expect(tenant, isNull);
      },
    );
  });

  group('TenantSupabaseDataSourceImpl — mapeamento completo', () {
    test(
      'mapeia todas as colunas incluindo billing, datas em UTC → local',
      () async {
        stub.handler = (path, request) {
          if (path.contains('tenants')) {
            return FakeResponse([
              {
                'id': 'tn7',
                'owner_user_id': 'u-dono',
                'business_name': 'Mercearia Teste',
                'plan_id': 'pl_starter',
                'status': 'pending',
                'rejection_reason': 'documentos ilegíveis',
                'approved_at': null,
                'created_at': '2026-01-15T08:30:00Z',
                'currency_code': 'MZN',
                'language': 'pt',
                'plan_expires_at': '2026-12-31T23:59:59Z',
                'next_invoice_at': '2026-10-01T00:00:00Z',
              },
            ]);
          }
          return FakeResponse(<dynamic>[]);
        };

        final pending = await ds.getPending();
        final tenant = pending.single;
        expect(tenant.id, 'tn7');
        expect(tenant.ownerUserId, 'u-dono');
        expect(tenant.businessName, 'Mercearia Teste');
        expect(tenant.planId, 'pl_starter');
        expect(tenant.status, TenantStatus.pending);
        expect(tenant.rejectionReason, 'documentos ilegíveis');
        expect(tenant.approvedAt, isNull);
        // O datasource converte para o fuso local; comparação independente
        // de fuso (o instante UTC é o mesmo).
        expect(
          tenant.createdAt,
          DateTime.parse('2026-01-15T08:30:00Z').toLocal(),
        );
        expect(tenant.currencyCode, 'MZN');
        expect(tenant.language, 'pt');
        expect(
          tenant.planExpiresAt,
          DateTime.parse('2026-12-31T23:59:59Z').toLocal(),
        );
        expect(
          tenant.nextInvoiceAt,
          DateTime.parse('2026-10-01T00:00:00Z').toLocal(),
        );
      },
    );

    test(
      'bancos antigos sem colunas de apresentação caem nos defaults MZN/pt',
      () async {
        stub.handler = (path, request) {
          if (path.contains('tenants')) {
            return FakeResponse([
              {
                'id': 'tn-antigo',
                'owner_user_id': 'u1',
                'business_name': 'Loja Antiga',
                'plan_id': 'pl_starter',
                'status': 'approved',
                'created_at': '2025-06-01T00:00:00Z',
                // currency_code / language / billing ausentes.
              },
            ]);
          }
          return FakeResponse(<dynamic>[]);
        };

        final all = await ds.getAll();
        final tenant = all.single;
        expect(tenant.currencyCode, 'MZN');
        expect(tenant.language, 'pt');
        expect(tenant.planExpiresAt, isNull);
        expect(tenant.nextInvoiceAt, isNull);
      },
    );
  });

  group('TenantSupabaseDataSourceImpl — escritas com guarda', () {
    test(
      'approve grava status approved + approved_at e valida linhas',
      () async {
        stub.handler = (path, request) {
          if (path.contains('tenants')) {
            return FakeResponse([
              {'id': 'tn1'},
            ]);
          }
          return FakeResponse(<dynamic>[]);
        };

        await ds.approve('tn1');
        final req = stub.requests.single;
        expect(req.method, 'PATCH');
        expect(req.url.path, contains('/rest/v1/tenants'));
        expect(req.url.queryParameters, containsPair('id', 'eq.tn1'));
        final body = jsonBodyOf(req) as Map<String, dynamic>;
        expect(body['status'], 'approved');
        expect(body['approved_at'], isNotNull);
      },
    );

    test('approve em tenant inexistente (0 linhas) lança StateError', () async {
      // Handler padrão (null) responde [] → guarda de linhas afetadas.
      await expectLater(ds.approve('tn-fantasma'), throwsStateError);
    });

    test('reject grava status rejected + motivo e valida linhas', () async {
      stub.handler = (path, request) {
        if (path.contains('tenants')) {
          return FakeResponse([
            {'id': 'tn2'},
          ]);
        }
        return FakeResponse(<dynamic>[]);
      };

      await ds.reject('tn2', 'documentos pendentes');
      final body = jsonBodyOf(stub.requests.single) as Map<String, dynamic>;
      expect(body['status'], 'rejected');
      expect(body['rejection_reason'], 'documentos pendentes');
    });

    test('reject em tenant inexistente lança StateError', () async {
      await expectLater(ds.reject('tn-fantasma', 'motivo'), throwsStateError);
    });

    test('updatePlan grava o plano e valida linhas', () async {
      stub.handler = (path, request) {
        if (path.contains('tenants')) {
          return FakeResponse([
            {'id': 'tn3'},
          ]);
        }
        return FakeResponse(<dynamic>[]);
      };

      await ds.updatePlan('tn3', 'pl_pro');
      final body = jsonBodyOf(stub.requests.single) as Map<String, dynamic>;
      expect(body['plan_id'], 'pl_pro');
    });

    test('updatePlan em tenant inexistente lança StateError', () async {
      await expectLater(
        ds.updatePlan('tn-fantasma', 'pl_pro'),
        throwsStateError,
      );
    });

    test(
      'updateBilling grava as datas de cobrança em UTC e valida linhas',
      () async {
        stub.handler = (path, request) {
          if (path.contains('tenants')) {
            return FakeResponse([
              {'id': 'tn4'},
            ]);
          }
          return FakeResponse(<dynamic>[]);
        };

        await ds.updateBilling(
          'tn4',
          planExpiresAt: DateTime.utc(2027, 1, 31),
          nextInvoiceAt: DateTime.utc(2026, 10, 1),
        );
        final body = jsonBodyOf(stub.requests.single) as Map<String, dynamic>;
        expect(body['plan_expires_at'], '2027-01-31T00:00:00.000Z');
        expect(body['next_invoice_at'], '2026-10-01T00:00:00.000Z');
      },
    );

    test('updateBilling em tenant inexistente lança StateError', () async {
      await expectLater(
        ds.updateBilling(
          'tn-fantasma',
          planExpiresAt: DateTime(2027),
          nextInvoiceAt: DateTime(2026, 10),
        ),
        throwsStateError,
      );
    });

    test(
      'updateSettings do dono vai pela RPC update_tenant_settings (não UPDATE direto)',
      () async {
        await ds.updateSettings('tn1', currencyCode: 'ZAR', language: 'en');
        final rpcReq = stub.requests.single;
        expect(
          rpcReq.url.path,
          contains('/rest/v1/rpc/update_tenant_settings'),
        );
        final body = jsonBodyOf(rpcReq) as Map<String, dynamic>;
        // p_mfa_enforced vai SEMPRE (default false): PostgREST resolve RPC
        // por assinatura exata — omitir o argumento falha (PGRST203) em
        // bancos com overload 3/4-args (CREATE OR REPLACE com assinatura
        // nova). false NÃO altera o estado (não é ativação).
        expect(body, {
          'p_tenant_id': 'tn1',
          'p_currency_code': 'ZAR',
          'p_language': 'en',
          'p_mfa_enforced': false,
        });
      },
    );
  });

  group('TenantSupabaseDataSourceImpl.requestAccess', () {
    test(
      'INSERT bem-sucedido devolve o tenant criado (status pending)',
      () async {
        stub.handler = (path, request) {
          if (path.contains('tenants')) {
            final body =
                jsonDecode((request as http.Request).body)
                    as Map<String, dynamic>;
            return FakeResponse([
              {
                'id': body['id'],
                'owner_user_id': body['owner_user_id'],
                'business_name': body['business_name'],
                'plan_id': body['plan_id'],
                'status': body['status'],
                'currency_code': body['currency_code'],
                'language': body['language'],
                'created_at': '2026-03-01T00:00:00Z',
              },
            ]);
          }
          return FakeResponse(<dynamic>[]);
        };

        final tenant = await ds.requestAccess(
          ownerUserId: 'u-novo',
          businessName: 'Nova Loja',
          planId: 'pl_starter',
          currencyCode: 'MZN',
          language: 'pt',
        );
        expect(tenant.id, startsWith('tn'));
        expect(tenant.status, TenantStatus.pending);
        expect(tenant.businessName, 'Nova Loja');

        final body = jsonBodyOf(stub.requests.single) as Map<String, dynamic>;
        expect(body['status'], 'pending');
        expect(body['owner_user_id'], 'u-novo');
        expect(body['currency_code'], 'MZN');
        expect(body['language'], 'pt');
      },
    );

    test(
      'erro de unicidade 23505 vira InvalidTenantRequestException amigável',
      () async {
        stub.handler = (path, request) {
          return FakeResponse({
            'message':
                'duplicate key value violates unique constraint "tenants_one_pending_per_owner"',
            'code': '23505',
          }, status: 409);
        };

        await expectLater(
          ds.requestAccess(
            ownerUserId: 'u-dup',
            businessName: 'Duplicada',
            planId: 'pl_starter',
            currencyCode: 'MZN',
            language: 'pt',
          ),
          throwsA(
            isA<InvalidTenantRequestException>().having(
              (e) => e.message,
              'message',
              contains('Aguarde a aprovação'),
            ),
          ),
        );
      },
    );

    test('outros erros do PostgREST propagam sem tradução', () async {
      stub.handler = (path, request) {
        return FakeResponse({
          'message': 'permissão negada pela RLS',
          'code': '42501',
        }, status: 403);
      };

      await expectLater(
        ds.requestAccess(
          ownerUserId: 'u1',
          businessName: 'X',
          planId: 'pl_starter',
          currencyCode: 'MZN',
          language: 'pt',
        ),
        throwsA(
          isA<PostgrestException>().having((e) => e.code, 'code', '42501'),
        ),
      );
    });
  });

  group('TenantSupabaseDataSourceImpl — rede', () {
    test(
      'uma conexão interrompida é compensada pela política de retry do cliente',
      () async {
        // O PostgrestClient embutido retenta em falhas de conexão —
        // o contrato observable: UMA queda não falha a listagem.
        stub.failNext = 1;
        final all = await ds.getAll();
        expect(all, isEmpty);
        // 2 tentativas gravadas: a que falhou + a que teve sucesso.
        expect(stub.requests.length, greaterThanOrEqualTo(2));
      },
    );
  });
}
