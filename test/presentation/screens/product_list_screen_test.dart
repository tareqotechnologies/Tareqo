import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dumbhanengue/presentation/widgets/app_button.dart';

import '../../helpers/test_app.dart';

import 'package:dumbhanengue/domain/entities/product.dart';
import 'package:dumbhanengue/domain/repositories/i_product_repository.dart';
import 'package:dumbhanengue/domain/repositories/i_unit_of_work.dart';
import 'package:dumbhanengue/domain/usecases/fifo_stock_use_case.dart';
import 'package:dumbhanengue/domain/usecases/get_products_use_case.dart';
import 'package:dumbhanengue/domain/usecases/update_product_stock_use_case.dart';
import 'package:dumbhanengue/domain/usecases/update_product_use_case.dart';
import 'package:dumbhanengue/presentation/controllers/account_providers.dart';
import 'package:dumbhanengue/data/services/product_image_store_noop.dart';
import 'package:dumbhanengue/presentation/controllers/products_providers.dart';
import 'package:dumbhanengue/presentation/screens/products/product_list_screen.dart';

import '../../helpers/fake_stock_lot_repository.dart';
import '../../helpers/store_context.dart';

/// Fake do [GetProductsUseCase] — a tela nunca toca em GetIt nem em
/// datasources; o provider é sobrescrito no [ProviderScope].
class _FakeGetProductsUseCase implements GetProductsUseCase {
  _FakeGetProductsUseCase(this.products);

  final List<Product> products;

  @override
  Future<List<Product>> call({required String storeId}) async => products;
}

/// Repositório em memória para testes de edição.
class _InMemoryProductRepository implements IProductRepository {
  final List<Product> products = [];

  @override
  Future<Product?> getById(String id, {required String storeId}) async {
    for (final p in products) {
      if (p.id == id && p.storeId == storeId) return p;
    }
    return null;
  }

  @override
  Future<void> add(Product product) async => products.add(product);

  @override
  Future<void> update(Product product) async {
    final idx = products.indexWhere((p) => p.id == product.id && p.storeId == product.storeId);
    if (idx >= 0) products[idx] = product;
  }

  @override
  Future<void> updateStock(String id, int newQuantity, {required String storeId}) async {
    final idx = products.indexWhere((p) => p.id == id && p.storeId == storeId);
    if (idx >= 0) {
      products[idx] = products[idx].copyWith(stockQuantity: newQuantity);
    }
  }

  @override
  Future<List<Product>> getAll({required String storeId}) async =>
      products.where((p) => p.storeId == storeId).toList();

  Future<List<Product>> searchByName(String query, {required String storeId}) async {
    final q = query.toLowerCase();
    return products.where((p) =>
      p.storeId == storeId &&
      (p.name.toLowerCase().contains(q) || p.description.toLowerCase().contains(q))
    ).toList();
  }

  Future<void> delete(String id, {required String storeId}) async {
    products.removeWhere((p) => p.id == id && p.storeId == storeId);
  }
}

/// UnitOfWork direta (sem transação real) — para testes.
class _DirectUnitOfWork implements IUnitOfWork {
  const _DirectUnitOfWork();

  @override
  Future<T> run<T>(Future<T> Function() action) => action();
}

/// Constrói o [UpdateProductUseCase] real sobre o repositório em memória.
UpdateProductUseCase _updateUseCase(_InMemoryProductRepository repository) {
  return UpdateProductUseCase(
    repository,
    FifoStockUseCase(
      FakeStockLotRepository(),
      UpdateProductStockUseCase(repository),
    ),
    const _DirectUnitOfWork(),
  );
}

/// Fake que sempre falha, para exercitar o estado de erro.
class _ThrowingGetProductsUseCase implements GetProductsUseCase {
  @override
  Future<List<Product>> call({required String storeId}) async =>
      throw Exception('falha simulada ao buscar produtos');
}

