import 'package:flutter_test/flutter_test.dart';

import 'package:dumbhanengue/core/utils/formatters.dart';
import 'package:dumbhanengue/core/utils/quantity.dart';
import 'package:dumbhanengue/domain/entities/financial_transaction.dart';
import 'package:dumbhanengue/domain/entities/product.dart';
import 'package:dumbhanengue/domain/entities/sale.dart';
import 'package:dumbhanengue/domain/entities/sale_lot_consumption.dart';
import 'package:dumbhanengue/domain/entities/sale_item.dart';
import 'package:dumbhanengue/domain/entities/stock_lot.dart';
import 'package:dumbhanengue/domain/repositories/i_financial_transaction_repository.dart';
import 'package:dumbhanengue/domain/repositories/i_product_repository.dart';
import 'package:dumbhanengue/domain/repositories/i_sale_processor.dart';
import 'package:dumbhanengue/domain/repositories/i_sale_repository.dart';
import 'package:dumbhanengue/domain/repositories/i_unit_of_work.dart';
import 'package:dumbhanengue/domain/usecases/fifo_stock_use_case.dart';
import 'package:dumbhanengue/domain/usecases/process_sale_use_case.dart';
import 'package:dumbhanengue/domain/usecases/update_product_stock_use_case.dart';

import '../../helpers/fake_stock_lot_repository.dart';

/// Fake do repositório de vendas.
class _FakeSaleRepository implements ISaleRepository {
  final List<Sale> sales = [];
  bool registerCalled = false;
  final List<LotConsumption> registeredConsumption = [];

  @override
  Future<void> registerSale(Sale sale) async {
    registerCalled = true;
    sales.add(sale);
  }

  @override
  Future<Sale?> getById(String id, {required String storeId}) async {
    for (final sale in sales) {
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
  ) async {
    registeredConsumption.addAll(consumption);
  }

  @override
  Future<List<Sale>> getAll({required String storeId}) async =>
      List.unmodifiable(sales);
}

/// Fake do repositório de produtos, com estoque controlado.
class _FakeProductRepository implements IProductRepository {
  final Map<String, Product> products = {};
  int updateStockCalls = 0;

  @override
  Future<List<Product>> getAll({required String storeId}) async =>
      products.values.toList();

  @override
  Future<Product?> getById(String id, {required String storeId}) async =>
      products[id];

  @override
  Future<void> add(Product product) async {
    products[product.id] = product;
  }

  @override
  Future<void> update(Product product) async {
    final current = products[product.id]!;
    // Preserva o estoque (a mutação de quantidade passa pelo FIFO).
    products[product.id] = current.copyWith(
      name: product.name,
      description: product.description,
      purchasePriceCents: product.purchasePriceCents,
      salePriceCents: product.salePriceCents,
      code: product.code,
      vendaPorFracao: product.vendaPorFracao,
      unitLabel: product.unitLabel,
      isActive: product.isActive,
    );
  }

  @override
  Future<void> updateStock(
    String id,
    int newQuantity, {
    required String storeId,
  }) async {
    updateStockCalls++;
    products[id] = products[id]!.copyWith(stockQuantity: newQuantity);
  }
}

/// Fake do repositório financeiro — captura a entrada no caixa da venda.
class _FakeTransactionRepository implements IFinancialTransactionRepository {
  final List<FinancialTransaction> transactions = [];

  @override
  Future<List<FinancialTransaction>> getAll({required String storeId}) async =>
      List.unmodifiable(transactions);

  @override
  Future<List<FinancialTransaction>> getByPeriod({
    required String storeId,
    required DateTime start,
    required DateTime end,
  }) async =>
      List.unmodifiable(transactions);

  @override
  Future<void> add(FinancialTransaction transaction) async {
    transactions.add(transaction);
  }

