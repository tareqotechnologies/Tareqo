import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'store_context.dart';
import 'test_app.dart';

import 'package:tareqo/domain/entities/customer.dart';
import 'package:tareqo/domain/entities/debt.dart';
import 'package:tareqo/domain/entities/cash_closing.dart';
import 'package:tareqo/domain/entities/financial_transaction.dart';
import 'package:tareqo/domain/entities/product.dart';
import 'package:tareqo/domain/entities/purchase.dart';
import 'package:tareqo/domain/entities/sale.dart';
import 'package:tareqo/domain/entities/sale_item.dart';
import 'package:tareqo/domain/entities/sale_lot_consumption.dart';
import 'package:tareqo/domain/repositories/i_cash_closing_processor.dart';
import 'package:tareqo/domain/repositories/i_cash_closing_summary_repository.dart';
import 'package:tareqo/domain/repositories/i_cash_flow_repository.dart';
import 'package:tareqo/domain/repositories/i_customer_repository.dart';
import 'package:tareqo/domain/repositories/i_debt_processor.dart';
import 'package:tareqo/domain/repositories/i_financial_transaction_repository.dart';
import 'package:tareqo/domain/repositories/i_product_repository.dart';
import 'package:tareqo/domain/repositories/i_purchase_processor.dart';
import 'package:tareqo/domain/repositories/i_sale_processor.dart';
import 'package:tareqo/domain/repositories/i_sale_repository.dart';
import 'package:tareqo/domain/repositories/i_unit_of_work.dart';
import 'package:tareqo/domain/usecases/add_customer_use_case.dart';
import 'package:tareqo/domain/usecases/add_product_use_case.dart';
import 'package:tareqo/domain/usecases/add_purchase_use_case.dart';
import 'package:tareqo/domain/usecases/close_cash_register_use_case.dart';
import 'package:tareqo/domain/usecases/delete_customer_use_case.dart';
import 'package:tareqo/domain/usecases/fifo_stock_use_case.dart';
import 'package:tareqo/domain/usecases/get_cash_closing_summary_use_case.dart';
import 'package:tareqo/domain/usecases/get_cash_flow_use_case.dart';
import 'package:tareqo/domain/usecases/get_customers_use_case.dart';
import 'package:tareqo/domain/usecases/get_dashboard_kpis_use_case.dart';
import 'package:tareqo/domain/usecases/get_pending_debts_use_case.dart';
import 'package:tareqo/domain/usecases/get_settled_debts_use_case.dart';
import 'package:tareqo/domain/usecases/get_purchases_use_case.dart';
import 'package:tareqo/domain/usecases/get_products_use_case.dart';
import 'package:tareqo/domain/usecases/mark_transaction_as_paid_use_case.dart';
import 'package:tareqo/domain/usecases/process_sale_use_case.dart';
import 'package:tareqo/domain/usecases/settle_debt_use_case.dart';
import 'package:tareqo/domain/usecases/update_product_stock_use_case.dart';
import 'package:tareqo/domain/usecases/update_product_use_case.dart';
import 'package:tareqo/domain/usecases/update_customer_use_case.dart';
import 'package:tareqo/presentation/controllers/customers_providers.dart';
import 'package:tareqo/presentation/controllers/dashboard_providers.dart';
import 'package:tareqo/presentation/controllers/debts_providers.dart';
import 'package:tareqo/presentation/controllers/finance_providers.dart';
import 'package:tareqo/presentation/controllers/products_providers.dart';
import 'package:tareqo/presentation/controllers/purchases_providers.dart';
import 'package:tareqo/presentation/controllers/sales_providers.dart';
import 'package:tareqo/presentation/screens/credit/debts_screen.dart';
import 'package:tareqo/presentation/screens/customers/customers_screen.dart';
import 'package:tareqo/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:tareqo/presentation/screens/financial/financial_screen.dart';
import 'package:tareqo/presentation/screens/products/product_list_screen.dart';
import 'package:tareqo/presentation/screens/purchases/add_purchase_sheet.dart';
import 'package:tareqo/presentation/screens/sales/new_sale_sheet.dart';
import 'package:tareqo/presentation/screens/sales/sales_screen.dart';
import 'fake_stock_lot_repository.dart';

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

