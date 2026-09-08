import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/domain/entities/financial_transaction.dart';
import 'package:tareqo/domain/repositories/i_cash_flow_repository.dart';
import 'package:tareqo/domain/repositories/i_financial_transaction_repository.dart';
import 'package:tareqo/domain/usecases/get_cash_flow_use_case.dart';

/// Fake que simula a consulta por período (como o SQL faria).
/// Fake do repositório de agregação server-side (H2) — simula a RPC.
class _FakeCashFlowRepository implements ICashFlowRepository {
  _FakeCashFlowRepository(this._handler);

  final CashFlow Function(String storeId, DateTime start, DateTime end)
  _handler;

  @override
  Future<CashFlow> fetchCashFlow({
    required String storeId,
    required DateTime start,
    required DateTime end,
  }) async => _handler(storeId, start, end);
}

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
  required int amountCents,
  required TransactionType type,
  String category = 'vendas',
  required DateTime date,
  TransactionStatus status = TransactionStatus.paid,
}) {
  return FinancialTransaction(
    id: id,
    description: description,
    amountCents: amountCents,
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
        amountCents: 100000,
        type: TransactionType.income,
        date: august,
      ),
      _transaction(
        '2',
        description: 'Venda',
        amountCents: 50000,
        type: TransactionType.income,
        date: august,
      ),
      _transaction(
        '3',
        description: 'Aluguel',
        amountCents: 30000,
        type: TransactionType.expense,
        date: august,
      ),
      _transaction(
        '4',
        description: 'Energia elétrica',
        amountCents: 15000,
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

    expect(result.incomeCents, 150000);
    expect(result.expenseCents, 45000);
    expect(result.balanceCents, 105000);
  });

  test('ignora transações fora do período consultado', () async {
    final repository = _FakeFinancialTransactionRepository([
      _transaction(
        '1',
        description: 'Venda julho',
        amountCents: 200000,
        type: TransactionType.income,
        date: july,
      ),
      _transaction(
        '2',
        description: 'Venda agosto',
        amountCents: 100000,
        type: TransactionType.income,
        date: august,
      ),
      _transaction(
        '3',
        description: 'Aluguel setembro',
        amountCents: 40000,
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
    expect(result.incomeCents, 100000);
    expect(result.expenseCents, 0);
    expect(result.balanceCents, 100000);
  });

  test('período sem transações resulta em saldo zero', () async {
    final repository = _FakeFinancialTransactionRepository(const []);
    final useCase = GetCashFlowUseCase(repository);

    final result = await useCase.call(
      storeId: 'st1',
      start: august,
      end: august,
    );

    expect(result.incomeCents, 0);
    expect(result.expenseCents, 0);
    expect(result.balanceCents, 0);
  });

  test(
    'ignora transações pendentes (fiado não infla o caixa realizado)',
    () async {
      final repository = _FakeFinancialTransactionRepository([
        _transaction(
          '1',
          description: 'Venda à vista',
          amountCents: 100000,
          type: TransactionType.income,
          date: august,
        ),
        _transaction(
          '2',
          description: 'Venda fiada (pendente)',
          amountCents: 50000,
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

      expect(result.incomeCents, 100000);
      expect(result.expenseCents, 0);
      expect(result.balanceCents, 100000);
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
        amountCents: -500,
        type: TransactionType.income,
        date: august,
      ),
      throwsAssertionError,
    );
  });

  test('delega para o repositório server-side quando fornecido (H2)', () async {
    // Fake do ICashFlowRepository: simula a RPC get_cash_flow.
    final serverCalls = <String>[];
    final useCase = GetCashFlowUseCase(
      _FakeFinancialTransactionRepository(const []),
      serverRepository: _FakeCashFlowRepository((storeId, start, end) {
        serverCalls.add(storeId);
        return const CashFlow(incomeCents: 1111, expenseCents: 222);
      }),
    );

    final result = await useCase.call(
      storeId: 'st1',
      start: august,
      end: august,
    );

    // Uma única chamada ao servidor; nenhum cálculo local.
    expect(serverCalls, ['st1']);
    expect(result.incomeCents, 1111);
    expect(result.expenseCents, 222);
    expect(result.balanceCents, 889);
  });

  test('acúmulo exato em centavos (regressão auditoria H1)', () async {
    // 3 × 9.9 em double acumula 29.700000000000003; o fluxo deve somar
    // centavos e devolver 29.7 exato.
    final repository = _FakeFinancialTransactionRepository([
      for (var i = 0; i < 3; i++)
        _transaction(
          'c$i',
          description: 'Venda',
          amountCents: 990,
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

    expect(result.incomeCents, 2970);
    expect(result.balanceCents, 2970);
  });
}
