import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

import 'package:dumbhanengue/domain/entities/financial_transaction.dart';
import 'package:dumbhanengue/domain/repositories/i_financial_transaction_repository.dart';
import 'package:dumbhanengue/domain/usecases/get_cash_flow_use_case.dart';
import 'package:dumbhanengue/domain/usecases/mark_transaction_as_paid_use_case.dart';
import 'package:dumbhanengue/presentation/controllers/finance_providers.dart';
import 'package:dumbhanengue/presentation/screens/financial/financial_screen.dart';

import '../../helpers/store_context.dart';

class _FakeFinanceRepository implements IFinancialTransactionRepository {
  _FakeFinanceRepository(this._transactions);

  final List<FinancialTransaction> _transactions;

  @override
  Future<List<FinancialTransaction>> getByPeriod({
    required String storeId,
    required DateTime start,
    required DateTime end,
  }) async {
    return _transactions
        .where((t) => !t.date.isBefore(start) && !t.date.isAfter(end))
        .toList();
  }

  @override
  Future<List<FinancialTransaction>> getAll({required String storeId}) async =>
      List.unmodifiable(_transactions);

  @override
  Future<void> add(FinancialTransaction transaction) async {
    _transactions.add(transaction);
  }

  @override
  Future<void> markAsPaid(String id, {required String storeId}) async {
    final index = _transactions.indexWhere((t) => t.id == id);
    _transactions[index] =
        _transactions[index].copyWith(status: TransactionStatus.paid);
  }
}

class _FakeGetCashFlowUseCase implements GetCashFlowUseCase {
  @override
  Future<CashFlow> call({
    required String storeId,
    required DateTime start,
    required DateTime end,
  }) async =>
      const CashFlow(income: 1500, expense: 450);
}

class _FakeMarkTransactionAsPaidUseCase implements MarkTransactionAsPaidUseCase {
  _FakeMarkTransactionAsPaidUseCase(this._repository);

  final _FakeFinanceRepository _repository;

  @override
  Future<void> call(String transactionId, {required String storeId}) =>
      _repository.markAsPaid(transactionId, storeId: storeId);
}

Widget _buildApp(_FakeFinanceRepository repository) {
  return ProviderScope(
    overrides: [
      // Contexto de loja — o Financeiro escopa pela loja ativa.
      ...storeContextOverrides(),
      financeRepositoryProvider.overrideWithValue(repository),
      getCashFlowUseCaseProvider.overrideWithValue(_FakeGetCashFlowUseCase()),
      markTransactionAsPaidUseCaseProvider.overrideWithValue(
        _FakeMarkTransactionAsPaidUseCase(repository),
      ),
    ],
    child: testApp(home: FinancialScreen()),
  );
}

void main() {
  testWidgets('mostra entradas, saídas, saldo e as movimentações',
      (tester) async {
    final now = DateTime(2026, 8, 3, 10);
    await tester.pumpWidget(
      _buildApp(
        _FakeFinanceRepository([
          FinancialTransaction(
            id: 't1',
            description: 'Venda PIX',
            amount: 1000,
            type: TransactionType.income,
            category: 'Vendas',
            date: now,
          ),
          FinancialTransaction(
            id: 't2',
            description: 'Aluguel da loja',
            amount: 200,
            type: TransactionType.expense,
            category: 'Contas',
            date: now,
          ),
          FinancialTransaction(
            id: 't3',
            description: 'Venda fiado (João)',
            amount: 25,
            type: TransactionType.income,
            category: 'Fiado',
            date: now,
            status: TransactionStatus.pending,
          ),
        ]),
      ),
    );

    await tester.pumpAndSettle();

    // KPIs do fluxo de caixa (vindos do use case fake).
    expect(find.text('Entradas'), findsOneWidget);
    expect(find.text('Saídas'), findsOneWidget);
    expect(find.text('Saldo'), findsOneWidget);
    expect(find.text('R\$ 1.500,00'), findsOneWidget);
    expect(find.text('R\$ 450,00'), findsOneWidget);
    expect(find.text('R\$ 1.050,00'), findsOneWidget);

    // Movimentações.
    expect(find.text('Venda PIX'), findsOneWidget);
    expect(find.text('Aluguel da loja'), findsOneWidget);
    expect(find.text('Venda fiado (João)'), findsOneWidget);
    expect(find.text('Pendente'), findsOneWidget);
    // Entrada pendente oferece o recebimento.
    expect(find.text('Receber'), findsOneWidget);
  });

  testWidgets('botão Receber marca a entrada pendente como paga',
      (tester) async {
    final now = DateTime(2026, 8, 3, 10);
    final repository = _FakeFinanceRepository([
      FinancialTransaction(
        id: 't3',
        description: 'Venda fiado (João)',
        amount: 25,
        type: TransactionType.income,
        category: 'Fiado',
        date: now,
        status: TransactionStatus.pending,
      ),
    ]);
    await tester.pumpWidget(_buildApp(repository));
    await tester.pumpAndSettle();

    expect(find.text('Pendente'), findsOneWidget);

    // Abre a confirmação.
    await tester.tap(find.text('Receber'));
    await tester.pumpAndSettle();
    expect(find.text('Receber pendência?'), findsOneWidget);

    // Confirma o recebimento.
    await tester.tap(find.widgetWithText(FilledButton, 'Receber'));
    await tester.pumpAndSettle();

    expect(find.text('Movimentação recebida!'), findsOneWidget);

    // Após invalidar, a transação está paga — o chip 'Pendente' some.
    expect(find.text('Pendente'), findsNothing);
  });
}
