import 'package:flutter_test/flutter_test.dart';

import 'package:dumbhanengue/domain/entities/financial_transaction.dart';
import 'package:dumbhanengue/domain/repositories/i_financial_transaction_repository.dart';
import 'package:dumbhanengue/domain/usecases/get_cash_flow_use_case.dart';

/// Fake que simula a consulta por período (como o SQL faria).
class _FakeFinancialTransactionRepository
    implements IFinancialTransactionRepository {
  _FakeFinancialTransactionRepository(this._allTransactions);

  final List<FinancialTransaction> _allTransactions;

  @override
  Future<List<FinancialTransaction>> getByPeriod({
    required String storeId,
    required DateTime start,
    required DateTime end,
  }) async {
    return _allTransactions
        .where((t) => !t.date.isBefore(start) && !t.date.isAfter(end))
        .toList();
  }

  @override
  Future<List<FinancialTransaction>> getAll({required String storeId}) async =>
      List.unmodifiable(_allTransactions);

  @override
  Future<void> add(FinancialTransaction transaction) async {
    _allTransactions.add(transaction);
  }

  @override
  Future<void> markAsPaid(String id, {required String storeId}) async {
    final index = _allTransactions.indexWhere((t) => t.id == id);
    _allTransactions[index] = _allTransactions[index].copyWith(
      status: TransactionStatus.paid,
    );
  }
}

FinancialTransaction _transaction(
  String id, {
  required String description,
  required double amount,
  required TransactionType type,
  String category = 'vendas',
  required DateTime date,
  TransactionStatus status = TransactionStatus.paid,
}) {
  return FinancialTransaction(
    id: id,
    description: description,
    amount: amount,
    type: type,
    category: category,
    date: date,
    status: status,
  );
}

void main() {
  final august = DateTime.utc(2026, 8, 3);
  final july = DateTime.utc(2026, 7, 15);
  final september = DateTime.utc(2026, 9, 1);

  test('calcula o saldo = entradas − saídas no período', () async {
    final repository = _FakeFinancialTransactionRepository([
      _transaction(
        '1',
        description: 'Venda',
        amount: 1000,
        type: TransactionType.income,
        date: august,
      ),
      _transaction(
        '2',
        description: 'Venda',
        amount: 500,
        type: TransactionType.income,
        date: august,
      ),
      _transaction(
        '3',
        description: 'Aluguel',
        amount: 300,
        type: TransactionType.expense,
        date: august,
      ),
      _transaction(
        '4',
        description: 'Energia elétrica',
        amount: 150,
        type: TransactionType.expense,
        date: august,
      ),
    ]);
    final useCase = GetCashFlowUseCase(repository);

    final result = await useCase.call(
      storeId: 'st1',
      start: august,
      end: august,
    );

    expect(result.income, 1500);
    expect(result.expense, 450);
    expect(result.balance, 1050);
  });

  test('ignora transações fora do período consultado', () async {
    final repository = _FakeFinancialTransactionRepository([
      _transaction(
        '1',
        description: 'Venda julho',
        amount: 2000,
        type: TransactionType.income,
        date: july,
      ),
      _transaction(
        '2',
        description: 'Venda agosto',
        amount: 1000,
        type: TransactionType.income,
        date: august,
      ),
      _transaction(
        '3',
        description: 'Aluguel setembro',
        amount: 400,
        type: TransactionType.expense,
        date: september,
      ),
    ]);
    final useCase = GetCashFlowUseCase(repository);

    final result = await useCase.call(
      storeId: 'st1',
      start: august,
      end: august,
    );

    // Apenas a transação de agosto entra no cálculo.
    expect(result.income, 1000);
    expect(result.expense, 0);
    expect(result.balance, 1000);
  });

  test('período sem transações resulta em saldo zero', () async {
    final repository = _FakeFinancialTransactionRepository(const []);
    final useCase = GetCashFlowUseCase(repository);

    final result = await useCase.call(
      storeId: 'st1',
      start: august,
      end: august,
    );

    expect(result.income, 0);
    expect(result.expense, 0);
    expect(result.balance, 0);
  });

  test(
    'ignora transações pendentes (fiado não infla o caixa realizado)',
    () async {
      final repository = _FakeFinancialTransactionRepository([
        _transaction(
          '1',
          description: 'Venda à vista',
          amount: 1000,
          type: TransactionType.income,
          date: august,
        ),
        _transaction(
          '2',
          description: 'Venda fiada (pendente)',
          amount: 500,
          type: TransactionType.income,
          date: august,
          status: TransactionStatus.pending,
        ),
      ]);
      final useCase = GetCashFlowUseCase(repository);

      final result = await useCase.call(
        storeId: 'st1',
        start: august,
        end: august,
      );

      expect(result.income, 1000);
      expect(result.expense, 0);
      expect(result.balance, 1000);
    },
  );

  test('lança InvalidPeriodException quando start é posterior a end', () async {
    final repository = _FakeFinancialTransactionRepository(const []);
    final useCase = GetCashFlowUseCase(repository);

    await expectLater(
      useCase.call(storeId: 'st1', start: august, end: july),
      throwsA(isA<InvalidPeriodException>()),
    );
  });

  test('rejeita amount negativo (invariante da entidade)', () {
    expect(
      () => _transaction(
        'x',
        description: 'Inválida',
        amount: -5,
        type: TransactionType.income,
        date: august,
      ),
      throwsAssertionError,
    );
  });

  test('acúmulo exato em centavos (regressão auditoria H1)', () async {
    // 3 × 9.9 em double acumula 29.700000000000003; o fluxo deve somar
    // centavos e devolver 29.7 exato.
    final repository = _FakeFinancialTransactionRepository([
      for (var i = 0; i < 3; i++)
        _transaction(
          'c$i',
          description: 'Venda',
          amount: 9.9,
          type: TransactionType.income,
          date: august,
        ),
    ]);
    final useCase = GetCashFlowUseCase(repository);

    final result = await useCase.call(
      storeId: 'st1',
      start: august,
      end: august,
    );

    expect(result.income, 29.7);
    expect(result.income, closeTo(29.7, 0.0000001));
    expect(result.balance, 29.7);
  });
}
