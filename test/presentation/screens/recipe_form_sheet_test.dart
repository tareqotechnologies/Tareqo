import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/store_context.dart';
import '../../helpers/test_app.dart';

import 'package:tareqo/domain/entities/product.dart';
import 'package:tareqo/domain/entities/recipe.dart';
import 'package:tareqo/domain/usecases/get_products_use_case.dart';
import 'package:tareqo/domain/usecases/production_use_cases.dart';
import 'package:tareqo/presentation/controllers/products_providers.dart';
import 'package:tareqo/presentation/controllers/production_providers.dart';
import 'package:tareqo/presentation/screens/production/recipe_form_sheet.dart';
import 'package:tareqo/presentation/widgets/app_sheet.dart';
import 'package:tareqo/presentation/widgets/search_field.dart';

class _FakeGetProductsUseCase implements GetProductsUseCase {
  _FakeGetProductsUseCase(this._products);

  final List<Product> _products;

  @override
  Future<List<Product>> call({required String storeId}) async => _products;
}

/// Fake do caso de uso de gravação — o form é a única unidade sob teste
/// (validação e persistência reais têm testes de domínio próprios).
class _FakeSaveRecipeUseCase implements SaveRecipeUseCase {
  int calls = 0;
  Recipe? lastRecipe;

  @override
  Future<void> call(Recipe recipe) async {
    calls++;
    lastRecipe = recipe;
  }
}

/// Nome longo de propósito: é o que denuncia truncagem ("…") num dropdown.
const _finished = Product(
  id: 'p1',
  name: 'Bolo de Chocolate Belga com Cobertura Especial da Casa',
  purchasePriceCents: 0,
  salePriceCents: 2500,
  stockQuantity: 3000,
  type: ProductType.manufactured,
);

const _component = Product(
  id: 'p2',
  name: 'Farinha de Trigo Integral Premium Selecionada',
  purchasePriceCents: 500,
  salePriceCents: 0,
  stockQuantity: 10000,
  type: ProductType.rawMaterial,
);

