import 'package:freezed_annotation/freezed_annotation.dart';

part 'cash_closing.freezed.dart';
part 'cash_closing.g.dart';

/// Fecho de caixa DIÁRIO (Z-report) — o registro persistido do fecho da
/// loja em um dia.
///
/// Um fecho por loja por dia (unicidade `(store_id, closing_date)` no banco
/// — refazer o fecho do mesmo dia ATUALIZA o registro, corrigindo a
/// contagem física sem apagar o histórico). Armazena o SNAPSHOT do dia:
///
/// - [totalSalesCents] — Σ de TODAS as vendas ativas do dia (todas as
///   formas de pagamento);
/// - [expectedCashCents] — o que DEVERIA estar na gaveta: **apenas as
///   vendas pagas em DINHEIRO** (cartão, M-Pesa, E-Mola e transferência
///   não passam pela gaveta física);
/// - [countedCashCents] — o dinheiro físico CONTADO pelo usuário na
///   conferência;
/// - [salesByMethodCents] — abertura por forma de pagamento (`method.name`
///   → centavos) para o relatório Z;
/// - [closedAt] — momento em que o fecho foi confirmado.
///
/// Valores em CENTAVOS inteiros (W4) e datas normalizadas ao início do dia
/// local ([CashClosing.day]) — a mesma semântica dos demais módulos.
@freezed
abstract class CashClosing with _$CashClosing {
  @Assert('expectedCashCents >= 0', 'O valor esperado deve ser positivo.')
  @Assert('countedCashCents >= 0', 'O valor contado deve ser positivo.')
  const factory CashClosing({
    required String id,
    // Loja dona do fecho — o caixa é por loja (Fase 2 do multi-tenancy).
    @Default('st1') String storeId,
    // Dia fechado (início do dia local — a unicidade é por loja + dia).
    required DateTime day,
    // Σ das vendas ATIVAS do dia (todas as formas de pagamento).
    required int totalSalesCents,
    // O que deveria estar na gaveta: só vendas em DINHEIRO (a conferência
    // física compara contra este valor).
    required int expectedCashCents,
    // Dinheiro físico contado pelo usuário na conferência.
    required int countedCashCents,
    // Abertura por forma de pagamento (method.name → centavos) — o Z.
    @Default({}) Map<String, int> salesByMethodCents,
    // Momento em que o fecho foi confirmado/atualizado.
    required DateTime closedAt,
  }) = _CashClosing;

  factory CashClosing.fromJson(Map<String, dynamic> json) =>
      _$CashClosingFromJson(json);
}

/// Diferença entre o contado e o esperado (centavos):
///
/// - 0 → caixa CONFERE;
/// - positivo → SOBRA no caixa (contado > esperado);
/// - negativo → FALTA no caixa (contado < esperado).
extension CashClosingDifference on CashClosing {
  int get differenceCents => countedCashCents - expectedCashCents;
}
