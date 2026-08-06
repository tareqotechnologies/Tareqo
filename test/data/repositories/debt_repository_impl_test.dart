import 'package:flutter_test/flutter_test.dart';

import 'package:dumbhanengue/data/datasources/local/debt_local_data_source_impl.dart';
import 'package:dumbhanengue/data/repositories/debt_repository_impl.dart';
import 'package:dumbhanengue/domain/entities/debt.dart';

void main() {
  test('add persiste e getAll retorna a dívida', () async {
    final repository = DebtRepositoryImpl(DebtLocalDataSourceImpl());

    await repository.add(
      Debt(
        id: 'd1',
        personName: 'João',
        amountCents: 2500,
        dueDate: DateTime(2026, 8, 15),
        isCustomerDebt: true,
      ),
    );

    final debts = await repository.getAll(storeId: 'st1');

    expect(debts, hasLength(1));
    expect(debts.first.personName, 'João');
    expect(debts.first.isCustomerDebt, isTrue);
  });

  test('markAsPaid é escopado pela loja (id de outra loja não baixa)',
      () async {
    final repository = DebtRepositoryImpl(DebtLocalDataSourceImpl());

    await repository.add(
      Debt(
        id: 'd1',
        storeId: 'st1',
        personName: 'João',
        amountCents: 2500,
        dueDate: DateTime(2026, 8, 15),
        isCustomerDebt: true,
      ),
    );

    // Guarda: baixar pela loja errada falha e não muta nada.
    await expectLater(
      repository.markAsPaid('d1', storeId: 'st2'),
      throwsStateError,
    );
    expect(
      (await repository.getAll(storeId: 'st1')).single.isPaid,
      isFalse,
    );

    // Pela loja correta, funciona.
    await repository.markAsPaid('d1', storeId: 'st1');
    expect((await repository.getAll(storeId: 'st1')).single.isPaid, isTrue);
  });
}
