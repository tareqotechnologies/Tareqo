import 'package:flutter_test/flutter_test.dart';

import 'package:dumbhanengue/domain/entities/financial_transaction.dart';

void main() {
 test('status padrão é pago quando não informado', () {
 final transaction = FinancialTransaction(
 id: '1',
 description: 'Venda à vista',
 amountCents: 5000,
 type: TransactionType.income,
 category: 'vendas',
 date: DateTime.utc(2026, 8, 3),
 );

 expect(transaction.status, TransactionStatus.paid);
 });

 test('transação "fiada" pode ser marcada como pendente', () {
 final transaction = FinancialTransaction(
 id: '2',
 description: 'Venda fiada',
 amountCents: 8000,
 type: TransactionType.income,
 category: 'vendas',
 date: DateTime.utc(2026, 8, 3),
 status: TransactionStatus.pending,
 );

 expect(transaction.status, TransactionStatus.pending);
 });

 test('status é preservado no round-trip JSON', () {
 final transaction = FinancialTransaction(
 id: '2',
 description: 'Venda fiada',
 amountCents: 8000,
 type: TransactionType.income,
 category: 'vendas',
 date: DateTime.utc(2026, 8, 3),
 status: TransactionStatus.pending,
 );

 final restored = FinancialTransaction.fromJson(transaction.toJson());

 expect(restored, transaction);
 expect(restored.status, TransactionStatus.pending);
 expect(transaction.toJson()['status'], 'pending');
 });
}
