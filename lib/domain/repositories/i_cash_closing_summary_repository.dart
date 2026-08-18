import '../usecases/get_cash_closing_summary_use_case.dart';

/// Contrato da agregação da PRÉVIA do fecho de caixa (H2).
///
/// No modo Supabase é implementado por uma RPC server-side
/// ([CashClosingSummary] agregado no Postgres — `get_cash_closing_summary`);
/// o [GetCashClosingSummaryUseCase] continua calculando localmente quando
/// este repositório não está registrado (modo local/testes).
abstract interface class ICashClosingSummaryRepository {
 /// Resumo do dia [day] da loja [storeId] para a pré-visualização do
 /// Z-report (total, esperado na gaveta, abertura por forma e o fecho já
 /// registrado, se houver) — agregado no servidor em UMA chamada.
 Future<CashClosingSummary> fetchSummary({
 required String storeId,
 required DateTime day,
 });
}
