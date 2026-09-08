import '../../core/utils/quantity.dart';
import '../entities/sale.dart';
import '../repositories/i_product_repository.dart';
import '../repositories/i_sale_repository.dart';
import '../repositories/i_sales_report_repository.dart';

/// Produto mais vendido (por quantidade) no período.
final class BestSeller {
  const BestSeller({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.revenueCents,
  });

  final String productId;
  final String productName;
  final int quantity;
  final int revenueCents;
}

/// Total de vendas de um dia (centavos).
final class DailySales {
  const DailySales({required this.day, required this.totalCents});

  final DateTime day;
  final int totalCents;
}

/// Resultado do relatório de vendas de um período.
///
/// Valores em CENTAVOS inteiros (W4) — a soma é exata.
final class SalesReport {
  const SalesReport({
    required this.totalRevenueCents,
    required this.totalProfitCents,
    required this.bestSellers,
    required this.perDay,
  });

  /// Faturamento bruto no período (Σ totais das vendas, em centavos).
  final int totalRevenueCents;

  /// Lucro bruto estimado: Σ sobre os itens de
  /// `quantidade × (preço de venda no snapshot − preço de compra ATUAL)`.
  ///
  /// Atenção: Usa o preço de compra atual do catálogo ([Product.purchasePriceCents])
  /// — para produtos que não existem mais no catálogo, o custo é tratado
  /// como 0 (o lucro fica superestimado nesse caso).
  final int totalProfitCents;

  /// Margem bruta percentual (0–100). 0 quando não há faturamento.
  double get margin =>
      totalRevenueCents == 0 ? 0 : totalProfitCents / totalRevenueCents * 100;

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
///
/// Modo Supabase (H2): quando um [ISalesReportRepository] é injetado, a
/// agregação acontece NO SERVIDOR (RPC `get_sales_report` — UMA chamada).
class GetSalesReportUseCase {
  const GetSalesReportUseCase(
    this._saleRepository,
    this._productRepository, {
    this.serverRepository,
  });

  final ISaleRepository _saleRepository;
  final IProductRepository _productRepository;

  /// Agregação server-side (H2) — `null` no modo local/testes.
  final ISalesReportRepository? serverRepository;

  Future<SalesReport> call({
    required String storeId,
    required DateTime start,
    required DateTime end,
  }) async {
    final server = serverRepository;
    if (server != null) {
      // Modo Supabase (H2): agregação no Postgres em UMA chamada RPC.
      return server.fetchSalesReport(storeId: storeId, start: start, end: end);
    }

    final sales = (await _saleRepository.getAll(storeId: storeId))
        .where(
          (sale) =>
              // Vendas ANULADAS saem do relatório (mesmo critério da RPC
              // get_sales_report: só status 'active').
              sale.status == SaleStatus.active &&
              !sale.dateTime.isBefore(start) &&
              !sale.dateTime.isAfter(end),
        )
        .toList();

    final products = await _productRepository.getAll(storeId: storeId);
    final purchasePriceCentsById = {
      for (final product in products) product.id: product.purchasePriceCents,
    };

    // Acúmulos em CENTAVOS inteiros (W4): `int` é exato — sem
    // arredondamento de fronteira, sem artefatos de double.
    var revenueCents = 0;
    var profitCents = 0;
    final quantityById = <String, int>{};
    final revenueById = <String, int>{};
    final nameById = <String, String>{};
    final dayTotals = <DateTime, int>{};

    for (final sale in sales) {
      revenueCents += sale.totalAmountCents;

      final day = DateTime(
        sale.dateTime.year,
        sale.dateTime.month,
        sale.dateTime.day,
      );
      dayTotals[day] = (dayTotals[day] ?? 0) + sale.totalAmountCents;

      for (final item in sale.items) {
        final costCents = purchasePriceCentsById[item.productId] ?? 0;
        // Lucro por item: quantidade (MILÉSIMOS) × (preço de venda −
        // custo) ~/ 1000 — divisão inteira exata (W4 + W11), mesmo
        // contrato das RPCs do servidor.
        profitCents += Quantity.lineTotal(
          item.quantity,
          item.unitPriceCents - costCents,
        );

        quantityById[item.productId] =
            (quantityById[item.productId] ?? 0) + item.quantity;
        revenueById[item.productId] =
            (revenueById[item.productId] ?? 0) +
            Quantity.lineTotal(item.quantity, item.unitPriceCents);
        // Último snapshot de nome vence (produtos renomeados no catálogo).
        nameById[item.productId] = item.productName;
      }
    }

    final bestSellers =
        quantityById.entries
            .map(
              (entry) => BestSeller(
                productId: entry.key,
                productName: nameById[entry.key] ?? entry.key,
                quantity: entry.value,
                revenueCents: revenueById[entry.key] ?? 0,
              ),
            )
            .toList()
          ..sort((a, b) => b.quantity.compareTo(a.quantity));

    final perDay =
        dayTotals.entries
            .map((entry) => DailySales(day: entry.key, totalCents: entry.value))
            .toList()
          ..sort((a, b) => a.day.compareTo(b.day));

    return SalesReport(
      totalRevenueCents: revenueCents,
      totalProfitCents: profitCents,
      bestSellers: bestSellers.take(5).toList(),
      perDay: perDay,
    );
  }
}