Sale _sale({
  required int number,
  required int totalCents,
  required int minuteOfDay,
}) => Sale(
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

/// Clientes demo — cadastro real de comércio (pt-MZ).
final List<Customer> demoCustomers = [
  const Customer(
    id: 'c1',
    name: 'Ana Costa',
    phone: '841234567',
    email: 'ana.costa@example.com',
  ),
  const Customer(id: 'c2', name: 'Ernesto Nhamirre', phone: '847654321'),
  const Customer(id: 'c3', name: 'Lurdes Chissano', phone: '861122334'),
];

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

/// Compra sem efeito — o golden é leitura e nunca confirma o carrinho.
class FakeProcessPurchaseUseCase implements ProcessPurchaseUseCase {
  const FakeProcessPurchaseUseCase();

  @override
  IPurchaseAtomicProcessor? get processor => null;

  @override
  Future<void> call(Purchase purchase) async {}
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
  FakeFinanceRepository([List<FinancialTransaction>? transactions])
    : _transactions = transactions ?? demoTransactions;

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
      const _FixedGetCashFlowUseCase(),
    ),
    getPendingDebtsUseCaseProvider.overrideWithValue(
      const _FixedGetPendingDebtsUseCase(),
    ),
    getSettledDebtsUseCaseProvider.overrideWithValue(
      const _FixedGetSettledDebtsUseCase(),
    ),
    getPurchasesUseCaseProvider.overrideWithValue(
      const FakeGetPurchasesUseCase(),
    ),
    financeRepositoryProvider.overrideWithValue(FakeFinanceRepository()),
    dashboardKpisProvider.overrideWith(FixedDashboardKpisNotifier.new),
  ];
}

/// Dashboard pronto para golden — monta a tela real com os fakes.
/// [locale] permite exercitar traduções (ex.: teste de overflow em fr).
Widget dashboardGoldenApp({ThemeData? theme, Locale? locale}) {
  return ProviderScope(
    overrides: [...dashboardGoldenOverrides()],
    child: testApp(
      theme: theme,
      locale: locale ?? const Locale('pt'),
      home: const DashboardScreen(),
    ),
  );
}

/// PDV (NewSaleSheet) pronto para golden — mesma tela real aberta pelo
/// FAB/aba de Vendas (fullscreen via showAppSheet em produção).
/// [locale] permite exercitar traduções (ex.: teste de overflow em fr).
Widget newSaleGoldenApp({ThemeData? theme, Locale? locale}) {
  return ProviderScope(
    overrides: [
      ...storeContextOverrides(),
      getProductsUseCaseProvider.overrideWithValue(FakeGetProductsUseCase()),
      processSaleUseCaseProvider.overrideWithValue(FakeProcessSaleUseCase()),
      salesRepositoryProvider.overrideWithValue(FakeSalesRepository()),
    ],
    child: testApp(
      theme: theme,
      locale: locale ?? const Locale('pt'),
      home: const Scaffold(body: NewSaleSheet()),
    ),
  );
}

