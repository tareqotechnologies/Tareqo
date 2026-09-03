import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/domain/entities/debt.dart';

void main() {
 final debt = Debt(
 id: 'DIVIDA-001',
 number: 42,
 storeId: 'st2',
 personName: 'João da Silva',
 amountCents: 2500,
 dueDate: DateTime.utc(2026, 8, 15),
 isCustomerDebt: true,
 isPaid: true,
 paidAt: DateTime.utc(2026, 8, 3, 10, 30),
 customerId: 'c1',
 );

 test('toJson/fromJson preserva todos os campos (round-trip)', () {
 final restored = Debt.fromJson(debt.toJson());

 expect(restored, debt);
 expect(restored.personName, 'João da Silva');
 expect(restored.storeId, 'st2');
 expect(restored.amountCents, 2500);
 expect(restored.dueDate, DateTime.utc(2026, 8, 15));
 expect(restored.isCustomerDebt, isTrue);
 expect(restored.isPaid, isTrue);
 expect(restored.paidAt, DateTime.utc(2026, 8, 3, 10, 30));
 expect(restored.customerId, 'c1');
 // Número SEQUENCIAL da dívida na loja sobrevive ao round-trip.
 expect(restored.number, 42);
 expect(debt.toJson()['number'], 42);
 });

 test('default do number é 0 (nunca persistido — o banco atribui)', () {
 final semNumero = Debt(
 id: 'DIVIDA-002',
 personName: 'Maria',
 amountCents: 1000,
 dueDate: DateTime.utc(2026, 8, 1),
 isCustomerDebt: true,
 );

 expect(semNumero.number, 0);
 });
}
