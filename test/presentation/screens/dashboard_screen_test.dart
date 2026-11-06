import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';
import '../../helpers/viewport.dart';
import '../../helpers/store_context.dart';

import 'package:tareqo/core/theme/app_theme.dart';
import 'package:tareqo/domain/entities/app_user.dart';
import 'package:tareqo/domain/entities/debt.dart';
import 'package:tareqo/domain/entities/financial_transaction.dart';
import 'package:tareqo/domain/entities/product.dart';
import 'package:tareqo/domain/entities/purchase.dart';
import 'package:tareqo/domain/entities/sale.dart';
import 'package:tareqo/domain/entities/sale_lot_consumption.dart';
import 'package:tareqo/domain/entities/sale_item.dart';
import 'package:tareqo/domain/entities/store.dart';
import 'package:tareqo/domain/entities/store_employee.dart';
import 'package:tareqo/domain/repositories/i_financial_transaction_repository.dart';
import 'package:tareqo/domain/usecases/get_dashboard_kpis_use_case.dart';
import 'package:tareqo/domain/repositories/i_cash_flow_repository.dart';
import 'package:tareqo/domain/repositories/i_sale_repository.dart';
import 'package:tareqo/domain/usecases/get_cash_flow_use_case.dart';
import 'package:tareqo/domain/usecases/get_employees_use_case.dart';
import 'package:tareqo/domain/usecases/get_pending_debts_use_case.dart';
import 'package:tareqo/domain/usecases/get_products_use_case.dart';
import 'package:tareqo/domain/usecases/get_purchases_use_case.dart';
import 'package:tareqo/domain/usecases/get_settled_debts_use_case.dart';
import 'package:tareqo/presentation/controllers/account_providers.dart';
import 'package:tareqo/presentation/controllers/admin_providers.dart';
import 'package:tareqo/presentation/controllers/dashboard_providers.dart';
import 'package:tareqo/presentation/controllers/auth_providers.dart';
import 'package:tareqo/presentation/controllers/debts_providers.dart';
import 'package:tareqo/presentation/controllers/finance_providers.dart';
import 'package:tareqo/presentation/controllers/products_providers.dart';
import 'package:tareqo/presentation/controllers/purchases_providers.dart';
import 'package:tareqo/presentation/controllers/sales_providers.dart';
import 'package:tareqo/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:tareqo/presentation/screens/shell/menu_screen.dart';
import 'package:tareqo/presentation/widgets/store_switcher.dart';

/// Notifier de KPIs que SEMPRE falha (simula a RPC `get_dashboard_kpis`
/// indisponível) — usado para verificar que a linha de métricas nunca mostra
/// zeros falsos e que o aviso com retry aparece no lugar.
class _FailingDashboardKpisNotifier extends DashboardKpisNotifier {
  @override
  Future<DashboardKpis> build() async => throw Exception('RPC falhou');
}

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
  Future<Sale?> getById(String id, {required String storeId}) async {
    for (final sale in _sales) {
      if (sale.id == id) return sale;
    }
    return null;
  }

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

class _FakeGetSettledDebtsUseCase implements GetSettledDebtsUseCase {
  _FakeGetSettledDebtsUseCase(this._debts);

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

class _FakeFinanceRepository implements IFinancialTransactionRepository {
  _FakeFinanceRepository(this._transactions);

  final List<FinancialTransaction> _transactions;

  @override
  Future<List<FinancialTransaction>> getByPeriod({
    required String storeId,
    required DateTime start,
    required DateTime end,
  }) async => _transactions;

  @override
  Future<List<FinancialTransaction>> getAll({required String storeId}) async =>
      _transactions;

  @override
  Future<void> add(FinancialTransaction transaction) async {}

  @override
  Future<void> markAsPaid(String id, {required String storeId}) async {}
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
  List<Debt> settledDebts = const [],
  List<FinancialTransaction> transactions = const [],
  List<dynamic> extraOverrides = const [],
}) {
  return ProviderScope(
    overrides: [
      ...storeContextOverrides(),
      ...extraOverrides,
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
      getSettledDebtsUseCaseProvider.overrideWithValue(
        _FakeGetSettledDebtsUseCase(settledDebts),
      ),
      getPurchasesUseCaseProvider.overrideWithValue(
        _FakeGetPurchasesUseCase(purchases),
      ),
      financeRepositoryProvider.overrideWithValue(
        _FakeFinanceRepository(transactions),
      ),
    ],
    child: testApp(home: const DashboardScreen()),
  );
}

