import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';
import '../../helpers/viewport.dart';
import '../../helpers/store_context.dart';

import 'package:dumbhanengue/domain/entities/app_user.dart';
import 'package:dumbhanengue/domain/entities/debt.dart';
import 'package:dumbhanengue/domain/entities/product.dart';
import 'package:dumbhanengue/domain/entities/purchase.dart';
import 'package:dumbhanengue/domain/entities/sale.dart';
import 'package:dumbhanengue/domain/entities/sale_item.dart';
import 'package:dumbhanengue/domain/entities/store.dart';
import 'package:dumbhanengue/domain/entities/store_employee.dart';
import 'package:dumbhanengue/domain/repositories/i_cash_flow_repository.dart';
import 'package:dumbhanengue/domain/repositories/i_sale_repository.dart';
import 'package:dumbhanengue/domain/usecases/get_cash_flow_use_case.dart';
import 'package:dumbhanengue/domain/usecases/get_employees_use_case.dart';
import 'package:dumbhanengue/domain/usecases/get_pending_debts_use_case.dart';
import 'package:dumbhanengue/domain/usecases/get_products_use_case.dart';
import 'package:dumbhanengue/domain/usecases/get_purchases_use_case.dart';
import 'package:dumbhanengue/presentation/controllers/account_providers.dart';
import 'package:dumbhanengue/presentation/controllers/admin_providers.dart';
import 'package:dumbhanengue/presentation/controllers/auth_providers.dart';
import 'package:dumbhanengue/presentation/controllers/debts_providers.dart';
import 'package:dumbhanengue/presentation/controllers/finance_providers.dart';
import 'package:dumbhanengue/presentation/controllers/products_providers.dart';
import 'package:dumbhanengue/presentation/controllers/purchases_providers.dart';
import 'package:dumbhanengue/presentation/controllers/sales_providers.dart';
import 'package:dumbhanengue/presentation/screens/dashboard/dashboard_screen.dart';

class _FakeGetProductsUseCase implements GetProductsUseCase {
  _FakeGetProductsUseCase(this._products);

  final List<Product> _products;

  @override
  Future<List<Product>> call({required String storeId}) async => _products;
}

class _FakeSalesRepository implements ISaleRepository {
  _FakeSalesRepository(this._sales);

  final List<Sale> _sales;

  @override
  Future<void> registerSale(Sale sale) async {}

  @override
  Future<List<Sale>> getAll({required String storeId}) async => _sales;
}

class _FakeGetCashFlowUseCase implements GetCashFlowUseCase {
  _FakeGetCashFlowUseCase(this._cashFlow);

  final CashFlow _cashFlow;

  @override
  final ICashFlowRepository? serverRepository = null;

  @override
  Future<CashFlow> call({
    required String storeId,
    required DateTime start,
    required DateTime end,
  }) async => _cashFlow;
}

class _FakeGetPendingDebtsUseCase implements GetPendingDebtsUseCase {
  _FakeGetPendingDebtsUseCase(this._debts);

  final List<Debt> _debts;

  @override
  Future<List<Debt>> call({required String storeId}) async => _debts;
}

class _FakeGetPurchasesUseCase implements GetPurchasesUseCase {
  _FakeGetPurchasesUseCase(this._purchases);

  final List<Purchase> _purchases;

  @override
  Future<List<Purchase>> call({required String storeId}) async => _purchases;
}

class _FakeGetEmployeesUseCase implements GetEmployeesUseCase {
  _FakeGetEmployeesUseCase(this._employees);

  final List<StoreEmployee> _employees;

  @override
  Future<List<StoreEmployee>> call(String tenantId) async => _employees;
}

Sale _sale({required int totalCents, int number = 1}) => Sale(
  id: 's-$totalCents',
  number: number,
  items: const [
    SaleItem(
      productId: 'p1',
      productName: 'Caneta',
      quantity: 1,
      unitPriceCents: 200,
    ),
  ],
  totalAmountCents: totalCents,
  paymentMethod: PaymentMethod.mPesa,
  dateTime: DateTime.now(),
);

