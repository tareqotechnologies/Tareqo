import '../usecases/get_cash_flow_use_case.dart';

/// Contrato da agregação de fluxo de caixa (H2).
///
/// Declara apenas *o que* o sistema precisa — **não** *como*. No modo
/// Supabase é implementado por uma RPC server-side ([CashFlow] agregado no
/// Postgres); o [GetCashFlowUseCase] continua calculando localmente quando
/// este repositório não está registrado (modo local/testes).
abstract interface class ICashFlowRepository {
  /// Entradas − saídas (PAID) da loja [storeId] no período `[start, end]`.
  Future<CashFlow> fetchCashFlow({
    required String storeId,
    required DateTime start,
    required DateTime end,
  });
}
