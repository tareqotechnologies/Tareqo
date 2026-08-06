import 'package:flutter_test/flutter_test.dart';

import 'package:dumbhanengue/domain/entities/debt.dart';
import 'package:dumbhanengue/domain/repositories/i_debt_repository.dart';
import 'package:dumbhanengue/domain/usecases/get_settled_debts_use_case.dart';

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
    _debts[index] = _debts[index].copyWith(
      isPaid: true,
      paidAt: DateTime(2026, 8, 20),
    );
  }
}

Debt _debt(
  String id, {
  required bool isCustomerDebt,
  required bool isPaid,
}) =>
    Debt(
      id: id,
      personName: 'Pessoa $id',
      amountCents: 2500,
      dueDate: DateTime(2026, 8, 15),
      isCustomerDebt: isCustomerDebt,
      isPaid: isPaid,
      paidAt: isPaid ? DateTime(2026, 8, 20) : null,
    );

void main() {
  test('retorna apenas dívidas de clientes JÁ quitadas', () async {
    final repository = _FakeDebtRepository([
      _debt('d1', isCustomerDebt: true, isPaid: true),
      _debt('d2', isCustomerDebt: true, isPaid: false), // pendente — fora
      _debt('d3', isCustomerDebt: false, isPaid: true), // fornecedor — fora
      _debt('d4', isCustomerDebt: false, isPaid: false), // fora
    ]);
    final useCase = GetSettledDebtsUseCase(repository);

    final settled = await useCase(storeId: 'st1');

    expect(settled.map((d) => d.id), ['d1']);
    expect(settled.first.paidAt, DateTime(2026, 8, 20));
  });

  test('retorna lista vazia quando nada foi quitado', () async {
    final repository = _FakeDebtRepository([
      _debt('d1', isCustomerDebt: true, isPaid: false),
    ]);
    final useCase = GetSettledDebtsUseCase(repository);

    expect(await useCase(storeId: 'st1'), isEmpty);
  });
}
