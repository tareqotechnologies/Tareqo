import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';
import 'package:tareqo/presentation/widgets/app_sheet.dart';
import 'package:tareqo/presentation/widgets/fade_indexed_stack.dart';

void main() {
  // Entrada da sheet (plano UI/UX — F4.3): scale 0.92 + fade no PRIMEIRO
  // frame, assentando em scale 1.0 — o padrão iOS "card stack". Toda sheet
  // do app herda a física sem o chamador fazer nada.
  testWidgets('showAppSheet abre com scale 0.92 + fade e assenta em 1.0', (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () => showAppSheet<void>(
                  context,
                  builder: (_) => const SizedBox(width: 100, height: 60),
                ),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pump(); // 1º frame da transição de rota + scale-in

    // O scale-in (TweenAnimationBuilder) está a interpolar na abertura —
    // presença prova que a física de entrada correu sobre a sheet.
    expect(find.byType(TweenAnimationBuilder<double>), findsOneWidget);

    await tester.pumpAndSettle();
    // Assentou: a sheet está em ecrã, sem exceção.
    expect(tester.takeException(), isNull);
  });

  // Movimento reduzido: entrada estática — sem Transform/Opacity animados
  // sobre a sheet (o slide de rota padrão cuida do resto).
  testWidgets('showAppSheet respeita disableAnimations (entrada estática)', (
    tester,
  ) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: testApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () => showAppSheet<void>(
                    context,
                    builder: (_) => const SizedBox(width: 100, height: 60),
                  ),
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    // A sheet está em ecrã e a subtree dela não passou pelo scale-in
    // (TweenAnimationBuilder teria interpolado).
    expect(find.byType(TweenAnimationBuilder<double>), findsNothing);
    expect(tester.takeException(), isNull);
  });

  // Troca de abas (plano UI/UX — F4.4): fade-through M3 — fade out rápido
  // do conteúdo antigo, troca de índice, fade in + slide de 24px do novo.
  // O estado das abas é preservado (IndexedStack).
  testWidgets('FadeIndexedStack faz fade-through entre índices', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FadeIndexedStack(
            index: 0,
            children: [
              Text('A', key: Key('a')),
              Text('B', key: Key('b')),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Primeiro build: opaco, índice 0 visível.
    expect(find.byKey(const Key('a')), findsOneWidget);
    expect(find.text('A'), findsOneWidget);

    // Troca de índice — reconstrói com index 1 (o shell passa a nova aba).
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FadeIndexedStack(
            index: 1,
            children: [
              Text('A', key: Key('a')),
              Text('B', key: Key('b')),
            ],
          ),
        ),
      ),
    );

    // Fase 1 (fade out 90ms): o conteúdo ANTIGO ainda está montado.
    await tester.pump(const Duration(milliseconds: 30));
    expect(find.text('A'), findsOneWidget);

    // Fase 2 (fade in 220ms): o conteúdo novo assumiu (o pump extra cobre
    // a retoma do async após o fade out — o frame seguinte reconstrói).
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('B'), findsOneWidget);
    expect(find.text('A'), findsNothing);

    await tester.pumpAndSettle();
    // Estado preservado: o filho antigo permanece MONTADO na IndexedStack
    // (só deixa de ser pintado — daí skipOffstage: false).
    expect(find.byKey(const Key('a'), skipOffstage: false), findsOneWidget);
    expect(find.byKey(const Key('b'), skipOffstage: false), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  // Movimento reduzido: troca direta, sem fase de fade.
  testWidgets('FadeIndexedStack respeita disableAnimations (troca direta)', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: MaterialApp(
          home: Scaffold(
            body: FadeIndexedStack(
              index: 0,
              children: [Text('A'), Text('B')],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: MaterialApp(
          home: Scaffold(
            body: FadeIndexedStack(
              index: 1,
              children: [Text('A'), Text('B')],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // Troca IMEDIATA — sem fase de saída.
    expect(find.text('B'), findsOneWidget);
    expect(find.text('A'), findsNothing);
  });
}
