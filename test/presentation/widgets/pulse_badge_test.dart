import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/presentation/widgets/pulse_badge.dart';

/// Comportamento observável do [PulseBadge]:
/// - count <= 0 → apenas o filho, sem badge nem Transform de pulso;
/// - count > 0 → texto do badge visível (e valor exato);
/// - count > maxCount → "maxCount+" com o NÚMERO interpolado (regressão do
///   bug `'$widget.maxCount+'`, que renderizava `Instance of 'PulseBadge'`);
/// - showPulse controla a animação — observável pela ESCALA renderizada
///   (Transform.scale muda com o tempo quando pulsa; fica 1.0 quando parado);
/// - transição para 0 remove o badge.
void main() {
  /// Escala atual do badge (0 → não há Transform na árvore).
  double? badgeScale(WidgetTester tester) {
    final transforms = tester.widgetList<Transform>(
      find.descendant(
        of: find.byType(PulseBadge),
        matching: find.byType(Transform),
      ),
    );
    if (transforms.isEmpty) return null;
    return transforms.first.transform.storage[0];
  }

  Future<void> pumpBadge(
    WidgetTester tester, {
    required int count,
    bool showPulse = true,
    int maxCount = 99,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(colorSchemeSeed: Colors.green),
        home: Scaffold(
          body: Center(
            child: PulseBadge(
              count: count,
              showPulse: showPulse,
              maxCount: maxCount,
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Finder badgeText() => find.byWidgetPredicate(
    (w) => w is Text && RegExp(r'^\d+\+?$').hasMatch(w.data ?? ''),
  );

  testWidgets('count 0 exibe apenas o filho, sem badge', (tester) async {
    await pumpBadge(tester, count: 0);

    expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    expect(badgeText(), findsNothing);
    expect(badgeScale(tester), isNull);
  });

  testWidgets('count negativo também não renderiza badge', (tester) async {
    await pumpBadge(tester, count: -3);

    expect(badgeText(), findsNothing);
    expect(badgeScale(tester), isNull);
  });

  testWidgets('count positivo exibe o número exato', (tester) async {
    await pumpBadge(tester, count: 7);

    expect(find.text('7'), findsOneWidget);
  });

  testWidgets('count acima do máximo satura em "<maxCount>+" com número', (
    tester,
  ) async {
    await pumpBadge(tester, count: 120, maxCount: 99);

    // Regressão: `'$widget.maxCount+'` renderizava
    // "Instance of 'PulseBadge'.maxCount+" em vez de "99+".
    expect(find.text('99+'), findsOneWidget);
    expect(
      find.textContaining('Instance'),
      findsNothing,
      reason: 'A interpolação de widget não pode vazar para a UI',
    );
  });

  testWidgets('showPulse desligado mantém a escala parada em 1.0', (
    tester,
  ) async {
    await pumpBadge(tester, count: 5, showPulse: false);
    expect(badgeScale(tester), 1.0);

    await tester.pump(const Duration(milliseconds: 400));
    expect(badgeScale(tester), 1.0, reason: 'Sem pulso a escala não muda');
  });

  testWidgets('showPulse ligado anima: a escala muda entre frames', (
    tester,
  ) async {
    await pumpBadge(tester, count: 5);

    // Primeiro frame: controller recomeçando — escala ~= 1.0.
    final initial = badgeScale(tester);
    expect(initial, isNotNull);

    // Com repeat(reverse), a escala evolui (nunca fica fixa em 1.0).
    await tester.pump(const Duration(milliseconds: 500));
    final mid = badgeScale(tester);
    await tester.pump(const Duration(milliseconds: 500));
    final later = badgeScale(tester);

    expect(mid, isNotNull);
    expect(later, isNotNull);
    expect(
      mid != initial || later != mid,
      isTrue,
      reason: 'O pulso deve alterar a escala ao longo do tempo',
    );
  });

  testWidgets('mudar count para 0 remove o badge (didUpdateWidget)', (
    tester,
  ) async {
    await pumpBadge(tester, count: 5);
    expect(find.text('5'), findsOneWidget);

    await pumpBadge(tester, count: 0);

    expect(find.text('5'), findsNothing);
    expect(badgeScale(tester), isNull);
  });

  testWidgets('aumentar o count reexibe o badge', (tester) async {
    await pumpBadge(tester, count: 0);
    expect(badgeText(), findsNothing);

    await pumpBadge(tester, count: 3);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('dispose não vaza: remover da árvore não lança', (tester) async {
    await pumpBadge(tester, count: 9);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
