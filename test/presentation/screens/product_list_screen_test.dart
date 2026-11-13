import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/presentation/widgets/app_button.dart';
import 'package:tareqo/presentation/widgets/app_sheet.dart';

import '../../helpers/test_app.dart';

import 'package:tareqo/domain/entities/product.dart';
import 'package:tareqo/domain/repositories/i_product_repository.dart';
import 'package:tareqo/domain/repositories/i_unit_of_work.dart';
import 'package:tareqo/domain/usecases/add_product_use_case.dart';
import 'package:tareqo/domain/usecases/fifo_stock_use_case.dart';
import 'package:tareqo/domain/usecases/get_products_use_case.dart';
import 'package:tareqo/domain/usecases/update_product_stock_use_case.dart';
import 'package:tareqo/domain/usecases/update_product_use_case.dart';
import 'package:tareqo/presentation/controllers/account_providers.dart';
import 'package:tareqo/data/services/product_image_store_noop.dart';
import 'package:tareqo/presentation/controllers/products_providers.dart';
import 'package:tareqo/presentation/screens/products/product_form_sheets.dart';
import 'package:tareqo/presentation/screens/products/product_list_screen.dart';

import '../../helpers/fake_stock_lot_repository.dart';
import '../../helpers/store_context.dart';
import '../../helpers/viewport.dart';

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
    final idx = products.indexWhere(
      (p) => p.id == product.id && p.storeId == product.storeId,
    );
    if (idx >= 0) products[idx] = product;
  }

  @override
  Future<void> updateStock(
    String id,
    int newQuantity, {
    required String storeId,
  }) async {
    final idx = products.indexWhere((p) => p.id == id && p.storeId == storeId);
    if (idx >= 0) {
      products[idx] = products[idx].copyWith(stockQuantity: newQuantity);
    }
  }

  @override
  Future<List<Product>> getAll({required String storeId}) async =>
      products.where((p) => p.storeId == storeId).toList();

  Future<List<Product>> searchByName(
    String query, {
    required String storeId,
  }) async {
    final q = query.toLowerCase();
    return products
        .where(
          (p) =>
              p.storeId == storeId &&
              (p.name.toLowerCase().contains(q) ||
                  p.description.toLowerCase().contains(q)),
        )
        .toList();
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

/// Constrói o [AddProductUseCase] real sobre o repositório em memória.
AddProductUseCase _addUseCase(_InMemoryProductRepository repository) {
  return AddProductUseCase(
    repository,
    FakeStockLotRepository(),
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
  _InMemoryProductRepository? addRepository,
}) {
  return ProviderScope(
    overrides: [
      // Contexto de loja — a lista de produtos escopa pela loja ativa.
      ...storeContextOverrides(),
      getProductsUseCaseProvider.overrideWithValue(useCase),
      // Cadastro/edição: use cases reais sobre fakes em memória (a tela
      // nunca toca em GetIt — o provider é sobrescrito no ProviderScope).
      addProductUseCaseProvider.overrideWithValue(
        _addUseCase(addRepository ?? _InMemoryProductRepository()),
      ),
      updateProductUseCaseProvider.overrideWithValue(
        updateUseCase ?? _updateUseCase(_InMemoryProductRepository()),
      ),
      // Fotos: no-op em testes (sem disco/Storage — a UI cai no fallback
      // de ícone; sem override, o provider chamaria o GetIt não configurado).
      productImageStoreProvider.overrideWithValue(
        const ProductImageStoreNoop(),
      ),
    ],
    child: testApp(home: const ProductListScreen()),
  );
}

/// Produtos com o utilizador logado como FUNCIONÁRIO comum: `currentAccessLevel`
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
    child: testApp(home: const ProductListScreen()),
  );
}

