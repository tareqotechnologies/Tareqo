import 'package:flutter_test/flutter_test.dart';

import 'package:dumbhanengue/domain/entities/product.dart';
import 'package:dumbhanengue/domain/entities/sale.dart';
import 'package:dumbhanengue/domain/entities/sale_item.dart';
import 'package:dumbhanengue/domain/repositories/i_product_repository.dart';
import 'package:dumbhanengue/domain/repositories/i_sale_repository.dart';
import 'package:dumbhanengue/domain/usecases/get_sales_report_use_case.dart';

class _FakeSaleRepository implements ISaleRepository {
  _FakeSaleRepository(this._sales);

  final List<Sale> _sales;

  @override
  Future<void> registerSale(Sale sale) async {}

  @override
  Future<List<Sale>> getAll({required String storeId}) async =>
      List.unmodifiable(_sales);
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
            quantity: 2,
            unitPrice: 3.0, // custo atual 1.0 → lucro 2.0 por unidade
          ),
        ],
        totalAmount: 6.0,
        paymentMethod: PaymentMethod.pix,
        dateTime: DateTime(2026, 8, 3, 9),
      ),
      Sale(
        id: 's2',
        items: const [
          SaleItem(
            productId: 'p1',
            productName: 'Caneta',
            quantity: 1,
            unitPrice: 3.0,
          ),
          SaleItem(
            productId: 'p2',
            productName: 'Caderno',
            quantity: 1,
            unitPrice: 10.0, // custo atual 5.0 → lucro 5.0
          ),
        ],
        totalAmount: 13.0,
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
            quantity: 10,
            unitPrice: 3.0,
          ),
        ],
        totalAmount: 30.0,
        paymentMethod: PaymentMethod.cash,
        dateTime: DateTime(2025, 1, 1),
      ),
    ];

    const products = [
      Product(id: 'p1', name: 'Caneta', purchasePrice: 1.0, salePrice: 3.0),
      Product(id: 'p2', name: 'Caderno', purchasePrice: 5.0, salePrice: 10.0),
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

    expect(report.totalRevenue, 19.0); // 6.0 + 13.0
    // Lucro: caneta 2×2 + 1×2 + caderno 1×5 = 4 + 2 + 5 = 11.
    expect(report.totalProfit, 11.0);
    expect(report.margin, closeTo(11.0 / 19.0 * 100, 0.001));

    // Mais vendidos: p1 (3 un.) à frente de p2 (1 un.).
    expect(report.bestSellers, hasLength(2));
    expect(report.bestSellers.first.productId, 'p1');
    expect(report.bestSellers.first.quantity, 3);
    expect(report.bestSellers.first.revenue, 9.0);

    // Vendas por dia: 03/08 (6.0) e 04/08 (13.0).
    expect(report.perDay, hasLength(2));
    expect(report.perDay.first.total, 6.0);
    expect(report.perDay.last.total, 13.0);
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

    expect(report.totalRevenue, 0);
    expect(report.totalProfit, 0);
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
              quantity: 1,
              unitPrice: 10.0,
            ),
          ],
          totalAmount: 10.0,
          paymentMethod: PaymentMethod.pix,
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

    expect(report.totalProfit, 10.0);
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
              quantity: 1,
              unitPrice: 9.9,
            ),
          ],
          totalAmount: 9.9,
          paymentMethod: PaymentMethod.pix,
          dateTime: DateTime(2026, 8, 3),
        ),
    ];

    final report = await GetSalesReportUseCase(
      _FakeSaleRepository(sales),
      _FakeProductRepository(const [
        Product(id: 'p1', name: 'Caneta', purchasePrice: 5.0, salePrice: 9.9),
      ]),
    )(storeId: 'st1', start: DateTime(2026, 8, 1), end: DateTime(2026, 8, 31));

    expect(report.totalRevenue, 29.7);
    expect(report.totalProfit, closeTo(14.7, 0.0000001)); // 3 × 4.9
    expect(report.perDay.first.total, 29.7);
    expect(report.bestSellers.first.revenue, 29.7);
  });
}
