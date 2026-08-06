import '../../domain/repositories/i_cash_flow_repository.dart';
import '../../domain/usecases/get_cash_flow_use_case.dart';
import '../datasources/remote/supabase_datasource_helpers.dart';

/// Agregação do fluxo de caixa no SERVIDOR via RPC `get_cash_flow`
/// (SECURITY DEFINER com guarda `is_my_store`) — UMA chamada em vez de
/// listar as transações do período e somar no cliente (escala H2).
///
/// Valores em CENTAVOS inteiros (W4): a RPC devolve BIGINT.
final class SupabaseCashFlowRepository implements ICashFlowRepository {
  const SupabaseCashFlowRepository();

  @override
  Future<CashFlow> fetchCashFlow({
    required String storeId,
    required DateTime start,
    required DateTime end,
  }) async {
    requireCurrentUserId(); // Falha cedo (cliente) se não houver sessão.
    final rows = await supabaseClient.rpc(
      'get_cash_flow',
      params: {
        'p_store_id': storeId,
        'p_start': start.toUtc().toIso8601String(),
        'p_end': end.toUtc().toIso8601String(),
      },
    ) as List<dynamic>;

    if (rows.isEmpty) {
      return const CashFlow(incomeCents: 0, expenseCents: 0);
    }
    final row = rows.first as Map<String, dynamic>;
    return CashFlow(
      incomeCents: (row['income_cents'] as num).toInt(),
      expenseCents: (row['expense_cents'] as num).toInt(),
    );
  }
}
