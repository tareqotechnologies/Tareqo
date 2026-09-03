import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';
import '../../helpers/viewport.dart';

import 'package:tareqo/domain/entities/customer.dart';
import 'package:tareqo/domain/entities/debt.dart';
import 'package:tareqo/domain/entities/financial_transaction.dart';
import 'package:tareqo/domain/entities/plan.dart';
import 'package:tareqo/domain/entities/plan_request.dart';
import 'package:tareqo/domain/entities/product.dart';
import 'package:tareqo/domain/entities/sale.dart';
import 'package:tareqo/domain/entities/sale_lot_consumption.dart';
import 'package:tareqo/domain/entities/store_employee.dart';
import 'package:tareqo/domain/repositories/i_cash_flow_repository.dart';
import 'package:tareqo/domain/repositories/i_financial_transaction_repository.dart';
import 'package:tareqo/domain/repositories/i_sale_repository.dart';
import 'package:tareqo/domain/usecases/get_cash_flow_use_case.dart';
import 'package:tareqo/domain/usecases/get_customers_use_case.dart';
import 'package:tareqo/domain/usecases/get_employees_use_case.dart';
import 'package:tareqo/domain/usecases/get_my_plan_requests_use_case.dart';
import 'package:tareqo/domain/usecases/get_pending_debts_use_case.dart';
import 'package:tareqo/domain/usecases/get_plans_use_case.dart';
import 'package:tareqo/domain/usecases/get_products_use_case.dart';
import 'package:tareqo/domain/usecases/get_settled_debts_use_case.dart';
import 'package:tareqo/presentation/controllers/account_providers.dart';
import 'package:tareqo/presentation/controllers/customers_providers.dart';
import 'package:tareqo/presentation/controllers/debts_providers.dart';
import 'package:tareqo/presentation/controllers/finance_providers.dart';
import 'package:tareqo/presentation/controllers/products_providers.dart';
import 'package:tareqo/presentation/controllers/sales_providers.dart';
import 'package:tareqo/presentation/screens/shell/app_shell.dart';

import '../../helpers/store_context.dart';

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
 Future<List<Sale>> getAll({required String storeId}) async => const [];
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
 const CashFlow(incomeCents: 0, expenseCents: 0);
}

class _FakeGetPendingDebtsUseCase implements GetPendingDebtsUseCase {
 @override
 Future<List<Debt>> call({required String storeId}) async => const [];
}

class _FakeGetSettledDebtsUseCase implements GetSettledDebtsUseCase {
 @override
 Future<List<Debt>> call({required String storeId}) async => const [];
}

class _FakeGetCustomersUseCase implements GetCustomersUseCase {
 @override
 Future<List<Customer>> call({required String storeId}) async => const [
 Customer(id: 'c1', name: 'João'),
 ];
}

class _FakeFinanceRepository implements IFinancialTransactionRepository {
 @override
 Future<List<FinancialTransaction>> getByPeriod({
 required String storeId,
 required DateTime start,
 required DateTime end,
 }) async =>
 const [];

 @override
 Future<List<FinancialTransaction>> getAll({required String storeId}) async =>
 const [];

 @override
 Future<void> add(FinancialTransaction transaction) async {}

 @override
 Future<void> markAsPaid(String id, {required String storeId}) async {}
}

class _FakeGetEmployeesUseCase implements GetEmployeesUseCase {
 @override
 Future<List<StoreEmployee>> call(String tenantId) async => const [];
}

class _FakeGetPlansUseCase implements GetPlansUseCase {
 @override
 Future<List<Plan>> call() async => const [];
}

class _FakeGetMyPlanRequestsUseCase implements GetMyPlanRequestsUseCase {
 @override
 Future<List<PlanRequest>> call(String tenantId) async => const [];
}