/// Carrinho de NOVA COMPRA (AddPurchaseSheet) pronto para golden — mesma
/// tela real aberta pelo FAB de Compras (mais um sheet de tela cheia).
/// [locale] permite exercitar traduções (ex.: teste de overflow em fr).
Widget addPurchaseGoldenApp({ThemeData? theme, Locale? locale}) {
  return ProviderScope(
    overrides: [
      ...storeContextOverrides(),
      getProductsUseCaseProvider.overrideWithValue(FakeGetProductsUseCase()),
      processPurchaseUseCaseProvider.overrideWithValue(
        const FakeProcessPurchaseUseCase(),
      ),
    ],
    child: testApp(
      theme: theme,
      locale: locale ?? const Locale('pt'),
      home: const Scaffold(body: AddPurchaseSheet()),
    ),
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
  const _FixedGetSettledDebtsUseCase([this.debts = const []]);

  final List<Debt> debts;

  @override
  Future<List<Debt>> call({required String storeId}) async => debts;
}

/// ─── Telas de comércio (Fase 2.3 — baseline golden) ───────────────────

/// Repositório de clientes em memória (espelho do fake dos testes
/// funcionais, sem contadores — golden é leitura).
class FakeCustomerRepository implements ICustomerRepository {
  FakeCustomerRepository([List<Customer>? customers])
    : _customers = customers ?? demoCustomers;

  final List<Customer> _customers;

  @override
  Future<List<Customer>> getAll({required String storeId}) async => _customers;

  @override
  Future<Customer> add(Customer customer) async => customer;

  @override
  Future<Customer> update(Customer customer) async => customer;

  @override
  Future<void> delete(String customerId) async {
    _customers.removeWhere((c) => c.id == customerId);
  }
}

/// Repositório de produtos em memória — o [ProductListScreen] exige use
/// cases REAIS de cadastro (Add/Update sobre repositório + UnitOfWork).
class FakeProductRepository implements IProductRepository {
  FakeProductRepository([List<Product>? products])
    : _products = products ?? demoProducts;

  final List<Product> _products;

  @override
  Future<Product?> getById(String id, {required String storeId}) async {
    for (final p in _products) {
      if (p.id == id && p.storeId == storeId) return p;
    }
    return null;
  }

  @override
  Future<void> add(Product product) async => _products.add(product);

  @override
  Future<void> update(Product product) async {
    final idx = _products.indexWhere(
      (p) => p.id == product.id && p.storeId == product.storeId,
    );
    if (idx >= 0) _products[idx] = product;
  }

  @override
  Future<void> updateStock(
    String id,
    int newQuantity, {
    required String storeId,
  }) async {
    final idx = _products.indexWhere((p) => p.id == id && p.storeId == storeId);
    if (idx >= 0) {
      _products[idx] = _products[idx].copyWith(stockQuantity: newQuantity);
    }
  }

  @override
  Future<List<Product>> getAll({required String storeId}) async =>
      _products.where((p) => p.storeId == storeId).toList();
}

/// UnitOfWork direta (sem transação real) — mesma dos testes funcionais.
class FakeDirectUnitOfWork implements IUnitOfWork {
  const FakeDirectUnitOfWork();

  @override
  Future<T> run<T>(Future<T> Function() action) => action();
}

List<dynamic> productGoldenOverrides() {
  final repository = FakeProductRepository();
  return [
    ...storeContextOverrides(),
    getProductsUseCaseProvider.overrideWithValue(FakeGetProductsUseCase()),
    addProductUseCaseProvider.overrideWithValue(
      AddProductUseCase(
        repository,
        FakeStockLotRepository(),
        const FakeDirectUnitOfWork(),
      ),
    ),
    updateProductUseCaseProvider.overrideWithValue(
      UpdateProductUseCase(
        repository,
        FifoStockUseCase(
          FakeStockLotRepository(),
          UpdateProductStockUseCase(repository),
        ),
        const FakeDirectUnitOfWork(),
      ),
    ),
  ];
}

Widget productGoldenApp({ThemeData? theme, Locale? locale}) {
  return ProviderScope(
    overrides: [...productGoldenOverrides()],
    child: testApp(
      theme: theme,
      locale: locale ?? const Locale('pt'),
      home: const ProductListScreen(),
    ),
  );
}

Widget salesGoldenApp({ThemeData? theme, Locale? locale}) {
  return ProviderScope(
    overrides: [
      ...storeContextOverrides(),
      salesRepositoryProvider.overrideWithValue(FakeSalesRepository()),
    ],
    child: testApp(
      theme: theme,
      locale: locale ?? const Locale('pt'),
      home: const SalesScreen(),
    ),
  );
}

Widget customersGoldenApp({ThemeData? theme, Locale? locale}) {
  final repository = FakeCustomerRepository();
  return ProviderScope(
    overrides: [
      ...storeContextOverrides(),
      getCustomersUseCaseProvider.overrideWithValue(
        GetCustomersUseCase(repository),
      ),
      addCustomerUseCaseProvider.overrideWithValue(
        AddCustomerUseCase(repository),
      ),
      updateCustomerUseCaseProvider.overrideWithValue(
        UpdateCustomerUseCase(repository),
      ),
      deleteCustomerUseCaseProvider.overrideWithValue(
        DeleteCustomerUseCase(repository),
      ),
      getPendingDebtsUseCaseProvider.overrideWithValue(
        const _FixedGetPendingDebtsUseCase(),
      ),
    ],
    child: testApp(
      theme: theme,
      locale: locale ?? const Locale('pt'),
      home: const CustomersScreen(),
    ),
  );
}

/// Settle sem efeito (leitura — o golden nunca toca no botão).
class _FakeSettleDebt implements SettleDebtUseCase {
  const _FakeSettleDebt();

  @override
  IDebtAtomicProcessor? get processor => null;

  @override
  Future<void> call(String debtId, {required String storeId}) async {}
}

Widget debtsGoldenApp({
  ThemeData? theme,
  Locale? locale,
  List<Debt> settledDebts = const [],
}) {
  return ProviderScope(
    overrides: [
      ...storeContextOverrides(),
      getPendingDebtsUseCaseProvider.overrideWithValue(
        const _FixedGetPendingDebtsUseCase(),
      ),
      getSettledDebtsUseCaseProvider.overrideWithValue(
        _FixedGetSettledDebtsUseCase(settledDebts),
      ),
      settleDebtUseCaseProvider.overrideWithValue(const _FakeSettleDebt()),
    ],
    child: testApp(
      theme: theme,
      locale: locale ?? const Locale('pt'),
      home: const DebtsScreen(),
    ),
  );
}

class _GoldenGetCashFlowUseCase implements GetCashFlowUseCase {
  const _GoldenGetCashFlowUseCase();

  @override
  final ICashFlowRepository? serverRepository = null;

  @override
  Future<CashFlow> call({
    required String storeId,
    required DateTime start,
    required DateTime end,
  }) async => const CashFlow(incomeCents: 1249000, expenseCents: 350000);
}

class _GoldenMarkTransactionAsPaid implements MarkTransactionAsPaidUseCase {
  const _GoldenMarkTransactionAsPaid();

  @override
  Future<void> call(String transactionId, {required String storeId}) async {}
}

class _GoldenCashClosingSummary implements GetCashClosingSummaryUseCase {
  const _GoldenCashClosingSummary();

  @override
  ICashClosingSummaryRepository? get serverRepository => null;

  @override
  Future<CashClosingSummary> call({
    required String storeId,
    required DateTime day,
  }) async {
    return CashClosingSummary(
      day: DateTime(day.year, day.month, day.day),
      totalSalesCents: 4050,
      expectedCashCents: 1100,
      salesByMethodCents: const {'cash': 1100, 'mPesa': 2950},
    );
  }
}

class _GoldenCloseCashRegister implements CloseCashRegisterUseCase {
  const _GoldenCloseCashRegister();

  @override
  ICashClosingProcessor? get processor => null;

  @override
  Future<CashClosing> call({
    required String storeId,
    required DateTime day,
    required int countedCashCents,
  }) async => CashClosing(
    id: 'cc-$storeId',
    storeId: storeId,
    day: DateTime(day.year, day.month, day.day),
    totalSalesCents: 4050,
    expectedCashCents: 1100,
    countedCashCents: countedCashCents,
    salesByMethodCents: const {'cash': 1100, 'mPesa': 2950},
    closedAt: kGoldenNow,
  );
}

Widget financialGoldenApp({ThemeData? theme, Locale? locale}) {
  return ProviderScope(
    overrides: [
      ...storeContextOverrides(),
      financeRepositoryProvider.overrideWithValue(FakeFinanceRepository()),
      getCashFlowUseCaseProvider.overrideWithValue(
        const _GoldenGetCashFlowUseCase(),
      ),
      markTransactionAsPaidUseCaseProvider.overrideWithValue(
        const _GoldenMarkTransactionAsPaid(),
      ),
      getCashClosingSummaryUseCaseProvider.overrideWithValue(
        const _GoldenCashClosingSummary(),
      ),
      closeCashRegisterUseCaseProvider.overrideWithValue(
        const _GoldenCloseCashRegister(),
      ),
    ],
    child: testApp(
      theme: theme,
      locale: locale ?? const Locale('pt'),
      home: const FinancialScreen(),
    ),
  );
}