void main() {
  group('ProductListScreen', () {
    // A11y (Fase 6): busca, filtros e linhas de produto passam nos
    // guidelines de toque (≥48dp) e contraste de texto.
    testWidgets('a11y: stock passa nos guidelines de toque e contraste', (
      tester,
    ) async {
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

      final handle = tester.ensureSemantics();
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    // A11y (plano UI/UX — Fase 3.1): o tile de produto é UM nó semântico —
    // nome, detalhe, preço, estoque e estado lidos de uma vez (o texto
    // visual do nome NÃO tem nó próprio — excludeSemantics).
    testWidgets('tile de produto expõe rótulo composto', (tester) async {
      // Handle ANTES do pump: a árvore de semântica é construída no frame.
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _buildApp(
          _FakeGetProductsUseCase(const [
            Product(
              id: '1',
              name: 'Caderno',
              description: '200 folhas',
              purchasePriceCents: 500,
              salePriceCents: 800,
              stockQuantity: 5000,
            ),
          ]),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel(RegExp(r'^Caderno: 200 folhas, R\$ 8,00, ')),
        findsOneWidget,
      );
      // O texto visual resolve para o nó PAI composto — nunca anunciado
      // sozinho.
      expect(
        tester.getSemantics(find.text('Caderno')).label,
        startsWith('Caderno: 200 folhas, R\$ 8,00'),
      );
      handle.dispose();
    });

    testWidgets('exibe os produtos retornados pelo caso de uso', (
      tester,
    ) async {
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
      await tester.pumpWidget(_buildApp(_FakeGetProductsUseCase(const [])));
      await tester.pumpAndSettle();

      expect(find.text('Nenhum produto cadastrado'), findsOneWidget);
      expect(
        find.text('Toque em "Novo produto" para começar.'),
        findsOneWidget,
      );
    });

    testWidgets('busca por nome filtra a lista (case-insensitive)', (
      tester,
    ) async {
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

      // A busca agora vive no sheet de filtros avançados (AppBar →
      // botão "Filtrar"): digita a query e aplica.
      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'CANETA');
      await tester.tap(find.text('Aplicar'));
      await tester.pumpAndSettle();

      expect(find.text('Caneta Azul'), findsOneWidget);
      expect(find.text('Caderno Vermelho'), findsNothing);
    });

    testWidgets('lupa abre a busca inline e filtra ao digitar', (tester) async {
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

      // A lupa da AppBar abre o campo de busca no topo da lista.
      await tester.tap(find.byIcon(Icons.search_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'CANETA');
      await tester.pumpAndSettle();
      expect(find.text('Caneta Azul'), findsOneWidget);
      expect(find.text('Caderno Vermelho'), findsNothing);

      // O X limpa e fecha a busca, devolvendo a lista completa.
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Caderno Vermelho'), findsOneWidget);
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

      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Inexistente');
      await tester.tap(find.text('Aplicar'));
      await tester.pumpAndSettle();

      expect(find.text('Nenhum produto encontrado'), findsOneWidget);
      expect(find.text('Ajuste a pesquisa ou os filtros.'), findsOneWidget);
      expect(find.text('Limpar filtros'), findsOneWidget);
    });

    testWidgets('busca combina com o filtro de stock baixo', (tester) async {
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

      // Abre o sheet avançado e seleciona o chip "Stock baixo" da
      // seção STATUS (a seção Disponibilidade tem um chip homônimo —
      // escopa pela primeira SheetSection para acertar o status).
      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.widgetWithText(SheetSection, 'Status'),
          matching: find.text('Stock baixo'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aplicar'));
      await tester.pumpAndSettle();

      expect(find.text('Caneta'), findsOneWidget);
      expect(find.text('Caderno'), findsNothing);
    });

    testWidgets('chip de categoria na lista filtra os produtos', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          _FakeGetProductsUseCase(const [
            Product(
              id: '1',
              name: 'Refrigerante',
              purchasePriceCents: 300,
              salePriceCents: 500,
              category: 'Bebidas',
            ),
            Product(
              id: '2',
              name: 'Pão de forma',
              purchasePriceCents: 500,
              salePriceCents: 800,
              category: 'Padaria',
            ),
            Product(
              id: '3',
              name: 'Caneta',
              purchasePriceCents: 100,
              salePriceCents: 200,
            ),
          ]),
        ),
      );
      await tester.pumpAndSettle();

      // Faixa rápida: todas, sem categoria e os rótulos do catálogo.
      expect(find.text('Bebidas'), findsOneWidget);
      expect(find.text('Padaria'), findsOneWidget);

      await tester.tap(find.text('Bebidas'));
      await tester.pumpAndSettle();

      expect(find.text('Refrigerante'), findsOneWidget);
      expect(find.text('Pão de forma'), findsNothing);
      expect(find.text('Caneta'), findsNothing);
      // O subtítulo reflecte o filtro ativo.
      expect(find.text('1 produto'), findsOneWidget);

      // "Todas" limpa a categoria e devolve o catálogo completo.
      await tester.tap(find.text('Todas'));
      await tester.pumpAndSettle();
      expect(find.text('Pão de forma'), findsOneWidget);
      expect(find.text('Caneta'), findsOneWidget);
      expect(find.text('3 produtos'), findsOneWidget);

      await tester.tap(find.text('Sem categoria'));
      await tester.pumpAndSettle();
      expect(find.text('Caneta'), findsOneWidget);
      expect(find.text('Refrigerante'), findsNothing);
      expect(find.text('Pão de forma'), findsNothing);
      expect(find.text('1 produto'), findsOneWidget);
      await tester.tap(find.text('Limpar filtros'));
      await tester.pumpAndSettle();
      expect(find.text('3 produtos'), findsOneWidget);
    });

    testWidgets('categoria combina com busca e limpar devolve catálogo', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          _FakeGetProductsUseCase(const [
            Product(
              id: '1',
              name: 'Água',
              category: 'Bebidas',
              purchasePriceCents: 100,
              salePriceCents: 200,
            ),
            Product(
              id: '2',
              name: 'Sumo',
              category: ' bebidas ',
              purchasePriceCents: 100,
              salePriceCents: 200,
            ),
            Product(
              id: '3',
              name: 'Pão',
              category: 'Padaria',
              purchasePriceCents: 100,
              salePriceCents: 200,
            ),
          ]),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bebidas'));
      await tester.pumpAndSettle();
      expect(find.text('2 produtos'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.search_rounded));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'sumo');
      await tester.pumpAndSettle();
      expect(find.text('Sumo'), findsOneWidget);
      expect(find.text('Água'), findsNothing);
      await tester.enterText(find.byType(TextField), 'pão');
      await tester.pumpAndSettle();
      expect(find.text('Nenhum produto encontrado'), findsOneWidget);
      await tester.tap(find.text('Limpar filtros'));
      await tester.pumpAndSettle();
      expect(find.text('3 produtos'), findsOneWidget);
    });

    testWidgets('filtro avançado inclui a secção de categoria', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          _FakeGetProductsUseCase(const [
            Product(
              id: '1',
              name: 'Refrigerante',
              purchasePriceCents: 300,
              salePriceCents: 500,
              category: 'Bebidas',
            ),
            Product(
              id: '2',
              name: 'Pão de forma',
              purchasePriceCents: 500,
              salePriceCents: 800,
              category: 'Padaria',
            ),
          ]),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();

      // A primeira secção do sheet é a de categoria (chips + "Todas").
      final section = find.byType(SheetSection).first;
      expect(
        find.descendant(of: section, matching: find.text('Padaria')),
        findsOneWidget,
      );
      await tester.tap(
        find.descendant(of: section, matching: find.text('Padaria')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aplicar'));
      await tester.pumpAndSettle();

      expect(find.text('Pão de forma'), findsOneWidget);
      expect(find.text('Refrigerante'), findsNothing);
    });

    testWidgets('filtro de produtos usa rótulo próprio "Todos"', (
      tester,
    ) async {
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

      // Abre o sheet de filtros: o filtro padrão é o chip "Todos"
      // (não "Tudo") — aparece nas seções Status e Disponibilidade.
      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Todos'), findsWidgets);

      // Aplica sem mudanças e verifica a contagem do cabeçalho.
      await tester.tap(find.text('Aplicar'));
      await tester.pumpAndSettle();
      expect(find.text('1 produto'), findsOneWidget);
    });

    testWidgets('ativar venda por peso não quebra o dropdown de unidade', (
      tester,
    ) async {
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

      // Ativa "Venda por peso (fração)" — o switch pode ficar abaixo da
      // dobra na sheet; garante visibilidade antes do tap.
      await tester.ensureVisible(find.byType(Switch).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      // Dropdown de unidade aparece
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);

      // Seleciona 'g'
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('g').last);
      await tester.pumpAndSettle();

      // O formulário é rolável; volta ao cabeçalho antes de fechar.
      await tester.ensureVisible(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.byType(AddProductSheet), findsNothing);
    });

    testWidgets('cadastro de produto permite definir a validade', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          _FakeGetProductsUseCase(const []),
          updateUseCase: _updateUseCase(_InMemoryProductRepository()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Novo produto'));
      await tester.pumpAndSettle();

      // Preenche campos obrigatórios (rótulos atuais do design system).
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nome'),
        'Arroz',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Preço de compra'),
        '10,00',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Preço de venda'),
        '15,00',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Quantidade em stock'),
        '50',
      );

      // Abre seletor de validade (pode ficar abaixo da dobra).
      await tester.ensureVisible(find.text('Definir validade'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Definir validade'));
      await tester.pumpAndSettle();

      // Seleciona uma data no futuro (o date picker usa data atual + 30 dias por defeito)
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Submete — o AppButton DENTRO da sheet de cadastro (a tela de
      // fundo também tem um AppButton: o CTA "Novo produto" do estado
      // vazio, então não dá para usar `find.byType(AppButton).first`).
      final submit = find.descendant(
        of: find.byType(AddProductSheet),
        matching: find.byType(AppButton),
      );
      await tester.ensureVisible(submit);
      await tester.pumpAndSettle();
      await tester.tap(submit);
      await tester.pumpAndSettle();

      // Verifica sucesso
      expect(find.text('Produto adicionado!'), findsOneWidget);
    });

    testWidgets('cadastro guarda o código de barras lido (QR/EAN)', (
      tester,
    ) async {
      // Viewport retrato alto: o formulário completo (com o barcode) e a
      // ação cabem sem depender de scroll em tela de teste baixa.
      usePortraitViewport(tester);
      final repository = _InMemoryProductRepository();
      await tester.pumpWidget(
        _buildApp(_FakeGetProductsUseCase(const []), addRepository: repository),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Novo produto'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nome'),
        'Leite',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Preço de compra'),
        '40,00',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Preço de venda'),
        '70,00',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Quantidade em stock'),
        '10',
      );
      // Mesmo valor que o scanner QR/EAN preenche no formulário.
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Código de barras'),
        '7891000315507',
      );

      final submit = find.descendant(
        of: find.byType(AddProductSheet),
        matching: find.byType(AppButton),
      );
      await tester.ensureVisible(submit);
      await tester.pumpAndSettle();
      await tester.tap(submit);
      await tester.pumpAndSettle();

      // O barcode deixa de ser descartado no save (bug do QR "não
      // encontrado" no PDV): chega ao repositório tal como foi lido.
      expect(repository.products, hasLength(1));
      expect(repository.products.single.barcode, '7891000315507');
    });

    testWidgets('cadastro guarda a categoria e a sugestão preenche o campo', (
      tester,
    ) async {
      usePortraitViewport(tester);
      final repository = _InMemoryProductRepository();
      await tester.pumpWidget(
        _buildApp(
          _FakeGetProductsUseCase(const [
            Product(
              id: '9',
              name: 'Sumo',
              purchasePriceCents: 300,
              salePriceCents: 500,
              category: 'Bebidas',
            ),
          ]),
          addRepository: repository,
        ),
      );
      await tester.pumpAndSettle();

      // Catálogo não vazio: o cadastro abre pelo FAB.
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nome'),
        'Água',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Preço de compra'),
        '1,00',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Preço de venda'),
        '2,00',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Quantidade em stock'),
        '10',
      );

      // A categoria existente aparece como sugestão e preenche o campo.
      final suggestion = find.descendant(
        of: find.byType(AddProductSheet),
        matching: find.text('Bebidas'),
      );
      await tester.ensureVisible(suggestion);
      await tester.pumpAndSettle();
      await tester.tap(suggestion);
      await tester.pumpAndSettle();

      final submit = find.descendant(
        of: find.byType(AddProductSheet),
        matching: find.byType(AppButton),
      );
      await tester.ensureVisible(submit);
      await tester.pumpAndSettle();
      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(repository.products, hasLength(1));
      expect(repository.products.single.category, 'Bebidas');
    });

    testWidgets('cadastro guarda QR alfanumérico (URL) inteiro, sem truncar', (
      tester,
    ) async {
      // Regressão do "produto não encontrado": o QR de URL era rejeitado
      // pela validação "só dígitos" e truncado em 13 caracteres. Agora o
      // campo aceita o conteúdo opaco do QR e guarda o texto bruto.
      usePortraitViewport(tester);
      const qr = 'https://tareqo.app/p/7891000315507?lote=42';
      final repository = _InMemoryProductRepository();
      await tester.pumpWidget(
        _buildApp(_FakeGetProductsUseCase(const []), addRepository: repository),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Novo produto'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nome'),
        'Leite',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Preço de compra'),
        '40,00',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Preço de venda'),
        '70,00',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Quantidade em stock'),
        '10',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Código de barras'),
        qr,
      );

      final submit = find.descendant(
        of: find.byType(AddProductSheet),
        matching: find.byType(AppButton),
      );
      await tester.ensureVisible(submit);
      await tester.pumpAndSettle();
      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(repository.products, hasLength(1));
      expect(repository.products.single.barcode, qr);
    });

    testWidgets('tocar no produto abre a edição (dono/gerente)', (
      tester,
    ) async {
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
      expect(find.text('Guardar alterações'), findsOneWidget);
      // Pré-preenchido com os valores atuais.
      expect(find.widgetWithText(TextFormField, 'Caneta'), findsOneWidget);
      expect(
        find.text('2.00'),
        findsOneWidget,
      ); // preço de venda pré-preenchido
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
      await tester.enterText(
        find.widgetWithText(TextFormField, '2.00'),
        '2.50',
      );

      // O botão "Guardar alterações" fica no rodapé da sheet.
      await tester.ensureVisible(find.text('Guardar alterações'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar alterações'), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(); // Extra wait for async operations

      // Snackbar de sucesso + persistência no repositório (stock intacto).
      expect(find.text('Produto atualizado!'), findsOneWidget);
      expect(repository.products.single.name, 'Caneta Azul');
      expect(repository.products.single.salePriceCents, 250);
      expect(repository.products.single.stockQuantity, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('editar categoria guarda a alteração', (tester) async {
      usePortraitViewport(tester);
      final repository = _InMemoryProductRepository()
        ..add(
          const Product(
            id: '1',
            name: 'Caneta',
            purchasePriceCents: 100,
            salePriceCents: 200,
            category: 'Papelaria',
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
              category: 'Papelaria',
            ),
          ]),
          updateUseCase: _updateUseCase(repository),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Caneta'));
      await tester.pumpAndSettle();

      // Campo pré-preenchido com a categoria atual e editável.
      final field = find.widgetWithText(TextFormField, 'Papelaria');
      await tester.ensureVisible(field);
      await tester.pumpAndSettle();
      await tester.enterText(field, 'Escritório');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Guardar alterações'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar alterações'), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      expect(repository.products.single.category, 'Escritório');
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

      // Desativa o produto (switch "Produto activo" → off) e salva.
      await tester.ensureVisible(find.text('Produto activo'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch).last);
      await tester.pumpAndSettle();

      // O botão "Guardar alterações" fica no rodapé da sheet.
      await tester.ensureVisible(find.text('Guardar alterações'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar alterações'), warnIfMissed: false);
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

      expect(find.text('Inactivo'), findsOneWidget);
    });

    testWidgets('exibe erro e permite tentar novamente', (tester) async {
      await tester.pumpWidget(_buildApp(_ThrowingGetProductsUseCase()));
      await tester.pumpAndSettle();

      expect(
        find.text('Não foi possível carregar os produtos.'),
        findsOneWidget,
      );
      expect(find.text('Tentar novamente'), findsOneWidget);

      // Tentar novamente não explode (o erro persiste, mas a UI não quebra).
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('não estoura com escala de texto 2.0 em tela estreita', (
      tester,
    ) async {
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

      // Rotação 90°
      await tester.binding.setSurfaceSize(const Size(800, 600));
      await tester.pumpAndSettle();

      expect(find.text('Caneta'), findsOneWidget);

      // Volta ao retrato
      await tester.binding.setSurfaceSize(const Size(600, 800));
      await tester.pumpAndSettle();

      expect(find.text('Caneta'), findsOneWidget);
    });
    testWidgets('funcionário comum NÃO vê o botão de novo produto (só vende)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildAppEmployee(
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

      expect(find.byIcon(Icons.add), findsNothing);
      expect(find.text('Novo produto'), findsNothing);
    });
  });

  group('Guard de remoção de foto do produto', () {
    // Produto COM foto (caminho não-vazio ativa a lixeira no picker).
    Product photoProduct() => const Product(
      id: '1',
      name: 'Caneta',
      purchasePriceCents: 100,
      salePriceCents: 200,
      imagePath: '/tmp/foto.jpg',
    );

    Future<void> openEditSheet(WidgetTester tester) async {
      await tester.pumpWidget(
        _buildApp(_FakeGetProductsUseCase([photoProduct()])),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Caneta'));
      await tester.pumpAndSettle();
    }

    testWidgets('toque na lixeira NÃO remove a foto sem confirmar', (
      tester,
    ) async {
      await openEditSheet(tester);

      // Anti-flicker: a lixeira só entra na árvore se há foto (i.i.).
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);

      // Um toque NÃO pode remover — o diálogo de confirmação aparece.
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('Remover fotografia'), findsOneWidget);
      expect(find.text('Guardar alterações'), findsOneWidget);
    });

    testWidgets('cancelar mantém a foto intacta', (tester) async {
      await openEditSheet(tester);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      // Cancela (TextButton do confirm dialog).
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      // A foto continua no preview (não removida) e o sheet segue aberto.
      expect(find.text('Remover fotografia'), findsNothing);
      expect(find.text('Guardar alterações'), findsOneWidget);
    });
  });
}
