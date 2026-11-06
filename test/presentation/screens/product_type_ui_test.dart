import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/domain/entities/product.dart';
import 'package:tareqo/domain/usecases/get_products_use_case.dart';
import 'package:tareqo/presentation/controllers/products_providers.dart';
import 'package:tareqo/presentation/screens/products/product_list_screen.dart';
import 'package:tareqo/presentation/widgets/app_sheet.dart';

import '../../helpers/test_app.dart';
import '../../helpers/store_context.dart';
import 'package:tareqo/data/services/product_image_store_noop.dart';

/// Fase 1 — tipo do produto na tela de Produtos:
/// - matérias-primas, produzidos, compostos e embalagens ganham o selo;
/// - o filtro por tipo (sheet avançado) filtra corretamente.
class _FakeGetProductsUseCase implements GetProductsUseCase {
  _FakeGetProductsUseCase(this.products);

  final List<Product> products;

  @override
  Future<List<Product>> call({required String storeId}) async => products;
}

Widget _buildProductsApp(List<Product> products) {
  return ProviderScope(
    overrides: [
      ...storeContextOverrides(),
      getProductsUseCaseProvider.overrideWithValue(
        _FakeGetProductsUseCase(products),
      ),
      productImageStoreProvider.overrideWithValue(
        const ProductImageStoreNoop(),
      ),
    ],
    child: testApp(home: const ProductListScreen()),
  );
}

Product productOf(ProductType type) => Product(
  id: 'p-${type.name}',
  name: 'Produto ${type.name}',
  purchasePriceCents: 100,
  salePriceCents: 200,
  type: type,
);

enum _TypeChip { rawMaterial, manufactured }

String _chipLabel(_TypeChip chip) => switch (chip) {
  _TypeChip.rawMaterial => 'Matéria-prima',
  _TypeChip.manufactured => 'Produzido',
};

Future<void> _applyTypeFilter(WidgetTester tester, _TypeChip chip) async {
  await tester.tap(find.byIcon(Icons.tune_rounded));
  await tester.pumpAndSettle();

  // Chip do TIPO dentro da seção "Tipo" do sheet avançado — o MESMO
  // rótulo também aparece como selo no card do produto (atrás do modal),
  // então o finder é escopado às seções do sheet (canal público
  // SheetSection) para não acertar o card encoberto pelo scrim.
  final chipFinder = find.descendant(
    of: find.byType(SheetSection),
    matching: find.text(_chipLabel(chip)),
  );
  await tester.ensureVisible(chipFinder);
  await tester.pumpAndSettle();
  await tester.tap(chipFinder);
  await tester.pumpAndSettle();

  await tester.tap(find.text('Aplicar'));
  await tester.pumpAndSettle();
}

void main() {
  // Superfície alta: o sheet de filtros (0.85 da altura) comporta as
  // 6 seções sem cortar os chips de Tipo — sem isso o tap cai fora.
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('filtra matérias-primas excluindo revenda', (tester) async {
    // Superfície mais alta: no padrão 800x600 o sheet de filtros corta a
    // seção "Tipo" e o tap do chip não acerta (hit-test warning).
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _buildProductsApp([
        productOf(ProductType.resale),
        productOf(ProductType.rawMaterial),
      ]),
    );
    await tester.pumpAndSettle();

    await _applyTypeFilter(tester, _TypeChip.rawMaterial);

    expect(find.text('Produto rawMaterial'), findsOneWidget);
    expect(find.text('Produto resale'), findsNothing);
  });

  testWidgets('limpar filtros restaura a lista completa', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _buildProductsApp([
        productOf(ProductType.resale),
        productOf(ProductType.manufactured),
      ]),
    );
    await tester.pumpAndSettle();

    await _applyTypeFilter(tester, _TypeChip.manufactured);
    expect(find.text('Produto resale'), findsNothing);

    // Limpa os filtros no próprio sheet — o botão de fechar do SheetHeader
    // (X) tem onClose = _clear, que reseta os filtros sem fechar a sheet;
    // depois Aplicar devolve a lista completa.
    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aplicar'));
    await tester.pumpAndSettle();

    expect(find.text('Produto resale'), findsOneWidget);
    expect(find.text('Produto manufactured'), findsOneWidget);
  });

  testWidgets('sheet de filtros abre com todas as opções de tipo', (
    tester,
  ) async {
    await tester.pumpWidget(_buildProductsApp([productOf(ProductType.resale)]));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pumpAndSettle();

    // As 5 opções do enum + "Todos" — na seção Tipo e no dropdown do
    // formulário (fora do escopo aqui). Os rótulos vêm do enum ProductType.
    expect(find.text('Matéria-prima'), findsOneWidget);
    expect(find.text('Produzido'), findsOneWidget);
    expect(find.text('Composto'), findsOneWidget);
    expect(find.text('Embalagem'), findsOneWidget);

    await tester.tap(find.text('Aplicar'));
    await tester.pumpAndSettle();
  });
}
