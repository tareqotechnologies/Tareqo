import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';
import '../../helpers/viewport.dart';

import 'package:dumbhanengue/domain/entities/app_user.dart';
import 'package:dumbhanengue/domain/entities/product.dart';
import 'package:dumbhanengue/domain/entities/store.dart';
import 'package:dumbhanengue/domain/entities/store_employee.dart';
import 'package:dumbhanengue/domain/repositories/i_product_repository.dart';
import 'package:dumbhanengue/domain/repositories/i_unit_of_work.dart';
import 'package:dumbhanengue/domain/usecases/fifo_stock_use_case.dart';
import 'package:dumbhanengue/domain/usecases/get_employees_use_case.dart';
import 'package:dumbhanengue/domain/usecases/get_products_use_case.dart';
import 'package:dumbhanengue/domain/usecases/update_product_stock_use_case.dart';
import 'package:dumbhanengue/domain/usecases/update_product_use_case.dart';
import 'package:dumbhanengue/presentation/controllers/account_providers.dart';
import 'package:dumbhanengue/presentation/controllers/auth_providers.dart';
import 'package:dumbhanengue/data/services/product_image_store_noop.dart';
import 'package:dumbhanengue/presentation/controllers/products_providers.dart';
import 'package:dumbhanengue/presentation/screens/products/product_list_screen.dart';
import 'package:dumbhanengue/presentation/widgets/list_skeleton.dart';

import '../../helpers/fake_stock_lot_repository.dart';
import '../../helpers/store_context.dart';

/// Fake do [GetProductsUseCase] — a tela nunca toca em GetIt nem em
/// datasources; o provider é sobrescrito no [ProviderScope].
class _FakeGetProductsUseCase implements GetProductsUseCase {
 _FakeGetProductsUseCase(this._products);

 final List<Product> _products;

 @override
 Future<List<Product>> call({required String storeId}) async => _products;
}

/// Repositório de produtos em memória (edição real sem GetIt).
class _InMemoryProductRepository implements IProductRepository {
 final List<Product> products = [];

 @override
 Future<List<Product>> getAll({required String storeId}) async =>
 List.unmodifiable(products);

 @override
 Future<Product?> getById(String id, {required String storeId}) async {
 for (final product in products) {
 if (product.id == id && product.storeId == storeId) return product;
 }
 return null;
 }

 @override
 Future<void> add(Product product) async => products.add(product);

 @override
 Future<void> update(Product product) async {
 final index = products.indexWhere(
 (p) => p.id == product.id && p.storeId == product.storeId,
 );
 final current = products[index];
 products[index] = current.copyWith(
 name: product.name,
 description: product.description,
 purchasePriceCents: product.purchasePriceCents,
 salePriceCents: product.salePriceCents,
 code: product.code,
 vendaPorFracao: product.vendaPorFracao,
 unitLabel: product.unitLabel,
 isActive: product.isActive,
 );
 }

 @override
 Future<void> updateStock(
 String id,
 int newQuantity, {
 required String storeId,
 }) async {
 final index = products.indexWhere(
 (p) => p.id == id && p.storeId == storeId,
 );
 products[index] = products[index].copyWith(stockQuantity: newQuantity);
 }
}

/// Unit of work no-op para o caminho composto da edição.
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
///
/// Atenção: Não usa `storeContextOverrides()`: o helper fixa o usuário como DONO
/// do tenant (ownerUserId = userId) e registra `authStateProvider` — um
/// segundo override do MESMO provider quebraria com "Tried to override a
/// provider twice". Aqui o usuário é 'u1' e o tenant pertence a '9'.
Widget _buildAppAsEmployee(GetProductsUseCase useCase) {
 return ProviderScope(
 overrides: [
 authStateProvider.overrideWith(
 (ref) => Stream.value(AppUser(id: 'u1', email: 'func@loja.com')),
 ),
 getMyTenantUseCaseProvider.overrideWithValue(
 FakeGetMyTenantUseCase(approvedTenant(ownerUserId: '9')),
 ),
 getStoresUseCaseProvider.overrideWithValue(
 FakeGetStoresUseCase(const [
 Store(id: 'st1', tenantId: 'tn1', name: 'Loja Centro'),
 ]),
 ),
 getEmployeesUseCaseProvider.overrideWithValue(_FakeGetEmployeesUseCase()),
 getProductsUseCaseProvider.overrideWithValue(useCase),
 ],
 child: testApp(home: ProductListScreen()),
 );
}

