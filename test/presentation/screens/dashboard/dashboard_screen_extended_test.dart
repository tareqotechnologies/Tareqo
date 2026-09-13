import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/store_context.dart';
import '../../../helpers/test_app.dart';

import 'package:tareqo/domain/entities/debt.dart';
import 'package:tareqo/domain/entities/financial_transaction.dart';
import 'package:tareqo/domain/entities/product.dart';
import 'package:tareqo/domain/entities/purchase.dart';
import 'package:tareqo/domain/entities/sale.dart';
import 'package:tareqo/domain/entities/sale_item.dart';
import 'package:tareqo/domain/entities/sale_lot_consumption.dart';
import 'package:tareqo/domain/entities/stock_lot.dart';
import 'package:tareqo/domain/repositories/i_cash_flow_repository.dart';
import 'package:tareqo/domain/repositories/i_financial_transaction_repository.dart';
import 'package:tareqo/domain/repositories/i_sale_repository.dart';
import 'package:tareqo/domain/usecases/get_cash_flow_use_case.dart';
import 'package:tareqo/domain/usecases/get_dashboard_kpis_use_case.dart';
import 'package:tareqo/domain/usecases/get_pending_debts_use_case.dart';
import 'package:tareqo/domain/usecases/get_products_use_case.dart';
import 'package:tareqo/domain/usecases/get_purchases_use_case.dart';
import 'package:tareqo/domain/usecases/get_settled_debts_use_case.dart';
import 'package:tareqo/domain/usecases/get_stock_lots_use_case.dart';
import 'package:tareqo/domain/repositories/i_dashboard_kpis_repository.dart';
import 'package:tareqo/presentation/controllers/expiry_alerts_provider.dart';
import 'package:tareqo/presentation/controllers/dashboard_providers.dart';
import 'package:tareqo/presentation/controllers/debts_providers.dart';
import 'package:tareqo/presentation/controllers/finance_providers.dart';
import 'package:tareqo/presentation/controllers/products_providers.dart';
import 'package:tareqo/presentation/controllers/purchases_providers.dart';
import 'package:tareqo/presentation/controllers/sales_providers.dart';
import 'package:tareqo/presentation/screens/dashboard/dashboard_screen.dart';

// ─── Fakes (padrão do dashboard_screen_test.dart) ───────────────────────────

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
  Future<List<Sale>> getAll({required String storeId}) async => _sales;
}

