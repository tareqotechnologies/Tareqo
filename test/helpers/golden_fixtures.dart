import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'store_context.dart';
import 'test_app.dart';

import 'package:tareqo/domain/entities/debt.dart';
import 'package:tareqo/domain/entities/financial_transaction.dart';
import 'package:tareqo/domain/entities/product.dart';
import 'package:tareqo/domain/entities/purchase.dart';
import 'package:tareqo/domain/entities/sale.dart';
import 'package:tareqo/domain/entities/sale_item.dart';
import 'package:tareqo/domain/entities/sale_lot_consumption.dart';
import 'package:tareqo/domain/repositories/i_cash_flow_repository.dart';
import 'package:tareqo/domain/repositories/i_financial_transaction_repository.dart';
import 'package:tareqo/domain/repositories/i_sale_processor.dart';
import 'package:tareqo/domain/repositories/i_sale_repository.dart';
import 'package:tareqo/domain/usecases/get_cash_flow_use_case.dart';
import 'package:tareqo/domain/usecases/get_dashboard_kpis_use_case.dart';
import 'package:tareqo/domain/usecases/get_pending_debts_use_case.dart';
import 'package:tareqo/domain/usecases/get_settled_debts_use_case.dart';
import 'package:tareqo/domain/usecases/get_purchases_use_case.dart';
import 'package:tareqo/domain/usecases/get_products_use_case.dart';
import 'package:tareqo/domain/usecases/process_sale_use_case.dart';
import 'package:tareqo/presentation/controllers/dashboard_providers.dart';
import 'package:tareqo/presentation/controllers/debts_providers.dart';
import 'package:tareqo/presentation/controllers/finance_providers.dart';
import 'package:tareqo/presentation/controllers/products_providers.dart';
import 'package:tareqo/presentation/controllers/purchases_providers.dart';
import 'package:tareqo/presentation/controllers/sales_providers.dart';
import 'package:tareqo/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:tareqo/presentation/screens/sales/new_sale_sheet.dart';

/// Dados demo reutilizados pelos goldens de tela cheia.
///
/// **Determinismo temporal:** todas as datas derivam de uma âncora fixa —
/// `kGoldenNow` — e o relógio do app é injetado nela. Nenhuma entidade usa
/// `DateTime.now()` direto; assim o golden não muda entre dias/meses.
// Âncora temporal dos dados demo — `final` (DateTime não tem construtor
// const em Dart); as entidades que a usam não podem ser const.
final DateTime kGoldenNow = DateTime(2026, 9, 17, 10, 30);

/// Catálogo demo do PDV — produtos reais de um comércio (nomes, unidades e
/// preços plausíveis; nada de "Item 1"/"Produto X").
final List<Product> demoProducts = [
  const Product(
    id: 'p1',
    name: 'Arroz Gerusa 25 kg',
    purchasePriceCents: 185000,
    salePriceCents: 249000,
    stockQuantity: 14000,
    code: '10001',
  ),
  const Product(
    id: 'p2',
    name: 'Óleo Alentejo 900 ml',
    purchasePriceCents: 12500,
    salePriceCents: 18900,
    stockQuantity: 36000,
    code: '10002',
  ),
  const Product(
    id: 'p3',
    name: 'Açúcar Kenyon 1 kg',
    purchasePriceCents: 6200,
    salePriceCents: 9500,
    stockQuantity: 22000,
    code: '10003',
  ),
  const Product(
    id: 'p4',
    name: 'Cerveja 2M 330 ml',
    purchasePriceCents: 3500,
    salePriceCents: 6000,
    stockQuantity: 48000,
    code: '10004',
  ),
  const Product(
    id: 'p5',
    name: 'Sabão Omo 500 g',
    purchasePriceCents: 8900,
    salePriceCents: 13900,
    stockQuantity: 1500,
    code: '10005',
  ),
];

/// Vendas demo (hoje, na âncora do relógio).
List<Sale> demoSales = List.unmodifiable([
  _sale(number: 1, totalCents: 249000, minuteOfDay: 8),
  _sale(number: 2, totalCents: 12700, minuteOfDay: 6),
]);

Sale _sale({required int number, required int totalCents, required int minuteOfDay}) => Sale(
  id: 's-$number',
  number: number,
  items: [
    SaleItem(
      productId: 'p$number',
      productName: 'Produto $number',
      quantity: 1000,
      unitPriceCents: totalCents,
    ),
  ],
  totalAmountCents: totalCents,
  paymentMethod: number.isEven ? PaymentMethod.mPesa : PaymentMethod.cash,
  dateTime: DateTime(
    kGoldenNow.year,
    kGoldenNow.month,
    kGoldenNow.day,
    kGoldenNow.hour,
    minuteOfDay,
  ),
);

final List<Debt> demoDebts = [
  Debt(
    id: 'd1',
    personName: 'Maria Simbine',
    amountCents: 150000,
    dueDate: kGoldenNow,
    isCustomerDebt: true,
  ),
  Debt(
    id: 'd2',
    personName: 'João Macuácua',
    amountCents: 45000,
    dueDate: kGoldenNow,
    isCustomerDebt: true,
  ),
];

