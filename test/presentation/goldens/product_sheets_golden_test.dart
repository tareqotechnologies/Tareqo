import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/golden_fixtures.dart';
import '../../helpers/golden_fonts.dart';
import '../../helpers/viewport.dart';

import 'package:tareqo/core/theme/app_theme.dart';
import 'package:tareqo/core/utils/app_clock.dart';
import 'package:tareqo/presentation/screens/products/product_form_sheets.dart';

/// Baseline visual dos FORMULÁRIOS de produto — os dois sheets abertos a
/// partir da lista real (`ProductListScreen`), e não o widget solto: o
/// golden captura o resultado de verdade (scrim, cantos, alça, cabeçalho,
/// seções e ação primária), que é onde a hierarquia visual aparece.
///
/// Por que viewport mais alto que o telefone (412×915) dos goldens de tela
/// cheia: a sheet tem `maxHeightFactor` (0.88/0.9) e rola — numa altura de
/// telefone a ação primária ficaria fora do quadro. Aqui a altura é
/// suficiente para o formulário inteiro caber numa imagem só, que é o que
/// se quer revisar num diff.
///
/// Mesmo contrato dos outros goldens: fonte Inter real (`loadGoldenFonts`),
/// relógio injetado em [kGoldenNow] e fakes determinísticos de
/// `golden_fixtures.dart` (catálogo `demoProducts`).
void main() {
  setUpAll(loadGoldenFonts);

  setUp(() => AppClock.inject(() => kGoldenNow));
  tearDown(AppClock.reset);

  Future<void> pumpList(WidgetTester tester, ThemeData theme) async {
    await tester.pumpWidget(productGoldenApp(theme: theme));
    await tester.pumpAndSettle();
  }

  for (final dark in [false, true]) {
    final brightness = dark ? 'dark' : 'light';
    final theme = dark ? AppTheme.dark : AppTheme.light;

    testWidgets('novo produto — $brightness', (tester) async {
      usePortraitViewport(tester, size: const Size(412, 1400));
      await pumpList(tester, theme);

      // Abre pelo FAB do catálogo (mesmo caminho do usuário).
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      expect(find.byType(AddProductSheet), findsOneWidget);

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/produto_novo_$brightness.png'),
      );
    });

    testWidgets('editar produto — $brightness', (tester) async {
      usePortraitViewport(tester, size: const Size(412, 1600));
      await pumpList(tester, theme);

      // Tocar no produto abre a edição (dono/gerente).
      await tester.tap(find.text(demoProducts.first.name));
      await tester.pumpAndSettle();
      expect(find.byType(EditProductSheet), findsOneWidget);

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/produto_editar_$brightness.png'),
      );
    });
  }
}