Purchase _purchase({
  required String id,
  required int number,
  required String supplierName,
  int totalAmountCents = 100,
}) => Purchase(
  id: id,
  number: number,
  storeId: 'st1',
  supplierName: supplierName,
  items: const [
    PurchaseItem(
      productId: 'p1',
      productName: 'Caneta',
      quantity: 1000, // 1 unidade em MILÉSIMOS (W11)
      unitPriceCents: 100,
    ),
  ],
  totalAmountCents: totalAmountCents,
  dateTime: DateTime.now(),
);

Widget _buildApp({
  required List<Product> products,
  required List<Sale> sales,
  required CashFlow cashFlow,
  required List<Debt> debts,
  List<Purchase> purchases = const [],
}) {
  return ProviderScope(
    overrides: [
      ...storeContextOverrides(),
      getProductsUseCaseProvider.overrideWithValue(
        _FakeGetProductsUseCase(products),
      ),
      salesRepositoryProvider.overrideWithValue(_FakeSalesRepository(sales)),
      getCashFlowUseCaseProvider.overrideWithValue(
        _FakeGetCashFlowUseCase(cashFlow),
      ),
      getPendingDebtsUseCaseProvider.overrideWithValue(
        _FakeGetPendingDebtsUseCase(debts),
      ),
      getPurchasesUseCaseProvider.overrideWithValue(
        _FakeGetPurchasesUseCase(purchases),
      ),
    ],
    child: testApp(home: const DashboardScreen()),
  );
}

/// Dashboard com o usuário logado como FUNCIONÁRIO ou GERENTE da loja
/// (o tenant pertence a OUTRO usuário — `ownerUserId` ≠ `userId`). O
/// `currentAccessLevelProvider` resolve o cargo pelo vínculo em
/// `store_employees` (matriz de acesso Aug 6).
///
/// ⚠️ NÃO usa `storeContextOverrides()`: este helper já registra o
/// `getMyTenantUseCaseProvider` com um tenant de OUTRO dono (ownerUserId
/// '9') — um segundo override do MESMO provider dentro do mesmo scope
/// quebraria com "Tried to override a provider twice".
Widget _buildAppAsEmployee({
  required EmployeeRole role,
  required List<Product> products,
}) {
  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith(
        (ref) => Stream.value(AppUser(id: '1', email: 'func@loja.com')),
      ),
      getMyTenantUseCaseProvider.overrideWithValue(
        FakeGetMyTenantUseCase(approvedTenant(ownerUserId: '9')),
      ),
      getStoresUseCaseProvider.overrideWithValue(
        FakeGetStoresUseCase(const [
          Store(id: 'st1', tenantId: 'tn1', name: 'Loja Centro'),
        ]),
      ),
      adminRepositoryProvider.overrideWithValue(const FakeAdminRepository()),
      getEmployeesUseCaseProvider.overrideWithValue(
        _FakeGetEmployeesUseCase([
          StoreEmployee(
            id: 'e1',
            tenantId: 'tn1',
            storeId: 'st1',
            userId: '1',
            fullName: 'Funcionária',
            email: 'func@loja.com',
            role: role,
          ),
        ]),
      ),
      getProductsUseCaseProvider.overrideWithValue(
        _FakeGetProductsUseCase(products),
      ),
      salesRepositoryProvider.overrideWithValue(_FakeSalesRepository(const [])),
      getCashFlowUseCaseProvider.overrideWithValue(
        _FakeGetCashFlowUseCase(
          const CashFlow(incomeCents: 0, expenseCents: 0),
        ),
      ),
      getPendingDebtsUseCaseProvider.overrideWithValue(
        _FakeGetPendingDebtsUseCase(const []),
      ),
      getPurchasesUseCaseProvider.overrideWithValue(
        _FakeGetPurchasesUseCase(const []),
      ),
    ],
    child: testApp(home: const DashboardScreen()),
  );
}

