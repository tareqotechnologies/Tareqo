import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:dumbhanengue/data/datasources/local/debt_sqlite_data_source_impl.dart';
import 'package:dumbhanengue/domain/entities/debt.dart';

import '../../../helpers/test_sqlite.dart';

void main() {
  late Database db;

  setUp(() => db = openTestDatabase());
  tearDown(() => db.dispose());

  test('add persiste e getAll reconstrói a dívida (incl. booleanos)', () async {
    final dataSource = DebtSqliteDataSourceImpl(db);

    await dataSource.add(
      Debt(
        id: 'd1',
        personName: 'João',
        amount: 25.0,
        dueDate: DateTime(2026, 8, 15),
        isCustomerDebt: true,
        isPaid: true,
      ),
    );
    await dataSource.add(
      Debt(
        id: 'd2',
        personName: 'Distribuidora',
        amount: 120.0,
        dueDate: DateTime(2026, 8, 20),
        isCustomerDebt: false,
      ),
    );

    final debts = await dataSource.getAll(storeId: 'st1');

    expect(debts, hasLength(2));
    expect(debts.first.isCustomerDebt, isTrue);
    expect(debts.first.isPaid, isTrue);
    expect(debts.last.isCustomerDebt, isFalse);
    expect(debts.last.isPaid, isFalse);
    expect(debts.first.dueDate, DateTime(2026, 8, 15));
  });

  test('markAsPaid marca a dívida como paga e carimba a data da baixa',
      () async {
    final dataSource = DebtSqliteDataSourceImpl(db);

    await dataSource.add(
      Debt(
        id: 'd1',
        personName: 'João',
        amount: 25.0,
        dueDate: DateTime(2026, 8, 15),
        isCustomerDebt: true,
      ),
    );
    expect(
      (await dataSource.getAll(storeId: 'st1')).first.isPaid,
      isFalse,
    );
    expect(
      (await dataSource.getAll(storeId: 'st1')).first.paidAt,
      isNull,
    );

    await dataSource.markAsPaid('d1', storeId: 'st1');

    final settled = (await dataSource.getAll(storeId: 'st1')).first;
    expect(settled.isPaid, isTrue);
    // Data da baixa carimbada (histórico de quitações).
    expect(settled.paidAt, isNotNull);
  });

  test('add persiste e reconstrói a data da baixa (paidAt)', () async {
    final dataSource = DebtSqliteDataSourceImpl(db);

    await dataSource.add(
      Debt(
        id: 'd1',
        personName: 'Ana',
        amount: 40.0,
        dueDate: DateTime(2026, 7, 15),
        isCustomerDebt: true,
        isPaid: true,
        paidAt: DateTime(2026, 8, 3, 10, 30),
      ),
    );

    final settled = (await dataSource.getAll(storeId: 'st1')).first;
    expect(settled.isPaid, isTrue);
    expect(settled.paidAt, DateTime(2026, 8, 3, 10, 30));
  });

  test('markAsPaid lança StateError para dívida inexistente', () async {
    final dataSource = DebtSqliteDataSourceImpl(db);

    await expectLater(
      dataSource.markAsPaid('nope', storeId: 'st1'),
      throwsStateError,
    );
  });
}