  @override
  Future<void> markAsPaid(String id, {required String storeId}) async {
    final index = transactions.indexWhere((t) => t.id == id);
    transactions[index] =
        transactions[index].copyWith(status: TransactionStatus.paid);
  }
}

/// Estoque em UNIDADES (W11): convertido para MILÉSIMOS internamente.
Product _product(String id, {int stockUnits = 10}) => Product(
      id: id,
      name: 'Produto $id',
      purchasePriceCents: 500,
      salePriceCents: 990,
      stockQuantity: Quantity.fromUnits(stockUnits),
    );

/// Semeia o produto + o LOTE correspondente (a invariante W11 exige que
/// o estoque do produto esteja coberto por lotes — o FIFO consome lotes).
void _seedProductWithLot(
  _FakeProductRepository products,
  FakeStockLotRepository lots,
  String id, {
  int stockUnits = 10,
}) {
  products.add(_product(id, stockUnits: stockUnits));
  lots.add(
    StockLot(
      id: 'lot-$id',
      productId: id,
      entryDate: DateTime.utc(2026, 8, 1),
      expiryDate: null,
      initialQuantity: Quantity.fromUnits(stockUnits),
      currentQuantity: Quantity.fromUnits(stockUnits),
      costPriceCents: 500,
    ),
  );
}

Sale _sale(List<SaleItem> items, {int? totalAmountCents}) => Sale(
      id: 'VENDA-1',
      items: items,
      // Total consistente com os itens (W11: qtd milésimos × preço ~/ 1000).
      totalAmountCents: totalAmountCents ??
          items.fold<int>(
            0,
            (sum, item) =>
                sum + Quantity.lineTotal(item.quantity, item.unitPriceCents),
          ),
      paymentMethod: PaymentMethod.mPesa,
      dateTime: DateTime.utc(2026, 8, 3),
    );

/// Unit of work no-op para os fakes em memória (a atomicidade real é
/// coberta pelos testes de integração com SQLite).
class _DirectUnitOfWork implements IUnitOfWork {
  const _DirectUnitOfWork();

  @override
  Future<T> run<T>(Future<T> Function() action) => action();
}

/// Fake do processador atômico (Supabase via RPC) — conta as chamadas.
class _FakeSaleProcessor implements ISaleAtomicProcessor {
  int calls = 0;
  Sale? lastSale;

