import '../../core/utils/ids.dart';
import '../entities/cash_closing.dart';
import '../repositories/i_cash_closing_processor.dart';
import '../repositories/i_cash_closing_repository.dart';
import '../repositories/i_sale_repository.dart';
import 'get_cash_closing_summary_use_case.dart';

/// Exceção de domínio: contagem física inválida para o fecho de caixa.
final class InvalidCashCountException implements Exception {
  const InvalidCashCountException(this.message);

  final String message;

  @override
  String toString() => 'InvalidCashCountException: $message';
}

/// Caso de uso: FECHO DE CAIXA DIÁRIO (Z-report) — registra o fecho do dia
/// da loja com a conferência do dinheiro físico.
///
/// Fluxo:
/// 1. Valida a contagem física ([countedCashCents] ≥ 0 — o dono pode
/// fechar com a gaveta zerada, mas nunca com valor negativo);
/// 2. Calcula o ESPERADO na gaveta: Σ das vendas ATIVAS pagas em DINHEIRO
/// no dia (cartão/M-Pesa/E-Mola/transferência não passam pela gaveta);
/// 3. Persiste o fecho (UPSERT por loja + dia — refazer corrige a
/// contagem, sem duplicar) e devolve o registro.
///
/// Modo Supabase: delega à RPC `close_cash_register` (cálculo + guarda
/// gerencial `is_manager_of_store` + UPSERT em UMA transação no servidor).
/// Modo local (SQLite/memória): calcula client-side e persiste via
/// [ICashClosingRepository].
class CloseCashRegisterUseCase {
  const CloseCashRegisterUseCase(
    this._saleRepository,
    this._closingRepository, {
    this.processor,
  });

  final ISaleRepository _saleRepository;
  final ICashClosingRepository _closingRepository;

  /// Processador atômico opcional (Supabase via RPC).
  final ICashClosingProcessor? processor;

  Future<CashClosing> call({
    required String storeId,
    required DateTime day,
    required int countedCashCents,
  }) async {
    if (countedCashCents < 0) {
      throw const InvalidCashCountException(
        'A contagem física não pode ser negativa.',
      );
    }

    final atomicProcessor = processor;
    if (atomicProcessor != null) {
      // Modo Supabase: o servidor calcula o esperado/total e persiste.
      return atomicProcessor.close(
        storeId: storeId,
        day: day,
        countedCashCents: countedCashCents,
      );
    }

    // Modo local: agregação client-side do dia — MESMO critério da prévia
    // (vendas ATIVAS na janela do dia; anuladas ficam de fora) via helper
    // compartilhado, espelhando o que a RPC close_cash_register calcula
    // no servidor.
    final start = DateTime(day.year, day.month, day.day);
    final sales = await _saleRepository.getAll(storeId: storeId);
    final aggregation = aggregateCashClosingDay(sales: sales, start: start);

    final closing = CashClosing(
      id: AppIds.newId('cc'),
      storeId: storeId,
      day: start,
      totalSalesCents: aggregation.totalSalesCents,
      expectedCashCents: aggregation.expectedCashCents,
      countedCashCents: countedCashCents,
      salesByMethodCents: aggregation.salesByMethodCents,
      closedAt: DateTime.now(),
    );
    await _closingRepository.save(closing);
    return closing;
  }
}
