import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/golden_fixtures.dart';
import '../../helpers/golden_fonts.dart';
import '../../helpers/viewport.dart';

import 'package:tareqo/core/theme/app_theme.dart';
import 'package:tareqo/core/utils/app_clock.dart';

/// Golden de tela cheia do PDV ([NewSaleSheet]) — a superfície de maior
/// frequência do app. Catálogo com produtos reais de comércio (ver
/// [demoProducts] nos fixtures).
///
/// Relógio injetado na âncora [kGoldenNow]: o resumo "Hoje · N vendas" do
/// cabeçalho conta as vendas demo de forma determinística.
void main() {
  setUpAll(loadGoldenFonts);

  setUp(() => AppClock.inject(() => kGoldenNow));
  tearDown(AppClock.reset);

  testWidgets('pdv — dark', (tester) async {
    usePortraitViewport(tester, size: const Size(412, 915));
    await tester.pumpWidget(newSaleGoldenApp(theme: AppTheme.dark));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/pdv_dark.png'),
    );
  });

  testWidgets('pdv — light', (tester) async {
    usePortraitViewport(tester, size: const Size(412, 915));
    await tester.pumpWidget(newSaleGoldenApp(theme: AppTheme.light));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/pdv_light.png'),
    );
  });
}