  @override
  Future<void> process(Sale sale) async {
    calls++;
    lastSale = sale;
  }
}

/// Monta o cenário com um [ProcessSaleUseCase] ligado aos fakes fornecidos.
ProcessSaleUseCase _buildUseCase(
  _FakeSaleRepository saleRepository,
  _FakeProductRepository productRepository,
  FakeStockLotRepository lotRepository,
  _FakeTransactionRepository transactionRepository,
) {
  return ProcessSaleUseCase(
    saleRepository,
    FifoStockUseCase(
      lotRepository,
      UpdateProductStockUseCase(productRepository),
    ),
    transactionRepository,
    const _DirectUnitOfWork(),
  );
}

void main() {
  late _FakeSaleRepository saleRepository;
  late _FakeProductRepository productRepository;
  late FakeStockLotRepository lotRepository;
  late _FakeTransactionRepository transactionRepository;

  setUp(() {
    saleRepository = _FakeSaleRepository();
    productRepository = _FakeProductRepository();
    lotRepository = FakeStockLotRepository();
    transactionRepository = _FakeTransactionRepository();
  });

  test('registra a venda, baixa o estoque em FIFO e lança a entrada no caixa',
      () async {
    _seedProductWithLot(productRepository, lotRepository, '1', stockUnits: 10);
    _seedProductWithLot(productRepository, lotRepository, '2', stockUnits: 5);
    final useCase = _buildUseCase(
      saleRepository,
      productRepository,
      lotRepository,
      transactionRepository,
    );

    await useCase(_sale(const [
      SaleItem(
          productId: '1', productName: 'Produto 1', quantity: 2000, unitPriceCents: 990),
      SaleItem(
          productId: '2', productName: 'Produto 2', quantity: 1000, unitPriceCents: 990),
    ]));

    expect(saleRepository.registerCalled, isTrue);
    expect(saleRepository.sales, hasLength(1));
    // W11: estoque em MILÉSIMOS (10 - 2 = 8 unidades = 8000 milésimos).
    expect(productRepository.products['1']!.stockQuantity, 8000);
    expect(productRepository.products['2']!.stockQuantity, 4000);
    expect(productRepository.updateStockCalls, 2);
    // Lotes zerados (baixa FIFO completa).
    final lots1 =
        await lotRepository.getActiveByProduct('1', storeId: 'st1');
    expect(lots1.first.currentQuantity, 8000);

    // Entrada no caixa: valor exato da venda, categoria Vendas, paga.
    expect(transactionRepository.transactions, hasLength(1));
    final entry = transactionRepository.transactions.first;
    // 2 × 9.90 + 9.90 = 29,70 → 2970 centavos (inteiro, exato).
    expect(entry.amountCents, 2970);
    expect(entry.type, TransactionType.income);
    expect(entry.status, TransactionStatus.paid);
    expect(entry.category, 'Vendas');
    expect(entry.description, contains('M-Pesa'));
  });

  test('lança InsufficientStockException e NÃO registra a venda', () async {
    _seedProductWithLot(productRepository, lotRepository, '1', stockUnits: 1);
    final useCase = _buildUseCase(
      saleRepository,
      productRepository,
      lotRepository,
      transactionRepository,
    );

    await expectLater(
      useCase(_sale(const [
        SaleItem(
            productId: '1', productName: 'Produto 1', quantity: 5000, unitPriceCents: 990),
      ])),
      throwsA(
        isA<InsufficientStockException>()
            .having((e) => e.productId, 'productId', '1')
            .having((e) => e.available, 'available', 1000)
            .having((e) => e.requested, 'requested', 5000),
      ),
    );

    // Integridade: a venda não foi persistida, o estoque não mudou e não
    // houve entrada no caixa.
    expect(saleRepository.registerCalled, isFalse);
    expect(saleRepository.sales, isEmpty);
    expect(productRepository.products['1']!.stockQuantity, 1000);
    expect(productRepository.updateStockCalls, 0);
    expect(transactionRepository.transactions, isEmpty);
  });

  test('lança InactiveProductException para produto DESATIVADO (nada muda)',
      () async {
    _seedProductWithLot(productRepository, lotRepository, '1', stockUnits: 10);
    productRepository.products['1'] =
        productRepository.products['1']!.copyWith(isActive: false);
    final useCase = _buildUseCase(
      saleRepository,
      productRepository,
      lotRepository,
      transactionRepository,
    );

    await expectLater(
      useCase(_sale(const [
        SaleItem(
            productId: '1',
            productName: 'Produto 1',
            quantity: 1000,
            unitPriceCents: 990),
      ])),
      throwsA(
        isA<InactiveProductException>()
            .having((e) => e.productId, 'productId', '1'),
      ),
    );

    // Integridade: nada foi persistido nem baixado.
    expect(saleRepository.registerCalled, isFalse);
    expect(productRepository.updateStockCalls, 0);
    expect(transactionRepository.transactions, isEmpty);
  });

  test('lança ProductNotFoundException quando o produto não existe', () async {
    // Nenhum produto cadastrado.
    final useCase = _buildUseCase(
      saleRepository,
      productRepository,
      lotRepository,
      transactionRepository,
    );

    await expectLater(
      useCase(_sale(const [
        SaleItem(
            productId: 'X', productName: 'Fantasma', quantity: 1000, unitPriceCents: 990),
      ])),
      throwsA(isA<ProductNotFoundException>()),
    );

    expect(saleRepository.registerCalled, isFalse);
    expect(transactionRepository.transactions, isEmpty);
  });

  test('rejeita venda sem itens e NÃO persiste nada', () async {
    _seedProductWithLot(productRepository, lotRepository, '1');
    final useCase = _buildUseCase(
      saleRepository,
      productRepository,
      lotRepository,
      transactionRepository,
    );

    await expectLater(
      useCase(_sale(const [])),
      throwsA(isA<InvalidSaleException>()),
    );

    expect(saleRepository.registerCalled, isFalse);
    expect(productRepository.updateStockCalls, 0);
    expect(transactionRepository.transactions, isEmpty);
  });

  test('rejeita venda com total divergente dos itens', () async {
    _seedProductWithLot(productRepository, lotRepository, '1');
    final useCase = _buildUseCase(
      saleRepository,
      productRepository,
      lotRepository,
      transactionRepository,
    );

    // Itens somam 9.9, mas o total informado é 99.0 — inconsistente.
    await expectLater(
      useCase(_sale(const [
        SaleItem(
            productId: '1', productName: 'Produto 1', quantity: 1000, unitPriceCents: 990),
      ], totalAmountCents: 9900)),
      throwsA(isA<InvalidSaleException>()),
    );

    expect(saleRepository.registerCalled, isFalse);
    expect(productRepository.updateStockCalls, 0);
    expect(transactionRepository.transactions, isEmpty);
  });

  test('validação falha antes de abrir a transação (nada é persistido)',
      () async {
    _seedProductWithLot(productRepository, lotRepository, '1');
    final useCase = _buildUseCase(
      saleRepository,
      productRepository,
      lotRepository,
      transactionRepository,
    );

    await expectLater(
      useCase(_sale(const [
        SaleItem(
            productId: '1', productName: 'Produto 1', quantity: 1000, unitPriceCents: 990),
      ], totalAmountCents: 9900)),
      throwsA(isA<InvalidSaleException>()),
    );

    expect(saleRepository.registerCalled, isFalse);
    expect(productRepository.updateStockCalls, 0);
    expect(transactionRepository.transactions, isEmpty);
  });

  test('grava descrição e categoria em inglês quando o idioma ativo é en',
      () async {
    Formatters.applySettings(currencyCode: 'USD', language: 'en');
    addTearDown(
      () => Formatters.applySettings(currencyCode: 'BRL', language: 'pt'),
    );

    _seedProductWithLot(productRepository, lotRepository, '1');
    final useCase = _buildUseCase(
      saleRepository,
      productRepository,
      lotRepository,
      transactionRepository,
    );

    await useCase(_sale(const [
      SaleItem(
          productId: '1',
          productName: 'Produto 1',
          quantity: 1000,
          unitPriceCents: 990),
    ]));

    final entry = transactionRepository.transactions.first;
    expect(entry.description, 'Sale — M-Pesa');
    expect(entry.category, 'Sales');
  });

  test('delega para o processador atômico quando fornecido (Supabase)',
      () async {
    final processor = _FakeSaleProcessor();
    final useCase = ProcessSaleUseCase(
      saleRepository,
      FifoStockUseCase(
        lotRepository,
        UpdateProductStockUseCase(productRepository),
      ),
      transactionRepository,
      const _DirectUnitOfWork(),
      processor: processor,
    );

    final sale = _sale(const [
      SaleItem(
          productId: '1', productName: 'Produto 1', quantity: 1000, unitPriceCents: 990),
    ]);
    await useCase(sale);

    // O caminho composto NÃO roda — a venda inteira é do servidor.
    expect(processor.calls, 1);
    expect(processor.lastSale?.id, sale.id);
    expect(saleRepository.registerCalled, isFalse);
    expect(productRepository.updateStockCalls, 0);
    expect(transactionRepository.transactions, isEmpty);
  });

  test('validação continua valendo com processador atômico', () async {
    final processor = _FakeSaleProcessor();
    final useCase = ProcessSaleUseCase(
      saleRepository,
      FifoStockUseCase(
        lotRepository,
        UpdateProductStockUseCase(productRepository),
      ),
      transactionRepository,
      const _DirectUnitOfWork(),
      processor: processor,
    );

    // Total divergente → inválido antes de qualquer chamada ao servidor.
    await expectLater(
      useCase(_sale(const [
        SaleItem(
            productId: '1', productName: 'Produto 1', quantity: 1000, unitPriceCents: 990),
      ], totalAmountCents: 9900)),
      throwsA(isA<InvalidSaleException>()),
    );
    expect(processor.calls, 0);
  });
}
