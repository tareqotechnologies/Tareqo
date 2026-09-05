import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/domain/entities/sale.dart';
import 'package:tareqo/domain/entities/sale_item.dart';
import 'package:tareqo/domain/entities/store_employee.dart';
import 'package:tareqo/domain/usecases/employee_commission_calculator.dart';

StoreEmployee employee(String id, String userId, {String storeId = 'st1'}) =>
    StoreEmployee(
      id: id,
      tenantId: 'tn1',
      storeId: storeId,
      userId: userId,
      fullName: 'Funcionário $userId',
      email: '$userId@loja.com',
    );

Sale sale(
  String id,
  String userId,
  int totalAmountCents, {
  String storeId = 'st1',
  DateTime? dateTime,
  SaleStatus status = SaleStatus.active,
}) =>
    Sale(
      id: id,
      userId: userId,
      storeId: storeId,
      items: const [
        SaleItem(
          productId: 'p1',
          productName: 'Caneta',
          quantity: 1000,
          unitPriceCents: 100,
        ),
      ],
      totalAmountCents: totalAmountCents,
      paymentMethod: PaymentMethod.cash,
      dateTime: dateTime ?? DateTime(2026, 9, 10, 10),
      status: status,
    );

void main() {
  final roster = [
    employee('e1', 'u1'),
    employee('e2', 'u2'),
    employee('e3', 'u3'),
  ];

  group('calculateEmployeeCommissions', () {
    test('comissão = vendas ATIVAS do mês × taxa (pontos base)', () {
      final entries = calculateEmployeeCommissions(
        roster: roster,
        sales: [
          // u1: 12.000 + 8.000 = 20.000 MT → 5% = 1.000 MT
          sale('s1', 'u1', 1200000),
          sale('s2', 'u1', 800000),
          // u2: 8.500 → 7% = 595 MT
          sale('s3', 'u2', 850000),
        ],
        rateBpsByUserId: {'u1': 500, 'u2': 700},
        storeId: 'st1',
        month: '2026-09',
      );

      final byUser = {for (final e in entries) e.userId: e};
      expect(byUser['u1']!.salesCents, 2000000);
      expect(byUser['u1']!.commissionCents, 100000);
      expect(byUser['u2']!.salesCents, 850000);
      expect(byUser['u2']!.commissionCents, 59500);
      // Sem taxa nem vendas → zero honesto (não inventado).
      expect(byUser['u3']!.salesCents, 0);
      expect(byUser['u3']!.commissionCents, 0);
      // Ordenado por comissão decrescente.
      expect(entries.first.userId, 'u1');
    });

    test('ignora vendas de OUTRO mês, de OUTRA loja e anuladas', () {
      final entries = calculateEmployeeCommissions(
        roster: roster,
        sales: [
          sale('s1', 'u1', 100000, dateTime: DateTime(2026, 8, 20)),
          sale('s2', 'u1', 100000, storeId: 'st2'),
          sale('s3', 'u1', 100000, status: SaleStatus.cancelled),
          sale('s4', 'u1', 200000), // única que conta
        ],
        rateBpsByUserId: {'u1': 500},
        storeId: 'st1',
        month: '2026-09',
      );

      expect(entries.first.salesCents, 200000);
      expect(entries.first.commissionCents, 10000);
    });

    test('venda sem userId (legada) não gera comissão para ninguém', () {
      final entries = calculateEmployeeCommissions(
        roster: roster,
        sales: [sale('s1', '', 1000000)],
        rateBpsByUserId: {'u1': 500},
        storeId: 'st1',
        month: '2026-09',
      );

      for (final entry in entries) {
        expect(entry.salesCents, 0);
        expect(entry.commissionCents, 0);
      }
    });

    test('só funcionários DA loja entram no resumo', () {
      final otherStore = employee('e9', 'u9', storeId: 'st2');
      final entries = calculateEmployeeCommissions(
        roster: [...roster, otherStore],
        sales: [sale('s1', 'u9', 500000, storeId: 'st2')],
        rateBpsByUserId: {'u9': 500},
        storeId: 'st1',
        month: '2026-09',
      );

      expect(entries.any((e) => e.userId == 'u9'), isFalse);
    });
  });

  test('employeeMonthOf formata YYYY-MM', () {
    expect(employeeMonthOf(DateTime(2026, 9, 5)), '2026-09');
    expect(employeeMonthOf(DateTime(2026, 12, 31)), '2026-12');
  });
}