import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/domain/entities/product.dart';
import 'package:tareqo/domain/entities/sale.dart';
import 'package:tareqo/domain/entities/sale_lot_consumption.dart';
import 'package:tareqo/domain/entities/sale_item.dart';
import 'package:tareqo/domain/repositories/i_product_repository.dart';
import 'package:tareqo/domain/repositories/i_sale_repository.dart';
import 'package:tareqo/domain/repositories/i_sales_report_repository.dart';
import 'package:tareqo/domain/usecases/get_sales_report_use_case.dart';

class _FakeSaleRepository implements ISaleRepository {
  _FakeSaleRepository(this._sales);

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
  Future<List<Sale>> getAll({required String storeId}) async =>
      List.unmodifiable(_sales);
}

/// Fake do repositório de agregação server-side (H2) — simula a RPC.
class _FakeSalesReportRepository implements ISalesReportRepository {
  _FakeSalesReportRepository(this._handler);

  final SalesReport Function(String storeId, DateTime start, DateTime end)
  _handler;

  @override
  Future<SalesReport> fetchSalesReport({
    required String storeId,
    required DateTime start,
    required DateTime end,
  }) async => _handler(storeId, start, end);
}

class _FakeProductRepository implements IProductRepository {
  _FakeProductRepository(this._products);

  final List<Product> _products;

  @override
  Future<List<Product>> getAll({required String storeId}) async =>
      List.unmodifiable(_products);

  @override
  Future<Product?> getById(String id, {required String storeId}) async => null;

  @override
  Future<void> add(Product product) async {}

  @override
  Future<void> update(Product product) async {}

  @override
  Future<void> updateStock(
    String id,
    int newQuantity, {
    required String storeId,
  }) async {}
}

