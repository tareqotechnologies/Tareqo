import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';
import '../../helpers/store_context.dart';

import 'package:dumbhanengue/domain/entities/app_user.dart';
import 'package:dumbhanengue/domain/entities/debt.dart';
import 'package:dumbhanengue/domain/entities/product.dart';
import 'package:dumbhanengue/domain/entities/sale.dart';
import 'package:dumbhanengue/domain/entities/sale_item.dart';
import 'package:dumbhanengue/domain/entities/store.dart';
import 'package:dumbhanengue/domain/entities/store_employee.dart';
import 'package:dumbhanengue/domain/repositories/i_sale_repository.dart';
import 'package:dumbhanengue/domain/usecases/get_cash_flow_use_case.dart';
import 'package:dumbhanengue/domain/usecases/get_employees_use_case.dart';
import 'package:dumbhanengue/domain/usecases/get_pending_debts_use_case.dart';
import 'package:dumbhanengue/domain/usecases/get_products_use_case.dart';
import 'package:dumbhanengue/presentation/controllers/account_providers.dart';
import 'package:dumbhanengue/presentation/controllers/admin_providers.dart';
import 'package:dumbhanengue/presentation/controllers/auth_providers.dart';
import 'package:dumbhanengue/presentation/controllers/debts_providers.dart';
import 'package:dumbhanengue/presentation/controllers/finance_providers.dart';
import 'package:dumbhanengue/presentation/controllers/products_providers.dart';
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
  Future<CashFlow> call({
    required String storeId,
    required DateTime start,
    required DateTime end,
  }) async =>
      _cashFlow;
}

class _FakeGetPendingDebtsUseCase implements GetPendingDebtsUseCase {
  _FakeGetPendingDebtsUseCase(this._debts);

  final List<Debt> _debts;

  @override
  Future<List<Debt>> call({required String storeId}) async => _debts;
}

class _FakeGetEmployeesUseCase implements GetEmployeesUseCase {
  _FakeGetEmployeesUseCase(this._employees);

  final List<StoreEmployee> _employees;

  @override
  Future<List<StoreEmployee>> call(String tenantId) async => _employees;
}

Sale _sale({required double total}) => Sale(
  id: 's-$total',
  items: const [
    SaleItem(
      productId: 'p1',
      productName: 'Caneta',
      quantity: 1,
      unitPrice: 2.0,
    ),
  ],
  totalAmount: total,
  paymentMethod: PaymentMethod.pix,
  dateTime: DateTime.now(),
);

Widget _buildApp({
  required List<Product> products,
  required List<Sale> sales,
  required CashFlow cashFlow,
  required List<Debt> debts,
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
        FakeGetStoresUseCase(
          const [Store(id: 'st1', tenantId: 'tn1', name: 'Loja Centro')],
        ),
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
        _FakeGetCashFlowUseCase(const CashFlow(income: 0, expense: 0)),
      ),
      getPendingDebtsUseCaseProvider.overrideWithValue(
        _FakeGetPendingDebtsUseCase(const []),
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

  testWidgets('exibe saudação, KPIs, loja ativa e vendas recentes',
      (tester) async {
    await pumpDashboard(
      tester,
      _buildApp(
        products: const [
          Product(id: 'p1', name: 'Caneta', purchasePrice: 1.0, salePrice: 2.0),
          Product(
            id: 'p2',
            name: 'Caderno',
            purchasePrice: 3.0,
            salePrice: 6.0,
          ),
        ],
        sales: [_sale(total: 20), _sale(total: 10)],
        cashFlow: const CashFlow(income: 100, expense: 40),
        debts: [
          Debt(
            id: 'd1',
            personName: 'Cliente A',
            amount: 15.0,
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

    // Vendas recentes (as 2 fornecidas, mais recentes primeiro).
    expect(find.text('Vendas recentes'), findsOneWidget);
    expect(find.text('1 item · Pix'), findsNWidgets(2));
  });

  testWidgets('exibe alerta de estoque baixo apenas para produtos com stock < 5',
      (tester) async {
    await pumpDashboard(
      tester,
      _buildApp(
        products: const [
          Product(
            id: 'p1',
            name: 'Caneta',
            purchasePrice: 1.0,
            salePrice: 2.0,
            stockQuantity: 2,
          ),
          Product(
            id: 'p2',
            name: 'Caderno',
            purchasePrice: 3.0,
            salePrice: 6.0,
            stockQuantity: 10,
          ),
        ],
        sales: [],
        cashFlow: const CashFlow(income: 0, expense: 0),
        debts: const [],
      ),
    );

    expect(find.text('Estoque baixo'), findsOneWidget);
    expect(find.text('Caneta'), findsOneWidget);
    expect(find.text('2 un.'), findsOneWidget);
    // O caderno (stock 10) não entra no alerta.
    expect(find.text('Caderno'), findsNothing);
  });

  testWidgets('mostra estado vazio de vendas recentes', (tester) async {
    await pumpDashboard(
      tester,
      _buildApp(
        products: const [],
        sales: const [],
        cashFlow: const CashFlow(income: 0, expense: 0),
        debts: const [],
      ),
    );

    expect(
      find.text('Nenhuma venda ainda — registre a primeira!'),
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
        cashFlow: const CashFlow(income: 0, expense: 0),
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
  testWidgets('funcionário NÃO vê Compras, Relatórios nem Lojas',
      (tester) async {
    await pumpDashboard(
      tester,
      _buildAppAsEmployee(
        role: EmployeeRole.employee,
        products: const [],
      ),
    );

    // Operação diária continua visível.
    expect(find.text('Clientes'), findsOneWidget);
    // Módulos gerenciais e de gestão ficam ocultos.
    expect(find.text('Compras'), findsNothing);
    expect(find.text('Relatórios'), findsNothing);
    expect(find.text('Lojas'), findsNothing);
  });

  testWidgets('gerente vê Compras e Relatórios, mas NÃO Lojas', (tester) async {
    await pumpDashboard(
      tester,
      _buildAppAsEmployee(
        role: EmployeeRole.manager,
        products: const [],
      ),
    );

    expect(find.text('Clientes'), findsOneWidget);
    expect(find.text('Compras'), findsOneWidget);
    expect(find.text('Relatórios'), findsOneWidget);
    // Gestão de lojas/funcionários/plano é exclusiva do dono.
    expect(find.text('Lojas'), findsNothing);
  });
}
