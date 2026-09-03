import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/domain/entities/financial_transaction.dart';
import 'package:tareqo/domain/repositories/i_financial_transaction_repository.dart';
import 'package:tareqo/domain/usecases/add_financial_transaction_use_case.dart';

class _FakeFinancialTransactionRepository
 implements IFinancialTransactionRepository {
 final List<FinancialTransaction> items = [];

 @override
 Future<List<FinancialTransaction>> getByPeriod({
 required String storeId,
 required DateTime start,
 required DateTime end,
 }) async =>
 items;

 @override
 Future<List<FinancialTransaction>> getAll({required String storeId}) async =>
 List.unmodifiable(items);

 @override
 Future<void> add(FinancialTransaction transaction) async {
 items.add(transaction);
 }

 @override
 Future<void> markAsPaid(String id, {required String storeId}) async {
 final index = items.indexWhere((t) => t.id == id);
 items[index] =
 items[index].copyWith(status: TransactionStatus.paid);
 }
}

FinancialTransaction _transaction(int amountCents) => FinancialTransaction(
 id: 't1',
 description: 'Venda',
 amountCents: amountCents,
 type: TransactionType.income,
 category: 'Vendas',
 date: DateTime(2026, 8, 3),
 );

void main() {
 test('registra uma transação com valor válido', () async {
 final repository = _FakeFinancialTransactionRepository();
 final useCase = AddFinancialTransactionUseCase(repository);

 await useCase(_transaction(10000));

 expect(repository.items, hasLength(1));
 expect(repository.items.first.amountCents, 10000);
 });

 test('rejeita valor zero e NÃO persiste', () async {
 final repository = _FakeFinancialTransactionRepository();
 final useCase = AddFinancialTransactionUseCase(repository);

 await expectLater(
 useCase(_transaction(0)),
 throwsA(isA<InvalidAmountException>()),
 );

 expect(repository.items, isEmpty);
 });
}
