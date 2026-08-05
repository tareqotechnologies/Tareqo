import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

import 'package:dumbhanengue/domain/entities/product.dart';
import 'package:dumbhanengue/domain/usecases/get_products_use_case.dart';
import 'package:dumbhanengue/presentation/controllers/products_providers.dart';
import 'package:dumbhanengue/presentation/screens/products/product_list_screen.dart';

import '../../helpers/store_context.dart';

/// Fake do [GetProductsUseCase] — a tela nunca toca em GetIt nem em
/// datasources; o provider é sobrescrito no [ProviderScope].
class _FakeGetProductsUseCase implements GetProductsUseCase {
  _FakeGetProductsUseCase(this._products);

  final List<Product> _products;

  @override
  Future<List<Product>> call({required String storeId}) async => _products;
}

/// Fake que sempre falha, para exercitar o estado de erro.
class _ThrowingGetProductsUseCase implements GetProductsUseCase {
  @override
  Future<List<Product>> call({required String storeId}) async =>
      throw Exception('falha simulada ao buscar produtos');
}

Widget _buildApp(GetProductsUseCase useCase) {
  return ProviderScope(
    overrides: [
      // Contexto de loja — a lista de produtos escopa pela loja ativa.
      ...storeContextOverrides(),
      getProductsUseCaseProvider.overrideWithValue(useCase),
    ],
    child: testApp(home: ProductListScreen()),
  );
}

void main() {
  testWidgets('exibe os produtos retornados pelo caso de uso', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        _FakeGetProductsUseCase(const [
          Product(
            id: '1',
            name: 'Caneta',
            purchasePrice: 1.0,
            salePrice: 2.0,
          ),
          Product(
            id: '2',
            name: 'Caderno',
            purchasePrice: 5.0,
            salePrice: 9.9,
          ),
        ]),
      ),
    );

    // Estado inicial: carregando.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('Caneta'), findsOneWidget);
    expect(find.text('Caderno'), findsOneWidget);
    expect(find.textContaining('Venda: R\$'), findsNWidgets(2));
  });

  testWidgets('exibe estado vazio quando não há produtos', (tester) async {
    await tester.pumpWidget(_buildApp(_FakeGetProductsUseCase(const [])));

    await tester.pumpAndSettle();

    expect(find.text('Nenhum produto cadastrado'), findsOneWidget);
  });

  testWidgets('exibe erro e permite tentar novamente', (tester) async {
    await tester.pumpWidget(_buildApp(_ThrowingGetProductsUseCase()));

    await tester.pumpAndSettle();

    // Estado de erro: mensagem + botão de retry.
    expect(find.text('Não foi possível carregar os produtos.'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);

    // O retry invalida o provider e re-executa o caso de uso (que volta
    // a falhar neste fake, permanecendo no estado de erro).
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    expect(find.text('Tentar novamente'), findsOneWidget);
  });
}
