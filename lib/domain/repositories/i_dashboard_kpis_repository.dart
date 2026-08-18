import '../usecases/get_dashboard_kpis_use_case.dart';

/// Contrato da agregação das KPIs do dashboard.
abstract interface class IDashboardKpisRepository {
 /// Retorna os agregados da loja [storeId] no período `[start, end]`.
 Future<DashboardKpis> fetchKpis({
 required String storeId,
 required DateTime start,
 required DateTime end,
 });
}
