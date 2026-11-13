import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tareqo/core/theme/app_theme.dart';
import 'package:tareqo/domain/entities/product.dart';
import 'package:tareqo/presentation/controllers/products_providers.dart';
import 'package:tareqo/presentation/controllers/sales_providers.dart';
import 'package:tareqo/presentation/screens/products/product_list_screen.dart';
import 'package:tareqo/presentation/screens/sales/new_sale_sheet.dart';

import '../../helpers/golden_fixtures.dart';
import '../../helpers/golden_fonts.dart';
import '../../helpers/store_context.dart';
import '../../helpers/test_app.dart';
import '../../helpers/viewport.dart';

const products = [
  Product(
    id: '1',
    name: 'Água mineral 500 ml',
    category: 'Bebidas',
    purchasePriceCents: 1500,
    salePriceCents: 2500,
    stockQuantity: 24000,
  ),
  Product(
    id: '2',
    name: 'Sumo de laranja 1 l',
    category: 'Bebidas',
    purchasePriceCents: 6000,
    salePriceCents: 9000,
    stockQuantity: 12000,
  ),
  Product(
    id: '3',
    name: 'Pão de forma',
    category: 'Padaria',
    purchasePriceCents: 4000,
    salePriceCents: 6000,
    stockQuantity: 8000,
  ),
  Product(
    id: '4',
    name: 'Saco reutilizável',
    purchasePriceCents: 500,
    salePriceCents: 1000,
    stockQuantity: 10000,
  ),
];

void main() {
  setUpAll(loadGoldenFonts);
  for (final dark in [false, true]) {
    for (final pdv in [false, true]) {
      final name =
          '${pdv ? 'pdv' : 'produtos'}_categorias_${dark ? 'dark' : 'light'}';
      testWidgets(name, (tester) async {
        usePortraitViewport(tester, size: const Size(412, 915));
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ...storeContextOverrides(),
              getProductsUseCaseProvider.overrideWithValue(
                FakeGetProductsUseCase(products),
              ),
              salesRepositoryProvider.overrideWithValue(
                FakeSalesRepository([]),
              ),
            ],
            child: testApp(
              theme: dark ? AppTheme.dark : AppTheme.light,
              home: pdv
                  ? const Scaffold(body: NewSaleSheet())
                  : const ProductListScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Bebidas'));
        await tester.pumpAndSettle();
        expect(find.text('Água mineral 500 ml'), findsOneWidget);
        expect(find.text('Pão de forma'), findsNothing);
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/$name.png'),
        );
      });
    }
  }
}
