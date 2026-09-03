import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/domain/entities/debt.dart';
import 'package:tareqo/domain/entities/financial_transaction.dart';
import 'package:tareqo/domain/repositories/i_debt_processor.dart';
import 'package:tareqo/domain/repositories/i_debt_repository.dart';
import 'package:tareqo/domain/repositories/i_financial_transaction_repository.dart';
import 'package:tareqo/domain/usecases/add_debt_use_case.dart';

class _FakeDebtRepository implements IDebtRepository {
 final List<Debt> items = [];

 @override
 Future<List<Debt>> getAll({required String storeId}) async =>
 List.unmodifiable(items);

 @override
 Future<void> add(Debt debt) async {
 items.add(debt);
 }

 @override
 Future<void> markAsPaid(String id, {required String storeId}) async {
 final index = items.indexWhere((debt) => debt.id == id);
 if (index == -1) {
 throw StateError('Dívida $id não encontrada para baixa.');
 }
 items[index] = items[index].copyWith(isPaid: true);
 }
}

class _FakeTransactionRepository implements IFinancialTransactionRepository {
 final List<FinancialTransaction> transactions = [];

 /// Simula falha isolada na gravação da pendência.
 bool failOnAdd = false;

 @override
 Future<List<FinancialTransaction>> getAll({required String storeId}) async =>
 List.unmodifiable(transactions);

 @override
 Future<List<FinancialTransaction>> getByPeriod({
 required String storeId,
 required DateTime start,
 required DateTime end,
 }) async =>
 List.unmodifiable(transactions);

 @override
 Future<void> add(FinancialTransaction transaction) async {
 if (failOnAdd) throw StateError('falha simulada na gravação da pendência');
 transactions.add(transaction);
 }

 @override
 Future<void> markAsPaid(String id, {required String storeId}) async {
 final index = transactions.indexWhere((t) => t.id == id);
 transactions[index] =
 transactions[index].copyWith(status: TransactionStatus.paid);
 }
}

/// Fake do processador atômico (Supabase via RPC) — conta as chamadas.
class _FakeDebtProcessor implements IDebtAtomicProcessor {
 int calls = 0;
 Debt? lastDebt;

 @override
 Future<void> register(Debt debt) async {
 calls++;
 lastDebt = debt;
 }

 @override
 Future<void> settle(String debtId, {required String storeId}) async {
 // Não usado nos testes de registro.
 }
}

Debt _debt(int amountCents, {bool isCustomerDebt = true}) => Debt(
 id: 'd1',
 personName: 'João',
 amountCents: amountCents,
 dueDate: DateTime(2026, 8, 15),
 isCustomerDebt: isCustomerDebt,
 );

void main() {
 test('registra a dívida e cria a pendência financeira vinculada',
 () async {
 final repository = _FakeDebtRepository();
 final transactions = _FakeTransactionRepository();
 final useCase = AddDebtUseCase(repository, transactions);

 await useCase(_debt(2500));

 expect(repository.items, hasLength(1));
 expect(repository.items.first.amountCents, 2500);

 // O livro reflete o fiado desde o início: entrada PENDENTE vinculada.
 expect(transactions.transactions, hasLength(1));
 final entry = transactions.transactions.first;
 expect(entry.amountCents, 2500);
 expect(entry.type, TransactionType.income);
 expect(entry.status, TransactionStatus.pending);
 expect(entry.category, 'Fiado');
 expect(entry.debtId, 'd1');
 expect(entry.description, contains('João'));
 });

 test('dívida a pagar (fornecedor) cria pendência de SAÍDA', () async {
 final repository = _FakeDebtRepository();
 final transactions = _FakeTransactionRepository();
 final useCase = AddDebtUseCase(repository, transactions);

 await useCase(_debt(12000, isCustomerDebt: false));

 final entry = transactions.transactions.first;
 expect(entry.type, TransactionType.expense);
 expect(entry.status, TransactionStatus.pending);
 expect(entry.debtId, 'd1');
 });

 test('rejeita valor zero e NÃO persiste nada', () async {
 final repository = _FakeDebtRepository();
 final transactions = _FakeTransactionRepository();
 final useCase = AddDebtUseCase(repository, transactions);

 await expectLater(
 useCase(_debt(0)),
 throwsA(isA<InvalidDebtAmountException>()),
 );

 expect(repository.items, isEmpty);
 expect(transactions.transactions, isEmpty);
 });

 test('falha da pendência lança PendingEntryRegistrationException e '
 'mantém a dívida registrada', () async {
 final repository = _FakeDebtRepository();
 final transactions = _FakeTransactionRepository()..failOnAdd = true;
 final useCase = AddDebtUseCase(repository, transactions);

 await expectLater(
 useCase(_debt(25)),
 throwsA(isA<PendingEntryRegistrationException>()),
 );

 // A dívida foi persistida (só a pendência falhou) — a UI deve
 // orientar a conferir o Financeiro, não a tentar novamente.
 expect(repository.items, hasLength(1));
 expect(transactions.transactions, isEmpty);
 });

 test('delega para o processador atômico quando fornecido (Supabase)',
 () async {
 final processor = _FakeDebtProcessor();
 final repository = _FakeDebtRepository();
 final transactions = _FakeTransactionRepository();
 final useCase = AddDebtUseCase(
 repository,
 transactions,
 processor: processor,
 );

 final debt = _debt(2500);
 await useCase(debt);

 // O caminho composto NÃO roda — o servidor grava dívida + pendência
 // em uma única transação.
 expect(processor.calls, 1);
 expect(processor.lastDebt?.id, debt.id);
 expect(repository.items, isEmpty);
 expect(transactions.transactions, isEmpty);
 });

 test('validação continua valendo com processador atômico', () async {
 final processor = _FakeDebtProcessor();
 final useCase = AddDebtUseCase(
 _FakeDebtRepository(),
 _FakeTransactionRepository(),
 processor: processor,
 );

 await expectLater(
 useCase(_debt(0)),
 throwsA(isA<InvalidDebtAmountException>()),
 );
 expect(processor.calls, 0);
 });
}