class _FakeGetEmployeesUseCase implements GetEmployeesUseCase {
 @override
 Future<List<StoreEmployee>> call(String tenantId) async => const [
 StoreEmployee(
 id: 'e1',
 tenantId: 'tn1',
 storeId: 'st1',
 userId: 'u1',
 fullName: 'Funcionária',
 email: 'func@loja.com',
 role: EmployeeRole.employee,
 ),
 ];
}

void main() {
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
 salePriceCents: 990,
 ),
 ]),
 ),
 );

 // Estado inicial: carregando — skeleton da lista (padrão das telas).
 expect(find.byType(ListSkeleton), findsOneWidget);

 await tester.pumpAndSettle();

 expect(find.text('Caneta'), findsOneWidget);
 expect(find.text('Caderno'), findsOneWidget);
 // Rolodex V3 (canvas): preço de venda em destaque na coluna direita.
 expect(find.text('R\$ 2,00'), findsOneWidget); // Caneta (200 centavos)
 expect(find.text('R\$ 9,90'), findsOneWidget); // Caderno (990 centavos)
 });

 testWidgets('exibe estado vazio quando não há produtos', (tester) async {
 await tester.pumpWidget(_buildApp(_FakeGetProductsUseCase(const [])));

 await tester.pumpAndSettle();

 expect(find.text('Nenhum produto cadastrado'), findsOneWidget);
 // CTA ÚNICO: no estado vazio o FAB some e o EmptyState traz o botão.
 expect(find.text('Novo produto'), findsOneWidget);
 expect(find.byType(FloatingActionButton), findsNothing);
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
 name: 'Caderno',
 purchasePriceCents: 500,
 salePriceCents: 990,
 ),
 ]),
 ),
 );
 await tester.pumpAndSettle();

 expect(find.text('Caneta Azul'), findsOneWidget);
 expect(find.text('Caderno'), findsOneWidget);

 // MAIÚSCULAS: o termo digitado é normalizado — 'CANETA' acha
 // 'Caneta Azul' (regressão: antes o query não era convertido e a
 // busca com maiúscula não achava nada).
 await tester.enterText(find.byType(TextField), 'CANETA');
 await tester.pumpAndSettle();

 expect(find.text('Caneta Azul'), findsOneWidget);
 expect(find.text('Caderno'), findsNothing);

 // Parte do nome, minúscula — filtra para o outro produto.
 await tester.enterText(find.byType(TextField), 'cad');
 await tester.pumpAndSettle();

 expect(find.text('Caderno'), findsOneWidget);
 expect(find.text('Caneta Azul'), findsNothing);
 });

 testWidgets('busca sem resultado mostra o estado próprio', (tester) async {
 await tester.pumpWidget(
 _buildApp(
 _FakeGetProductsUseCase(const [
 Product(
 id: '1',
 name: 'Caneta Azul',
 purchasePriceCents: 100,
 salePriceCents: 200,
 ),
 ]),
 ),
 );
 await tester.pumpAndSettle();

 await tester.enterText(find.byType(TextField), 'zzz');
 await tester.pumpAndSettle();

 expect(find.text('Nenhum resultado'), findsOneWidget);
 expect(find.text('Caneta Azul'), findsNothing);
 });

 testWidgets('busca combina com o filtro de estoque baixo', (tester) async {
 await tester.pumpWidget(
 _buildApp(
 _FakeGetProductsUseCase(const [
 // Estoque 0 (milésimos) → abaixo do limiar (5 unidades = 5000):
 // entra no filtro de estoque baixo.
 Product(
 id: '1',
 name: 'Caneta Azul',
 purchasePriceCents: 100,
 salePriceCents: 200,
 ),
 // Estoque 10 unidades → fora do filtro.
 Product(
 id: '2',
 name: 'Caderno',
 purchasePriceCents: 500,
 salePriceCents: 990,
 stockQuantity: 10000,
 ),
 ]),
 ),
 );
 await tester.pumpAndSettle();

 // Ativa o filtro rápido de estoque baixo (chips V3 do canvas).
 await tester.tap(find.textContaining('Estoque baixo'));
 await tester.pumpAndSettle();

 expect(find.text('Caneta Azul'), findsOneWidget);
 expect(find.text('Caderno'), findsNothing);

 // Buscar um produto fora do filtro → sem resultados.
 await tester.enterText(find.byType(TextField), 'caderno');
 await tester.pumpAndSettle();
 expect(find.text('Nenhum resultado'), findsOneWidget);
 expect(find.text('Caneta Azul'), findsNothing);

 // Buscar um produto DENTRO do filtro → aparece.
 await tester.enterText(find.byType(TextField), 'caneta');
 await tester.pumpAndSettle();
 expect(find.text('Caneta Azul'), findsOneWidget);
 });

 // Microcopy: o filtro "todos os produtos" tem rótulo PRÓPRIO ("Todos")
 // — distinto do "Tudo" do período; "Tudo" (neutro) soaria estranho num
 // menu de produtos ao lado de "Estoque baixo"/"Inativos".
 testWidgets('filtro de produtos usa rótulo próprio "Todos"', (tester) async {
 await tester.pumpWidget(
 _buildApp(
 _FakeGetProductsUseCase(const [
 Product(
 id: '1',
 name: 'Caneta Azul',
 purchasePriceCents: 100,
 salePriceCents: 200,
 ),
 ]),
 ),
 );
 await tester.pumpAndSettle();

 // Chips V3 do canvas: rótulo "Todos · 1" com a contagem real; o
 // rótulo do período ("Tudo") não aparece.
 expect(find.text('Todos · 1'), findsOneWidget);
 expect(find.textContaining('Estoque baixo'), findsOneWidget);
 expect(find.text('Inativos'), findsOneWidget);
 expect(find.text('Tudo'), findsNothing);
 });

 // Regressão (W11): ativar "Venda por peso" renderizava o dropdown de
 // unidade com o valor padrão 'un' — que não existe na lista de itens
 // (kg/g/l/ml) — e o DropdownButtonFormField lançava a asserção "exactly
 // one item with value 'un'" (crash reportado em produção).
 testWidgets('ativar venda por peso não quebra o dropdown de unidade', (
 tester,
 ) async {
 await tester.pumpWidget(_buildApp(_FakeGetProductsUseCase(const [])));
 await tester.pumpAndSettle();

 // Abre o cadastro pelo CTA único do estado vazio.
 await tester.tap(find.text('Novo produto'));
 await tester.pumpAndSettle();

 // Antes do toggle: sem dropdown de unidade.
 expect(find.byType(DropdownButtonFormField<String>), findsNothing);

 // O seletor de foto adicionou altura no topo da sheet — garante que
 // o toggle fique visível no viewport curto do teste antes do tap.
 await tester.ensureVisible(find.textContaining('Venda por peso'));
 await tester.pumpAndSettle();

 // Ativa "Venda por peso" — o bug lançava asserção aqui.
 await tester.tap(find.textContaining('Venda por peso'));
 await tester.pumpAndSettle();

 // Sem crash; o dropdown aparece com 'kg' (unidade padrão válida).
 expect(tester.takeException(), isNull);
 expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);

 // A sheet é rolável e o viewport de teste é curto — garante que o
 // dropdown fique visível antes de interagir com ele.
 await tester.ensureVisible(find.byType(DropdownButtonFormField<String>));
 await tester.pumpAndSettle();
 expect(find.text('kg'), findsOneWidget);

 // Trocando a unidade para 'g' também funciona.
 await tester.tap(find.text('kg'));
 await tester.pumpAndSettle();
 await tester.tap(find.text('g').last);
 await tester.pumpAndSettle();
 expect(tester.takeException(), isNull);

 // Desativa: dropdown some e nada quebra.
 await tester.tap(find.textContaining('Venda por peso'));
 await tester.pumpAndSettle();
 expect(tester.takeException(), isNull);
 expect(find.byType(DropdownButtonFormField<String>), findsNothing);
 });

 // W11: o cadastro de produto aceita validade — o lote inicial do
 // estoque de abertura nasce com ela e o dashboard passa a alertar
 // (vermelho = vencido; amarelo = vence em < 30 dias).
 testWidgets('cadastro de produto permite definir a validade', (tester) async {
 await tester.pumpWidget(_buildApp(_FakeGetProductsUseCase(const [])));
 await tester.pumpAndSettle();

 await tester.tap(find.text('Novo produto'));
 await tester.pumpAndSettle();

 // Sem validade: botão "Definir validade" visível (a sheet é rolável
 // e o viewport de teste é curto — garante visibilidade primeiro).
 await tester.ensureVisible(find.text('Definir validade'));
 await tester.pumpAndSettle();
 expect(find.text('Definir validade'), findsOneWidget);

 // Abre o date picker e confirma a data sugerida (hoje + 30 dias).
 await tester.tap(find.text('Definir validade'));
 await tester.pumpAndSettle();
 await tester.tap(find.text('OK'));
 await tester.pumpAndSettle();

 // A data escolhida aparece no botão e o botão de limpar surge.
 expect(find.textContaining('Validade ·'), findsOneWidget);
 expect(find.byTooltip('Remover validade'), findsOneWidget);
 expect(tester.takeException(), isNull);

 // Limpar volta ao estado inicial.
 await tester.tap(find.byTooltip('Remover validade'));
 await tester.pumpAndSettle();
 expect(find.text('Definir validade'), findsOneWidget);
 expect(tester.takeException(), isNull);
 });

 testWidgets('tocar no produto abre a edição (dono/gerente)', (tester) async {
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

 // Toca no tile do produto → a sheet de edição abre pré-preenchida.
 await tester.tap(find.text('Caneta'));
 await tester.pumpAndSettle();

 expect(find.text('Editar produto'), findsOneWidget);
 expect(find.text('Salvar alterações'), findsOneWidget);
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
 await tester.ensureVisible(find.text('Salvar alterações'));
 await tester.pumpAndSettle();
 await tester.tap(find.text('Salvar alterações'));
 await tester.pumpAndSettle();

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
 await tester.ensureVisible(find.text('Salvar alterações'));
 await tester.pumpAndSettle();
 await tester.tap(find.text('Salvar alterações'));
 await tester.pumpAndSettle();

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

 // Selo "Inativo" visível (produto permanece no histórico da loja).
 expect(find.text('Inativo'), findsOneWidget);
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

 // Regressão (UI): o chip de estoque ficava sem Flexível e o texto do
 // card sem ellipsis — com escala de texto 2.0 em tela estreita, o Row
 // estourava. Agora o nome/descrição cedem espaço e o chip encolhe;
 // overflows de RenderFlex falham o teste via takeException.
 testWidgets('não estoura com escala de texto 2.0 em tela estreita', (
 tester,
 ) async {
 tester.platformDispatcher.textScaleFactorTestValue = 2.0;
 addTearDown(tester.platformDispatcher.clearAllTestValues);

 // Estreita (360) porém alta: garante que o tile seja construído/pintado
 // com escala 2.0 (abaixo do fold o overflow ficaria mascarado).
 tester.view.physicalSize = const Size(360, 2000);
 tester.view.devicePixelRatio = 1.0;
 addTearDown(tester.view.reset);

 await tester.pumpWidget(
 _buildApp(
 _FakeGetProductsUseCase(const [
 Product(
 id: '1',
 name: 'Teclado Mecânico RGB com descrição bem comprida',
 purchasePriceCents: 123456,
 salePriceCents: 234567,
 stockQuantity: 9999,
 ),
 ]),
 ),
 );
 await tester.pumpAndSettle();

 // O produto continua visível (o texto é truncado visualmente, não
 // removido) e nenhum overflow foi registrado.
 expect(
 find.text('Teclado Mecânico RGB com descrição bem comprida'),
 findsOneWidget,
 );
 expect(tester.takeException(), isNull);
 });

 // Rotação (UI): aba Produtos em paisagem — lista e busca seguem
 // íntegras após o giro, sem overflow. Overflows de RenderFlex falham o
 // teste via takeException.
 testWidgets('produtos sobrevivem à rotação para paisagem', (tester) async {
 usePortraitViewport(tester);

 await tester.pumpWidget(
 _buildApp(
 _FakeGetProductsUseCase(const [
 Product(
 id: '1',
 name: 'Caneta',
 purchasePriceCents: 100,
 salePriceCents: 200,
 stockQuantity: 50,
 ),
 Product(
 id: '2',
 name: 'Caderno',
 purchasePriceCents: 500,
 salePriceCents: 990,
 stockQuantity: 20,
 ),
 ]),
 ),
 );
 await tester.pumpAndSettle();

 // Retrato: busca e os dois produtos visíveis.
 expect(find.byType(TextField), findsOneWidget);
 expect(find.text('Caneta'), findsOneWidget);
 expect(find.text('Caderno'), findsOneWidget);
 expect(tester.takeException(), isNull);

 // Gira para paisagem.
 await rotateToLandscape(tester);

 // Sem overflow; busca e produtos seguem presentes após o giro.
 expect(tester.takeException(), isNull);
 expect(find.byType(TextField), findsOneWidget);
 expect(find.text('Caneta'), findsOneWidget);
 expect(find.text('Caderno'), findsOneWidget);
 });

 testWidgets('funcionário comum NÃO vê o botão de novo produto (só vende)', (
 tester,
 ) async {
 await tester.pumpWidget(
 _buildAppAsEmployee(
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

 // O botão de cadastro SOME para o funcionário; a lista segue visível
 // (ele vende — só não cria produtos).
 expect(find.text('Novo produto'), findsNothing);
 expect(find.byType(FloatingActionButton), findsNothing);
 expect(find.text('Caneta'), findsOneWidget);
 });
}
