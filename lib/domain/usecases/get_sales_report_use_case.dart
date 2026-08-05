import '../repositories/i_product_repository.dart';
import '../repositories/i_sale_repository.dart';

/// Produto mais vendido (por quantidade) no período.
final class BestSeller {
  const BestSeller({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.revenue,
  });

  final String productId;
  final String productName;
  final int quantity;
  final double revenue;
}

/// Total de vendas de um dia.
final class DailySales {
  const DailySales({required this.day, required this.total});

  final DateTime day;
  final double total;
}

/// Resultado do relatório de vendas de um período.
final class SalesReport {
  const SalesReport({
    required this.totalRevenue,
    required this.totalProfit,
    required this.bestSellers,
    required this.perDay,
  });

  /// Faturamento bruto no período (Σ totais das vendas).
  final double totalRevenue;

  /// Lucro bruto estimado: Σ sobre os itens de
  /// `quantidade × (preço de venda no snapshot − preço de compra ATUAL)`.
  ///
  /// ⚠️ Usa o preço de compra atual do catálogo ([Product.purchasePrice]) —
  /// para produtos que não existem mais no catálogo, o custo é tratado como
  /// 0 (o lucro fica superestimado nesse caso).
  final double totalProfit;

  /// Margem bruta percentual (0–100). 0 quando não há faturamento.
  double get margin => totalRevenue == 0 ? 0 : totalProfit / totalRevenue * 100;

  /// Produtos mais vendidos por quantidade (top 5).
  final List<BestSeller> bestSellers;

  /// Vendas por dia (ordenação por data).
  final List<DailySales> perDay;
}

/// Caso de uso: relatório de vendas (faturamento, lucro, mais vendidos e
/// vendas por dia) em um período.
///
/// Calculado a partir das vendas registradas (snapshots) + catálogo atual —
/// sem dependência de datasources, testável com fakes.
class GetSalesReportUseCase {
  const GetSalesReportUseCase(this._saleRepository, this._productRepository);

  final ISaleRepository _saleRepository;
  final IProductRepository _productRepository;

  Future<SalesReport> call({
    required String storeId,
    required DateTime start,
    required DateTime end,
  }) async {
    final sales = (await _saleRepository.getAll(storeId: storeId))
        .where((sale) =>
            !sale.dateTime.isBefore(start) && !sale.dateTime.isAfter(end))
        .toList();

    final products = await _productRepository.getAll(storeId: storeId);
    final purchasePriceById = {
      for (final product in products) product.id: product.purchasePrice,
    };

    var revenue = 0.0;
    var profit = 0.0;
    final quantityById = <String, int>{};
    final revenueById = <String, double>{};
    final nameById = <String, String>{};
    final dayTotals = <DateTime, double>{};

    for (final sale in sales) {
      revenue += sale.totalAmount;

      final day = DateTime(sale.dateTime.year, sale.dateTime.month, sale.dateTime.day);
      dayTotals[day] = (dayTotals[day] ?? 0) + sale.totalAmount;

      for (final item in sale.items) {
        final cost = purchasePriceById[item.productId] ?? 0.0;
        profit += item.quantity * (item.unitPrice - cost);

        quantityById[item.productId] =
            (quantityById[item.productId] ?? 0) + item.quantity;
        revenueById[item.productId] =
            (revenueById[item.productId] ?? 0) + item.quantity * item.unitPrice;
        // Último snapshot de nome vence (produtos renomeados no catálogo).
        nameById[item.productId] = item.productName;
      }
    }

    final bestSellers = quantityById.entries
        .map((entry) => BestSeller(
              productId: entry.key,
              productName: nameById[entry.key] ?? entry.key,
              quantity: entry.value,
              revenue: revenueById[entry.key] ?? 0,
            ))
        .toList()
      ..sort((a, b) => b.quantity.compareTo(a.quantity));

    final perDay = dayTotals.entries
        .map((entry) => DailySales(day: entry.key, total: entry.value))
        .toList()
      ..sort((a, b) => a.day.compareTo(b.day));

    return SalesReport(
      totalRevenue: revenue,
      totalProfit: profit,
      bestSellers: bestSellers.take(5).toList(),
      perDay: perDay,
    );
  }
}
