import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:tareqo/data/datasources/local/employee_management_sqlite_data_source_impl.dart';
import 'package:tareqo/data/datasources/local/sale_sqlite_data_source_impl.dart';
import 'package:tareqo/domain/entities/sale.dart';
import 'package:tareqo/domain/entities/sale_item.dart';

import '../../../helpers/test_sqlite.dart';

void main() {
  late Database db;
  late EmployeeManagementSqliteDataSourceImpl dataSource;

  setUp(() {
    db = openTestDatabase();
    dataSource = EmployeeManagementSqliteDataSourceImpl(db);
  });
  tearDown(() => db.close());

  group('EmployeeManagementSqliteDataSourceImpl — ponto', () {
    test('clockIn insere e getAttendance devolve o registo do dia', () async {
      final record = await dataSource.clockIn(
        storeId: 'st1',
        userId: 'u1',
        workDate: '2026-09-05',
        clockIn: DateTime(2026, 9, 5, 8, 0),
      );

      expect(record.clockOut, isNull);
      final all = await dataSource.getAttendance(
        storeId: 'st1',
        workDate: '2026-09-05',
      );
      expect(all, hasLength(1));
      expect(all.first.userId, 'u1');
      expect(all.first.workDate, '2026-09-05');
    });

    test('clockOut atualiza a MESMA linha (uma entrada por dia)', () async {
      await dataSource.clockIn(
        storeId: 'st1',
        userId: 'u1',
        workDate: '2026-09-05',
        clockIn: DateTime(2026, 9, 5, 8, 0),
      );

      final closed = await dataSource.clockOut(
        storeId: 'st1',
        userId: 'u1',
        workDate: '2026-09-05',
        clockOut: DateTime(2026, 9, 5, 17, 0),
      );

      expect(closed.clockOut, DateTime(2026, 9, 5, 17, 0));
      final all = await dataSource.getAttendance(
        storeId: 'st1',
        workDate: '2026-09-05',
      );
      expect(all, hasLength(1)); // não criou segunda linha
      expect(all.single.clockOut, isNotNull);
    });

    test('clockIn duplicado no mesmo dia lança StateError', () async {
      await dataSource.clockIn(
        storeId: 'st1',
        userId: 'u1',
        workDate: '2026-09-05',
        clockIn: DateTime(2026, 9, 5, 8, 0),
      );

      await expectLater(
        dataSource.clockIn(
          storeId: 'st1',
          userId: 'u1',
          workDate: '2026-09-05',
          clockIn: DateTime(2026, 9, 5, 9, 0),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('clockOut sem entrada lança StateError', () async {
      await expectLater(
        dataSource.clockOut(
          storeId: 'st1',
          userId: 'u1',
          workDate: '2026-09-05',
          clockOut: DateTime(2026, 9, 5, 17, 0),
        ),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('EmployeeManagementSqliteDataSourceImpl — taxas', () {
    test('setCommissionRate insere e atualiza (UPSERT por funcionário)',
        () async {
      await dataSource.setCommissionRate(
        storeId: 'st1',
        userId: 'u1',
        rateBps: 500,
      );
      await dataSource.setCommissionRate(
        storeId: 'st1',
        userId: 'u1',
        rateBps: 700,
      );

      final rates = await dataSource.getCommissionRates(storeId: 'st1');
      expect(rates, hasLength(1));
      expect(rates.single.rateBps, 700);
    });

    test('taxa inválida lança StateError', () async {
      await expectLater(
        dataSource.setCommissionRate(
          storeId: 'st1',
          userId: 'u1',
          rateBps: 10001,
        ),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('EmployeeManagementSqliteDataSourceImpl — metas', () {
    test('setTarget insere e atualiza (UPSERT por funcionário/mês)',
        () async {
      await dataSource.setTarget(
        storeId: 'st1',
        userId: 'u1',
        month: '2026-09',
        targetCents: 150000,
      );
      await dataSource.setTarget(
        storeId: 'st1',
        userId: 'u1',
        month: '2026-09',
        targetCents: 200000,
      );

      final targets = await dataSource.getTargets(
        storeId: 'st1',
        month: '2026-09',
      );
      expect(targets, hasLength(1));
      expect(targets.single.targetCents, 200000);
    });

    test('removeTarget apaga apenas a meta indicada', () async {
      await dataSource.setTarget(
        storeId: 'st1',
        userId: 'u1',
        month: '2026-09',
        targetCents: 150000,
      );
      await dataSource.setTarget(
        storeId: 'st1',
        userId: 'u2',
        month: '2026-09',
        targetCents: 100000,
      );

      final all = await dataSource.getTargets(storeId: 'st1');
      await dataSource.removeTarget(all.first.id, storeId: 'st1');

      final remaining = await dataSource.getTargets(storeId: 'st1');
      expect(remaining, hasLength(1));
      expect(remaining.single.userId, 'u2');
    });
  });

  group('sales.user_id (v5) — atribuição de comissões', () {
    test('venda legada sem user_id persiste e lê como vazio (sem forjar)',
        () async {
      final saleSource = SaleSqliteDataSourceImpl(db);
      await saleSource.add(
        Sale(
          id: 's1',
          items: const [
            SaleItem(
              productId: 'p1',
              productName: 'Caneta',
              quantity: 1000,
              unitPriceCents: 200,
            ),
          ],
          totalAmountCents: 200,
          paymentMethod: PaymentMethod.cash,
          dateTime: DateTime(2026, 9, 5, 10),
        ),
      );

      final sales = await saleSource.getAll(storeId: 'st1');
      expect(sales.single.userId, '');
    });

    test('venda com caixa persiste e lê a atribuição', () async {
      final saleSource = SaleSqliteDataSourceImpl(db);
      await saleSource.add(
        Sale(
          id: 's1',
          userId: 'u1',
          items: const [
            SaleItem(
              productId: 'p1',
              productName: 'Caneta',
              quantity: 1000,
              unitPriceCents: 200,
            ),
          ],
          totalAmountCents: 200,
          paymentMethod: PaymentMethod.cash,
          dateTime: DateTime(2026, 9, 5, 10),
        ),
      );

      final sales = await saleSource.getAll(storeId: 'st1');
      expect(sales.single.userId, 'u1');
    });
  });
}