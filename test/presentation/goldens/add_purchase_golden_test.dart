import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/golden_fixtures.dart';
import '../../helpers/golden_fonts.dart';
import '../../helpers/viewport.dart';

import 'package:tareqo/core/theme/app_theme.dart';
import 'package:tareqo/core/utils/app_clock.dart';

/// Golden de tela cheia do carrinho de NOVA COMPRA ([AddPurchaseSheet]) —
/// o par de compras do golden do PDV. Catálogo com produtos reais de
/// comércio ([demoProducts]) e compra sem efeito ([FakeProcessPurchaseUseCase]),
/// já que o golden é leitura.
///
/// Relógio injetado na âncora [kGoldenNow] — determinismo temporal.
void main() {
  setUpAll(loadGoldenFonts);

  setUp(() => AppClock.inject(() => kGoldenNow));
  tearDown(AppClock.reset);

  testWidgets('compras — dark', (tester) async {
    usePortraitViewport(tester, size: const Size(412, 915));
    await tester.pumpWidget(addPurchaseGoldenApp(theme: AppTheme.dark));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/compras_dark.png'),
    );
  });

  testWidgets('compras — light', (tester) async {
    usePortraitViewport(tester, size: const Size(412, 915));
    await tester.pumpWidget(addPurchaseGoldenApp(theme: AppTheme.light));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/compras_light.png'),
    );
  });
}
