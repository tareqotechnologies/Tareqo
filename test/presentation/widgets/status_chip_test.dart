import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dumbhanengue/presentation/widgets/status_chip.dart';

void main() {
  // Regressão (âncoras): o rótulo do StatusChip fica SEMPRE numa única
  // linha — com um valor longo ('Fiado MZN 1.234.567,89') numa âncora
  // estreita e escala de texto alta, a pílula ENCOLHE (FittedBox scaleDown)
  // em vez de quebrar linha ou estourar o layout do card.
  testWidgets('rótulo longo do StatusChip não quebra linha nem estoura', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearAllTestValues);

    const chip = StatusChip(
      label: 'Fiado MZN 1.234.567,89',
      color: Color(0xFFFBBF24),
      icon: Icons.receipt_long_outlined,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: Center(
            // Âncora estreita de um card (largura típica em mobile).
            child: SizedBox(
              width: 200,
              child: Align(alignment: Alignment.centerRight, child: chip),
            ),
          ),
        ),
      ),
    );

    // Sem overflow (RenderFlex) e sem exceção.
    expect(tester.takeException(), isNull);

    // O rótulo interno está numa ÚNICA linha e sem truncamento.
    final text = tester.widget<Text>(
      find.descendant(of: find.byType(StatusChip), matching: find.byType(Text)),
    );
    expect(text.maxLines, 1);
    expect(text.overflow, isNull);

    // A pílula coube dentro da âncora (FittedBox encolheu o texto) e a
    // altura é de UMA linha só — se o rótulo quebrasse, dobraria.
    final size = tester.getSize(find.byType(StatusChip));
    expect(size.width, lessThanOrEqualTo(200));
    expect(size.height, lessThan(55));
  });
}
