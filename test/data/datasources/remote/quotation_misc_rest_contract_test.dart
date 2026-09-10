import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:tareqo/data/datasources/remote/supabase_quotation_data_source.dart';
import 'package:tareqo/data/datasources/remote/supabase_custom_invoice_data_source.dart';
import 'package:tareqo/data/datasources/remote/supabase_employee_data_source.dart';
import 'package:tareqo/data/datasources/auth/supabase_auth_remote_data_source.dart';
import 'package:tareqo/domain/entities/app_user.dart';
import 'package:tareqo/domain/entities/auth_event.dart';
import 'package:tareqo/domain/entities/quotation.dart';
import 'package:tareqo/domain/entities/custom_invoice.dart';
import 'package:tareqo/domain/entities/store_employee.dart';

import '../../../helpers/supabase_test_harness.dart';

/// Testes de CONTRATO REST dos datasources de documentos por loja
/// (cotações e facturas personalizadas — payload JSONB), vínculos de
/// funcionários e eventos de auth.
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

  Quotation quotation(String id) => Quotation(
    id: id,
    storeId: 'st1',
    customerId: 'c1',
    customerName: 'Cliente $id',
    items: const [
      QuotationItem(
        productId: 'p1',
        productName: 'Caneta',
        quantity: 1000,
        unitPriceCents: 200,
      ),
    ],
    totalAmountCents: 200,
    createdAt: DateTime.utc(2026, 8, 3, 10),
    validUntil: DateTime.utc(2026, 9, 3),
  );

  CustomInvoice customInvoice(String id) => CustomInvoice(
    id: id,
    storeId: 'st1',
    clientName: 'Cliente $id',
    items: const [
      CustomInvoiceItem(
        productName: 'Caneta',
        quantity: 1,
        unitPriceCents: 200,
        subtotalCents: 200,
      ),
    ],
    totalAmountCents: 200,
    createdAt: DateTime.utc(2026, 8, 3, 10),
  );

  group('QuotationSupabaseDataSourceImpl', () {
    const ds = QuotationSupabaseDataSourceImpl();

    test(
      'add grava o payload JSON e o servidor devolve o número real (trigger)',
      () async {
        stub.handler = (path, request) {
          if (path.contains('quotations')) {
            final body =
                jsonDecode((request as http.Request).body)
                    as Map<String, dynamic>;
            return FakeResponse([
              {
                'id': body['id'],
                'store_id': body['store_id'],
                'quotation_number': 5,
                'payload': body['payload'],
                'created_at': '2026-08-03T10:00:00Z',
              },
            ]);
          }
          return FakeResponse(<dynamic>[]);
        };

        final created = await ds.add(quotation('q1'));
        // O número do servidor (5) sobrepõe o local (0).
        expect(created.number, 5);
        expect(created.storeId, 'st1');
        expect(created.customerName, 'Cliente q1');

        final body = jsonBodyOf(stub.requests.single) as Map<String, dynamic>;
        expect(body['payload'], isA<String>());
        expect(body['store_id'], 'st1');
      },
    );

    test(
      'getAll aceita payload como String JSON (formato defensivo)',
      () async {
        stub.handler = (path, request) {
          if (path.contains('quotations')) {
            return FakeResponse([
              {
                'id': 'q1',
                'store_id': 'st1',
                'quotation_number': 7,
                'payload': jsonEncode(quotation('q1').toJson()),
                'created_at': '2026-08-03T10:00:00Z',
              },
            ]);
          }
          return FakeResponse(<dynamic>[]);
        };

        final list = await ds.getAll(storeId: 'st1');
        final quotationMapped = list.single;
        expect(quotationMapped.number, 7);
        expect(quotationMapped.items.single.productName, 'Caneta');
      },
    );

    test(
      'getAll aceita payload como Map decodificado (PostgREST jsonb)',
      () async {
        stub.handler = (path, request) {
          if (path.contains('quotations')) {
            return FakeResponse([
              {
                'id': 'q2',
                'store_id': 'st1',
                'quotation_number': 8,
                'payload': quotation('q2').toJson(),
                'created_at': '2026-08-03T10:00:00Z',
              },
            ]);
          }
          return FakeResponse(<dynamic>[]);
        };

        final list = await ds.getAll(storeId: 'st1');
        expect(list.single.id, 'q2');
        expect(list.single.number, 8);
      },
    );

    test('update grava o payload e devolve a linha atualizada', () async {
      stub.handler = (path, request) {
        if (path.contains('quotations')) {
          return FakeResponse([
            {
              'id': 'q1',
              'store_id': 'st1',
              'quotation_number': 5,
              'payload': quotation('q1').toJson(),
              'created_at': '2026-08-03T10:00:00Z',
            },
          ]);
        }
        return FakeResponse(<dynamic>[]);
      };

      final updated = await ds.update(quotation('q1'));
      expect(updated.number, 5);
      expect(stub.requests.single.method, 'PATCH');
    });
  });

  group('CustomInvoiceSupabaseDataSourceImpl', () {
    const ds = CustomInvoiceSupabaseDataSourceImpl();

    test('add grava payload e devolve número do servidor', () async {
      stub.handler = (path, request) {
        if (path.contains('custom_invoices')) {
          final body =
              jsonDecode((request as http.Request).body)
                  as Map<String, dynamic>;
          return FakeResponse([
            {
              'id': body['id'],
              'store_id': body['store_id'],
              'invoice_number': 2,
              'payload': body['payload'],
              'created_at': '2026-08-03T10:00:00Z',
            },
          ]);
        }
        return FakeResponse(<dynamic>[]);
      };

      final created = await ds.add(customInvoice('ci1'));
      expect(created.number, 2);
      expect(created.clientName, 'Cliente ci1');
    });

    test('getAll mapeia com payload String e escopo por loja', () async {
      stub.handler = (path, request) {
        if (path.contains('custom_invoices')) {
          expect(
            request.url.queryParameters,
            containsPair('store_id', 'eq.st1'),
          );
          return FakeResponse([
            {
              'id': 'ci1',
              'store_id': 'st1',
              'invoice_number': 3,
              'payload': jsonEncode(customInvoice('ci1').toJson()),
              'created_at': '2026-08-03T10:00:00Z',
            },
          ]);
        }
        return FakeResponse(<dynamic>[]);
      };

      final list = await ds.getAll(storeId: 'st1');
      expect(list.single.number, 3);
      expect(list.single.items.single.subtotalCents, 200);
    });
  });

  group('EmployeeSupabaseDataSourceImpl', () {
    const ds = EmployeeSupabaseDataSourceImpl();

    test(
      'getByStore mapeia vínculo com default is_active=true (legado)',
      () async {
        stub.handler = (path, request) {
          if (path.contains('store_employees')) {
            return FakeResponse([
              {
                'id': 'se1',
                'tenant_id': 'tn1',
                'store_id': 'st1',
                'user_id': 'u-emp',
                'full_name': 'Funcionário Um',
                'email': 'emp@test.local',
                'role': 'employee',
                // is_active ausente → servidor antigo → ativo.
              },
            ]);
          }
          return FakeResponse(<dynamic>[]);
        };

        final employees = await ds.getByStore('st1');
        final employee = employees.single;
        expect(employee.id, 'se1');
        expect(employee.role, EmployeeRole.employee);
        expect(employee.isActive, isTrue);
      },
    );

    test('getByTenant filtra por tenant e ordena por nome', () async {
      stub.handler = (path, request) {
        if (path.contains('store_employees')) {
          expect(
            request.url.queryParameters,
            containsPair('tenant_id', 'eq.tn1'),
          );
          return FakeResponse(<dynamic>[]);
        }
        return FakeResponse(<dynamic>[]);
      };

      expect(await ds.getByTenant('tn1'), isEmpty);
    });

    test('add grava role pelo nome e dados do vínculo', () async {
      final bodies = <Map<String, dynamic>>[];
      stub.handler = (path, request) {
        if (path.contains('store_employees')) {
          bodies.add(
            jsonDecode((request as http.Request).body) as Map<String, dynamic>,
          );
          return FakeResponse(<dynamic>[]);
        }
        return FakeResponse(<dynamic>[]);
      };

      await ds.add(
        const StoreEmployee(
          id: 'se2',
          tenantId: 'tn1',
          storeId: 'st1',
          userId: 'u-novo',
          fullName: 'Funcionário Dois',
          email: 'novo@test.local',
          role: EmployeeRole.manager,
          isActive: true,
        ),
      );
      final body = bodies.single;
      expect(body['role'], 'manager');
      expect(body['is_active'], isTrue);
      expect(body['tenant_id'], 'tn1');
    });
  });

  group('SupabaseAuthRemoteDataSourceImpl — eventos', () {
    final ds = SupabaseAuthRemoteDataSourceImpl();

    test('authEvents emite other no primeiro listener e não trava', () async {
      final events = <AuthEvent>[];
      final sub = ds.authEvents.listen(events.add);
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      expect(events, isNotEmpty);
    });

    test(
      'authStateChanges emite o estado atual ao primeiro listener',
      () async {
        // Sem sessão (pós signOut em outro teste) → null; com sessão → user.
        final states = <AppUser?>[];
        final sub = ds.authStateChanges.listen(states.add);
        await Future<void>.delayed(Duration.zero);
        await sub.cancel();
        // Contrato: o PRIMEIRO valor chega ao assinar (estado atual da
        // sessão — nunca um stream preso em loading); eventos subsequentes
        // do onAuthStateChange também são encaminhados.
        expect(states, isNotEmpty);
        expect(states.first, isNotNull);
        expect(states.first!.id, 'u1');
      },
    );
  });
}
