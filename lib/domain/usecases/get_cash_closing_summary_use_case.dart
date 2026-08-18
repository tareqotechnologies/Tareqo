import '../entities/cash_closing.dart';
import '../entities/sale.dart';
import '../repositories/i_cash_closing_repository.dart';
import '../repositories/i_cash_closing_summary_repository.dart';
import '../repositories/i_sale_repository.dart';

/// Resultado da agregação do dia (fecho de caixa).
///
/// Valores em CENTAVOS inteiros (W4) e `salesByMethodCents` chaveado pelo
/// nome do enum [PaymentMethod] (`method.name` → centavos) — o mesmo
/// formato persistido em [CashClosing.salesByMethodCents].
final class CashClosingDayAggregation {
 const CashClosingDayAggregation({
 required this.totalSalesCents,
 required this.expectedCashCents,
 required this.salesByMethodCents,
 });

 /// Σ de TODAS as vendas ativas do dia (todas as formas de pagamento).
 final int totalSalesCents;

 /// O que deveria estar na gaveta: apenas vendas em DINHEIRO do dia.
 final int expectedCashCents;

 /// Abertura por forma de pagamento (method.name → centavos).
 final Map<String, int> salesByMethodCents;
}

/// Agrega o dia para o Z-report — critério ÚNICO, compartilhado entre a
/// PRÉVIA ([GetCashClosingSummaryUseCase]) e a CONFIRMAÇÃO no modo local
/// ([CloseCashRegisterUseCase]): vendas ATIVAS dentro da janela do dia
/// [start, start + 1 dia), somadas por forma de pagamento. O ESPERADO na
/// gaveta é a soma das vendas em DINHEIRO (cartão/M-Pesa/E-Mola/
/// transferência não passam pela gaveta física).
///
/// Este é o MESMO critério da RPC `close_cash_register` (servidor é a
/// autoridade no modo SaaS); ter um único ponto evita que a prévia e a
/// confirmação divirjam quando o critério mudar (ex.: anuladas).
CashClosingDayAggregation aggregateCashClosingDay({
 required Iterable<Sale> sales,
 required DateTime start,
}) {
 final end = start.add(const Duration(days: 1));
 final byMethod = <String, int>{};
 var totalCents = 0;
 for (final sale in sales) {
 if (sale.status != SaleStatus.active) continue; // anulada sai do fecho
 if (sale.dateTime.isBefore(start) || !sale.dateTime.isBefore(end)) {
 continue; // fora da janela do dia
 }
 totalCents += sale.totalAmountCents;
 byMethod[sale.paymentMethod.name] =
 (byMethod[sale.paymentMethod.name] ?? 0) + sale.totalAmountCents;
 }
 return CashClosingDayAggregation(
 totalSalesCents: totalCents,
 expectedCashCents: byMethod[PaymentMethod.cash.name] ?? 0,
 salesByMethodCents: byMethod,
 );
}

/// Agregação do DIA para o Z-report (fecho de caixa).
///
/// Valores em CENTAVOS inteiros (W4) e `salesByMethodCents` chaveado pelo
/// nome do enum [PaymentMethod] (`method.name` → centavos) — o mesmo
/// formato persistido em [CashClosing.salesByMethodCents].
final class CashClosingSummary {
 const CashClosingSummary({
 required this.day,
 required this.totalSalesCents,
 required this.expectedCashCents,
 required this.salesByMethodCents,
 this.existingClosing,
 });

 /// Dia analisado (início do dia local).
 final DateTime day;

 /// Σ de TODAS as vendas ativas do dia (todas as formas de pagamento).
 final int totalSalesCents;

 /// O que deveria estar na gaveta: apenas vendas em DINHEIRO do dia.
 final int expectedCashCents;

 /// Abertura por forma de pagamento (method.name → centavos).
 final Map<String, int> salesByMethodCents;

 /// Fecho já registrado para o dia (null = dia ainda aberto).
 final CashClosing? existingClosing;

 bool get isClosed => existingClosing != null;
}

/// Caso de uso: montar o resumo do dia para o Z-report — vendas ativas do
/// dia por forma de pagamento, total e o esperado na gaveta (só dinheiro),
/// além do fecho já existente (se houver).
///
/// Modo Supabase (H2): quando um [ICashClosingSummaryRepository] é injetado,
/// a agregação acontece NO SERVIDOR (RPC `get_cash_closing_summary` — UMA
/// chamada, sem carregar o histórico de vendas no cliente). Sem ele (modo
/// local/testes), calcula client-side — MESMO critério do
/// [CloseCashRegisterUseCase] no modo local e da RPC `close_cash_register`
/// no servidor (critério único em [aggregateCashClosingDay]).
class GetCashClosingSummaryUseCase {
 const GetCashClosingSummaryUseCase(
 this._saleRepository,
 this._closingRepository, {
 this.serverRepository,
 });

 final ISaleRepository _saleRepository;
 final ICashClosingRepository _closingRepository;

 /// Agregação server-side (H2) — `null` no modo local/testes.
 final ICashClosingSummaryRepository? serverRepository;

 Future<CashClosingSummary> call({
 required String storeId,
 required DateTime day,
 }) async {
 final server = serverRepository;
 if (server != null) {
 // Modo Supabase (H2): agregação no Postgres em UMA chamada RPC.
 return server.fetchSummary(storeId: storeId, day: day);
 }

 final start = DateTime(day.year, day.month, day.day);
 final sales = await _saleRepository.getAll(storeId: storeId);
 final aggregation = aggregateCashClosingDay(sales: sales, start: start);

 final existing = await _closingRepository.getByDay(
 storeId: storeId,
 day: start,
 );

 return CashClosingSummary(
 day: start,
 totalSalesCents: aggregation.totalSalesCents,
 expectedCashCents: aggregation.expectedCashCents,
 salesByMethodCents: aggregation.salesByMethodCents,
 existingClosing: existing,
 );
 }
}
