import 'package:flutter_test/flutter_test.dart';

import 'package:dumbhanengue/core/utils/formatters.dart';
import 'package:dumbhanengue/domain/entities/financial_transaction.dart';
import 'package:dumbhanengue/domain/entities/product.dart';
import 'package:dumbhanengue/domain/entities/sale.dart';
import 'package:dumbhanengue/domain/entities/sale_item.dart';
import 'package:dumbhanengue/domain/repositories/i_financial_transaction_repository.dart';
import 'package:dumbhanengue/domain/repositories/i_product_repository.dart';
import 'package:dumbhanengue/domain/repositories/i_sale_processor.dart';
import 'package:dumbhanengue/domain/repositories/i_sale_repository.dart';
import 'package:dumbhanengue/domain/repositories/i_unit_of_work.dart';
import 'package:dumbhanengue/domain/usecases/process_sale_use_case.dart';
import 'package:dumbhanengue/domain/usecases/update_product_stock_use_case.dart';

/// Fake do repositório de vendas.
class _FakeSaleRepository implements ISaleRepository {
  final List<Sale> sales = [];
  bool registerCalled = false;

  @override
  Future<void> registerSale(Sale sale) async {
    registerCalled = true;
    sales.add(sale);
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

Product _product(String id, {int stock = 10}) => Product(
      id: id,
      name: 'Produto $id',
      purchasePrice: 5.0,
      salePrice: 9.9,
      stockQuantity: stock,
    );

Sale _sale(List<SaleItem> items, {double? totalAmount}) => Sale(
      id: 'VENDA-1',
      items: items,
      // Total consistente com os itens (quantidade × preço unitário).
      totalAmount: totalAmount ??
          items.fold(
            0.0,
            (sum, item) => sum + item.quantity * item.unitPrice,
          ),
      paymentMethod: PaymentMethod.pix,
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
  _FakeTransactionRepository transactionRepository,
) {
  return ProcessSaleUseCase(
    saleRepository,
    UpdateProductStockUseCase(productRepository),
    transactionRepository,
    const _DirectUnitOfWork(),
  );
}

void main() {
  late _FakeSaleRepository saleRepository;
  late _FakeProductRepository productRepository;
  late _FakeTransactionRepository transactionRepository;

  setUp(() {
    saleRepository = _FakeSaleRepository();
    productRepository = _FakeProductRepository();
    transactionRepository = _FakeTransactionRepository();
  });

  test('registra a venda, baixa o estoque e lança a entrada no caixa',
      () async {
    productRepository
      ..add(_product('1', stock: 10))
      ..add(_product('2', stock: 5));
    final useCase =
        _buildUseCase(saleRepository, productRepository, transactionRepository);

    await useCase(_sale(const [
      SaleItem(
          productId: '1', productName: 'Produto 1', quantity: 2, unitPrice: 9.9),
      SaleItem(
          productId: '2', productName: 'Produto 2', quantity: 1, unitPrice: 9.9),
    ]));

    expect(saleRepository.registerCalled, isTrue);
    expect(saleRepository.sales, hasLength(1));
    expect(productRepository.products['1']!.stockQuantity, 8); // 10 - 2
    expect(productRepository.products['2']!.stockQuantity, 4); // 5 - 1
    expect(productRepository.updateStockCalls, 2);

    // Entrada no caixa: valor exato da venda, categoria Vendas, paga.
    expect(transactionRepository.transactions, hasLength(1));
    final entry = transactionRepository.transactions.first;
    // closeTo: tolerância para precisão de ponto flutuante (2 × 9.9 + 9.9).
    expect(entry.amount, closeTo(29.7, 0.0001));
    expect(entry.type, TransactionType.income);
    expect(entry.status, TransactionStatus.paid);
    expect(entry.category, 'Vendas');
    expect(entry.description, contains('Pix'));
  });

  test('lança InsufficientStockException e NÃO registra a venda', () async {
    productRepository.add(_product('1', stock: 1));
    final useCase =
        _buildUseCase(saleRepository, productRepository, transactionRepository);

    await expectLater(
      useCase(_sale(const [
        SaleItem(
            productId: '1', productName: 'Produto 1', quantity: 5, unitPrice: 9.9),
      ])),
      throwsA(
        isA<InsufficientStockException>()
            .having((e) => e.productId, 'productId', '1')
            .having((e) => e.available, 'available', 1)
            .having((e) => e.requested, 'requested', 5),
      ),
    );

    // Integridade: a venda não foi persistida, o estoque não mudou e não
    // houve entrada no caixa.
    expect(saleRepository.registerCalled, isFalse);
    expect(saleRepository.sales, isEmpty);
    expect(productRepository.products['1']!.stockQuantity, 1);
    expect(productRepository.updateStockCalls, 0);
    expect(transactionRepository.transactions, isEmpty);
  });

  test('lança ProductNotFoundException quando o produto não existe', () async {
    // Nenhum produto cadastrado.
    final useCase =
        _buildUseCase(saleRepository, productRepository, transactionRepository);

    await expectLater(
      useCase(_sale(const [
        SaleItem(
            productId: 'X', productName: 'Fantasma', quantity: 1, unitPrice: 9.9),
      ])),
      throwsA(isA<ProductNotFoundException>()),
    );

    expect(saleRepository.registerCalled, isFalse);
    expect(transactionRepository.transactions, isEmpty);
  });

  test('rejeita venda sem itens e NÃO persiste nada', () async {
    productRepository.add(_product('1'));
    final useCase =
        _buildUseCase(saleRepository, productRepository, transactionRepository);

    await expectLater(
      useCase(_sale(const [])),
      throwsA(isA<InvalidSaleException>()),
    );

    expect(saleRepository.registerCalled, isFalse);
    expect(productRepository.updateStockCalls, 0);
    expect(transactionRepository.transactions, isEmpty);
  });

  test('rejeita venda com total divergente dos itens', () async {
    productRepository.add(_product('1', stock: 10));
    final useCase =
        _buildUseCase(saleRepository, productRepository, transactionRepository);

    // Itens somam 9.9, mas o total informado é 99.0 — inconsistente.
    await expectLater(
      useCase(_sale(const [
        SaleItem(
            productId: '1', productName: 'Produto 1', quantity: 1, unitPrice: 9.9),
      ], totalAmount: 99.0)),
      throwsA(isA<InvalidSaleException>()),
    );

    expect(saleRepository.registerCalled, isFalse);
    expect(productRepository.updateStockCalls, 0);
    expect(transactionRepository.transactions, isEmpty);
  });

  test('validação falha antes de abrir a transação (nada é persistido)',
      () async {
    productRepository.add(_product('1'));
    final useCase =
        _buildUseCase(saleRepository, productRepository, transactionRepository);

    await expectLater(
      useCase(_sale(const [
        SaleItem(
            productId: '1', productName: 'Produto 1', quantity: 1, unitPrice: 9.9),
      ], totalAmount: 99.0)),
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

    productRepository.add(_product('1', stock: 10));
    final useCase =
        _buildUseCase(saleRepository, productRepository, transactionRepository);

    await useCase(_sale(const [
      SaleItem(
          productId: '1',
          productName: 'Produto 1',
          quantity: 1,
          unitPrice: 9.9),
    ]));

    final entry = transactionRepository.transactions.first;
    expect(entry.description, 'Sale — Pix');
    expect(entry.category, 'Sales');
  });

  test('delega para o processador atômico quando fornecido (Supabase)',
      () async {
    final processor = _FakeSaleProcessor();
    final useCase = ProcessSaleUseCase(
      saleRepository,
      UpdateProductStockUseCase(productRepository),
      transactionRepository,
      const _DirectUnitOfWork(),
      processor: processor,
    );

    final sale = _sale(const [
      SaleItem(
          productId: '1', productName: 'Produto 1', quantity: 1, unitPrice: 9.9),
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
      UpdateProductStockUseCase(productRepository),
      transactionRepository,
      const _DirectUnitOfWork(),
      processor: processor,
    );

    // Total divergente → inválido antes de qualquer chamada ao servidor.
    await expectLater(
      useCase(_sale(const [
        SaleItem(
            productId: '1', productName: 'Produto 1', quantity: 1, unitPrice: 9.9),
      ], totalAmount: 99.0)),
      throwsA(isA<InvalidSaleException>()),
    );
    expect(processor.calls, 0);
  });
}
