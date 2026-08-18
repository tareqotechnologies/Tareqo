import '../repositories/i_dashboard_kpis_repository.dart';

/// Agregados das KPIs do dashboard (calculados no SERVIDOR no modo SaaS
/// via RPC `get_dashboard_kpis`; no modo local, fallback client-side).
///
/// Valores em CENTAVOS inteiros (W4) — o Postgres persiste BIGINT.
final class DashboardKpis {
 const DashboardKpis({
 required this.totalSalesCents,
 required this.cashIncomeCents,
 required this.cashExpenseCents,
 required this.pendingTotalCents,
 required this.stockTotal,
 });

 /// Total de vendas da loja (histórico completo — sem filtro de período),
 /// em centavos.
 final int totalSalesCents;

 /// Entradas realizadas no período (transações `paid` do tipo income),
 /// em centavos.
 final int cashIncomeCents;

 /// Saídas realizadas no período (transações `paid` do tipo expense),
 /// em centavos.
 final int cashExpenseCents;

 /// Total a receber de clientes ("fiado") ainda pendente, em centavos.
 final int pendingTotalCents;

 /// Soma das quantidades em estoque (unidades).
 final int stockTotal;

 /// Saldo em caixa: entradas − saídas do período (centavos).
 int get cashBalanceCents => cashIncomeCents - cashExpenseCents;

 static const empty = DashboardKpis(
 totalSalesCents: 0,
 cashIncomeCents: 0,
 cashExpenseCents: 0,
 pendingTotalCents: 0,
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