void main() {
 testWidgets('AppShell V3 exibe os 4 destinos e navega entre eles',
 (tester) async {
 await tester.pumpWidget(
 ProviderScope(
 overrides: [
 // Contexto de loja (sessão + tenant aprovado + loja demo) — os
 // módulos escopam pela loja ativa.
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
 financeRepositoryProvider.overrideWithValue(_FakeFinanceRepository()),
 getCustomersUseCaseProvider
 .overrideWithValue(_FakeGetCustomersUseCase()),
 ],
 child: testApp(home: AppShell()),
 ),
 );

 await tester.pumpAndSettle();

 // Os 4 destinos da barra V3.
 for (final label in ['Início', 'Vendas', 'Carteira', 'Menu']) {
 expect(find.text(label), findsWidgets);
 }

 // Navega para a aba de Vendas (lista vazia no fake) — o tap é
 // escopado à barra porque o dashboard tem uma métrica também chamada
 // "Vendas" (cards compactos do canvas V3).
 await tester.tap(
 find.descendant(
 of: find.byType(NavigationBar),
 matching: find.text('Vendas'),
 ),
 );
 await tester.pumpAndSettle();

 expect(find.text('Nenhuma venda registrada'), findsOneWidget);

 // Navega para a Carteira (Financeiro — lista vazia no fake).
 await tester.tap(find.text('Carteira'));
 await tester.pumpAndSettle();
 expect(find.text('Registrar movimentação'), findsNothing);
 });

 // Rotação/responsividade: em paisagem com largura >= 880px o AppShell
 // troca o NavigationBar (mobile) pelo NavigationRail (web/desktop) — o
 // conteúdo fica centralizado num ConstrainedBox (maxWidth 1040). Gira do
 // retrato (barra) para a paisagem larga (rail) e verifica: o rail
 // aparece, a barra some, os destinos continuam navegáveis e nenhum
 // overflow foi registrado.
 testWidgets('AppShell em paisagem larga usa NavigationRail (>= 880px)',
 (tester) async {
 // Retrato estreito: NavigationBar (mobile).
 usePortraitViewport(tester);

 await tester.pumpWidget(
 ProviderScope(
 overrides: [
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
 financeRepositoryProvider.overrideWithValue(_FakeFinanceRepository()),
 getCustomersUseCaseProvider
 .overrideWithValue(_FakeGetCustomersUseCase()),
 ],
 child: testApp(home: AppShell()),
 ),
 );
 await tester.pumpAndSettle();

 // Retrato: barra de navegação mobile, sem rail.
 expect(find.byType(NavigationBar), findsOneWidget);
 expect(find.byType(NavigationRail), findsNothing);
 expect(find.text('Início'), findsWidgets);

 // Gira para paisagem LARGA (1280×800) — acima do limiar de 880px.
 await rotateToLandscape(tester, size: const Size(1280, 800));

 // O rail aparece no lugar da barra, com os 4 destinos V3.
 expect(find.byType(NavigationRail), findsOneWidget);
 expect(find.byType(NavigationBar), findsNothing);
 for (final label in ['Início', 'Vendas', 'Carteira', 'Menu']) {
 expect(find.text(label), findsWidgets);
 }
 expect(tester.takeException(), isNull);

 // Navega pelo rail até a aba de Vendas (lista vazia no fake).
 await tester.tap(
 find.descendant(
 of: find.byType(NavigationRail),
 matching: find.text('Vendas'),
 ),
 );
 await tester.pumpAndSettle();

 expect(find.text('Nenhuma venda registrada'), findsOneWidget);
 expect(tester.takeException(), isNull);
 });

 // V3 — FAB central: abre o menu global de acções com as 4 ações do
 // canvas (nova venda, despesa, produto, fiado) e o Cancelar.
 testWidgets('FAB central abre o menu global de acções', (tester) async {
 await tester.pumpWidget(
 ProviderScope(
 overrides: [
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
 financeRepositoryProvider.overrideWithValue(_FakeFinanceRepository()),
 getCustomersUseCaseProvider
 .overrideWithValue(_FakeGetCustomersUseCase()),
 ],
 child: testApp(home: AppShell()),
 ),
 );
 await tester.pumpAndSettle();

 // O FAB central existe e abre o menu.
 expect(find.byTooltip('Nova ação'), findsOneWidget);
 await tester.tap(find.byTooltip('Nova ação'));
 await tester.pumpAndSettle();

 // A Home do canvas V3 não tem ações rápidas — as 4 acções do menu do
 // FAB são exclusivas dele (findsOneWidget). 'Registrar despesa' e
 // 'Cancelar' também são exclusivos do menu.
 for (final label in [
 'Nova venda',
 'Registrar despesa',
 'Adicionar produto',
 'Registrar fiado',
 ]) {
 expect(find.text(label), findsOneWidget);
 }
 expect(find.text('Cancelar'), findsOneWidget);

 // Fecha pelo Cancelar.
 await tester.tap(find.text('Cancelar'));
 await tester.pumpAndSettle();
 expect(find.text('Registrar despesa'), findsNothing);
 });

 testWidgets(
 'empurrar StoresScreen por cima do AppShell não lança conflito de '
 'Heroes (regressão do IndexedStack com FABs)', (tester) async {
 // Viewport alto o suficiente para o card "Lojas" do dashboard ficar
 // visível sem scroll.
 tester.view.physicalSize = const Size(1280, 1600);
 tester.view.devicePixelRatio = 1.0;
 addTearDown(tester.view.reset);

 await tester.pumpWidget(
 ProviderScope(
 overrides: [
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
 financeRepositoryProvider.overrideWithValue(_FakeFinanceRepository()),
 getCustomersUseCaseProvider
 .overrideWithValue(_FakeGetCustomersUseCase()),
 getEmployeesUseCaseProvider
 .overrideWithValue(_FakeGetEmployeesUseCase()),
 getPlansUseCaseProvider.overrideWithValue(_FakeGetPlansUseCase()),
 getMyPlanRequestsUseCaseProvider
 .overrideWithValue(_FakeGetMyPlanRequestsUseCase()),
 ],
 child: testApp(
 home: Scaffold(
 body: Center(
 child: Builder(
 builder: (context) => ElevatedButton(
 onPressed: () => Navigator.of(context).push(
 MaterialPageRoute<void>(
 builder: (_) => const AppShell(),
 ),
 ),
 child: const Text('abrir app'),
 ),
 ),
 ),
 ),
 ),
 ),
 );
 await tester.pumpAndSettle();

 // Transição de rota REAL para o AppShell: o IndexedStack mantém as 6
 // seções vivas (com FABs) no mesmo subtree. Antes dos heroTags únicos,
 // qualquer transição lançava "There are multiple heroes that share the
 // same tag within a subtree: <default FloatingActionButton tag>" (o
 // erro que aparecia no console do browser).
 await tester.tap(find.text('abrir app'));
 await tester.pumpAndSettle();
 expect(tester.takeException(), isNull);

 // O cenário exato do log do usuário: empurra StoresScreen por cima do
 // AppShell. No canvas V3 o dashboard não tem mais os cards de módulos
 // (Lojas saiu da Home) — o hub é a aba Menu. O viewport 1280px largo
 // usa o NavigationRail (web/desktop).
 await tester.tap(
 find.descendant(
 of: find.byType(NavigationRail),
 matching: find.text('Menu'),
 ),
 );
 await tester.pumpAndSettle();
 await tester.tap(find.text('Lojas'));
 await tester.pumpAndSettle();
 expect(tester.takeException(), isNull);

 // A tela abriu e o separador Funcionários está presente.
 expect(find.text('Funcionários'), findsOneWidget);
 });

 // Regressão (runtime no browser): o AppSection tem 7 seções mas a barra
 // tem 4 destinos. Navegar para Produtos/Crédito/Clientes (via Menu ou
 // FAB) em tela ESTREITA fazia o NavigationBar receber selectedIndex >= 4
 // e lançar "0 <= selectedIndex && selectedIndex < destinations.length".
 // O destaque deve cair no Menu (índice 3) — sem estourar a barra.
 testWidgets('seções fora das 4 abas não estouram a barra (mobile)',
 (tester) async {
 usePortraitViewport(tester);

 await tester.pumpWidget(
 ProviderScope(
 overrides: [
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
 financeRepositoryProvider.overrideWithValue(_FakeFinanceRepository()),
 getCustomersUseCaseProvider
 .overrideWithValue(_FakeGetCustomersUseCase()),
 ],
 child: testApp(home: AppShell()),
 ),
 );
 await tester.pumpAndSettle();

 // Tela estreita: barra de navegação mobile com 4 destinos.
 expect(find.byType(NavigationBar), findsOneWidget);

 // Navega para o Menu e abre Produtos (seção fora das 4 abas) — o
 // cenário exato que quebrava o selectedIndex da barra.
 await tester.tap(
 find.descendant(
 of: find.byType(NavigationBar),
 matching: find.text('Menu'),
 ),
 );
 await tester.pumpAndSettle();
 await tester.tap(find.text('Produtos'));
 await tester.pumpAndSettle();

 // Sem assertion de selectedIndex fora do intervalo e sem overflow.
 expect(tester.takeException(), isNull);
 // A tela de Produtos abriu (produto do fake visível).
 expect(find.text('Caneta'), findsOneWidget);

 // A barra continua funcionando: navegar para Vendas não lança nada.
 await tester.tap(
 find.descendant(
 of: find.byType(NavigationBar),
 matching: find.text('Vendas'),
 ),
 );
 await tester.pumpAndSettle();
 expect(tester.takeException(), isNull);
 expect(find.text('Nenhuma venda registrada'), findsOneWidget);
 });
}
