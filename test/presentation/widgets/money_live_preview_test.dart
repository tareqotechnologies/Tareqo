import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/core/utils/formatters.dart';
import 'package:tareqo/presentation/widgets/money_live_preview.dart';

import '../../helpers/test_app.dart';

void main() {
  testWidgets('mostra ao vivo o valor que será registado (A2)', (tester) async {
    // Formatação determinística (MZN + pt), independente de testes que
    // rodaram antes e alteraram o Formatters global.
    Formatters.applySettings(currencyCode: 'MZN', language: 'pt');
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      testApp(
        home: Scaffold(body: MoneyLivePreview(controller: controller)),
      ),
    );

    // Campo vazio → nenhum preview.
    expect(find.textContaining('='), findsNothing);

    // "1390" digitado sem separador → preview mostra 1.390,00 ANTES do
    // save (o erro clássico de registrar 100× o pretendido).
    controller.text = '1390';
    await tester.pump();
    expect(find.text('= MZN 1.390,00'), findsOneWidget);

    // Com separador decimal explícito → mostra o valor pretendido.
    controller.text = '13,90';
    await tester.pump();
    expect(find.text('= MZN 13,90'), findsOneWidget);

    // Entrada inválida → some (nada a prever).
    controller.text = 'abc';
    await tester.pump();
    expect(find.textContaining('='), findsNothing);

    // Zero → some (o validator do formulário cobre "maior que zero").
    controller.text = '0';
    await tester.pump();
    expect(find.textContaining('='), findsNothing);

    // Limpar o campo → some.
    controller.clear();
    await tester.pump();
    expect(find.textContaining('='), findsNothing);
  });

  testWidgets('obedece o idioma/moeda ativos do Formatters', (tester) async {
    Formatters.applySettings(currencyCode: 'BRL', language: 'pt');
    final controller = TextEditingController(text: '1.234,56');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      testApp(
        home: Scaffold(body: MoneyLivePreview(controller: controller)),
      ),
    );

    expect(find.text('= R\$ 1.234,56'), findsOneWidget);
  });
}
