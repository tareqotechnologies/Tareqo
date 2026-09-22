import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';
import '../../helpers/store_context.dart';

import 'package:tareqo/domain/entities/product.dart';
import 'package:tareqo/domain/entities/store.dart';
import 'package:tareqo/domain/repositories/i_product_repository.dart';
import 'package:tareqo/domain/repositories/i_unit_of_work.dart';
import 'package:tareqo/domain/usecases/fifo_stock_use_case.dart';
import 'package:tareqo/domain/usecases/add_product_use_case.dart';
import 'package:tareqo/domain/usecases/get_products_use_case.dart';
import 'package:tareqo/domain/usecases/update_product_use_case.dart';
import 'package:tareqo/presentation/controllers/products_providers.dart';
import 'package:tareqo/presentation/widgets/app_button.dart';
import 'package:tareqo/presentation/widgets/app_picker_field.dart';
import 'package:tareqo/presentation/controllers/stock_transfers_provider.dart';
import 'package:tareqo/presentation/screens/addons/store_transfers_screen.dart';

class _SpyUpdateProductUseCase extends UpdateProductUseCase {
  _SpyUpdateProductUseCase(this._products)
    : super(_NoopProductRepository(), _NoopFifoStock(), _NoopUnitOfWork());

  final Map<String, List<Product>> _products;
  final adjustments = <({String productId, int newQuantity, String storeId})>[];

  @override
  Future<void> adjustStock(
    String productId,
    int newQuantity, {
    required String storeId,
  }) async {
    adjustments.add((
      productId: productId,
      newQuantity: newQuantity,
      storeId: storeId,
    ));
    final list = _products[storeId]!;
    final index = list.indexWhere((p) => p.id == productId);
    if (index != -1) {
      list[index] = list[index].copyWith(stockQuantity: newQuantity);
    }
  }
}

// Stubs vazios: o spy sobrescreve adjustStock, então os membros da
// superclasse nunca são alcançados nestes testes.
class _NoopProductRepository implements IProductRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoopFifoStock implements FifoStockUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoopUnitOfWork implements IUnitOfWork {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeGetProducts implements GetProductsUseCase {
  _FakeGetProducts(Map<String, List<Product>> products) : _products = products;

  final Map<String, List<Product>> _products;

  @override
  Future<List<Product>> call({required String storeId}) async =>
      List.unmodifiable(_products[storeId] ?? const []);
}

class _SpyAddProduct implements AddProductUseCase {
  _SpyAddProduct([this._pool]);

  /// Pool opcional: registra a cópia criada E o insere na loja de
  /// destino (simula a persistência real — permite encadear uma
  /// segunda transferência que cai no ramo de SOMAR stock).
  final Map<String, List<Product>>? _pool;
  final created = <Product>[];

  @override
  Future<void> call(Product product, {DateTime? expiryDate}) async {
    created.add(product);
    _pool?[product.storeId]?.add(product);
  }
}

/// [stock] em MILÉSIMOS (10 un = 10000 milli).
Product _product(String id, {int stock = 10000, String storeId = 'st1'}) =>
    Product(
      id: id,
      storeId: storeId,
      name: 'Produto $id',
      purchasePriceCents: 500,
      salePriceCents: 900,
      stockQuantity: stock,
    );

Widget _buildApp({
  Map<String, List<Product>>? productsByStore,
  _SpyUpdateProductUseCase? updateSpy,
  _SpyAddProduct? addSpy,
  List<Store> stores = const [
    Store(id: 'st1', tenantId: 'tn1', name: 'Loja Centro'),
    Store(id: 'st2', tenantId: 'tn1', name: 'Loja Praia'),
  ],
}) {
  // Um único pool de stock compartilhado entre os fakes — o notifier
  // lê via GetProducts e grava via UpdateProductUseCase.
  final pool =
      productsByStore ??
      {
        'st1': [_product('p1', stock: 10000)],
        'st2': <Product>[],
      };
  final spy = updateSpy ?? _SpyUpdateProductUseCase(pool);
  final add = addSpy ?? _SpyAddProduct();

  return ProviderScope(
    overrides: [
      ...storeContextOverrides(stores: stores),
      getProductsUseCaseProvider.overrideWithValue(_FakeGetProducts(pool)),
      updateProductUseCaseProvider.overrideWithValue(spy),
      addProductUseCaseProvider.overrideWithValue(add),
    ],
    child: testApp(home: const StoreTransfersScreen()),
  );
}

void main() {
  testWidgets('exibe estado vazio quando não há transferências', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Sem transferências'), findsOneWidget);
    expect(find.byType(ListView), findsNothing);
  });

