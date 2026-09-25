import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/core/theme/app_theme.dart';
import 'package:tareqo/presentation/widgets/snackbar_with_undo.dart';

/// Testes do [showUndoSnackBar] — o snackbar de ações destrutivas
/// REVERSÍVEIS (plano UI/UX — Fase 1.3): duração de 4s, ação "Desfazer",
/// countdown de progresso (linha que esvazia ao longo da duração) e
/// substituição da barra anterior (dois undos consecutivos não empilham).
///
/// ⚠️ Com a barra de pé, o countdown agenda frames continuamente —
/// `pumpAndSettle` avançaria os 4s e a dispensaria. Os testes usam pumps
/// cronometrados para inspecioná-la ANTES do fim da duração.
void main() {
  // Tema real do app — o helper não define cores (contrato do
  // snackBarTheme auditado em theme_contrast_test.dart), apenas duração,
  // ação, countdown e controle de duplicidade.
  Widget app(WidgetBuilder onScreen) => MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(body: Builder(builder: onScreen)),
  );

  testWidgets('mostra mensagem + ação de undo que dispara o callback', (
    tester,
  ) async {
    var undoCalls = 0;
    await tester.pumpWidget(
      app(
        (context) => Center(
          child: ElevatedButton(
            onPressed: () => showUndoSnackBar(
              context,
              message: 'Cliente removido.',
              undoLabel: 'Desfazer',
              onUndo: () => undoCalls++,
            ),
            child: const Text('show'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('show'));
    // Entrada do snackbar completa antes do toque na ação (a barra está
    // "de pé" — daqui em diante, só pumps cronometrados).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Cliente removido.'), findsOneWidget);
    expect(find.text('Desfazer'), findsOneWidget);

    await tester.tap(find.text('Desfazer'));
    await tester.pump();
    expect(undoCalls, 1);
    // Undo dispensa a barra: agora o settle é seguro (sem countdown vivo).
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('contrato de duração longa (4s) no SnackBar criado', (
    tester,
  ) async {
    // A duração da barra é um dado do helper — verificada DIRETAMENTE no
    // widget construído (o timer interno do ScaffoldMessenger usa o
    // relógio fake do flutter_test e não encerra a barra fora de
    // pumpAndSettle com duração ≥ 1s no perfil de teste).
    await tester.pumpWidget(
      app(
        (context) => Center(
          child: ElevatedButton(
            onPressed: () {
              showUndoSnackBar(
                context,
                message: 'Cliente removido.',
                undoLabel: 'Desfazer',
                onUndo: () {},
              );
            },
            child: const Text('show'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('show'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // A barra renderizada na cena é a do helper — inspetor direto do
    // widget: duração, comportamento e rótulo da ação.
    final snackBarWidget = tester.widget<SnackBar>(
      find.ancestor(
        of: find.text('Cliente removido.'),
        matching: find.byType(SnackBar),
      ),
    );
    expect(snackBarWidget.duration, const Duration(seconds: 4));
    expect(snackBarWidget.behavior, SnackBarBehavior.floating);
    expect(snackBarWidget.action?.label, 'Desfazer');
  });

  testWidgets('countdown de progresso esvazia ao longo dos 4s', (tester) async {
    await tester.pumpWidget(
      app(
        (context) => Center(
          child: ElevatedButton(
            onPressed: () {
              showUndoSnackBar(
                context,
                message: 'Cliente removido.',
                undoLabel: 'Desfazer',
                onUndo: () {},
              );
            },
            child: const Text('show'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('show'));
    // Primeiro frame: barra entrada com a linha CHEIA (t = 0).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final indicator = find.byType(LinearProgressIndicator);
    expect(indicator, findsOneWidget);
    double value() => tester.widget<LinearProgressIndicator>(indicator).value!;

    final start = value();
    expect(start, greaterThan(0.85), reason: 'logo após a entrada, ~cheia');

    // A 2s dos 4s: metade do tempo restante — valor ~0.5.
    await tester.pump(const Duration(seconds: 2));
    final mid = value();
    expect(mid, closeTo(0.5, 0.1), reason: 'metade da duração = ~50%');

    // A 3.5s: quase vazia.
    await tester.pump(const Duration(milliseconds: 1500));
    expect(value(), lessThan(0.15), reason: 'fim da duração = vazia');

    // A 3.5s: quase vazia. O controller trava em 0 (clamp 0..1) —
    // nunca fica negativo nem reinicia.
    await tester.pump(const Duration(milliseconds: 1500));
    expect(value(), lessThan(0.15), reason: 'fim da duração = vazia');
    await tester.pump(const Duration(seconds: 1));
    expect(value(), 0.0);
  });

  testWidgets('segundo snackbar substitui o anterior (sem empilhar)', (
    tester,
  ) async {
    var undo1 = 0;
    var undo2 = 0;
    await tester.pumpWidget(
      app(
        (context) => Center(
          child: ElevatedButton(
            onPressed: () {
              showUndoSnackBar(
                context,
                message: 'Primeiro',
                undoLabel: 'Desfazer',
                onUndo: () => undo1++,
              );
              showUndoSnackBar(
                context,
                message: 'Segundo',
                undoLabel: 'Desfazer',
                onUndo: () => undo2++,
              );
            },
            child: const Text('show'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('show'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // A barra antiga foi substituída — não há duas empilhadas.
    expect(find.text('Primeiro'), findsNothing);
    expect(find.text('Segundo'), findsOneWidget);
    // A barra substituta tem countdown PRÓPRIO (nova linha cheia).
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    // O "Desfazer" visível pertence à SEGUNDA mensagem.
    await tester.tap(find.text('Desfazer'));
    await tester.pump();
    expect(undo2, 1);
    expect(undo1, 0);
    await tester.pumpAndSettle();
  });

  testWidgets('renderiza no tema real sem exceção (floating)', (tester) async {
    await tester.pumpWidget(
      app(
        (context) => Center(
          child: ElevatedButton(
            onPressed: () => showUndoSnackBar(
              context,
              message: 'mensagem',
              undoLabel: 'Desfazer',
              onUndo: () {},
            ),
            child: const Text('show'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('show'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Sem exceção e renderizado como barra flutuante (behavior do tema).
    expect(tester.takeException(), isNull);
    expect(find.text('mensagem'), findsOneWidget);
  });
}
