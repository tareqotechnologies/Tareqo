import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tareqo/core/theme/app_theme.dart';
import 'package:tareqo/presentation/widgets/product_category_filter.dart';

import '../../helpers/golden_fonts.dart';
import '../../helpers/test_app.dart';
import '../../helpers/viewport.dart';

void main() {
  setUpAll(loadGoldenFonts);

  for (final dark in [false, true]) {
    testWidgets(
      'categorias: toque, semântica, contraste e texto 2x ${dark ? 'dark' : 'light'}',
      (tester) async {
        usePortraitViewport(tester, size: const Size(320, 640));
        final semantics = tester.ensureSemantics();
        String? selected;
        await tester.pumpWidget(
          testApp(
            theme: dark ? AppTheme.dark : AppTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) => Align(
                  alignment: Alignment.topLeft,
                  child: ProductCategoryFilter(
                    categories: const [
                      'Bebidas',
                      'Material de limpeza e higiene',
                    ],
                    selected: selected,
                    includeUncategorized: true,
                    onSelected: (value) => setState(() => selected = value),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Sem categoria'));
        await tester.pumpAndSettle();
        expect(selected, '');
        expect(
          tester
              .getSemantics(find.text('Sem categoria'))
              .flagsCollection
              .isSelected,
          Tristate.isTrue,
        );
        await tester.tap(find.text('Todas'));
        await tester.pumpAndSettle();
        expect(selected, isNull);
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(-600, 0),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Material de limpeza e higiene'));
        await tester.pumpAndSettle();
        expect(selected, 'Material de limpeza e higiene');
        expect(tester.takeException(), isNull);
        semantics.dispose();
      },
    );
  }
}