void main() {
  // O dashboard é um ListView longo — itens abaixo do fold não são
  // construídos na viewport padrão (800×600). Usa uma viewport alta para
  // que toda a tela (KPIs, ações, módulos, vendas recentes) seja montada.
  Future<void> pumpDashboard(WidgetTester tester, Widget app) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
  }

  testWidgets('exibe saudação, KPIs, loja ativa e vendas recentes', (
    tester,
  ) async {
    await pumpDashboard(
      tester,
      _buildApp(
        products: const [
          Product(
            id: 'p1',
            name: 'Caneta',
            purchasePriceCents: 100,
            salePriceCents: 200,
          ),
          Product(
            id: 'p2',
            name: 'Caderno',
            purchasePriceCents: 300,
            salePriceCents: 600,
          ),
        ],
        sales: [_sale(totalCents: 2000), _sale(totalCents: 1000)],
        cashFlow: const CashFlow(incomeCents: 10000, expenseCents: 4000),
        debts: [
          Debt(
            id: 'd1',
            personName: 'Cliente A',
            amountCents: 1500,
            dueDate: DateTime.now(),
            isCustomerDebt: true,
          ),
        ],
      ),
    );

    // Saudação com o nome derivado do e-mail (sem fullName no AppUser).
    expect(find.text('Olá, dono 👋'), findsOneWidget);
    // Loja ativa (primeira do tenant).
    expect(find.text('Loja Centro'), findsOneWidget);

    // KPIs: total de vendas (20+10), saldo (100−40), a receber (15) e
    // estoque (2 produtos com stock padrão 0 → 0 un.).
    expect(find.text('Total de vendas'), findsOneWidget);
    expect(find.text('R\$ 30,00'), findsOneWidget);
    expect(find.text('Saldo em caixa'), findsOneWidget);
    expect(find.text('R\$ 60,00'), findsOneWidget);
    expect(find.text('A receber (fiado)'), findsOneWidget);
    expect(find.text('R\$ 15,00'), findsOneWidget);
    expect(find.text('Estoque em produtos'), findsOneWidget);

    // Vendas recentes (as 2 fornecidas, mais recentes primeiro) — o card
    // COMPARTILHADO mostra o número SEQUENCIAL da venda na loja (S-00001),
    // a forma de pagamento e o status 'Pago'.
    expect(find.text('Vendas recentes'), findsOneWidget);
    expect(find.text('S-00001 · 1 item'), findsNWidgets(2));
    expect(find.text('M-Pesa'), findsNWidgets(2));
    expect(find.text('Pago'), findsNWidgets(2));
  });

  testWidgets('tocar em uma venda recente abre os detalhes da venda', (
    tester,
  ) async {
    await pumpDashboard(
      tester,
      _buildApp(
        products: const [],
        sales: [_sale(totalCents: 2000)],
        cashFlow: const CashFlow(incomeCents: 0, expenseCents: 0),
        debts: const [],
      ),
    );

    // O card compartilhado é tocável: abre os detalhes da venda.
    await tester.tap(find.text('S-00001 · 1 item'));
    await tester.pumpAndSettle();

    expect(find.text('Detalhes da venda'), findsOneWidget);
    expect(find.text('Caneta'), findsOneWidget);
  });

  testWidgets('exibe as compras recentes do dashboard', (tester) async {
    await pumpDashboard(
      tester,
      _buildApp(
        products: const [],
        sales: const [],
        cashFlow: const CashFlow(incomeCents: 0, expenseCents: 0),
        debts: const [],
        purchases: [
          _purchase(
            id: 'c1',
            number: 1,
            supplierName: 'Distribuidora Central',
            totalAmountCents: 8500,
          ),
          _purchase(
            id: 'c2',
            number: 2,
            supplierName: 'Papelaria Souza',
            totalAmountCents: 2000,
          ),
        ],
      ),
    );

    // Seção com o card COMPARTILHADO da lista de Compras.
    expect(find.text('Compras recentes'), findsOneWidget);
    expect(find.text('Distribuidora Central'), findsOneWidget);
    expect(find.text('Papelaria Souza'), findsOneWidget);
    // Número SEQUENCIAL + itens em cada card (a linha termina com a forma
    // de pagamento — dinheiro por padrão nas fixtures).
    expect(find.textContaining('C-00001 · 1 item'), findsOneWidget);
    expect(find.textContaining('C-00002 · 1 item'), findsOneWidget);
    // Unidades adicionadas ao estoque (1 por compra).
    expect(find.text('Estoque +1 un.'), findsNWidgets(2));
    // Valores.
    expect(find.text('R\$ 85,00'), findsOneWidget);
    expect(find.text('R\$ 20,00'), findsOneWidget);
  });

  testWidgets(
    'exibe alerta de estoque baixo apenas para produtos com stock < 5',
    (tester) async {
      await pumpDashboard(
        tester,
        _buildApp(
          products: const [
            Product(
              id: 'p1',
              name: 'Caneta',
              purchasePriceCents: 100,
              salePriceCents: 200,
              stockQuantity: 2000, // 2 unidades em MILÉSIMOS (W11)
            ),
            Product(
              id: 'p2',
              name: 'Caderno',
              purchasePriceCents: 300,
              salePriceCents: 600,
              stockQuantity: 10000,
            ),
          ],
          sales: [],
          cashFlow: const CashFlow(incomeCents: 0, expenseCents: 0),
          debts: const [],
        ),
      );

      expect(find.text('Estoque baixo'), findsOneWidget);
      expect(find.text('Caneta'), findsOneWidget);
      expect(find.text('2 un.'), findsOneWidget);
      // O caderno (stock 10) não entra no alerta.
      expect(find.text('Caderno'), findsNothing);
    },
  );

  testWidgets('mostra estado vazio de vendas recentes', (tester) async {
    await pumpDashboard(
      tester,
      _buildApp(
        products: const [],
        sales: const [],
        cashFlow: const CashFlow(incomeCents: 0, expenseCents: 0),
        debts: const [],
      ),
    );

    expect(
      find.text('Nenhuma venda ainda — registre a primeira!'),
      findsOneWidget,
    );
    // Compras recentes também começam vazias (estado inline).
    expect(
      find.text('Nenhuma compra ainda — registre a primeira!'),
      findsOneWidget,
    );
    // Sem produtos com stock < 5, o bloco de estoque baixo não aparece.
    expect(find.text('Estoque baixo'), findsNothing);
  });

  testWidgets('exibe as ações rápidas e os módulos do ERP', (tester) async {
    await pumpDashboard(
      tester,
      _buildApp(
        products: const [],
        sales: const [],
        cashFlow: const CashFlow(incomeCents: 0, expenseCents: 0),
        debts: const [],
      ),
    );

    expect(find.text('Ações rápidas'), findsOneWidget);
    expect(find.text('Nova venda'), findsOneWidget);
    expect(find.text('Módulos'), findsOneWidget);
    expect(find.text('Clientes'), findsOneWidget);
    expect(find.text('Compras'), findsOneWidget);
    expect(find.text('Relatórios'), findsOneWidget);
    // Tenant aprovado + dono → card de Lojas também é exibido.
    expect(find.text('Lojas'), findsOneWidget);
  });

  // Matriz de acesso (Aug 6): DONO = tudo; GERENTE = operação completa
  // (inclui Compras/Relatórios) mas SEM Lojas; FUNCIONÁRIO = só operação
  // diária (SEM Compras, SEM Relatórios, SEM Lojas).
  testWidgets('funcionário NÃO vê Compras, Relatórios nem Lojas', (
    tester,
  ) async {
    await pumpDashboard(
      tester,
      _buildAppAsEmployee(role: EmployeeRole.employee, products: const []),
    );

    // Operação diária continua visível.
    expect(find.text('Clientes'), findsOneWidget);
    // Módulos gerenciais e de gestão ficam ocultos (incl. compras recentes).
    expect(find.text('Compras'), findsNothing);
    expect(find.text('Compras recentes'), findsNothing);
    expect(find.text('Relatórios'), findsNothing);
    expect(find.text('Lojas'), findsNothing);
  });

  testWidgets('gerente vê Compras e Relatórios, mas NÃO Lojas', (tester) async {
    await pumpDashboard(
      tester,
      _buildAppAsEmployee(role: EmployeeRole.manager, products: const []),
    );

    expect(find.text('Clientes'), findsOneWidget);
    expect(find.text('Compras'), findsOneWidget);
    // Compras recentes também é nível gerencial (seção visível, vazia).
    expect(find.text('Compras recentes'), findsOneWidget);
    expect(find.text('Relatórios'), findsOneWidget);
    // Gestão de lojas/funcionários/plano é exclusiva do dono.
    expect(find.text('Lojas'), findsNothing);
  });

  // Regressão (UI): o grid de KPIs usava childAspectRatio fixo e estourava
  // em 17px nos cards com caption ("BOTTOM OVERFLOWED BY 17 PIXELS"). A grade
  // agora cresce por conteúdo (IntrinsicHeight) — com escala de texto alta em
  // tela estreita, NENHUM card pode estourar (overflows de RenderFlex falham
  // o teste automaticamente via takeException).
  testWidgets('KPIs não estouram com escala de texto 2.0 em tela estreita', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearAllTestValues);

    // Viewport estreita (360, o estresse horizontal) porém alta: a seção
    // de estoque baixo fica abaixo do fold com escala 2.0 — o ListView só
    // constrói o que cabe, então é preciso altura para exercitar os cards.
    tester.view.physicalSize = const Size(360, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _buildApp(
        // Dados que exercitam os cards com conteúdo largo: alerta de
        // estoque baixo (stock 4 < limiar, nome comprido) e venda recente
        // com total grande (além dos KPIs com caption).
        products: const [
          Product(
            id: 'p1',
            name: 'Produto com nome extremamente comprido para estresse',
            purchasePriceCents: 100,
            salePriceCents: 200,
            stockQuantity: 4,
          ),
        ],
        sales: [_sale(totalCents: 999999999)],
        cashFlow: const CashFlow(incomeCents: 10000, expenseCents: 0),
        debts: const [],
      ),
    );
    await tester.pumpAndSettle();

    // Os quatro KPIs continuam visíveis e o layout não estourou.
    expect(find.text('Total de vendas'), findsOneWidget);
    expect(find.text('Saldo em caixa'), findsOneWidget);
    expect(find.text('A receber (fiado)'), findsOneWidget);
    expect(find.text('Estoque em produtos'), findsOneWidget);
    // O alerta de estoque baixo renderizou (venda recente e KPI incluídos).
    // A seção de compras recentes (vazia) desceu o estoque abaixo do fold
    // com escala 2.0 — rola até o alerta antes de afirmar.
    await tester.dragUntilVisible(
      find.text('Estoque baixo'),
      find.byType(ListView),
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();
    expect(find.text('Estoque baixo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  // Regressão (UI): o dashboard precisa sobreviver à rotação — em paisagem
  // o grid de KPIs reflui de 2 para 4 colunas (LayoutBuilder >= 720) e a
  // lista de vendas recentes (abaixo do fold) continua íntegra após a
  // rolagem. Overflows de RenderFlex falham o teste via takeException.
  testWidgets('KPIs e vendas recentes sobrevivem à rotação para paisagem', (
    tester,
  ) async {
    usePortraitViewport(tester);

    await tester.pumpWidget(
      _buildApp(
        products: const [
          Product(
            id: 'p1',
            name: 'Caneta',
            purchasePriceCents: 100,
            salePriceCents: 200,
          ),
          Product(
            id: 'p2',
            name: 'Caderno',
            purchasePriceCents: 300,
            salePriceCents: 600,
          ),
        ],
        sales: [
          _sale(totalCents: 2000, number: 1),
          _sale(totalCents: 1000, number: 2),
        ],
        cashFlow: const CashFlow(incomeCents: 10000, expenseCents: 4000),
        debts: const [],
      ),
    );
    await tester.pumpAndSettle();

    // Retrato: KPIs (2 colunas) e vendas recentes visíveis (números
    // sequenciais distintos — S-00001 e S-00002).
    expect(find.text('Total de vendas'), findsOneWidget);
    expect(find.text('R\$ 30,00'), findsOneWidget);
    expect(find.text('Vendas recentes'), findsOneWidget);
    expect(find.text('S-00001 · 1 item'), findsOneWidget);
    expect(find.text('S-00002 · 1 item'), findsOneWidget);

    // Gira para paisagem: o grid de KPIs passa a 4 colunas.
    await rotateToLandscape(tester);

    // Os quatro KPIs seguem visíveis no topo, sem overflow.
    expect(find.text('Total de vendas'), findsOneWidget);
    expect(find.text('Saldo em caixa'), findsOneWidget);
    expect(find.text('A receber (fiado)'), findsOneWidget);
    expect(find.text('Estoque em produtos'), findsOneWidget);
    expect(find.text('R\$ 30,00'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Rolando, as vendas recentes continuam íntegras.
    await tester.dragUntilVisible(
      find.text('S-00002 · 1 item'),
      find.byType(ListView),
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();

    expect(find.text('S-00001 · 1 item'), findsOneWidget);
    expect(find.text('S-00002 · 1 item'), findsOneWidget);
    expect(find.text('M-Pesa'), findsNWidgets(2));
    expect(find.text('Pago'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}
