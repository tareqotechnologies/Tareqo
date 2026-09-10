import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:tareqo/data/datasources/remote/supabase_debt_data_source.dart';
import 'package:tareqo/data/datasources/remote/supabase_purchase_data_source.dart';
import 'package:tareqo/domain/entities/debt.dart';
import 'package:tareqo/domain/entities/purchase.dart';
import 'package:tareqo/domain/entities/sale.dart' show PaymentMethod;

import '../../../helpers/supabase_test_harness.dart';

/// Testes de CONTRATO REST dos datasources remotos de dívidas (fiado) e
/// compras — numeração de fallback, guarda de baixa, leitura com itens
/// embutidos e default defensivo do método de pagamento.
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

  group('DebtSupabaseDataSourceImpl — REST', () {
    const ds = DebtSupabaseDataSourceImpl();

    test('getAll mapeia dívida completa com escopo por loja', () async {
      stub.handler = (path, request) {
        if (path.contains('debts')) {
          return FakeResponse([
            {
              'id': 'd1',
              'store_id': 'st1',
              'debt_number': 12,
              'person_name': 'Cliente Fiado',
              'amount': 3000,
              'due_date': '2026-09-01T00:00:00Z',
              'is_customer_debt': true,
              'is_paid': false,
              'paid_at': null,
              'customer_id': 'c1',
            },
          ]);
        }
        return FakeResponse(<dynamic>[]);
      };

      final debts = await ds.getAll(storeId: 'st1');
      final debt = debts.single;
      expect(debt.id, 'd1');
      expect(debt.number, 12);
      expect(debt.personName, 'Cliente Fiado');
      expect(debt.amountCents, 3000);
      expect(debt.isCustomerDebt, isTrue);
      expect(debt.isPaid, isFalse);
      expect(debt.paidAt, isNull);
      expect(debt.customerId, 'c1');
      expect(debt.dueDate, DateTime.parse('2026-09-01T00:00:00Z').toLocal());
    });

    test('add numera pela última dívida da loja (MAX+1)', () async {
      final bodies = <Map<String, dynamic>>[];
      stub.handler = (path, request) {
        if (path.contains('debts')) {
          final req = request as http.Request;
          if (req.method == 'GET') {
            return FakeResponse([
              {'debt_number': 4},
            ]);
          }
          bodies.add(jsonDecode(req.body) as Map<String, dynamic>);
          return FakeResponse(<dynamic>[]);
        }
        return FakeResponse(<dynamic>[]);
      };

      await ds.add(
        Debt(
          id: 'd-nova',
          personName: 'Cliente',
          amountCents: 3000,
          dueDate: DateTime.utc(2026, 9, 1),
          isCustomerDebt: true,
        ),
      );
      expect(bodies.single['debt_number'], 5);
      expect(bodies.single['user_id'], 'u1');
      expect(bodies.single['store_id'], 'st1');
    });

    test('markAsPaid carimba pago + data e valida linhas afetadas', () async {
      final bodies = <Map<String, dynamic>>[];
      stub.handler = (path, request) {
        if (path.contains('debts')) {
          bodies.add(
            jsonDecode((request as http.Request).body) as Map<String, dynamic>,
          );
          return FakeResponse([
            {'id': 'd1'},
          ]);
        }
        return FakeResponse(<dynamic>[]);
      };

      await ds.markAsPaid('d1', storeId: 'st1');
      final req = stub.requests.single;
      expect(req.url.queryParameters, containsPair('id', 'eq.d1'));
      expect(req.url.queryParameters, containsPair('store_id', 'eq.st1'));
      final body = bodies.single;
      expect(body['is_paid'], isTrue);
      expect(body['paid_at'], isNotNull);
    });

    test('markAsPaid em dívida inexistente lança StateError', () async {
      await expectLater(
        ds.markAsPaid('d-fantasma', storeId: 'st1'),
        throwsStateError,
      );
    });
  });

  group('PurchaseSupabaseDataSourceImpl — REST', () {
    const ds = PurchaseSupabaseDataSourceImpl();

    test(
      'getAll mapeia compra com itens embutidos e validade opcional',
      () async {
        stub.handler = (path, request) {
          if (path.contains('purchases')) {
            return FakeResponse([
              {
                'id': 'pc1',
                'store_id': 'st1',
                'purchase_number': 7,
                'supplier_name': 'Distribuidora X',
                'total_amount': 45000,
                'payment_method': null, // Pré-migração → default cash.
                'date_time': '2026-08-20T10:00:00Z',
                'purchase_items': [
                  {
                    'product_id': 'p1',
                    'product_name': 'Óleo',
                    'quantity': 10,
                    'unit_price': 4500,
                    'expiry_date': '2027-06-01T00:00:00Z',
                  },
                  {
                    'product_id': 'p2',
                    'product_name': 'Açúcar',
                    'quantity': 5,
                    'unit_price': 2000,
                    'expiry_date': null,
                  },
                ],
              },
            ]);
          }
          return FakeResponse(<dynamic>[]);
        };

        final purchases = await ds.getAll(storeId: 'st1');
        final purchase = purchases.single;
        expect(purchase.id, 'pc1');
        expect(purchase.number, 7);
        expect(purchase.supplierName, 'Distribuidora X');
        expect(purchase.totalAmountCents, 45000);
        // Default defensivo para linhas antigas (pré-migração W11).
        expect(purchase.paymentMethod, PaymentMethod.cash);
        expect(purchase.items, hasLength(2));
        expect(
          purchase.items.first.expiryDate,
          DateTime.parse('2027-06-01T00:00:00Z').toLocal(),
        );
        expect(purchase.items.last.expiryDate, isNull);
      },
    );

    test(
      'add numera pela última compra da loja e grava user_id da sessão',
      () async {
        final bodies = <Map<String, dynamic>>[];
        stub.handler = (path, request) {
          if (path.contains('purchases')) {
            final req = request as http.Request;
            if (req.method == 'GET') {
              return FakeResponse([
                {'purchase_number': 2},
              ]);
            }
            bodies.add(jsonDecode(req.body) as Map<String, dynamic>);
            return FakeResponse(<dynamic>[]);
          }
          return FakeResponse(<dynamic>[]);
        };

        await ds.add(
          Purchase(
            id: 'pc-nova',
            storeId: 'st1',
            supplierName: 'Fornecedor',
            items: const [
              PurchaseItem(
                productId: 'p1',
                productName: 'Óleo',
                quantity: 3,
                unitPriceCents: 4500,
                expiryDate: null,
              ),
            ],
            totalAmountCents: 13500,
            paymentMethod: PaymentMethod.transfer,
            dateTime: DateTime.utc(2026, 9, 1),
          ),
        );
        final body = bodies.single;
        expect(body['purchase_number'], 3);
        expect(body['user_id'], 'u1');
        expect(body['payment_method'], 'transfer');
        expect((body['purchase_items'] as List).single['quantity'], 3);
      },
    );
  });
}
