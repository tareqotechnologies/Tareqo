import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:dumbhanengue/data/datasources/local/financial_transaction_sqlite_data_source_impl.dart';
import 'package:dumbhanengue/domain/entities/financial_transaction.dart';

import '../../../helpers/test_sqlite.dart';

void main() {
  late Database db;

  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  test('add persiste e getAll reconstrói enums, data e valor', () async {
    final dataSource = FinancialTransactionSqliteDataSourceImpl(db);

    await dataSource.add(
      FinancialTransaction(
        id: 't1',
        description: 'Energia elétrica',
        amountCents: 18000,
        type: TransactionType.expense,
        category: 'Contas',
        date: DateTime(2026, 8, 3, 9, 15),
        status: TransactionStatus.pending,
      ),
    );

    final transactions = await dataSource.getAll(storeId: 'st1');

    expect(transactions, hasLength(1));
    final transaction = transactions.first;
    expect(transaction.id, 't1');
    expect(transaction.description, 'Energia elétrica');
    expect(transaction.amountCents, 18000);
    expect(transaction.type, TransactionType.expense);
    expect(transaction.category, 'Contas');
    expect(transaction.date, DateTime(2026, 8, 3, 9, 15));
    expect(transaction.status, TransactionStatus.pending);
  });

  test('default do status (paid) é persistido corretamente', () async {
    final dataSource = FinancialTransactionSqliteDataSourceImpl(db);

    await dataSource.add(
      FinancialTransaction(
        id: 't2',
        description: 'Venda',
        amountCents: 5000,
        type: TransactionType.income,
        category: 'Vendas',
        date: DateTime(2026, 8, 3),
      ),
    );

    expect(
      (await dataSource.getAll(storeId: 'st1')).first.status,
      TransactionStatus.paid,
    );
  });

  test('persiste e reconstrói o vínculo debtId (fiado)', () async {
    final dataSource = FinancialTransactionSqliteDataSourceImpl(db);

    await dataSource.add(
      FinancialTransaction(
        id: 't3',
        description: 'Venda fiado (João)',
        amountCents: 2500,
        type: TransactionType.income,
        category: 'Fiado',
        date: DateTime(2026, 8, 3),
        status: TransactionStatus.pending,
        debtId: 'd1',
      ),
    );

    final transaction = (await dataSource.getAll(storeId: 'st1')).first;

    expect(transaction.status, TransactionStatus.pending);
    expect(transaction.debtId, 'd1');
  });

  test('markAsPaid marca a transação pendente como paga', () async {
    final dataSource = FinancialTransactionSqliteDataSourceImpl(db);

    await dataSource.add(
      FinancialTransaction(
        id: 't1',
        description: 'Venda fiado',
        amountCents: 2500,
        type: TransactionType.income,
        category: 'Fiado',
        date: DateTime(2026, 8, 3),
        status: TransactionStatus.pending,
      ),
    );

    await dataSource.markAsPaid('t1', storeId: 'st1');

    expect(
      (await dataSource.getAll(storeId: 'st1')).first.status,
      TransactionStatus.paid,
    );
  });

  test('markAsPaid lança StateError para transação inexistente', () async {
    final dataSource = FinancialTransactionSqliteDataSourceImpl(db);

    await expectLater(
      dataSource.markAsPaid('nope', storeId: 'st1'),
      throwsStateError,
    );
  });
}
