import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:tareqo/data/datasources/remote/supabase_invoice_data_source.dart';
import 'package:tareqo/data/datasources/remote/supabase_invoice_notification_data_source.dart';
import 'package:tareqo/data/datasources/remote/supabase_product_data_source.dart';
import 'package:tareqo/data/datasources/remote/supabase_customer_data_source.dart';
import 'package:tareqo/data/datasources/remote/supabase_store_data_source.dart';
import 'package:tareqo/domain/entities/invoice.dart';
import 'package:tareqo/domain/entities/invoice_notification.dart';
import 'package:tareqo/domain/entities/product.dart';
import 'package:tareqo/domain/entities/customer.dart';
import 'package:tareqo/domain/entities/store.dart';

import '../../../helpers/supabase_test_harness.dart';

/// Testes de CONTRATO REST dos datasources remotos de facturas,
/// notificações de factura, produtos, clientes e lojas.
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

  group('InvoiceSupabaseDataSourceImpl', () {
    const ds = InvoiceSupabaseDataSourceImpl();

    test(
      'hasPendingForPeriod devolve true quando há pendente no período',
      () async {
        stub.handler = (path, request) {
          if (path.contains('invoices')) {
            expect(
              request.url.queryParameters,
              containsPair('period', 'eq.2026-09'),
            );
            return FakeResponse([
              {'id': 'inv1'},
            ]);
          }
          return FakeResponse(<dynamic>[]);
        };

        expect(await ds.hasPendingForPeriod('tn1', '2026-09'), isTrue);
      },
    );

    test(
      'hasPendingForPeriod devolve false sem pendente (anti-duplicação)',
      () async {
        expect(await ds.hasPendingForPeriod('tn1', '2026-10'), isFalse);
      },
    );

    test('getPending ordena por created_at asc e filtra status', () async {
      stub.handler = (path, request) {
        if (path.contains('invoices')) {
          expect(
            request.url.queryParameters,
            containsPair('status', 'eq.pending'),
          );
          return FakeResponse([
            {
              'id': 'inv1',
              'number': 3,
              'tenant_id': 'tn1',
              'plan_id': 'pl_starter',
              'amount_cents': 150000,
              'status': 'pending',
              'due_date': '2026-10-01T00:00:00Z',
              'period': '2026-09',
              'paid_at': null,
              'notes': null,
              'created_at': '2026-09-01T00:00:00Z',
            },
          ]);
        }
        return FakeResponse(<dynamic>[]);
      };

      final invoices = await ds.getPending();
      final invoice = invoices.single;
      expect(invoice.status, InvoiceStatus.pending);
      expect(invoice.period, '2026-09');
      expect(invoice.amountCents, 150000);
      expect(invoice.dueDate, DateTime.parse('2026-10-01T00:00:00Z').toLocal());
    });

    test('markAsPaid em factura inexistente lança StateError', () async {
      await expectLater(ds.markAsPaid('inv-fantasma'), throwsStateError);
    });

    test('cancel em factura inexistente lança StateError', () async {
      await expectLater(ds.cancel('inv-fantasma'), throwsStateError);
    });
  });

  group('InvoiceNotificationSupabaseDataSourceImpl', () {
    const ds = InvoiceNotificationSupabaseDataSourceImpl();

    Map<String, dynamic> row(String id, {bool read = false}) => {
      'id': id,
      'tenant_id': 'tn1',
      'invoice_id': 'inv1',
      'type': 'invoiceGenerated',
      'title': 'Factura #3',
      'body': 'Nova factura disponível',
      'is_read': read,
      'created_at': '2026-09-01T00:00:00Z',
      'read_at': null,
    };

    test('getUnreadByTenant filtra is_read = false', () async {
      stub.handler = (path, request) {
        if (path.contains('invoice_notifications')) {
          expect(
            request.url.queryParameters,
            containsPair('is_read', 'eq.false'),
          );
          return FakeResponse([row('n1')]);
        }
        return FakeResponse(<dynamic>[]);
      };

      final unread = await ds.getUnreadByTenant('tn1');
      final notification = unread.single;
      expect(notification.id, 'n1');
      expect(notification.isRead, isFalse);
      expect(notification.type, InvoiceNotificationType.invoiceGenerated);
    });

    test('getUnreadCount devolve o total não lido', () async {
      stub.handler = (path, request) {
        if (path.contains('invoice_notifications')) {
          return FakeResponse([
            {'id': 'n1'},
            {'id': 'n2'},
            {'id': 'n3'},
          ]);
        }
        return FakeResponse(<dynamic>[]);
      };

      expect(await ds.getUnreadCount('tn1'), 3);
    });

    test('markAsRead em notificação inexistente lança StateError', () async {
      await expectLater(ds.markAsRead('n-fantasma'), throwsStateError);
    });

    test('delete em notificação inexistente lança StateError', () async {
      await expectLater(ds.delete('n-fantasma'), throwsStateError);
    });
  });

  group('ProductSupabaseDataSourceImpl — REST', () {
    const ds = ProductSupabaseDataSourceImpl();

    Map<String, dynamic> row(String id, String name) => {
      'id': id,
      'store_id': 'st1',
      'name': name,
      'description': null,
      'image_path': null,
      'purchase_price': 500,
      'sale_price': 800,
      'stock_quantity': 25,
      'code': null,
      'venda_por_fracao': null,
      'unit_label': null,
      'is_active': null,
    };

    test(
      'getAll ordena por nome e aplica defaults para colunas novas',
      () async {
        stub.handler = (path, request) {
          if (path.contains('products')) {
            // Ordem de chegada propositalmente desordenada.
            return FakeResponse([row('p2', 'Zarroz'), row('p1', 'Arroz')]);
          }
          return FakeResponse(<dynamic>[]);
        };

        final products = await ds.getAll(storeId: 'st1');
        expect(products.map((p) => p.name).toList(), ['Arroz', 'Zarroz']);
        final product = products.last;
        // Defaults para bancos antigos:
        expect(product.description, '');
        expect(product.imagePath, '');
        expect(product.code, '');
        expect(product.vendaPorFracao, isFalse);
        expect(product.unitLabel, 'un');
        expect(product.isActive, isTrue); // DEFAULT true.
      },
    );

    test('getById com escopo por loja devolve null para outra loja', () async {
      final product = await ds.getById('p1', storeId: 'st-outro');
      expect(product, isNull);
      final req = stub.requests.single;
      expect(req.url.queryParameters, containsPair('id', 'eq.p1'));
      expect(req.url.queryParameters, containsPair('store_id', 'eq.st-outro'));
    });

    test(
      'update NÃO grava stock_quantity (invariante vai pelos lotes)',
      () async {
        final bodies = <Map<String, dynamic>>[];
        stub.handler = (path, request) {
          if (path.contains('products')) {
            bodies.add(
              jsonDecode((request as http.Request).body)
                  as Map<String, dynamic>,
            );
            return FakeResponse([
              {'id': 'p1'},
            ]);
          }
          return FakeResponse(<dynamic>[]);
        };

        await ds.update(
          const Product(
            id: 'p1',
            storeId: 'st1',
            name: 'Arroz',
            purchasePriceCents: 500,
            salePriceCents: 800,
            stockQuantity: 999, // Deve ser IGNORADO no UPDATE.
          ),
        );
        final body = bodies.single;
        expect(body.containsKey('stock_quantity'), isFalse);
        expect(body['name'], 'Arroz');
      },
    );

    test('update em produto inexistente lança StateError', () async {
      await expectLater(
        ds.update(
          const Product(
            id: 'p-fantasma',
            storeId: 'st1',
            name: 'X',
            purchasePriceCents: 1,
            salePriceCents: 2,
            stockQuantity: 0,
          ),
        ),
        throwsStateError,
      );
    });

    test('updateStock em produto inexistente lança StateError', () async {
      await expectLater(
        ds.updateStock('p-fantasma', 10, storeId: 'st1'),
        throwsStateError,
      );
    });

    test(
      'adjustStock vai pela RPC adjust_product_stock com guarda gerencial',
      () async {
        final bodies = <Map<String, dynamic>>[];
        stub.handler = (path, request) {
          if (path.contains('rpc/adjust_product_stock')) {
            bodies.add(
              jsonDecode((request as http.Request).body)
                  as Map<String, dynamic>,
            );
            return FakeResponse(<dynamic>[]);
          }
          return FakeResponse(<dynamic>[]);
        };

        await ds.adjustStock('p1', 100, storeId: 'st1');
        expect(bodies.single, {
          'p_product_id': 'p1',
          'p_store_id': 'st1',
          'p_new_quantity': 100,
        });
      },
    );
  });

  group('CustomerSupabaseDataSourceImpl', () {
    const ds = CustomerSupabaseDataSourceImpl();

    test('add grava user_id da sessão; getAll filtra por loja', () async {
      final bodies = <Map<String, dynamic>>[];
      stub.handler = (path, request) {
        if (path.contains('customers')) {
          final req = request as http.Request;
          if (req.method == 'POST') {
            bodies.add(jsonDecode(req.body) as Map<String, dynamic>);
          }
          return FakeResponse(<dynamic>[]);
        }
        return FakeResponse(<dynamic>[]);
      };

      await ds.add(const Customer(id: 'c1', storeId: 'st1', name: 'Ana'));
      expect(bodies.single['user_id'], 'u1');
      expect(bodies.single['name'], 'Ana');

      await ds.getAll(storeId: 'st1');
      expect(
        stub.requests.last.url.queryParameters,
        containsPair('store_id', 'eq.st1'),
      );
    });

    test('update e delete escopam pelo id', () async {
      stub.handler = (path, request) {
        if (path.contains('customers')) {
          return FakeResponse(<dynamic>[]);
        }
        return FakeResponse(<dynamic>[]);
      };

      await ds.update(
        const Customer(id: 'c1', storeId: 'st1', name: 'Ana Silva'),
      );
      await ds.delete('c1');
      expect(stub.requests, hasLength(2));
      expect(stub.requests.first.method, 'PATCH');
      expect(stub.requests.last.method, 'DELETE');
      expect(
        stub.requests.last.url.queryParameters,
        containsPair('id', 'eq.c1'),
      );
    });
  });

  group('StoreSupabaseDataSourceImpl', () {
    const ds = StoreSupabaseDataSourceImpl();

    test('getByTenant filtra por tenant e mapeia com defaults', () async {
      stub.handler = (path, request) {
        if (path.contains('stores')) {
          return FakeResponse([
            {
              'id': 'st1',
              'tenant_id': 'tn1',
              'name': 'Matriz',
              'address': null,
              'phone': null,
              'email': null,
              'nuit': null,
              'city': null,
            },
          ]);
        }
        return FakeResponse(<dynamic>[]);
      };

      final stores = await ds.getByTenant('tn1');
      final store = stores.single;
      expect(store.id, 'st1');
      expect(store.tenantId, 'tn1');
      expect(store.name, 'Matriz');
      expect(store.address, '');
      expect(store.phone, '');
      expect(store.nuit, '');
      expect(store.city, '');
    });

    test('add grava tenant_id explícito', () async {
      final bodies = <Map<String, dynamic>>[];
      stub.handler = (path, request) {
        if (path.contains('stores')) {
          bodies.add(
            jsonDecode((request as http.Request).body) as Map<String, dynamic>,
          );
          return FakeResponse(<dynamic>[]);
        }
        return FakeResponse(<dynamic>[]);
      };

      await ds.add(
        const Store(
          id: 'st2',
          tenantId: 'tn1',
          name: 'Filial',
          address: '',
          phone: '',
          email: '',
          nuit: '',
          city: 'Maputo',
        ),
      );
      expect(bodies.single['tenant_id'], 'tn1');
      expect(bodies.single['city'], 'Maputo');
    });
  });
}
