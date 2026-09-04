import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/app.dart';
import 'package:tareqo/domain/entities/customer.dart';
import 'package:tareqo/domain/entities/debt.dart';
import 'package:tareqo/domain/entities/product.dart';
import 'package:tareqo/domain/entities/purchase.dart';
import 'package:tareqo/domain/entities/sale.dart';
import 'package:tareqo/domain/entities/sale_lot_consumption.dart';
import 'package:tareqo/domain/entities/sale_item.dart';
import 'package:tareqo/domain/repositories/i_sale_repository.dart';
import 'package:tareqo/domain/repositories/i_cash_flow_repository.dart';
import 'package:tareqo/domain/usecases/get_cash_flow_use_case.dart';
import 'package:tareqo/domain/usecases/get_customers_use_case.dart';
import 'package:tareqo/domain/usecases/get_pending_debts_use_case.dart';
import 'package:tareqo/domain/usecases/get_products_use_case.dart';
import 'package:tareqo/domain/usecases/get_purchases_use_case.dart';
import 'package:tareqo/domain/usecases/get_settled_debts_use_case.dart';
import 'package:tareqo/presentation/controllers/customers_providers.dart';
import 'package:tareqo/presentation/controllers/purchases_providers.dart';
import 'package:tareqo/presentation/controllers/debts_providers.dart';
import 'package:tareqo/presentation/controllers/finance_providers.dart';
import 'package:tareqo/presentation/controllers/products_providers.dart';
import 'package:tareqo/presentation/controllers/sales_providers.dart';

import 'helpers/store_context.dart';
import 'helpers/test_app.dart';

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

class _FakeSalesRepository implements ISaleRepository {
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
 Future<List<Sale>> getAll({required String storeId}) async => [
 Sale(
 id: 's1',
 items: const [
 SaleItem(
 productId: 'p1',
 productName: 'Caneta',
 quantity: 2,
 unitPriceCents: 200,
 ),
 ],
 totalAmountCents: 400,
 paymentMethod: PaymentMethod.mPesa,
 dateTime: DateTime.now(),
 ),
 ];
}

class _FakeGetCashFlowUseCase implements GetCashFlowUseCase {
 @override
 final ICashFlowRepository? serverRepository = null;

 @override
 Future<CashFlow> call({
 required String storeId,
 required DateTime start,
 required DateTime end,
 }) async =>
 const CashFlow(incomeCents: 10000, expenseCents: 4000);
}

class _FakeGetPendingDebtsUseCase implements GetPendingDebtsUseCase {
 @override
 Future<List<Debt>> call({required String storeId}) async => [
 Debt(
 id: 'd1',
 personName: 'João',
 amountCents: 2500,
 dueDate: DateTime.now().add(const Duration(days: 3)),
 isCustomerDebt: true,
 ),
 ];
}

class _FakeGetSettledDebtsUseCase implements GetSettledDebtsUseCase {
 @override
 Future<List<Debt>> call({required String storeId}) async => const [];
}

class _FakeGetPurchasesUseCase implements GetPurchasesUseCase {
 @override
 Future<List<Purchase>> call({required String storeId}) async => const [];
}

class _FakeGetCustomersUseCase implements GetCustomersUseCase {
 @override
 Future<List<Customer>> call({required String storeId}) async => const [
 Customer(id: 'c1', name: 'João'),
 ];
}

void main() {
 // O [TareqoApp] roteia pelo [AuthGate], que resolve o MFA via GetIt.
 // Sem o bootstrap real, registra o SecureStorageService em memória.
 setUpAll(registerTestSecureStorage);

 testWidgets('Dashboard renderiza o ERP: KPIs, ações e navegação',
 (tester) async {
 await tester.pumpWidget(
 ProviderScope(
 overrides: [
 // Contexto de loja (sessão + tenant aprovado + loja demo) — o
 // AuthGate roteia para o AppShell e a loja ativa é resolvida.
 ...storeContextOverrides(),
 getProductsUseCaseProvider
 .overrideWithValue(_FakeGetProductsUseCase()),
 salesRepositoryProvider.overrideWithValue(_FakeSalesRepository()),
 getCashFlowUseCaseProvider
 .overrideWithValue(_FakeGetCashFlowUseCase()),
 getPendingDebtsUseCaseProvider
 .overrideWithValue(_FakeGetPendingDebtsUseCase()),
 getSettledDebtsUseCaseProvider
 .overrideWithValue(_FakeGetSettledDebtsUseCase()),
 getCustomersUseCaseProvider
 .overrideWithValue(_FakeGetCustomersUseCase()),
 getPurchasesUseCaseProvider
 .overrideWithValue(_FakeGetPurchasesUseCase()),
 ],
 child: const TareqoApp(),
 ),
 );

 await tester.pumpAndSettle();

 // Saudação com o nome derivado do e-mail da sessão.
 expect(find.textContaining('Olá, dono'), findsOneWidget);
 // Métricas compactas do dashboard (app de referência) — escopadas aos
 // cards, pois 'Vendas' também é um destino da barra de navegação.
 expect(
 find.descendant(
 of: find.byKey(const ValueKey('metric-sales')),
 matching: find.text('Vendas'),
 ),
 findsOneWidget,
 );
 expect(
 find.descendant(
 of: find.byKey(const ValueKey('metric-cash')),
 matching: find.text('Caixa'),
 ),
 findsOneWidget,
 );
 expect(
 find.descendant(
 of: find.byKey(const ValueKey('metric-receivables')),
 matching: find.text('A receber'),
 ),
 findsOneWidget,
 );
 // Navegação do shell V3 (NavigationBar em telas estreitas): 4
 // destinos + FAB central (menu global de acções).
 expect(find.text('Início'), findsWidgets);
 expect(find.text('Vendas'), findsWidgets);
 expect(find.text('Carteira'), findsWidgets);
 expect(find.text('Menu'), findsWidgets);
 // Os módulos vivem na aba Menu (canvas V3 — a Home não os exibe).
 await tester.tap(find.text('Menu'));
 await tester.pumpAndSettle();
 expect(find.text('Clientes'), findsWidgets);
 });
}