Widget _buildApp(
  GetProductsUseCase useCase, {
  UpdateProductUseCase? updateUseCase,
}) {
  return ProviderScope(
    overrides: [
      // Contexto de loja — a lista de produtos escopa pela loja ativa.
      ...storeContextOverrides(),
      getProductsUseCaseProvider.overrideWithValue(useCase),
      // Edição: use case real sobre fakes em memória (a tela nunca toca
      // em GetIt — o provider é sobrescrito no ProviderScope).
      updateProductUseCaseProvider.overrideWithValue(
        updateUseCase ?? _updateUseCase(_InMemoryProductRepository()),
      ),
      // Fotos: no-op em testes (sem disco/Storage — a UI cai no fallback
      // de ícone; sem override, o provider chamaria o GetIt não configurado).
      productImageStoreProvider.overrideWithValue(
        const ProductImageStoreNoop(),
      ),
    ],
    child: testApp(home: ProductListScreen()),
  );
}

/// Produtos com o usuário logado como FUNCIONÁRIO comum: `currentAccessLevel`
/// resolve `employee` — o botão de NOVO produto some (funcionário só vende).
Widget _buildAppEmployee(GetProductsUseCase useCase) {
  return ProviderScope(
    overrides: [
      ...storeContextOverrides(),
      // Acesso de funcionário comum (não é dono nem gerente).
      currentAccessLevelProvider.overrideWithValue(UserAccessLevel.employee),
      getProductsUseCaseProvider.overrideWithValue(useCase),
      updateProductUseCaseProvider.overrideWithValue(
        _updateUseCase(_InMemoryProductRepository()),
      ),
      productImageStoreProvider.overrideWithValue(
        const ProductImageStoreNoop(),
      ),
    ],
    child: testApp(home: ProductListScreen()),
  );
}

