import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/data/datasources/remote/supabase_invoice_data_source.dart';
import 'package:tareqo/data/datasources/remote/supabase_invoice_notification_data_source.dart';
import 'package:tareqo/domain/entities/invoice.dart';
import 'package:tareqo/domain/entities/invoice_notification.dart';

import '../../../helpers/supabase_test_harness.dart';

/// Testes de CONTRATO REST das leituras e escritas dos datasources de
/// facturas e notificações (complementa os caminhos de erro já cobertos).
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

  group('InvoiceSupabaseDataSourceImpl — leituras e escritas', () {
    const ds = InvoiceSupabaseDataSourceImpl();

    Map<String, dynamic> row({String status = 'pending'}) => {
      'id': 'inv1',
      'number': 3,
      'tenant_id': 'tn1',
      'plan_id': 'pl_starter',
      'amount_cents': 150000,
      'status': status,
      'due_date': '2026-10-01T00:00:00Z',
      'period': '2026-09',
      'paid_at': status == 'paid' ? '2026-09-20T12:00:00Z' : null,
      'notes': 'Mensalidade',
      'created_at': '2026-09-01T00:00:00Z',
    };

    test('getByTenant filtra por tenant e mapeia factura paga', () async {
      stub.handler = (path, request) {
        if (path.contains('invoices')) {
          expect(
            request.url.queryParameters,
            containsPair('tenant_id', 'eq.tn1'),
          );
          return FakeResponse([row(status: 'paid')]);
        }
        return FakeResponse(<dynamic>[]);
      };

      final invoices = await ds.getByTenant('tn1');
      final invoice = invoices.single;
      expect(invoice.status, InvoiceStatus.paid);
      expect(invoice.paidAt, DateTime.parse('2026-09-20T12:00:00Z').toLocal());
      expect(invoice.notes, 'Mensalidade');
      expect(invoice.number, 3);
    });

    test('getAll lista todas as facturas (painel do super admin)', () async {
      stub.handler = (path, request) {
        if (path.contains('invoices')) {
          return FakeResponse([row()]);
        }
        return FakeResponse(<dynamic>[]);
      };

      expect((await ds.getAll()).single.period, '2026-09');
    });

    test(
      'create grava status/period/notes e devolve a factura criada',
      () async {
        stub.handler = (path, request) {
          if (path.contains('invoices')) {
            final body = jsonBodyOf(request) as Map<String, dynamic>;
            return FakeResponse([
              {...row(), 'id': body['id'], 'status': body['status']},
            ]);
          }
          return FakeResponse(<dynamic>[]);
        };

        final created = await ds.create(
          Invoice(
            id: 'inv-nova',
            tenantId: 'tn1',
            planId: 'pl_starter',
            amountCents: 150000,
            status: InvoiceStatus.pending,
            dueDate: DateTime.utc(2026, 10, 1),
            period: '2026-10',
            notes: 'Mensalidade',
            createdAt: DateTime.utc(2026, 9, 10),
          ),
        );
        expect(created.id, 'inv-nova');
        final body = jsonBodyOf(stub.requests.single) as Map<String, dynamic>;
        expect(body['status'], 'pending');
        expect(body['period'], '2026-10');
        expect(body['amount_cents'], 150000);
      },
    );

    test('markAsPaid grava paid + paid_at com validação de linhas', () async {
      final bodies = <Map<String, dynamic>>[];
      stub.handler = (path, request) {
        if (path.contains('invoices')) {
          bodies.add(jsonBodyOf(request) as Map<String, dynamic>);
          return FakeResponse([
            {'id': 'inv1'},
          ]);
        }
        return FakeResponse(<dynamic>[]);
      };

      await ds.markAsPaid('inv1');
      final req = stub.requests.single;
      expect(req.method, 'PATCH');
      expect(req.url.queryParameters, containsPair('id', 'eq.inv1'));
      expect(bodies.single['status'], 'paid');
      expect(bodies.single['paid_at'], isNotNull);
    });

    test('cancel grava status cancelled', () async {
      final bodies = <Map<String, dynamic>>[];
      stub.handler = (path, request) {
        if (path.contains('invoices')) {
          bodies.add(jsonBodyOf(request) as Map<String, dynamic>);
          return FakeResponse([
            {'id': 'inv1'},
          ]);
        }
        return FakeResponse(<dynamic>[]);
      };

      await ds.cancel('inv1');
      expect(bodies.single['status'], 'cancelled');
    });
  });

  group('InvoiceNotificationSupabaseDataSourceImpl — leituras', () {
    const ds = InvoiceNotificationSupabaseDataSourceImpl();

    Map<String, dynamic> row({bool read = false}) => {
      'id': 'n1',
      'tenant_id': 'tn1',
      'invoice_id': 'inv1',
      'type': 'invoiceGenerated',
      'title': 'Factura #3',
      'body': 'Nova factura disponível',
      'is_read': read,
      'created_at': '2026-09-01T00:00:00Z',
      'read_at': read ? '2026-09-02T08:00:00Z' : null,
    };

    test('getByTenant mapeia notificação lida com read_at', () async {
      stub.handler = (path, request) {
        if (path.contains('invoice_notifications')) {
          expect(
            request.url.queryParameters,
            containsPair('tenant_id', 'eq.tn1'),
          );
          return FakeResponse([row(read: true)]);
        }
        return FakeResponse(<dynamic>[]);
      };

      final notifications = await ds.getByTenant('tn1');
      final notification = notifications.single;
      expect(notification.isRead, isTrue);
      expect(
        notification.readAt,
        DateTime.parse('2026-09-02T08:00:00Z').toLocal(),
      );
    });

    test('create grava type pelo nome e devolve a notificação', () async {
      stub.handler = (path, request) {
        if (path.contains('invoice_notifications')) {
          final body = jsonBodyOf(request) as Map<String, dynamic>;
          return FakeResponse([
            {...row(), 'id': body['id']},
          ]);
        }
        return FakeResponse(<dynamic>[]);
      };

      final created = await ds.create(
        InvoiceNotification(
          id: 'n-nova',
          tenantId: 'tn1',
          invoiceId: 'inv1',
          type: InvoiceNotificationType.invoiceGenerated,
          title: 'Factura #4',
          body: 'Nova factura disponível',
          isRead: false,
          createdAt: DateTime.utc(2026, 9, 10),
        ),
      );
      expect(created.id, 'n-nova');
      final body = jsonBodyOf(stub.requests.single) as Map<String, dynamic>;
      expect(body['type'], 'invoiceGenerated');
      expect(body['is_read'], isFalse);
    });

    test(
      'markAllAsRead atualiza em lente por tenant (bulk, sem guarda)',
      () async {
        await ds.markAllAsRead('tn1');
        final req = stub.requests.single;
        expect(req.method, 'PATCH');
        expect(req.url.queryParameters, containsPair('tenant_id', 'eq.tn1'));
        expect(req.url.queryParameters, containsPair('is_read', 'eq.false'));
      },
    );
  });
}