void main() {
  test('calcula faturamento, lucro, mais vendidos e vendas por dia', () async {
    final sales = [
      Sale(
        id: 's1',
        items: const [
          SaleItem(
            productId: 'p1',
            productName: 'Caneta',
            quantity: 2000, // 2 unidades em MILÉSIMOS (W11)
            unitPriceCents: 300, // custo atual 1.0 → lucro 2.0 por unidade
          ),
        ],
        totalAmountCents: 600,
        paymentMethod: PaymentMethod.mPesa,
        dateTime: DateTime(2026, 8, 3, 9),
      ),
      Sale(
        id: 's2',
        items: const [
          SaleItem(
            productId: 'p1',
            productName: 'Caneta',
            quantity: 1000,
            unitPriceCents: 300,
          ),
          SaleItem(
            productId: 'p2',
            productName: 'Caderno',
            quantity: 1000,
            unitPriceCents: 1000, // custo atual 5.0 → lucro 5.0
          ),
        ],
        totalAmountCents: 1300,
        paymentMethod: PaymentMethod.cash,
        dateTime: DateTime(2026, 8, 4, 15),
      ),
      // Fora do período — deve ser ignorada.
      Sale(
        id: 's3',
        items: const [
          SaleItem(
            productId: 'p1',
            productName: 'Caneta',
            quantity: 10000,
            unitPriceCents: 300,
          ),
        ],
        totalAmountCents: 3000,
        paymentMethod: PaymentMethod.cash,
        dateTime: DateTime(2025, 1, 1),
      ),
    ];

    const products = [
      Product(
        id: 'p1',
        name: 'Caneta',
        purchasePriceCents: 100,
        salePriceCents: 300,
      ),
      Product(
        id: 'p2',
        name: 'Caderno',
        purchasePriceCents: 500,
        salePriceCents: 1000,
      ),
    ];

    final useCase = GetSalesReportUseCase(
      _FakeSaleRepository(sales),
      _FakeProductRepository(products),
    );

    final report = await useCase(
      storeId: 'st1',
      start: DateTime(2026, 8, 1),
      end: DateTime(2026, 8, 31),
    );

    expect(report.totalRevenueCents, 1900); // 6.0 + 13.0
    // Lucro: caneta 2×2 + 1×2 + caderno 1×5 = 4 + 2 + 5 = 11.
    expect(report.totalProfitCents, 1100);
    expect(report.margin, closeTo(11.0 / 19.0 * 100, 0.001));

    // Mais vendidos: p1 (3 un.) à frente de p2 (1 un.).
    expect(report.bestSellers, hasLength(2));
    expect(report.bestSellers.first.productId, 'p1');
    // W11: quantidade em MILÉSIMOS (3 unidades = 3000).
    expect(report.bestSellers.first.quantity, 3000);
    expect(report.bestSellers.first.revenueCents, 900);

    // Vendas por dia: 03/08 (6.0) e 04/08 (13.0).
    expect(report.perDay, hasLength(2));
    expect(report.perDay.first.totalCents, 600);
    expect(report.perDay.last.totalCents, 1300);
  });

  test('delega para o repositório server-side quando fornecido (H2)', () async {
    // Fake do ISalesReportRepository: simula a RPC get_sales_report.
    final serverCalls = <String>[];
    final useCase = GetSalesReportUseCase(
      _FakeSaleRepository(const []),
      _FakeProductRepository(const []),
      serverRepository: _FakeSalesReportRepository((storeId, start, end) {
        serverCalls.add(storeId);
        return const SalesReport(
          totalRevenueCents: 9000,
          totalProfitCents: 3000,
          bestSellers: [],
          perDay: [],
        );
      }),
    );

    final report = await useCase(
      storeId: 'st1',
      start: DateTime(2026, 8, 1),
      end: DateTime(2026, 8, 31),
    );

    // Uma única chamada ao servidor; nenhum cálculo local.
    expect(serverCalls, ['st1']);
    expect(report.totalRevenueCents, 9000);
    expect(report.totalProfitCents, 3000);
  });

  test('margem é 0 quando não há faturamento', () async {
    final useCase = GetSalesReportUseCase(
      _FakeSaleRepository(const []),
      _FakeProductRepository(const []),
    );

    final report = await useCase(
      storeId: 'st1',
      start: DateTime(2026, 8, 1),
      end: DateTime(2026, 8, 31),
    );

    expect(report.totalRevenueCents, 0);
    expect(report.totalProfitCents, 0);
    expect(report.margin, 0);
    expect(report.bestSellers, isEmpty);
    expect(report.perDay, isEmpty);
  });

  test('produto fora do catálogo tem custo 0 (lucro superestimado)', () async {
    final useCase = GetSalesReportUseCase(
      _FakeSaleRepository([
        Sale(
          id: 's1',
          items: const [
            SaleItem(
              productId: 'antigo',
              productName: 'Produto antigo',
              quantity: 1000,
              unitPriceCents: 1000,
            ),
          ],
          totalAmountCents: 1000,
          paymentMethod: PaymentMethod.mPesa,
          dateTime: DateTime(2026, 8, 3),
        ),
      ]),
      _FakeProductRepository(const []),
    );

    final report = await useCase(
      storeId: 'st1',
      start: DateTime(2026, 8, 1),
      end: DateTime(2026, 8, 31),
    );

    expect(report.totalProfitCents, 1000);
    expect(report.bestSellers.first.productName, 'Produto antigo');
  });

  test('acúmulo exato em centavos (regressão auditoria H1)', () async {
    // 3 vendas de 9.9 → double soma 29.700000000000003; o relatório deve
    // arredondar cada fronteira e devolver 29.7 exato em faturamento,
    // vendas por dia e receita por produto.
    final sales = [
      for (var i = 0; i < 3; i++)
        Sale(
          id: 's$i',
          items: const [
            SaleItem(
              productId: 'p1',
              productName: 'Caneta',
              quantity: 1000,
              unitPriceCents: 990,
            ),
          ],
          totalAmountCents: 990,
          paymentMethod: PaymentMethod.mPesa,
          dateTime: DateTime(2026, 8, 3),
        ),
    ];

    final report = await GetSalesReportUseCase(
      _FakeSaleRepository(sales),
      _FakeProductRepository(const [
        Product(
          id: 'p1',
          name: 'Caneta',
          purchasePriceCents: 500,
          salePriceCents: 990,
        ),
      ]),
    )(storeId: 'st1', start: DateTime(2026, 8, 1), end: DateTime(2026, 8, 31));

    expect(report.totalRevenueCents, 2970);
    expect(report.totalProfitCents, closeTo(1470, 0.0000001)); // 3 × 4.9
    expect(report.perDay.first.totalCents, 2970);
    expect(report.bestSellers.first.revenueCents, 2970);
  });

  test(
    'venda ANULADA sai do relatório (faturamento, lucro, top e por dia)',
    () async {
      // (Lista NÃO-const: `cancelledAt` usa DateTime — sem construtor const.)
      final sales = [
        // Ativa — entra no relatório.
        Sale(
          id: 's1',
          items: [
            const SaleItem(
              productId: 'p1',
              productName: 'Caneta',
              quantity: 1000,
              unitPriceCents: 300,
            ),
          ],
          totalAmountCents: 300,
          paymentMethod: PaymentMethod.cash,
          dateTime: DateTime(2026, 8, 3, 10),
        ),
        // Anulada — NÃO deve contar (mesmo critério da RPC get_sales_report).
        Sale(
          id: 's2',
          items: [
            const SaleItem(
              productId: 'p1',
              productName: 'Caneta',
              quantity: 1000,
              unitPriceCents: 300,
            ),
          ],
          totalAmountCents: 300,
          paymentMethod: PaymentMethod.mPesa,
          dateTime: DateTime(2026, 8, 3, 11),
          status: SaleStatus.cancelled,
          cancelledAt: DateTime(2026, 8, 3, 12),
        ),
      ];

      const products = [
        Product(
          id: 'p1',
          name: 'Caneta',
          purchasePriceCents: 100,
          salePriceCents: 300,
        ),
      ];

      final report =
          await GetSalesReportUseCase(
            _FakeSaleRepository(sales),
            _FakeProductRepository(products),
          )(
            storeId: 'st1',
            start: DateTime(2026, 8, 1),
            end: DateTime(2026, 8, 31),
          );

      expect(report.totalRevenueCents, 300); // só a ativa (3.0)
      expect(report.totalProfitCents, 200);
      expect(report.bestSellers, hasLength(1));
      expect(report.bestSellers.first.quantity, 1000);
      expect(report.perDay, hasLength(1));
      expect(report.perDay.first.totalCents, 300);
    },
  );
}
