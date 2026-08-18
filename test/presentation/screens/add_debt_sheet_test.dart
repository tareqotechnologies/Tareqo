import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

import 'package:dumbhanengue/domain/entities/debt.dart';
import 'package:dumbhanengue/domain/repositories/i_debt_processor.dart';
import 'package:dumbhanengue/domain/usecases/add_debt_use_case.dart';
import 'package:dumbhanengue/presentation/controllers/debts_providers.dart';
import 'package:dumbhanengue/presentation/screens/credit/add_debt_sheet.dart';

/// Registra a dívida sem tocar em infraestrutura (o AddDebtUseCase já é
/// coberto por testes de domínio — aqui validamos apenas a orquestração da UI).
class _FakeAddDebtUseCase implements AddDebtUseCase {
 int calls = 0;
 Debt? lastDebt;

 @override
 Future<void> call(Debt debt) async {
 calls++;
 lastDebt = debt;
 }

 @override
 IDebtAtomicProcessor? get processor => null;
}

void main() {
 testWidgets('registrar fiado chama o AddDebtUseCase e mostra o snackbar',
 (tester) async {
 final addDebt = _FakeAddDebtUseCase();

 await tester.pumpWidget(
 ProviderScope(
 overrides: [addDebtUseCaseProvider.overrideWithValue(addDebt)],
 child: testApp(home: Scaffold(body: AddDebtSheet())),
 ),
 );
 await tester.pumpAndSettle();

 // Nome e valor (o campo de vencimento é um seletor, não um TextFormField).
 await tester.enterText(find.byType(TextFormField).at(0), 'Maria Souza');
 await tester.enterText(find.byType(TextFormField).at(1), '50,00');

 // O cabeçalho também se chama 'Registrar fiado' — toca no botão.
 await tester.tap(
 find.widgetWithText(FilledButton, 'Registrar fiado'),
 );
 await tester.pumpAndSettle();

 expect(addDebt.calls, 1);
 expect(addDebt.lastDebt?.personName, 'Maria Souza');
 expect(addDebt.lastDebt?.amountCents, 5000);
 expect(addDebt.lastDebt?.isCustomerDebt, isTrue);
 });
}
