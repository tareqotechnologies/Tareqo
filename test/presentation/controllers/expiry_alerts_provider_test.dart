import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/domain/entities/product.dart';
import 'package:tareqo/domain/entities/stock_lot.dart';
import 'package:tareqo/domain/usecases/get_products_use_case.dart';
import 'package:tareqo/domain/usecases/get_stock_lots_use_case.dart';
import 'package:tareqo/presentation/controllers/account_providers.dart';
import 'package:tareqo/presentation/controllers/auth_providers.dart';
import 'package:tareqo/presentation/controllers/expiry_alerts_provider.dart';
import 'package:tareqo/presentation/controllers/products_providers.dart';

import '../../helpers/fake_stock_lot_repository.dart';
import '../../helpers/store_context.dart';

/// Fake do [GetProductsUseCase] (contrato da classe concreta, não de uma
/// interface) para injetar o catálogo dos testes.
class _FakeGetProductsUseCase implements GetProductsUseCase {
 _FakeGetProductsUseCase(this._products);

 final List<Product> _products;

 @override
 Future<List<Product>> call({required String storeId}) async => _products;
}

void main() {
 Product buildProduct(String id, {int stock = 1000}) => Product(
 id: id,
 storeId: 'st1',
 name: 'Produto $id',
 purchasePriceCents: 100,
 salePriceCents: 200,
 stockQuantity: stock,
 );

 StockLot buildLot(
 String id, {
 required String productId,
 required DateTime expiry,
 int current = 500,
 }) =>
 StockLot(
 id: id,
 storeId: 'st1',
 productId: productId,
 entryDate: DateTime(2026, 1, 1),
 expiryDate: expiry,
 initialQuantity: current,
 currentQuantity: current,
 costPriceCents: 300,
 );

 List<dynamic> overridesFor(
 FakeStockLotRepository lotRepository,
 List<Product> products,
 ) =>
 [
 ...storeContextOverrides(),
 getStockLotsUseCaseProvider.overrideWithValue(
 GetStockLotsUseCase(lotRepository),
 ),
 getProductsUseCaseProvider.overrideWithValue(
 _FakeGetProductsUseCase(products),
 ),
 ];

 testWidgets(
 'alerta vermelho para lote vencido e amarelo para vencimento < 30 dias',
 (tester) async {
 final now = DateTime.now();
 final today = DateTime(now.year, now.month, now.day);

 final lotRepository = FakeStockLotRepository(
 seed: [
 // Vencido (vermelho) — 5 dias atrás.
 buildLot(
 'l-vencido',
 productId: 'p1',
 expiry: today.subtract(const Duration(days: 5)),
 ),
 // Vence em 15 dias (amarelo).
 buildLot(
 'l-15d',
 productId: 'p1',
 expiry: today.add(const Duration(days: 15)),
 ),
 // Vence em 45 dias — fora da janela, sem alerta.
 buildLot(
 'l-45d',
 productId: 'p1',
 expiry: today.add(const Duration(days: 45)),
 ),
 // Sem validade — nunca alerta.
 StockLot(
 id: 'l-sem',
 storeId: 'st1',
 productId: 'p1',
 entryDate: DateTime(2026, 1, 1),
 expiryDate: null,
 initialQuantity: 100,
 currentQuantity: 100,
 costPriceCents: 0,
 ),
 ],
 );
 final products = [buildProduct('p1')];

 await tester.pumpWidget(
 ProviderScope(
 overrides: [...overridesFor(lotRepository, products)],
 child: const MaterialApp(home: Scaffold(body: SizedBox())),
 ),
 );
 await tester.pumpAndSettle();

 final container = ProviderScope.containerOf(
 tester.element(find.byType(SizedBox)),
 );

 // Resolve a cadeia de contexto (sessão → tenant → lojas → loja ativa)
 // — o padrão dos testes de providers multi-loja: o `listen` faz o
 // stream de sessão emitir e mantém os providers autoDispose vivos, e
 // as leituras explícitas resolvem tenant/lojas antes do provider-alvo.
 final authSub = container.listen(authStateProvider, (_, _) {});
 await tester.pumpAndSettle();
 final tenantSub = container.listen(myTenantProvider('1'), (_, _) {});
 final storesSub = container.listen(storesProvider('tn1'), (_, _) {});
 addTearDown(() {
 authSub.close();
 tenantSub.close();
 storesSub.close();
 });
 await tester.runAsync(() => container.read(myTenantProvider('1').future));
 await tester.runAsync(() => container.read(storesProvider('tn1').future));
 expect(container.read(activeStoreIdProvider('1')), 'st1');

 final alerts = await tester
 .runAsync(() => container.read(expiryAlertsProvider.future));

 expect(alerts, hasLength(2));
 // Vencidos (vermelho) primeiro.
 expect(alerts!.first.lot.id, 'l-vencido');
 expect(alerts.first.isExpired, isTrue);
 expect(alerts.first.isExpiring, isTrue);
 expect(alerts.first.daysRemaining, lessThan(0));

 expect(alerts.last.lot.id, 'l-15d');
 expect(alerts.last.isExpired, isFalse);
 expect(alerts.last.isExpiring, isTrue);
 expect(alerts.last.daysRemaining, inInclusiveRange(0, 29));
 });

 testWidgets('sem lotes ou sem loja ativa, a lista de alertas é vazia',
 (tester) async {
 final lotRepository = FakeStockLotRepository();

 await tester.pumpWidget(
 ProviderScope(
 overrides: [...overridesFor(lotRepository, [buildProduct('p1')])],
 child: const MaterialApp(home: Scaffold(body: SizedBox())),
 ),
 );
 await tester.pumpAndSettle();

 final container = ProviderScope.containerOf(
 tester.element(find.byType(SizedBox)),
 );

 final authSub = container.listen(authStateProvider, (_, _) {});
 await tester.pumpAndSettle();
 final tenantSub = container.listen(myTenantProvider('1'), (_, _) {});
 final storesSub = container.listen(storesProvider('tn1'), (_, _) {});
 addTearDown(() {
 authSub.close();
 tenantSub.close();
 storesSub.close();
 });
 await tester.runAsync(() => container.read(myTenantProvider('1').future));
 await tester.runAsync(() => container.read(storesProvider('tn1').future));
 expect(container.read(activeStoreIdProvider('1')), 'st1');

 final alerts = await tester
 .runAsync(() => container.read(expiryAlertsProvider.future));

 expect(alerts, isEmpty);
 expect(alerts, isNotNull);
 });
}
