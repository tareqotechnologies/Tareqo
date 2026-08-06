import '../../domain/repositories/i_sales_report_repository.dart';
import '../../domain/usecases/get_sales_report_use_case.dart';
import '../datasources/remote/supabase_datasource_helpers.dart';

/// Agregação do relatório de vendas no SERVIDOR via RPC `get_sales_report`
/// (SECURITY DEFINER com guarda `is_my_store`) — UMA chamada em vez de
/// listar vendas + itens + catálogo e agregar no cliente (escala H2).
///
/// Valores em CENTAVOS inteiros (W4): a RPC devolve BIGINT. O dia é
/// agrupado no fuso do dispositivo (offset passado à RPC) para casar com
/// o agrupamento `DateTime(y, m, d)` local do cliente.
final class SupabaseSalesReportRepository implements ISalesReportRepository {
  const SupabaseSalesReportRepository();

  @override
  Future<SalesReport> fetchSalesReport({
    required String storeId,
    required DateTime start,
    required DateTime end,
  }) async {
    requireCurrentUserId(); // Falha cedo (cliente) se não houver sessão.
    final data = await supabaseClient.rpc(
      'get_sales_report',
      params: {
        'p_store_id': storeId,
        'p_start': start.toUtc().toIso8601String(),
        'p_end': end.toUtc().toIso8601String(),
        'p_tz_offset_minutes': DateTime.now().timeZoneOffset.inMinutes,
      },
    );

    // PostgREST devolve o JSONB da RPC (objeto único). Aceita também o
    // formato lista (defensivo) caso o schema mude para RETURNS TABLE.
    final map = data is List && data.isNotEmpty
        ? data.first as Map<String, dynamic>
        : data as Map<String, dynamic>;

    return SalesReport(
      totalRevenueCents: (map['total_revenue_cents'] as num).toInt(),
      totalProfitCents: (map['total_profit_cents'] as num).toInt(),
      bestSellers: [
        for (final item in (map['best_sellers'] as List<dynamic>? ?? const []))
          BestSeller(
            productId: (item as Map<String, dynamic>)['product_id'] as String,
            productName: item['product_name'] as String,
            quantity: (item['quantity'] as num).toInt(),
            revenueCents: (item['revenue_cents'] as num).toInt(),
          ),
      ],
      perDay: [
        for (final item in (map['per_day'] as List<dynamic>? ?? const []))
          DailySales(
            day: DateTime.parse((item as Map<String, dynamic>)['day'] as String),
            totalCents: (item['total_cents'] as num).toInt(),
          ),
      ],
    );
  }
}