void main() {
  group('ProductListScreen', () {
    testWidgets('exibe os produtos retornados pelo caso de uso', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          _FakeGetProductsUseCase(const [
            Product(
              id: '1',
              name: 'Caneta',
              purchasePriceCents: 100,
              salePriceCents: 200,
            ),
            Product(
              id: '2',
              name: 'Caderno',
              purchasePriceCents: 500,
              salePriceCents: 800,
            ),
          ]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Caneta'), findsOneWidget);
      expect(find.text('Caderno'), findsOneWidget);
    });

    testWidgets('exibe estado vazio quando não há produtos', (tester) async {
      await tester.pumpWidget(
        _buildApp(_FakeGetProductsUseCase(const [])),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nenhum produto cadastrado'), findsOneWidget);
      expect(find.text('Toque em "Novo produto" para começar.'), findsOneWidget);
    });

    testWidgets('busca por nome filtra a lista (case-insensitive)', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          _FakeGetProductsUseCase(const [
            Product(
              id: '1',
              name: 'Caneta Azul',
              purchasePriceCents: 100,
              salePriceCents: 200,
            ),
            Product(
              id: '2',
              name: 'Caderno Vermelho',
              purchasePriceCents: 500,
              salePriceCents: 800,
            ),
          ]),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'CANETA');
      await tester.pumpAndSettle();

      expect(find.text('Caneta Azul'), findsOneWidget);
      expect(find.text('Caderno Vermelho'), findsNothing);
    });

    testWidgets('busca sem resultado mostra o estado próprio', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          _FakeGetProductsUseCase(const [
            Product(
              id: '1',
              name: 'Caneta',
              purchasePriceCents: 100,
              salePriceCents: 200,
            ),
          ]),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Inexistente');
      await tester.pumpAndSettle();

      expect(find.text('Nenhum produto encontrado'), findsOneWidget);
      expect(find.text('Ajuste a pesquisa ou os filtros.'), findsOneWidget);
      expect(find.text('Limpar filtros'), findsOneWidget);
    });

    testWidgets('busca combina com o filtro de estoque baixo', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          _FakeGetProductsUseCase(const [
            Product(
              id: '1',
              name: 'Caneta',
              purchasePriceCents: 100,
              salePriceCents: 200,
              stockQuantity: 1000, // 1 un. — baixo
            ),
            Product(
              id: '2',
              name: 'Caderno',
              purchasePriceCents: 500,
              salePriceCents: 800,
              stockQuantity: 10000, // 10 un. — OK
            ),
          ]),
        ),
      );
      await tester.pumpAndSettle();

      // Seleciona o chip "Stock baixo"
      await tester.tap(find.text('Stock baixo · 1'));
      await tester.pumpAndSettle();

      expect(find.text('Caneta'), findsOneWidget);
      expect(find.text('Caderno'), findsNothing);
    });

    testWidgets('filtro de produtos usa rótulo próprio "Todos"', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          _FakeGetProductsUseCase(const [
            Product(
              id: '1',
              name: 'Caneta',
              purchasePriceCents: 100,
              salePriceCents: 200,
            ),
          ]),
        ),
      );
      await tester.pumpAndSettle();

      // O chip "Todos" mostra "Todos os produtos · N" (não "Tudo")
      expect(find.text('Todos os produtos · 1'), findsOneWidget);
    });

    testWidgets('ativar venda por peso não quebra o dropdown de unidade', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          _FakeGetProductsUseCase(const []),
          updateUseCase: _updateUseCase(_InMemoryProductRepository()),
        ),
      );
      await tester.pumpAndSettle();

      // Abre sheet de cadastro
      await tester.tap(find.text('Novo produto'));
      await tester.pumpAndSettle();

      // Ativa "Vender por peso"
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      // Dropdown de unidade aparece
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);

      // Seleciona 'g'
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('g').last);
      await tester.pumpAndSettle();

      // Fecha a sheet
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
    });

    testWidgets('cadastro de produto permite definir a validade', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          _FakeGetProductsUseCase(const []),
          updateUseCase: _updateUseCase(_InMemoryProductRepository()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Novo produto'));
      await tester.pumpAndSettle();

      // Preenche campos obrigatórios
      await tester.enterText(find.widgetWithText(TextFormField, 'Nome do produto'), 'Arroz');
      await tester.enterText(find.widgetWithText(TextFormField, 'Preço de compra (MT)'), '10,00');
      await tester.enterText(find.widgetWithText(TextFormField, 'Preço de venda (MT)'), '15,00');
      await tester.enterText(find.widgetWithText(TextFormField, 'Quantidade em stock'), '50');

      // Abre seletor de validade
      await tester.tap(find.text('Definir validade'));
      await tester.pumpAndSettle();

      // Seleciona uma data no futuro (o date picker usa data atual + 30 dias por defeito)
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Submete
      await tester.tap(find.byType(AppButton).first);
      await tester.pumpAndSettle();

      // Verifica sucesso
      expect(find.text('Produto guardado com sucesso'), findsOneWidget);
    });

    testWidgets('tocar no produto abre a edição (dono/gerente)', (tester) async {
      final repository = _InMemoryProductRepository()
        ..add(
          const Product(
            id: '1',
            name: 'Caneta',
            purchasePriceCents: 100,
            salePriceCents: 200,
          ),
        );

      await tester.pumpWidget(
        _buildApp(
          _FakeGetProductsUseCase(const [
            Product(
              id: '1',
              name: 'Caneta',
              purchasePriceCents: 100,
              salePriceCents: 200,
            ),
          ]),
          updateUseCase: _updateUseCase(repository),
        ),
      );
      await tester.pumpAndSettle();

      // Toca no tile do produto → a sheet de edição abre pré-preenchida.
      await tester.tap(find.text('Caneta'));
      await tester.pumpAndSettle();

      expect(find.text('Editar produto'), findsOneWidget);
      expect(find.text('Guardar'), findsOneWidget);
      // Pré-preenchido com os valores atuais.
      expect(find.widgetWithText(TextFormField, 'Caneta'), findsOneWidget);
      expect(find.text('2.00'), findsOneWidget); // preço de venda pré-preenchido
    });

    testWidgets('editar nome e preço salva as alterações', (tester) async {
      final repository = _InMemoryProductRepository()
        ..add(
          const Product(
            id: '1',
            name: 'Caneta',
            purchasePriceCents: 100,
            salePriceCents: 200,
          ),
        );

      await tester.pumpWidget(
        _buildApp(
          _FakeGetProductsUseCase(const [
            Product(
              id: '1',
              name: 'Caneta',
              purchasePriceCents: 100,
              salePriceCents: 200,
            ),
          ]),
          updateUseCase: _updateUseCase(repository),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Caneta'));
      await tester.pumpAndSettle();

      // Altera o nome e o preço de venda.
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Caneta'),
        'Caneta Azul',
      );
      await tester.enterText(find.widgetWithText(TextFormField, '2.00'), '2.50');

      // O botão "Guardar" está no cabeçalho da sheet.
      await tester.ensureVisible(find.text('Guardar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar'), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(); // Extra wait for async operations

      // Snackbar de sucesso + persistência no repositório (estoque intacto).
      expect(find.text('Produto atualizado!'), findsOneWidget);
      expect(repository.products.single.name, 'Caneta Azul');
      expect(repository.products.single.salePriceCents, 250);
      expect(repository.products.single.stockQuantity, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('desativar produto marca Inativo e salva', (tester) async {
      final repository = _InMemoryProductRepository()
        ..add(
          const Product(
            id: '1',
            name: 'Caneta',
            purchasePriceCents: 100,
            salePriceCents: 200,
          ),
        );

      await tester.pumpWidget(
        _buildApp(
          _FakeGetProductsUseCase(const [
            Product(
              id: '1',
              name: 'Caneta',
              purchasePriceCents: 100,
              salePriceCents: 200,
            ),
          ]),
          updateUseCase: _updateUseCase(repository),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Caneta'));
      await tester.pumpAndSettle();

      // Desativa o produto (switch "Produto ativo" → off) e salva.
      await tester.ensureVisible(find.text('Produto ativo'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch).last);
      await tester.pumpAndSettle();

      // O botão "Guardar" está no cabeçalho da sheet.
      await tester.ensureVisible(find.text('Guardar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar'), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(); // Extra wait for async operations

      expect(find.text('Produto atualizado!'), findsOneWidget);
      expect(repository.products.single.isActive, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('produto INATIVO exibe o selo no tile', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          _FakeGetProductsUseCase(const [
            Product(
              id: '1',
              name: 'Caneta',
              purchasePriceCents: 100,
              salePriceCents: 200,
              isActive: false,
            ),
          ]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Inativo'), findsOneWidget);
    });

    testWidgets('exibe erro e permite tentar novamente', (tester) async {
      await tester.pumpWidget(
        _buildApp(_ThrowingGetProductsUseCase()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Não foi possível carregar os produtos.'), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);

      // Tentar novamente não explode (o erro persiste, mas a UI não quebra).
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('não estoura com escala de texto 2.0 em tela estreita', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            textScaler: TextScaler.linear(2.0),
            size: Size(320, 600),
          ),
          child: _buildApp(_FakeGetProductsUseCase(const [])),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ProductListScreen), findsOneWidget);
    });

    testWidgets('produtos sobrevivem à rotação para paisagem', (tester) async {
      await tester.pumpWidget(
        _buildApp(_FakeGetProductsUseCase(const [
          Product(
            id: '1',
            name: 'Caneta',
            purchasePriceCents: 100,
            salePriceCents: 200,
          ),
        ])),
      );
      await tester.pumpAndSettle();

      // Rotação 90°
      await tester.binding.setSurfaceSize(const Size(800, 600));
      await tester.pumpAndSettle();

      expect(find.text('Caneta'), findsOneWidget);

      // Volta ao retrato
      await tester.binding.setSurfaceSize(const Size(600, 800));
      await tester.pumpAndSettle();

      expect(find.text('Caneta'), findsOneWidget);
    });

    testWidgets('funcionário comum NÃO vê o botão de novo produto (só vende)', (tester) async {
      await tester.pumpWidget(
        _buildAppEmployee(_FakeGetProductsUseCase(const [
          Product(
            id: '1',
            name: 'Caneta',
            purchasePriceCents: 100,
            salePriceCents: 200,
          ),
        ])),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.add), findsNothing);
      expect(find.text('Novo produto'), findsNothing);
    });
  });
}