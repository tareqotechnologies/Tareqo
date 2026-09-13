import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

import 'package:tareqo/presentation/screens/addons/payment_reconciliation_screen.dart';

void main() {
  testWidgets(
    'exibe título de pagamentos e banner honesto de integração bloqueada',
    (tester) async {
      // given — add-on `ao_mobile_money` desativado no catálogo: a tela
      // nunca deve fingir reconciliação real (sem dados demonstrativos).
      await tester.pumpWidget(
        ProviderScope(
          child: testApp(home: const PaymentReconciliationScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // then — appBar com o título l10n e o banner bloqueado visível.
      expect(find.text('M-Pesa / E-Mola'), findsOneWidget);
      expect(find.textContaining('M-Pesa/E-Mola'), findsWidgets);
      expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
    },
  );

  testWidgets(
    'não renderiza lista nem ações de reconciliação (estado bloqueado)',
    (tester) async {
      // given — honestidade do estado: sem botões de ação ou listas.
      await tester.pumpWidget(
        ProviderScope(
          child: testApp(home: const PaymentReconciliationScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // then — nenhum controle de reconciliação presente.
      expect(find.byType(ListView), findsNothing);
      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.byType(TextField), findsNothing);
    },
  );
}