class _FakeGetCashFlowUseCase implements GetCashFlowUseCase {
  _FakeGetCashFlowUseCase({this.incomeCents = 0, this.expenseCents = 0});
  final int incomeCents;
  final int expenseCents;
  @override
  final ICashFlowRepository? serverRepository = null;
  @override
  Future<CashFlow> call({
    required String storeId,
    required DateTime start,
    required DateTime end,
  }) async => CashFlow(incomeCents: incomeCents, expenseCents: expenseCents);
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

class _FakeFinanceRepository implements IFinancialTransactionRepository {
  _FakeFinanceRepository(this._transactions);
  final List<FinancialTransaction> _transactions;
  @override
  Future<List<FinancialTransaction>> getAll({required String storeId}) async =>
      _transactions;
  @override
  dynamic noSuchMethod(Invocation invocation) async => const [];
}

class _FakeGetStockLotsUseCase implements GetStockLotsUseCase {
  _FakeGetStockLotsUseCase(this._lots);
  final List<StockLot> _lots;
  @override
  Future<List<StockLot>> getByStore({required String storeId}) async => _lots;
}

class _FakeKpisRepository implements IDashboardKpisRepository {
  _FakeKpisRepository({this.pendingTotalCents = 0});
  final int pendingTotalCents;
  @override
  Future<DashboardKpis> fetchKpis({
    required String storeId,
    required DateTime start,
    required DateTime end,
  }) async => DashboardKpis(
    totalSalesCents: 0,
    cashIncomeCents: 0,
    cashExpenseCents: 0,
    pendingTotalCents: pendingTotalCents,
    stockTotal: 0,
  );
}

Product _product({
  String id = 'p1',
  String name = 'Paracetamol',
  int stock = 20000,
  bool isActive = true,
}) => Product(
  id: id,
  name: name,
  purchasePriceCents: 800,
  salePriceCents: 1500,
  stockQuantity: stock,
  isActive: isActive,
);

StockLot _lot({
  required String id,
  required String productId,
  required DateTime expiry,
}) => StockLot(
  id: id,
  productId: productId,
  entryDate: DateTime(2026, 9, 1),
  expiryDate: expiry,
  initialQuantity: 1000,
  currentQuantity: 500,
  costPriceCents: 800,
);

Sale _sale({
  required int totalCents,
  DateTime? at,
  SaleStatus status = SaleStatus.active,
}) => Sale(
  id: 's-$totalCents-$at',
  items: const [
    SaleItem(
      productId: 'p1',
      productName: 'Paracetamol',
      quantity: 1,
      unitPriceCents: 100,
    ),
  ],
  totalAmountCents: totalCents,
  paymentMethod: PaymentMethod.mPesa,
  dateTime: at ?? DateTime.now(),
  status: status,
);

Debt _settledDebt() => Debt(
  id: 'd1',
  personName: 'João',
  amountCents: 2500,
  dueDate: DateTime.now(),
  isCustomerDebt: true,
  isPaid: true,
  paidAt: DateTime.now(),
);

FinancialTransaction _expense() => FinancialTransaction(
  id: 't1',
  storeId: 'st1',
  description: 'Energia',
  category: 'Despesas gerais',
  type: TransactionType.expense,
  status: TransactionStatus.paid,
  amountCents: 1000,
  date: DateTime.now(),
);

Widget _buildApp({
  List<Product> products = const [],
  List<Sale> sales = const [],
  List<StockLot> lots = const [],
  List<Debt> pendingDebts = const [],
  List<Debt> settledDebts = const [],
  List<FinancialTransaction> transactions = const [],
  int cashIncomeCents = 0,
  int cashExpenseCents = 0,
  int kpisPendingCents = 0,
  bool failKpis = false,
}) {
  return ProviderScope(
    overrides: [
      ...storeContextOverrides(),
      getProductsUseCaseProvider.overrideWithValue(
        _FakeGetProductsUseCase(products),
      ),
      salesRepositoryProvider.overrideWithValue(_FakeSalesRepository(sales)),
      getCashFlowUseCaseProvider.overrideWithValue(
        _FakeGetCashFlowUseCase(
          incomeCents: cashIncomeCents,
          expenseCents: cashExpenseCents,
        ),
      ),
      getPendingDebtsUseCaseProvider.overrideWithValue(
        _FakeGetPendingDebtsUseCase(pendingDebts),
      ),
      getSettledDebtsUseCaseProvider.overrideWithValue(
        _FakeGetSettledDebtsUseCase(settledDebts),
      ),
      getPurchasesUseCaseProvider.overrideWithValue(
        _FakeGetPurchasesUseCase(const []),
      ),
      getStockLotsUseCaseProvider.overrideWithValue(
        _FakeGetStockLotsUseCase(lots),
      ),
      financeRepositoryProvider.overrideWithValue(
        _FakeFinanceRepository(transactions),
      ),
      if (failKpis)
        getDashboardKpisUseCaseProvider.overrideWithValue(
          GetDashboardKpisUseCase(_FailingKpisRepository()),
        )
      else
        getDashboardKpisUseCaseProvider.overrideWithValue(
          GetDashboardKpisUseCase(
            _FakeKpisRepository(pendingTotalCents: kpisPendingCents),
          ),
        ),
    ],
    child: testApp(
      home: const DashboardScreen(),
      builder: (context, child) =>
          MediaQuery.withClampedTextScaling(maxScaleFactor: 0.6, child: child!),
    ),
  );
}

class _FailingKpisRepository implements IDashboardKpisRepository {
  @override
  Future<DashboardKpis> fetchKpis({
    required String storeId,
    required DateTime start,
    required DateTime end,
  }) async => throw Exception('falha de rede');
}

Future<void> _pumpDashboard(WidgetTester tester, Widget app) async {
  tester.view.physicalSize = const Size(1250, 2200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('alertas de validade: lote vencido e vencendo no feed', (
    tester,
  ) async {
    final now = DateTime.now();
    await _pumpDashboard(
      tester,
      _buildApp(
        products: [_product(id: 'p1', name: 'Dorflex')],
        lots: [
          // Vencido há 3 dias (vermelho)...
          _lot(
            id: 'lot-old',
            productId: 'p1',
            expiry: now.subtract(const Duration(days: 3)),
          ),
          // ...e vence em 10 dias (amarelo).
          _lot(
            id: 'lot-soon',
            productId: 'p1',
            expiry: now.add(const Duration(days: 10)),
          ),
        ],
      ),
    );

    // Feed de atividade contém 2 alertas de validade: vencido (vermelho)
    // e a vencer (amarelo) — o título do tile é o NOME DO PRODUTO.
    expect(find.text('Dorflex'), findsNWidgets(2));
    expect(find.textContaining('Venceu há'), findsOneWidget);
    expect(find.textContaining('Vence em'), findsOneWidget);
  });

  testWidgets('produto sem estoque baixo nem alerta não gera atividade', (
    tester,
  ) async {
    await _pumpDashboard(
      tester,
      _buildApp(products: [_product(stock: 50000)], lots: const []),
    );

    expect(find.text('Nenhuma atividade registrada ainda.'), findsOneWidget);
  });

  testWidgets('feed mostra venda de hoje, fiado pago e despesa', (
    tester,
  ) async {
    await _pumpDashboard(
      tester,
      _buildApp(
        sales: [_sale(totalCents: 5000)],
        settledDebts: [_settledDebt()],
        transactions: [_expense()],
      ),
    );

    // Venda de hoje aparece no feed como "Venda S-00001" (rótulo pelo
    // número sequencial, não pelo valor).
    expect(find.text('3 eventos'), findsOneWidget);
    expect(find.textContaining('Venda S-'), findsWidgets);
    expect(find.text('Pagamento fiado'), findsOneWidget);
    expect(find.text('Despesa · Energia'), findsOneWidget);
  });

  testWidgets('venda cancelada não entra nas métricas nem no feed', (
    tester,
  ) async {
    await _pumpDashboard(
      tester,
      _buildApp(sales: [_sale(totalCents: 5000, status: SaleStatus.cancelled)]),
    );

    // Sem eventos: só o cancelado existiria. Zero em unidades no hero
    // ("0,00 BRL") — mas o KPI server-side pode sobrepor; usamos o feed.
    expect(find.text('Nenhuma atividade registrada ainda.'), findsOneWidget);
    expect(find.textContaining('Venda S-'), findsNothing);
  });

  testWidgets('banner de erro dos KPIs aparece com retry', (tester) async {
    await _pumpDashboard(tester, _buildApp(failKpis: true));

    expect(
      find.text('Não foi possível carregar os indicadores.'),
      findsOneWidget,
    );
    expect(find.text('Tentar novamente'), findsOneWidget);
  });

  testWidgets('caixa negativo é exibido como negativo', (tester) async {
    await _pumpDashboard(
      tester,
      _buildApp(cashIncomeCents: 1000, cashExpenseCents: 9000),
    );

    // Saída 9.000¢ − entrada 1.000¢ = −8.000 centavos = −80 unidades →
    // "-80,00 BRL", no card de caixa (key 'metric-cash', mesmo padrão
    // do dashboard_screen_test).
    final cashValue = find.descendant(
      of: find.byKey(const ValueKey('metric-cash')),
      matching: find.text('-80,00 BRL'),
    );
    expect(cashValue, findsOneWidget);
  });

  testWidgets('a receber usa os KPIs do servidor (RPC) quando disponível', (
    tester,
  ) async {
    await _pumpDashboard(
      tester,
      _buildApp(
        kpisPendingCents: 75000,
        pendingDebts: [
          Debt(
            id: 'd1',
            personName: 'João',
            amountCents: 2500,
            dueDate: DateTime.now(),
            isCustomerDebt: true,
          ),
        ],
      ),
    );

    // Valor dos KPIs server-side + contagem de fiados local.
    expect(find.textContaining('750,00'), findsWidgets);
    expect(find.textContaining('1 fiado'), findsWidgets);
  });
}
