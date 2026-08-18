import '../entities/cash_closing.dart';

/// Processador ATÔMICO do fecho de caixa (Z-report) no modo Supabase.
///
/// Delega à RPC `close_cash_register`, que calcula NO SERVIDOR o esperado
/// (Σ vendas ativas em dinheiro do dia) e o total do dia, valida a guarda
/// gerencial (`is_manager_of_store`) e faz o UPSERT em UMA transação — o
/// servidor é a autoridade (mesmo padrão de `process_sale`/`cancel_sale`).
///
/// No modo local (SQLite/memória) não é registrado: o
/// [CloseCashRegisterUseCase] calcula client-side e persiste via
/// [ICashClosingRepository].
abstract interface class ICashClosingProcessor {
 /// Fecha (ou refaz) o caixa do dia [day] da loja [storeId] com a
 /// contagem física [countedCashCents]. Retorna o fecho registrado.
 Future<CashClosing> close({
 required String storeId,
 required DateTime day,
 required int countedCashCents,
 });
}
