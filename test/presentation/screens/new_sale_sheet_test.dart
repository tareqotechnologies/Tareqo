import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

import 'package:tareqo/domain/entities/product.dart';
import 'package:tareqo/domain/entities/sale.dart';
import 'package:tareqo/domain/entities/sale_lot_consumption.dart';
import 'package:tareqo/domain/repositories/i_sale_processor.dart';
import 'package:tareqo/domain/repositories/i_sale_repository.dart';
import 'package:tareqo/domain/usecases/get_products_use_case.dart';
import 'package:tareqo/domain/usecases/process_sale_use_case.dart';
import 'package:tareqo/presentation/controllers/products_providers.dart';
import 'package:tareqo/presentation/controllers/sales_providers.dart';
import 'package:tareqo/presentation/screens/sales/new_sale_sheet.dart';
import 'package:tareqo/presentation/widgets/app_sheet.dart';

import '../../helpers/store_context.dart';

/// Catálogo vazio — o balcão renderiza o estado vazio (regressão de overflow).
class _EmptyProductsUseCase implements GetProductsUseCase {
 @override
 Future<List<Product>> call({required String storeId}) async => const [];
}

class _FakeGetProductsUseCase implements GetProductsUseCase {
 @override
 Future<List<Product>> call({required String storeId}) async => const [
 Product(
 id: 'p1',
 name: 'Caneta',
 purchasePriceCents: 100,
 salePriceCents: 200,
 stockQuantity: 10,
 ),
 ];
}

/// Registra a venda sem tocar em infraestrutura (o ProcessSaleUseCase já é
/// coberto por testes de domínio — aqui validamos apenas a orquestração da UI).
class _FakeProcessSaleUseCase implements ProcessSaleUseCase {
 int calls = 0;
 Sale? lastSale;

 @override
 Future<void> call(Sale sale) async {
 calls++;
 lastSale = sale;
 }

 @override
 ISaleAtomicProcessor? get processor => null;
}

/// Lista de vendas do cabeçalho ("Hoje · N vendas · total") sem tocar em
/// infraestrutura.
class _FakeSalesRepository implements ISaleRepository {
 _FakeSalesRepository(this._sales);

 final List<Sale> _sales;

 @override
 Future<void> registerSale(Sale sale) async {}

 @override
 Future<Sale?> getById(String id, {required String storeId}) async => null;

 @override
 Future<void> markCancelled(String id, {required String storeId}) async {}

 @override
 Future<List<LotConsumption>> getLotConsumption(
 String saleId, {
 required String storeId,
 }) async => const [];

 @override
 Future<void> registerLotConsumption(
 String saleId,
 String storeId,
 List<LotConsumption> consumption,
 ) async {}

 @override
 Future<List<Sale>> getAll({required String storeId}) async =>
 List.unmodifiable(_sales);
}

void main() {
 testWidgets('confirmar venda chama o ProcessSaleUseCase e mostra o total',
 (tester) async {
 final processSale = _FakeProcessSaleUseCase();

 await tester.pumpWidget(
 ProviderScope(
 overrides: [
 // Contexto de loja — o carrinho usa os produtos da loja ativa
 // e carimba a loja na venda.
 ...storeContextOverrides(),
 getProductsUseCaseProvider
 .overrideWithValue(_FakeGetProductsUseCase()),
 processSaleUseCaseProvider.overrideWithValue(processSale),
 // Resumo de hoje no cabeçalho (sem vendas no fake).
 salesRepositoryProvider.overrideWithValue(_FakeSalesRepository(const [])),
 ],
 child: testApp(home: Scaffold(body: NewSaleSheet())),
 ),
 );
 await tester.pumpAndSettle();

 // Header V3 (canvas): título "Vendas" + resumo de hoje no subtítulo.
 expect(find.text('Vendas'), findsOneWidget);
 expect(find.textContaining('Hoje'), findsOneWidget);

 // Produto carregado; adiciona 1 unidade ao carrinho.
 expect(find.text('Caneta'), findsOneWidget);
 await tester.tap(find.byIcon(Icons.add));
 await tester.pump();

 // Confirma a venda.
 await tester.tap(find.text('Confirmar venda'));
 await tester.pumpAndSettle();

 // O use case foi chamado exatamente uma vez, com o total calculado.
 expect(processSale.calls, 1);
 expect(processSale.lastSale?.totalAmountCents, 200);
 });

 testWidgets('cart pills mostram o resumo do carrinho no topo (canvas V3)',
 (tester) async {
 await tester.pumpWidget(
 ProviderScope(
 overrides: [
 ...storeContextOverrides(),
 getProductsUseCaseProvider
 .overrideWithValue(_FakeGetProductsUseCase()),
 processSaleUseCaseProvider.overrideWithValue(_FakeProcessSaleUseCase()),
 // Resumo de hoje no cabeçalho (sem vendas no fake).
 salesRepositoryProvider.overrideWithValue(_FakeSalesRepository(const [])),
 ],
 child: testApp(home: Scaffold(body: NewSaleSheet())),
 ),
 );
 await tester.pumpAndSettle();

 // Sem itens, a secção do carrinho não existe.
 expect(find.textContaining('Carrinho'), findsNothing);

 // Adiciona 1 unidade: a pill aparece com o bubble "1×".
 await tester.tap(find.byIcon(Icons.add));
 await tester.pump();

 expect(find.text('Carrinho · 1 item'), findsOneWidget);
 expect(find.text('1×'), findsOneWidget);
 });

 testWidgets('estado vazio não estoura em ecrã de telefone (regressão overflow)',
 (tester) async {
 // Viewport de telefone comum (a app abre o balcão fullscreen via
 // showAppSheet — mesmo caminho real do FAB e da tela de Vendas).
 tester.view.physicalSize = const Size(360 * 3, 800 * 3);
 tester.view.devicePixelRatio = 3.0;
 addTearDown(tester.view.reset);

 await tester.pumpWidget(
 ProviderScope(
 overrides: [
 ...storeContextOverrides(),
 getProductsUseCaseProvider.overrideWithValue(_EmptyProductsUseCase()),
 processSaleUseCaseProvider.overrideWithValue(_FakeProcessSaleUseCase()),
 salesRepositoryProvider.overrideWithValue(_FakeSalesRepository(const [])),
 ],
 child: testApp(
 home: Scaffold(
 body: Builder(
 builder: (context) => Center(
 child: FilledButton(
 onPressed: () => showAppSheet<void>(
 context,
 builder: (_) => const NewSaleSheet(),
 fullscreen: true,
 ),
 child: const Text('abrir'),
 ),
 ),
 ),
 ),
 ),
 ),
 );
 await tester.tap(find.text('abrir'));
 await tester.pumpAndSettle();

 // Estado vazio renderizado e SEM exceção de overflow.
 expect(find.text('Nenhum produto para vender'), findsOneWidget);
 expect(tester.takeException(), isNull);
 });
}
