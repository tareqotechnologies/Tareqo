import 'package:flutter_test/flutter_test.dart';

import 'package:dumbhanengue/domain/entities/debt.dart';
import 'package:dumbhanengue/domain/repositories/i_debt_repository.dart';
import 'package:dumbhanengue/domain/usecases/get_pending_debts_use_case.dart';

class _FakeDebtRepository implements IDebtRepository {
  _FakeDebtRepository(this._debts);

  final List<Debt> _debts;

  @override
  Future<List<Debt>> getAll({required String storeId}) async =>
      List.unmodifiable(_debts);

  @override
  Future<void> add(Debt debt) async {
    _debts.add(debt);
  }

  @override
  Future<void> markAsPaid(String id, {required String storeId}) async {
    final index = _debts.indexWhere((debt) => debt.id == id);
    _debts[index] = _debts[index].copyWith(isPaid: true);
  }
}

Debt _debt(
  String id, {
  required String personName,
  required double amount,
  required bool isCustomerDebt,
}) {
  return Debt(
    id: id,
    personName: personName,
    amount: amount,
    dueDate: DateTime.utc(2026, 8, 15),
    isCustomerDebt: isCustomerDebt,
  );
}

void main() {
  test('retorna apenas as dívidas a receber de clientes', () async {
    final repository = _FakeDebtRepository([
      _debt('1', personName: 'Maria', amount: 120.0, isCustomerDebt: true),
      _debt('2', personName: 'João', amount: 45.5, isCustomerDebt: true),
      _debt(
        '3',
        personName: 'Fornecedor ABC',
        amount: 300.0,
        isCustomerDebt: false,
      ),
    ]);
    final useCase = GetPendingDebtsUseCase(repository);

    final pending = await useCase(storeId: 'st1');

    expect(pending, hasLength(2));
    expect(pending.map((d) => d.personName), containsAll(['Maria', 'João']));
    // O fornecedor (a pagar) fica de fora.
    expect(pending.map((d) => d.personName), isNot(contains('Fornecedor ABC')));
  });

  test('retorna lista vazia quando não há dívidas de clientes', () async {
    final repository = _FakeDebtRepository([
      _debt(
        '3',
        personName: 'Fornecedor ABC',
        amount: 300.0,
        isCustomerDebt: false,
      ),
    ]);
    final useCase = GetPendingDebtsUseCase(repository);

    final pending = await useCase(storeId: 'st1');

    expect(pending, isEmpty);
  });

  test('retorna lista vazia quando não há dívidas registradas', () async {
    final useCase = GetPendingDebtsUseCase(_FakeDebtRepository(const []));

    expect(await useCase(storeId: 'st1'), isEmpty);
  });

  test('exclui dívidas já quitadas do que está a receber', () async {
    final repository = _FakeDebtRepository([
      _debt(
        '1',
        personName: 'Maria',
        amount: 120.0,
        isCustomerDebt: true,
      ).copyWith(isPaid: true),
      _debt('2', personName: 'João', amount: 45.5, isCustomerDebt: true),
    ]);
    final useCase = GetPendingDebtsUseCase(repository);

    final pending = await useCase(storeId: 'st1');

    expect(pending, hasLength(1));
    expect(pending.first.personName, 'João');
  });
}
