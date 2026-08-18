import 'package:flutter_test/flutter_test.dart';

import 'package:dumbhanengue/data/datasources/local/financial_transaction_local_data_source_impl.dart';
import 'package:dumbhanengue/data/repositories/financial_transaction_repository_impl.dart';
import 'package:dumbhanengue/domain/entities/financial_transaction.dart';

FinancialTransaction _transaction(String id, DateTime date) =>
 FinancialTransaction(
 id: id,
 description: 'Movimento $id',
 amountCents: 1000,
 type: TransactionType.income,
 category: 'Vendas',
 date: date,
 );

void main() {
 test('getByPeriod filtra inclusivo pelas datas informadas', () async {
 final repository = FinancialTransactionRepositoryImpl(
 FinancialTransactionLocalDataSourceImpl(seed: [
 _transaction('1', DateTime(2026, 8, 1)),
 _transaction('2', DateTime(2026, 8, 15)),
 _transaction('3', DateTime(2026, 8, 31)),
 _transaction('4', DateTime(2026, 9, 1)),
 ]),
 );

 final period = await repository.getByPeriod(
 storeId: 'st1',
 start: DateTime(2026, 8, 1),
 end: DateTime(2026, 8, 31),
 );

 // Inclui os extremos (1 e 31) e exclui setembro.
 expect(period.map((t) => t.id), containsAll(['1', '2', '3']));
 expect(period, hasLength(3));
 });

 test('add persiste e getAll retorna a transação', () async {
 final repository = FinancialTransactionRepositoryImpl(
 FinancialTransactionLocalDataSourceImpl(),
 );

 await repository.add(_transaction('x', DateTime(2026, 8, 3)));

 final all = await repository.getAll(storeId: 'st1');

 expect(all, hasLength(1));
 expect(all.first.id, 'x');
 });

 test('markAsPaid marca a transação pendente como paga', () async {
 final repository = FinancialTransactionRepositoryImpl(
 FinancialTransactionLocalDataSourceImpl(seed: [
 _transaction('x', DateTime(2026, 8, 3))
 .copyWith(status: TransactionStatus.pending),
 ]),
 );

 await repository.markAsPaid('x', storeId: 'st1');

 expect(
 (await repository.getAll(storeId: 'st1')).first.status,
 TransactionStatus.paid,
 );
 });

 test('markAsPaid lança StateError para transação inexistente', () async {
 final repository = FinancialTransactionRepositoryImpl(
 FinancialTransactionLocalDataSourceImpl(),
 );

 await expectLater(
 repository.markAsPaid('nope', storeId: 'st1'),
 throwsStateError,
 );
 });

 test('markAsPaid é escopado pela loja (id de outra loja não baixa)',
 () async {
 final repository = FinancialTransactionRepositoryImpl(
 FinancialTransactionLocalDataSourceImpl(seed: [
 _transaction('x', DateTime(2026, 8, 3))
 .copyWith(storeId: 'st1', status: TransactionStatus.pending),
 ]),
 );

 // Guarda: baixar pela loja errada falha e não muta nada.
 await expectLater(
 repository.markAsPaid('x', storeId: 'st2'),
 throwsStateError,
 );
 expect(
 (await repository.getAll(storeId: 'st1')).single.status,
 TransactionStatus.pending,
 );

 // Pela loja correta, funciona.
 await repository.markAsPaid('x', storeId: 'st1');
 expect(
 (await repository.getAll(storeId: 'st1')).single.status,
 TransactionStatus.paid,
 );
 });
}
