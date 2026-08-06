import '../repositories/i_dashboard_kpis_repository.dart';

/// Agregados das KPIs do dashboard (calculados no SERVIDOR no modo SaaS
/// via RPC `get_dashboard_kpis`; no modo local, fallback client-side).
final class DashboardKpis {
  const DashboardKpis({
    required this.totalSales,
    required this.cashIncome,
    required this.cashExpense,
    required this.pendingTotal,
    required this.stockTotal,
  });

  /// Total de vendas da loja (histórico completo — sem filtro de período).
  final double totalSales;

  /// Entradas realizadas no período (transações `paid` do tipo income).
  final double cashIncome;

  /// Saídas realizadas no período (transações `paid` do tipo expense).
  final double cashExpense;

  /// Total a receber de clientes ("fiado") ainda pendente.
  final double pendingTotal;

  /// Soma das quantidades em estoque (unidades).
  final int stockTotal;

  /// Saldo em caixa: entradas − saídas do período.
  double get cashBalance => cashIncome - cashExpense;

  static const empty = DashboardKpis(
    totalSales: 0,
    cashIncome: 0,
    cashExpense: 0,
    pendingTotal: 0,
    stockTotal: 0,
  );
}

/// Caso de uso: obter os agregados do dashboard da loja [storeId] no
/// período `[start, end]`. No modo Supabase delega à RPC `get_dashboard_kpis`
/// (agregação no Postgres — escala W5); no modo local, a implementação
/// calcula a partir dos repositórios locais.
class GetDashboardKpisUseCase {
  const GetDashboardKpisUseCase(this._repository);

  final IDashboardKpisRepository _repository;

  Future<DashboardKpis> call({
    required String storeId,
    required DateTime start,
    required DateTime end,
  }) =>
      _repository.fetchKpis(storeId: storeId, start: start, end: end);
}