final List<FinancialTransaction> demoTransactions = [
  FinancialTransaction(
    id: 't1',
    description: 'Renda da loja',
    amountCents: 3500000,
    type: TransactionType.expense,
    category: 'Despesas',
    date: kGoldenNow,
  ),
  FinancialTransaction(
    id: 't2',
    description: 'Venda balcão',
    amountCents: 249000,
    type: TransactionType.income,
    category: 'Vendas',
    date: kGoldenNow,
  ),
];

List<Purchase> demoPurchases = const [];

/// ─── Fakes (mesmos contratos dos testes funcionais) ─────────────────────

class FakeGetProductsUseCase implements GetProductsUseCase {
  FakeGetProductsUseCase([List<Product>? products])
    : _products = products ?? demoProducts;

  final List<Product> _products;

  @override
  Future<List<Product>> call({required String storeId}) async => _products;
}

class FakeProcessSaleUseCase implements ProcessSaleUseCase {
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

class FakeSalesRepository implements ISaleRepository {
  FakeSalesRepository([List<Sale>? sales]) : _sales = sales ?? demoSales;

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
  Future<List<Sale>> getAll({required String storeId}) async =>
      List.unmodifiable(_sales);

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
}

class FakeFinanceRepository implements IFinancialTransactionRepository {
  FakeFinanceRepository([
    List<FinancialTransaction>? transactions,
  ]) : _transactions = transactions ?? demoTransactions;

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

class FakeGetPurchasesUseCase implements GetPurchasesUseCase {
  const FakeGetPurchasesUseCase();

  @override
  Future<List<Purchase>> call({required String storeId}) async => demoPurchases;
}

/// KPIs determinísticos (bypass do notifier real — o cálculo server/local
/// já é coberto pelos testes funcionais).
class FixedDashboardKpisNotifier extends DashboardKpisNotifier {
  @override
  Future<DashboardKpis> build() async => const DashboardKpis(
    totalSalesCents: 1245000,
    cashIncomeCents: 1000000,
    cashExpenseCents: 350000,
    pendingTotalCents: 195000,
    stockTotal: 121500,
  );
}

/// ─── Montagem das telas ─────────────────────────────────────────────────

/// ProviderScope com TODOS os overrides do dashboard (contexto de loja,
/// fakes e KPIs fixos). Reutilizável pelos goldens.
/// (`List<dynamic>` como nos testes funcionais — Override do Riverpod 3.)
List<dynamic> dashboardGoldenOverrides() {
  return [
    ...storeContextOverrides(),
    getProductsUseCaseProvider.overrideWithValue(FakeGetProductsUseCase()),
    salesRepositoryProvider.overrideWithValue(FakeSalesRepository()),
    getCashFlowUseCaseProvider.overrideWithValue(
      _FixedGetCashFlowUseCase(),
    ),
    getPendingDebtsUseCaseProvider.overrideWithValue(
      _FixedGetPendingDebtsUseCase(),
    ),
    getSettledDebtsUseCaseProvider.overrideWithValue(
      _FixedGetSettledDebtsUseCase(),
    ),
    getPurchasesUseCaseProvider.overrideWithValue(FakeGetPurchasesUseCase()),
    financeRepositoryProvider.overrideWithValue(FakeFinanceRepository()),
    dashboardKpisProvider.overrideWith(FixedDashboardKpisNotifier.new),
  ];
}

/// Dashboard pronto para golden — monta a tela real com os fakes.
Widget dashboardGoldenApp({ThemeData? theme}) {
  return ProviderScope(
    overrides: [...dashboardGoldenOverrides()],
    child: testApp(theme: theme, home: const DashboardScreen()),
  );
}

/// PDV (NewSaleSheet) pronto para golden — mesma tela real aberta pelo
/// FAB/aba de Vendas (fullscreen via showAppSheet em produção).
Widget newSaleGoldenApp({ThemeData? theme}) {
  return ProviderScope(
    overrides: [
      ...storeContextOverrides(),
      getProductsUseCaseProvider.overrideWithValue(FakeGetProductsUseCase()),
      processSaleUseCaseProvider.overrideWithValue(FakeProcessSaleUseCase()),
      salesRepositoryProvider.overrideWithValue(FakeSalesRepository()),
    ],
    child: testApp(theme: theme, home: Scaffold(body: NewSaleSheet())),
  );
}

/// ─── Fakes de leitura fixa (KPIs) ───────────────────────────────────────

class _FixedGetCashFlowUseCase implements GetCashFlowUseCase {
  const _FixedGetCashFlowUseCase();

  @override
  final ICashFlowRepository? serverRepository = null;

  @override
  Future<CashFlow> call({
    required String storeId,
    required DateTime start,
    required DateTime end,
  }) async => const CashFlow(incomeCents: 1000000, expenseCents: 350000);
}

class _FixedGetPendingDebtsUseCase implements GetPendingDebtsUseCase {
  const _FixedGetPendingDebtsUseCase();

  @override
  Future<List<Debt>> call({required String storeId}) async => demoDebts;
}

class _FixedGetSettledDebtsUseCase implements GetSettledDebtsUseCase {
  const _FixedGetSettledDebtsUseCase();

  @override
  Future<List<Debt>> call({required String storeId}) async => const [];
}