/// Menu tab com o utilizador logado como FUNCIONÁRIO ou GERENTE (o tenant
/// pertence a OUTRO utilizador — `ownerUserId` ≠ `userId`). A matriz de acesso
/// (Compras/Relatórios/Lojas) vive no hub Menu desde o canvas V3 — o
/// dashboard não exibe mais módulos.
Widget _buildMenuAsEmployee({required EmployeeRole role}) {
  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith(
        (ref) => Stream.value(const AppUser(id: '1', email: 'func@loja.com')),
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
    ],
    child: testApp(home: const MenuScreen()),
  );
}

void main() {
  // O dashboard é um ListView — usa uma viewport alta para que toda a tela
  // (cabeçalho, métricas, feed) seja montada sem scroll.
  Future<void> pumpDashboard(WidgetTester tester, Widget app) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
  }

  // A11y (Fase 6): toda a tela passa nos guidelines de toque (≥48dp) e
  // contraste de texto — cobre KPIs, pílula de período, chip de loja e feed.
  testWidgets('a11y: dashboard passa nos guidelines de toque e contraste', (
    tester,
  ) async {
    await pumpDashboard(
      tester,
      _buildApp(
        products: const [],
        sales: const [],
        cashFlow: const CashFlow(incomeCents: 10000, expenseCents: 4000),
        debts: const [],
      ),
    );

    final handle = tester.ensureSemantics();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });

  // A11y (plano UI/UX — Fase 3.1): cada KPI do hero é UM nó semântico com
  // rótulo + valor (o leitor de ecrã anuncia "Vendas: 30,00 BRL" de uma
  // vez, não dígito a dígito) e os textos visuais ficam EXCLUÍDOS da
  // árvore de semântica (excludeSemantics — o rótulo composto é a única
  // fonte falada).
  testWidgets('KPIs do hero expõem rótulo completo e excluem nós filhos', (
    tester,
  ) async {
    await pumpDashboard(
      tester,
      _buildApp(
        products: const [],
        sales: [_sale(totalCents: 3000, number: 1)],
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

    final handle = tester.ensureSemantics();

    // Vendas: 30,00 sem delta (não há vendas no período anterior).
    expect(
      tester.getSemantics(find.byKey(const ValueKey('metric-sales'))).label,
      'Vendas: 30,00 BRL',
    );
    // Caixa: saldo do fluxo (10000−4000 centavos = 60,00).
    expect(
      tester.getSemantics(find.byKey(const ValueKey('metric-cash'))).label,
      'Caixa: 60,00 BRL',
    );
    // A receber: valor dos KPIs + contagem de fiados no subtexto.
    expect(
      tester
          .getSemantics(find.byKey(const ValueKey('metric-receivables')))
          .label,
      'A receber: 15,00 BRL, 1 fiado',
    );

    // excludeSemantics: o texto visual do rótulo NÃO tem nó próprio — o
    // elemento resolve para o nó PAI composto ("Vendas: 30,00 BRL"), então
    // o leitor nunca anuncia "Vendas" e "30,00 BRL" separados.
    expect(tester.getSemantics(find.text('Vendas')).label, 'Vendas: 30,00 BRL');
    handle.dispose();
  });

  testWidgets('exibe saudação, data, pílula de período, loja e métricas', (
    tester,
  ) async {
    await pumpDashboard(
      tester,
      _buildApp(
        products: const [],
        sales: [
          _sale(totalCents: 2000, number: 1),
          _sale(totalCents: 1000, number: 2),
        ],
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
    expect(find.text('Olá, dono'), findsOneWidget);
    // Data ACIMA da saudação (canvas V3) + pílula de período "Hoje".
    expect(find.text('Hoje'), findsOneWidget);
    expect(find.byKey(const ValueKey('dashboardPeriodPill')), findsOneWidget);
    // Loja ativa (chip verde-escuro abaixo da saudação).
    expect(find.byKey(StoreSwitcher.pillKey), findsOneWidget);
    expect(find.text('Loja Centro'), findsOneWidget);

    // 3 métricas no formato "1.000,00 MOEDA": Vendas (30), Caixa (60),
    // A receber (15) — valor com 2 casas + código da moeda no final.
    expect(find.text('Vendas'), findsOneWidget);
    expect(find.text('30,00 BRL'), findsOneWidget);
    expect(find.text('Caixa'), findsOneWidget);
    expect(find.text('60,00 BRL'), findsOneWidget);
    expect(find.text('A receber'), findsOneWidget);
    expect(find.text('15,00 BRL'), findsOneWidget);
    // Subtexto: contagem de fiados no A receber.
    expect(find.text('1 fiado'), findsOneWidget);

    // Feed de atividade: vendas de hoje como linhas compactas (o header
    // junta o título com a contagem — busca parcial).
    expect(find.textContaining('Atividade de hoje'), findsOneWidget);
    expect(find.text('Venda S-00001'), findsOneWidget);
    expect(find.text('Venda S-00002'), findsOneWidget);
    // O detalhe da linha traz o método ("M-Pesa · há X min").
    expect(find.textContaining('M-Pesa'), findsNWidgets(2));
    // Valores assinados sem símbolo (canvas V3).
    expect(find.text('+20,00'), findsOneWidget);
    expect(find.text('+10,00'), findsOneWidget);
  });

  // Semântica de caixa (UI): o VALOR do card "Caixa" segue o SINAL — verde
  // (income) para saldos ≥ 0, vermelho (expense) para negativos.
  testWidgets('saldo em caixa negativo usa a cor de saída', (tester) async {
    await pumpDashboard(
      tester,
      _buildApp(
        products: const [],
        sales: const [],
        cashFlow: const CashFlow(incomeCents: 10000, expenseCents: 20000),
        debts: const [],
      ),
    );

    final cashCard = find.byKey(const ValueKey('metric-cash'));
    // Saldo −10000 centavos → −100 unidades → valor "-100,00 BRL".
    final value = tester.widget<Text>(
      find.descendant(of: cashCard, matching: find.text('-100,00 BRL')),
    );
    // Saldo negativo → variante ESCURA de saída no tema escuro (AA).
    expect(value.style?.color, AppColors.expense);
  });

  // Regressão (UX): a RPC de KPIs falhar sem dados anteriores fazia a
  // grade exibir "R$ 0,00" em todos os cards — números falsos parecendo
  // reais. Agora a linha de métricas dá lugar a um aviso com retry; o feed
  // segue funcional porque usa providers próprios.
  testWidgets('falha nos KPIs mostra aviso com retry em vez de zeros', (
    tester,
  ) async {
    await pumpDashboard(
      tester,
      _buildApp(
        products: const [],
        sales: [_sale(totalCents: 2000)],
        cashFlow: const CashFlow(incomeCents: 0, expenseCents: 0),
        debts: const [],
        extraOverrides: [
          dashboardKpisProvider.overrideWith(_FailingDashboardKpisNotifier.new),
        ],
      ),
    );

    // Aviso com retry no lugar da linha de métricas.
    expect(
      find.text('Não foi possível carregar os indicadores.'),
      findsOneWidget,
    );
    expect(find.text('Tentar novamente'), findsOneWidget);
    // Nenhuma métrica com zero falso.
    expect(find.text('Vendas'), findsNothing);
    expect(find.text('Caixa'), findsNothing);
    // O resto da tela continua funcional (feed com a venda do provider
    // próprio — "+20,00" está lá).
    expect(find.text('Atividade de hoje'), findsOneWidget);
    expect(find.text('+20,00'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  // O banner de sincronização pendente vive no SHELL desde o Lote 3
  // (estado global do caminho de dinheiro, visível em todas as abas) —
  // o cenário migrado está em app_shell_test.dart.

  testWidgets('tocar em uma venda do feed abre os detalhes da venda', (
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

    await tester.tap(find.text('Venda S-00001'));
    await tester.pumpAndSettle();

    // O feed da Home mantém a tela completa de detalhe (o sheet padrão de
    // eventos é usado pela lista de Vendas, via showSaleDetailSheet).
    expect(find.text('Detalhes da venda'), findsOneWidget);
    expect(find.text('Caneta'), findsOneWidget);
  });

  // Canvas V3: as COMPRAS de hoje aparecem no feed como entradas de stock
  // ("Stock · Caneta" / "Entrada de 1 un · há X min" / "+1").
  testWidgets('compras de hoje entram no feed como entradas de stock', (
    tester,
  ) async {
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

    expect(find.text('Stock · Caneta'), findsNWidgets(2));
    expect(find.textContaining('Entrada de 1 un'), findsNWidgets(2));
    expect(find.text('+1'), findsNWidgets(2));
  });

  // Canvas V3: baixas de fiado de hoje viram "Pagamento fiado" no feed.
  testWidgets('baixas de fiado de hoje aparecem no feed', (tester) async {
    await pumpDashboard(
      tester,
      _buildApp(
        products: const [],
        sales: const [],
        cashFlow: const CashFlow(incomeCents: 0, expenseCents: 0),
        debts: const [],
        settledDebts: [
          Debt(
            id: 'd2',
            personName: 'Carlos M.',
            amountCents: 120000,
            dueDate: DateTime.now(),
            isCustomerDebt: true,
            isPaid: true,
            paidAt: DateTime.now(),
          ),
        ],
      ),
    );

    expect(find.text('Pagamento fiado'), findsOneWidget);
    expect(find.textContaining('Carlos M.'), findsOneWidget);
    expect(find.text('+1.200,00'), findsOneWidget);
  });

  // Canvas V3: despesas de hoje viram "Despesa · Luz" no feed (valor vermelho).
  testWidgets('despesas de hoje aparecem no feed', (tester) async {
    await pumpDashboard(
      tester,
      _buildApp(
        products: const [],
        sales: const [],
        cashFlow: const CashFlow(incomeCents: 0, expenseCents: 0),
        debts: const [],
        transactions: [
          FinancialTransaction(
            id: 't1',
            description: 'Luz',
            amountCents: 89000,
            type: TransactionType.expense,
            category: 'Despesas',
            date: DateTime.now(),
          ),
        ],
      ),
    );

    expect(find.text('Despesa · Luz'), findsOneWidget);
    expect(find.text('-890,00'), findsOneWidget);
  });

  testWidgets(
    'exibe alerta de stock baixo apenas para produtos com stock < 5',
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

      // Canvas V3: título "Stock baixo" + detalhe "{produto} · {qty}
      // restantes" + pílula "Alerta".
      expect(find.text('Stock baixo'), findsOneWidget);
      expect(find.textContaining('Caneta'), findsOneWidget);
      expect(find.text('Alerta'), findsOneWidget);
      // O caderno (stock 10) não entra no alerta.
      expect(find.textContaining('Caderno'), findsNothing);
    },
  );

  testWidgets('mostra estado vazio de atividade', (tester) async {
    await pumpDashboard(
      tester,
      _buildApp(
        products: const [],
        sales: const [],
        cashFlow: const CashFlow(incomeCents: 0, expenseCents: 0),
        debts: const [],
      ),
    );

    expect(find.text('Nenhuma atividade registada ainda.'), findsOneWidget);
    expect(find.text('Stock baixo'), findsNothing);
  });

  // App de referência: a Home é só cabeçalho + 3 métricas compactas + o
  // feed de atividade (SEM ações rápidas, SEM módulos — essas vivem no
  // FAB central e na aba Menu).
  testWidgets('não exibe ações rápidas nem módulos', (tester) async {
    await pumpDashboard(
      tester,
      _buildApp(
        products: const [],
        sales: const [],
        cashFlow: const CashFlow(incomeCents: 0, expenseCents: 0),
        debts: const [],
      ),
    );

    expect(find.text('Ações rápidas'), findsNothing);
    expect(find.text('Módulos'), findsNothing);
    expect(find.text('Clientes'), findsNothing);
    expect(find.text('Compras recentes'), findsNothing);
    // Feed: título + contagem (sem link "Ver todas" no app de referência).
    expect(find.text('Atividade de hoje'), findsOneWidget);
    expect(find.text('Ver todas'), findsNothing);
  });

  // Matriz de acesso (canvas V3): os módulos vivem no hub Menu — DONO = tudo;
  // GERENTE = operação completa (inclui Compras/Relatórios) mas SEM Lojas;
  // FUNCIONÁRIO = só operação diária (SEM Compras, SEM Relatórios, SEM Lojas).
  testWidgets('funcionário NÃO vê Compras, Relatórios nem Lojas (Menu)', (
    tester,
  ) async {
    await pumpDashboard(
      tester,
      _buildMenuAsEmployee(role: EmployeeRole.employee),
    );

    // Operação diária continua visível.
    expect(find.text('Clientes'), findsOneWidget);
    // Módulos gerenciais e de gestão ficam ocultos.
    expect(find.text('Compras'), findsNothing);
    expect(find.text('Relatórios'), findsNothing);
    expect(find.text('Lojas'), findsNothing);
  });

  testWidgets('gerente vê Compras e Relatórios, mas NÃO Lojas (Menu)', (
    tester,
  ) async {
    await pumpDashboard(
      tester,
      _buildMenuAsEmployee(role: EmployeeRole.manager),
    );

    expect(find.text('Clientes'), findsOneWidget);
    expect(find.text('Compras'), findsOneWidget);
    expect(find.text('Relatórios'), findsOneWidget);
    // Gestão de lojas/funcionários/plano é exclusiva do dono.
    expect(find.text('Lojas'), findsNothing);
  });

  // Regressão (UI): os 3 cards de métrica e o feed não podem estourar com
  // escala de texto 2.0 em tela estreita (FittedBox no valor; overflows de
  // RenderFlex falham o teste automaticamente via takeException).
  testWidgets('métricas e feed não estouram com escala de texto 2.0', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearAllTestValues);

    tester.view.physicalSize = const Size(360, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _buildApp(
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

    // Os 3 cards de métrica continuam visíveis e o layout não estourou.
    expect(find.text('Vendas'), findsOneWidget);
    expect(find.text('Caixa'), findsOneWidget);
    expect(find.text('A receber'), findsOneWidget);
    // O alerta de stock baixo entrou no feed (produto com nome comprido
    // dentro do detalhe "{nome} · ... restantes").
    await tester.dragUntilVisible(
      find.textContaining('Produto com nome extremamente comprido'),
      find.byType(ListView),
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Produto com nome extremamente comprido'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  // Badge do feed ("Alerta"/"Alert"/"Alerte") SEM cortar: a pílula usa
  // FittedBox scaleDown (mesmo padrão do StatusChip) — com fonte ampliada
  // (2.0×, pior caso do badge localizado) o texto encolhe em vez de
  // cortar (clip) ou estourar a Row (auditoria de legibilidade — #1).
  testWidgets('badge do feed não corta com fonte 2.0 (auto-size)', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearAllTestValues);

    tester.view.physicalSize = const Size(360, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _buildApp(
        products: const [
          Product(
            id: 'p1',
            name: 'Produto',
            purchasePriceCents: 100,
            salePriceCents: 200,
            stockQuantity: 4, // < 5 un — entra no feed como stock baixo.
          ),
        ],
        sales: [_sale(totalCents: 500)],
        cashFlow: const CashFlow(incomeCents: 10000, expenseCents: 0),
        debts: const [],
      ),
    );
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.textContaining('Alert'),
      find.byType(ListView),
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();

    // A pílula do badge é auto-size (FittedBox): o texto nunca é
    // cortado — o padrão fica trancado por este teste.
    expect(
      find.ancestor(
        of: find.textContaining('Alert'),
        matching: find.byType(FittedBox),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  // Regressão (UI): o dashboard precisa sobreviver à rotação — as 3 métricas
  // continuam no topo e o feed íntegro após a rolagem.
  testWidgets('métricas e feed sobrevivem à rotação para paisagem', (
    tester,
  ) async {
    usePortraitViewport(tester);

    await tester.pumpWidget(
      _buildApp(
        products: const [],
        sales: [
          _sale(totalCents: 2000, number: 1),
          _sale(totalCents: 1000, number: 2),
        ],
        cashFlow: const CashFlow(incomeCents: 10000, expenseCents: 4000),
        debts: const [],
      ),
    );
    await tester.pumpAndSettle();

    // Retrato: métricas + feed de atividade visíveis.
    expect(find.text('Vendas'), findsOneWidget);
    expect(find.text('30,00 BRL'), findsOneWidget);
    expect(find.text('Atividade de hoje'), findsOneWidget);
    expect(find.text('Venda S-00001'), findsOneWidget);
    expect(find.text('Venda S-00002'), findsOneWidget);

    // Gira para paisagem.
    await rotateToLandscape(tester);

    // As 3 métricas seguem visíveis no topo, sem overflow.
    expect(find.text('Vendas'), findsOneWidget);
    expect(find.text('Caixa'), findsOneWidget);
    expect(find.text('A receber'), findsOneWidget);
    expect(find.text('30,00 BRL'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Rolando, o feed de atividade continua íntegro.
    await tester.dragUntilVisible(
      find.text('Venda S-00002'),
      find.byType(ListView),
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();

    expect(find.text('Venda S-00001'), findsOneWidget);
    expect(find.text('Venda S-00002'), findsOneWidget);
    expect(find.textContaining('M-Pesa'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}
