import '../entities/financial_transaction.dart';
import '../repositories/i_cash_flow_repository.dart';
import '../repositories/i_financial_transaction_repository.dart';

/// Exceção de domínio: período inválido para cálculo de fluxo de caixa.
final class InvalidPeriodException implements Exception {
 const InvalidPeriodException(this.message);

 final String message;

 @override
 String toString() => 'InvalidPeriodException: $message';
}

/// Resultado do fluxo de caixa em um período.
///
/// Valores em CENTAVOS inteiros (W4) — a soma é exata (nunca 0.1+0.2).
final class CashFlow {
 const CashFlow({required this.incomeCents, required this.expenseCents});

 /// Total de entradas no período (centavos).
 final int incomeCents;

 /// Total de saídas no período (centavos).
 final int expenseCents;

 /// Saldo: entradas − saídas (centavos).
 int get balanceCents => incomeCents - expenseCents;

 @override
 String toString() => 'CashFlow(income: $incomeCents, expense: $expenseCents, '
 'balance: $balanceCents)';
}

/// Caso de uso: calcular o fluxo de caixa (entradas − saídas) em um período.
///
/// Modo Supabase (H2): quando um [ICashFlowRepository] é injetado, a
/// agregação acontece NO SERVIDOR (RPC `get_cash_flow` — UMA chamada).
/// Sem ele (modo local/testes), calcula client-side pelas transações.
class GetCashFlowUseCase {
 const GetCashFlowUseCase(
 this._repository, {
 this.serverRepository,
 });

 final IFinancialTransactionRepository _repository;

 /// Agregação server-side (H2) — `null` no modo local/testes.
 final ICashFlowRepository? serverRepository;

 /// Calcula o **fluxo de caixa realizado** da loja [storeId] no período
 /// `[start, end]` (inclusive) — considera apenas transações com
 /// [TransactionStatus.paid].
 ///
 /// Vendas "fiadas" (entradas pendentes) só contam quando recebidas;
 /// contas a pagar pendentes também não saem do caixa ainda.
 ///
 /// Lança [InvalidPeriodException] se `start` for posterior a `end`.
 Future<CashFlow> call({
 required String storeId,
 required DateTime start,
 required DateTime end,
 }) async {
 if (start.isAfter(end)) {
 throw InvalidPeriodException(
 'A data inicial ($start) não pode ser posterior à final ($end).',
 );
 }

 final server = serverRepository;
 if (server != null) {
 // Modo Supabase (H2): agregação no Postgres em UMA chamada RPC.
 return server.fetchCashFlow(
 storeId: storeId,
 start: start,
 end: end,
 );
 }

 final transactions = await _repository.getByPeriod(
 storeId: storeId,
 start: start,
 end: end,
 );

 // Soma em CENTAVOS inteiros (W4): `int` não tem artefato de
 // representação — a aritmética é exata por construção.
 var incomeCents = 0;
 var expenseCents = 0;
 for (final transaction in transactions) {
 // Caixa realizado: ignora transações ainda pendentes.
 if (transaction.status != TransactionStatus.paid) continue;

 if (transaction.type == TransactionType.income) {
 incomeCents += transaction.amountCents;
 } else {
 expenseCents += transaction.amountCents;
 }
 }

 return CashFlow(incomeCents: incomeCents, expenseCents: expenseCents);
 }
}
