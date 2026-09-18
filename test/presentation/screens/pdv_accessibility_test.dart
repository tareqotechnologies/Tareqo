import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/domain/entities/product.dart';
import 'package:tareqo/domain/entities/sale.dart';
import 'package:tareqo/domain/repositories/i_sale_processor.dart';
import 'package:tareqo/domain/repositories/i_sale_repository.dart';
import 'package:tareqo/domain/usecases/get_products_use_case.dart';
import 'package:tareqo/domain/usecases/process_sale_use_case.dart';
import 'package:tareqo/presentation/controllers/products_providers.dart';
import 'package:tareqo/presentation/controllers/sales_providers.dart';
import 'package:tareqo/presentation/screens/sales/new_sale_sheet.dart';

import '../../helpers/store_context.dart';
import '../../helpers/test_app.dart';

/// Catálogo mínimo com produto por unidade e por peso — os steppers do PDV
/// são os toques mais frequentes do app e agora têm rótulo semântico.
class _CatalogUseCase implements GetProductsUseCase {
  @override
  Future<List<Product>> call({required String storeId}) async => const [
    Product(
      id: 'c1',
      code: '123',
      name: 'Caneta Azul',
      purchasePriceCents: 100,
      salePriceCents: 200,
      stockQuantity: 50000,
    ),
    Product(
      id: 'f1',
      code: '456',
      name: 'Arroz 25kg',
      purchasePriceCents: 5000,
      salePriceCents: 8000,
      stockQuantity: 10000,
      vendaPorFracao: true,
      unitLabel: 'kg',
    ),
  ];
}

class _FakeProcessSaleUseCase implements ProcessSaleUseCase {
  @override
  Future<void> call(Sale sale) async {}

  @override
  ISaleAtomicProcessor? get processor => null;
}

class _FakeSalesRepository implements ISaleRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<Sale>> getAll({required String storeId}) async => const [];
}

void main() {
  testWidgets(
    'a11y: steppers do PDV passam o guideline de toque (48dp) e têm rótulo',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...storeContextOverrides(),
            getProductsUseCaseProvider.overrideWithValue(_CatalogUseCase()),
            processSaleUseCaseProvider.overrideWithValue(
              _FakeProcessSaleUseCase(),
            ),
            salesRepositoryProvider.overrideWithValue(_FakeSalesRepository()),
          ],
          child: testApp(home: Scaffold(body: NewSaleSheet())),
        ),
      );
      await tester.pumpAndSettle();

      // A SliverList é lazy: rola até o produto por peso (2º) para todos os
      // tipos de stepper existirem na árvore.
      await tester.scrollUntilVisible(
        find.text('Arroz 25kg'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Rótulos semânticos dos steppers (tooltips): leitor de ecrã anuncia
      // a AÇÃO, não apenas "botão". O "+' do produto por peso anuncia o
      // passo de fração (0,1).
      expect(find.byTooltip('Aumentar quantidade'), findsWidgets);
      expect(find.byTooltip('Diminuir quantidade'), findsWidgets);
      expect(find.byTooltip('Adicionar 0,1 (peso)'), findsOneWidget);

      // Guideline Android: alvos de toque ≥ 48dp — pegou o problema real
      // dos steppers compactos (40dp) e das linhas de pagamento (37dp),
      // ambos corrigidos na fonte. Este teste protege a regressão.
      final handle = tester.ensureSemantics();
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    },
  );
}
