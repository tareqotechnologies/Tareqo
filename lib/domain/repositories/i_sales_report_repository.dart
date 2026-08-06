import '../usecases/get_sales_report_use_case.dart';

/// Contrato da agregação do relatório de vendas (H2).
///
/// No modo Supabase é implementado por uma RPC server-side ([SalesReport]
/// agregado no Postgres); o [GetSalesReportUseCase] continua calculando
/// localmente quando este repositório não está registrado.
abstract interface class ISalesReportRepository {
  /// Relatório de vendas da loja [storeId] no período `[start, end]`
  /// (faturamento, lucro bruto, mais vendidos e vendas por dia).
  Future<SalesReport> fetchSalesReport({
    required String storeId,
    required DateTime start,
    required DateTime end,
  });
}