  testWidgets('lista transferências no histórico com status recebido', (
    tester,
  ) async {
    // Seed do histórico via notifier (o provider é global por processo).
    final container = ProviderContainer(
      overrides: [
        ...storeContextOverrides(),
        getProductsUseCaseProvider.overrideWithValue(
          _FakeGetProducts({
            'st1': [_product('p1', stock: 10000)],
            'st2': <Product>[],
          }),
        ),
        updateProductUseCaseProvider.overrideWithValue(
          _SpyUpdateProductUseCase({
            'st1': [_product('p1', stock: 10000)],
            'st2': <Product>[],
          }),
        ),
        addProductUseCaseProvider.overrideWithValue(_SpyAddProduct()),
      ],
    );
    addTearDown(container.dispose);
    await container
        .read(stockTransfersProvider.notifier)
        .executeTransfer(
          productId: 'p1',
          productName: 'Produto p1',
          fromStoreId: 'st1',
          fromStoreName: 'Loja Centro',
          toStoreId: 'st2',
          toStoreName: 'Loja Praia',
          quantityMilli: 4000,
          unitLabel: 'un',
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: testApp(home: const StoreTransfersScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Card do histórico: percurso completo + produto + status recebido.
    expect(find.text('Loja Centro  →  Loja Praia'), findsOneWidget);
    expect(find.text('Recebida'), findsOneWidget);
  });

  testWidgets('sheet exige ao menos duas lojas (guarda de tenant mono-loja)', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        stores: const [Store(id: 'st1', tenantId: 'tn1', name: 'Loja Única')],
      ),
    );
    await tester.pumpAndSettle();

    // Abre o sheet — deve mostrar a guarda, não o formulário.
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Cadastre pelo menos 2 lojas'), findsOneWidget);
    expect(find.byType(AppPickerField<String>), findsNothing);
  });

  testWidgets('fluxo completo: origem padrão, item e execução', (tester) async {
    final pool = {
      'st1': [_product('p1', stock: 10000)],
      'st2': <Product>[],
    };
    final updateSpy = _SpyUpdateProductUseCase(pool);
    final addSpy = _SpyAddProduct(pool);

    await tester.pumpWidget(
      _buildApp(productsByStore: pool, updateSpy: updateSpy, addSpy: addSpy),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Origem já vem pré-selecionada (loja ativa); seleciona destino.
    await tester.tap(
      find.widgetWithText(AppPickerField<String>, 'Loja de Destino'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Loja Praia').last);
    await tester.pumpAndSettle();

    // Seleciona produto.
    await tester.tap(
      find.widgetWithText(AppPickerField<String>, 'Produto').first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Produto p1').last);
    await tester.pumpAndSettle();

    // Adiciona o item (quantia padrão 1).
    await tester.tap(find.widgetWithText(AppButton, 'Adicionar'));
    await tester.pumpAndSettle();

    // Executa.
    await tester.tap(find.widgetWithText(AppButton, 'Executar Transferência'));
    await tester.pumpAndSettle();

    // Baixa na origem (10000 - 1000) — valores em MILÉSIMOS.
    expect(updateSpy.adjustments, [
      (productId: 'p1', newQuantity: 9000, storeId: 'st1'),
    ]);
    // Produto NÃO existia no destino → cria CÓPIA com novo id e o
    // stock transferido (a entrada no destino é a criação, não adjust).
    expect(addSpy.created, hasLength(1));
    expect(addSpy.created.single.id, isNot('p1'));
    expect(addSpy.created.single.storeId, 'st2');
    expect(addSpy.created.single.stockQuantity, 1000);
    // Sucesso → snackbar (singular: 1 item); sheet fechado.
    expect(find.text('1 produto transferido com sucesso'), findsOneWidget);
  });

  testWidgets('stock insuficiente mostra erro e não muta', (tester) async {
    final pool = {
      'st1': [_product('p1', stock: 1000)], // 1 un disponível.
      'st2': <Product>[],
    };
    final updateSpy = _SpyUpdateProductUseCase(pool);

    await tester.pumpWidget(
      _buildApp(productsByStore: pool, updateSpy: updateSpy),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.tap(
      find.widgetWithText(AppPickerField<String>, 'Loja de Destino'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Loja Praia').last);
    await tester.pumpAndSettle();

    await tester.tap(
      find.widgetWithText(AppPickerField<String>, 'Produto').first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Produto p1').last);
    await tester.pumpAndSettle();

    // Quantia 5 > stock 1 → o notifier lança ArgumentError.
    await tester.enterText(find.widgetWithText(TextField, 'Quantidade'), '5');
    await tester.tap(find.widgetWithText(AppButton, 'Adicionar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppButton, 'Executar Transferência'));
    await tester.pumpAndSettle();

    expect(find.textContaining('insuficiente'), findsOneWidget);
    // Nenhuma mutação na origem.
    expect(updateSpy.adjustments, isEmpty);
  });

  testWidgets('destino já tem o produto → SOMA no stock (sem criar cópia)', (
    tester,
  ) async {
    final pool = {
      'st1': [_product('p1', stock: 10000)],
      'st2': [_product('p1', stock: 5000, storeId: 'st2')],
    };
    final updateSpy = _SpyUpdateProductUseCase(pool);
    final addSpy = _SpyAddProduct(pool);

    await tester.pumpWidget(
      _buildApp(productsByStore: pool, updateSpy: updateSpy, addSpy: addSpy),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.tap(
      find.widgetWithText(AppPickerField<String>, 'Loja de Destino'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Loja Praia').last);
    await tester.pumpAndSettle();

    await tester.tap(
      find.widgetWithText(AppPickerField<String>, 'Produto').first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Produto p1').last);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(AppButton, 'Adicionar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppButton, 'Executar Transferência'));
    await tester.pumpAndSettle();

    // Baixa na origem E soma no destino (5000 + 1000) — nenhuma
    // cópia criada (o produto já existe no destino).
    expect(updateSpy.adjustments, [
      (productId: 'p1', newQuantity: 9000, storeId: 'st1'),
      (productId: 'p1', newQuantity: 6000, storeId: 'st2'),
    ]);
    expect(addSpy.created, isEmpty);
    expect(find.text('1 produto transferido com sucesso'), findsOneWidget);
  });
}
