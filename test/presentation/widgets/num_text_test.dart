import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/core/theme/app_theme.dart';
import 'package:tareqo/presentation/widgets/num_text.dart';

/// P1 da auditoria tipográfica: NumText é o componente numérico com
/// `tabularFigures` embutido — mata as cópias manuais de `fontFeatures`
/// espalhadas pelo app (21+ no momento da auditoria).
void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget Function(ThemeData theme) build,
  ) async {
    // Tema DO APP: os papéis têm fontSize/tabular explícitos no objeto
    // (o ThemeData cru resolve tamanhos por herança e o fontSize fica null).
    final theme = AppTheme.dark;
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(body: build(theme)),
      ),
    );
  }

  Text textOf(WidgetTester tester) => tester.widget<Text>(
    find.descendant(of: find.byType(NumText), matching: find.byType(Text)),
  );

  testWidgets('aplica tabularFigures ao estilo herdado do TextTheme', (
    tester,
  ) async {
    await pump(tester, (theme) {
      return NumText('1.234,56', style: theme.textTheme.labelSmall);
    });

    final style = textOf(tester).style!;
    expect(style.fontSize, 11); // veio do papel
    expect(
      style.fontFeatures!.contains(const FontFeature.tabularFigures()),
      isTrue,
      reason: 'NumText deve EMBUTIR tabular no estilo passado',
    );
  });

  testWidgets('funciona sem estilo (TextStyle próprio só com tabular)', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: NumText('42'))),
    );

    expect(
      textOf(
        tester,
      ).style!.fontFeatures!.contains(const FontFeature.tabularFigures()),
      isTrue,
    );
  });

  testWidgets('preserva fontFeatures pré-existentes do estilo', (tester) async {
    await pump(
      tester,
      (_) => const NumText(
        '7',
        style: TextStyle(
          fontSize: 14,
          fontFeatures: [FontFeature.enable('smcp')],
        ),
      ),
    );

    final features = textOf(tester).style!.fontFeatures!;
    expect(features, contains(const FontFeature.enable('smcp')));
    expect(features, contains(const FontFeature.tabularFigures()));
  });

  testWidgets('encaminha semanticsLabel ao Text', (tester) async {
    await pump(
      tester,
      (_) => const NumText(
        '3',
        semanticsLabel: '3 unidades',
        style: TextStyle(fontSize: 12),
      ),
    );

    expect(textOf(tester).semanticsLabel, '3 unidades');
  });
}
