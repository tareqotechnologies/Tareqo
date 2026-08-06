import '../../domain/repositories/i_dashboard_kpis_repository.dart';
import '../../domain/usecases/get_dashboard_kpis_use_case.dart';
import '../datasources/remote/supabase_datasource_helpers.dart';

/// Agregação das KPIs no SERVIDOR via RPC `get_dashboard_kpis`
/// (SECURITY DEFINER com guarda `is_my_store`) — UMA chamada em vez de 4
/// listagens de até 1000 linhas somadas no cliente (escala W5).
final class SupabaseDashboardKpisRepository implements IDashboardKpisRepository {
  const SupabaseDashboardKpisRepository();

  @override
  Future<DashboardKpis> fetchKpis({
    required String storeId,
    required DateTime start,
    required DateTime end,
  }) async {
    requireCurrentUserId(); // Falha cedo (cliente) se não houver sessão.
    final rows = await supabaseClient.rpc(
      'get_dashboard_kpis',
      params: {
        'p_store_id': storeId,
        'p_start': start.toUtc().toIso8601String(),
        'p_end': end.toUtc().toIso8601String(),
      },
    ) as List<dynamic>;

    if (rows.isEmpty) return DashboardKpis.empty;

    final row = rows.first as Map<String, dynamic>;
    // Valores em CENTAVOS inteiros (W4): a RPC devolve BIGINT.
    return DashboardKpis(
      totalSalesCents: (row['total_sales'] as num).toInt(),
      cashIncomeCents: (row['cash_income'] as num).toInt(),
      cashExpenseCents: (row['cash_expense'] as num).toInt(),
      pendingTotalCents: (row['pending_total'] as num).toInt(),
      stockTotal: (row['stock_total'] as num).toInt(),
    );
  }
}