Widget _buildApp({
  _FakeSaveRecipeUseCase? saveRecipe,
  double textScale = 1,
  Locale locale = const Locale('pt'),
}) {
  return ProviderScope(
    overrides: [
      ...storeContextOverrides(),
      getProductsUseCaseProvider.overrideWithValue(
        _FakeGetProductsUseCase(const [_finished, _component]),
      ),
      saveRecipeUseCaseProvider.overrideWithValue(
        saveRecipe ?? _FakeSaveRecipeUseCase(),
      ),
    ],
    child: testApp(
      locale: locale,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: FilledButton(
              onPressed: () => showAppSheet<void>(
                context,
                builder: (_) => const RecipeFormSheet(),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Campo do produto acabado (o toque abre a sheet pesquisável).
final _finishedPicker = find.byKey(const Key('recipe-finished-product'));

/// Campo de produto do primeiro componente.
Finder get _componentPicker => find
    .descendant(
      of: find.byKey(const ValueKey('recipe-component-0')),
      matching: find.byType(InputDecorator),
    )
    .first;

Finder get _pickerSearch => find.descendant(
  of: find.byType(SearchField),
  matching: find.byType(TextField),
);

void main() {
  testWidgets(
    'nomes longos aparecem completos a 360dp com escala de texto 2.0',
    (tester) async {
      tester.view.physicalSize = const Size(360, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final saveRecipe = _FakeSaveRecipeUseCase();
      await tester.pumpWidget(_buildApp(saveRecipe: saveRecipe, textScale: 2));
      await _openSheet(tester);

      // Escolhe o produto acabado na sheet pesquisável.
      await _tap(tester, _finishedPicker);
      expect(find.byType(SearchField), findsOneWidget);
      expect(find.text(_finished.name), findsOneWidget);
      await tester.enterText(_pickerSearch, 'bolo');
      await tester.pumpAndSettle();
      expect(find.text(_component.name), findsNothing);
      await _tap(tester, find.text(_finished.name));

      // Escolhe o componente.
      await _tap(tester, _componentPicker);
      await tester.enterText(_pickerSearch, 'farinha');
      await tester.pumpAndSettle();
      // A busca filtra a lista: só o componente resta. O nome do acabado
      // que ainda aparece é o VALOR do campo já preenchido no formulário.
      expect(find.text(_component.name), findsOneWidget);
      await _tap(tester, find.text(_component.name));

      // Os nomes completos estão no formulário — sem maxLines nem ellipsis.
      for (final name in [_finished.name, _component.name]) {
        final text = tester.widget<Text>(find.text(name));
        expect(text.maxLines, isNull, reason: '$name não pode ser cortado');
        expect(text.overflow, anyOf(isNull, TextOverflow.clip));
      }

      // Quantidade do componente e gravação.
      final quantityField = find.widgetWithText(TextField, 'Quantidade');
      await tester.ensureVisible(quantityField);
      await tester.pumpAndSettle();
      await tester.enterText(quantityField, '2');
      await tester.pumpAndSettle();
      await _tap(tester, find.text('Guardar'));

      expect(saveRecipe.calls, 1);
      expect(saveRecipe.lastRecipe!.productId, _finished.id);
      expect(saveRecipe.lastRecipe!.items.single.productId, _component.id);
      expect(saveRecipe.lastRecipe!.items.single.quantity, 2000);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('valida produto, rendimento e componentes em português', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final saveRecipe = _FakeSaveRecipeUseCase();
    await tester.pumpWidget(_buildApp(saveRecipe: saveRecipe));
    await _openSheet(tester);

    // Sem produto e sem componente: mensagens locais, sem tocar no domínio.
    await _tap(tester, find.text('Guardar'));
    expect(find.text('Selecione o produto acabado.'), findsOneWidget);
    expect(find.text('Adicione pelo menos um componente.'), findsOneWidget);
    expect(saveRecipe.calls, 0);

    // Rendimento zero também é barrado com mensagem traduzida.
    await tester.enterText(
      find.widgetWithText(TextField, 'Rendimento da base (unidades)'),
      '0',
    );
    await tester.pumpAndSettle();
    await _tap(tester, find.text('Guardar'));
    expect(find.text('Indique um rendimento maior que zero.'), findsOneWidget);
    expect(saveRecipe.calls, 0);

    // Quantidade de componente vazia também é barrada, e o erro desaparece
    // assim que o campo é corrigido.
    await _tap(tester, _finishedPicker);
    await _tap(tester, find.text(_finished.name));
    await _tap(tester, _componentPicker);
    await _tap(tester, find.text(_component.name));
    await tester.enterText(
      find.widgetWithText(TextField, 'Rendimento da base (unidades)'),
      '1',
    );
    await tester.pumpAndSettle();
    await _tap(tester, find.text('Guardar'));
    expect(find.text('Indique uma quantidade maior que zero.'), findsOneWidget);
    expect(saveRecipe.calls, 0);

    await tester.enterText(find.widgetWithText(TextField, 'Quantidade'), '1');
    await tester.pumpAndSettle();
    expect(find.text('Indique uma quantidade maior que zero.'), findsNothing);
    await _tap(tester, find.text('Guardar'));
    expect(saveRecipe.calls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('em edição o produto acabado fica fixo e sem chevron', (
    tester,
  ) async {
    final recipe = Recipe(
      id: 'r1',
      storeId: 'st1',
      productId: _finished.id,
      yieldQuantity: 1000,
      items: [RecipeItem(productId: _component.id, quantity: 500)],
      createdAt: DateTime(2026),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...storeContextOverrides(),
          getProductsUseCaseProvider.overrideWithValue(
            _FakeGetProductsUseCase(const [_finished, _component]),
          ),
          saveRecipeUseCaseProvider.overrideWithValue(_FakeSaveRecipeUseCase()),
        ],
        child: testApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: FilledButton(
                  onPressed: () => showAppSheet<void>(
                    context,
                    builder: (_) => RecipeFormSheet(initial: recipe),
                  ),
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await _openSheet(tester);

    expect(find.text(_finished.name), findsOneWidget);
    expect(find.text(_component.name), findsOneWidget);
    // Sem chevron no campo fixo: não há como trocar o acabado.
    expect(
      find.descendant(
        of: _finishedPicker,
        matching: find.byIcon(Icons.expand_more_rounded),
      ),
      findsNothing,
    );
    // E tocar no campo fixo não abre picker algum.
    await _tap(tester, _finishedPicker);
    expect(find.byType(SearchField), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
