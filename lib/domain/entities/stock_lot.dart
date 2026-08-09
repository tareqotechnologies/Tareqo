import 'package:freezed_annotation/freezed_annotation.dart';

part 'stock_lot.freezed.dart';
part 'stock_lot.g.dart';

/// Entidade de domínio que representa um **lote** de estoque (W11 — FIFO e
/// controlo de validade).
///
/// Cada entrada de mercadoria cria um lote associado ao produto com a sua
/// própria quantidade e (opcionalmente) data de validade. A baixa de estoque
/// no PDV consome os lotes em ordem FIFO: o lote com vencimento mais
/// próximo (ou entrada mais antiga, quando sem validade) primeiro.
///
/// Imutável por construção (Freezed) — mesmas convenções do restante do
/// domínio. Quantidades em MILÉSIMOS de unidade (W11) e custo em CENTAVOS
/// inteiros (W4).
@freezed
abstract class StockLot with _$StockLot {
  const factory StockLot({
    required String id,
    // Loja dona do lote — cada loja tem seus próprios lotes (Fase 2 do
    // multi-tenancy).
    @Default('st1') String storeId,
    required String productId,
    // Data de ENTRADA do lote (data da compra) — critério FIFO quando não
    // há data de validade.
    required DateTime entryDate,
    // Data de VALIDADE — `null` para produtos sem validade (não
    // perecíveis), que seguem FIFO por data de entrada.
    DateTime? expiryDate,
    // Quantidade INICIAL recebida (milésimos) — referência histórica.
    required int initialQuantity,
    // Quantidade ATUAL disponível (milésimos) — diminui a cada venda FIFO;
    // lotes zerados são inativos e não participam das baixas.
    required int currentQuantity,
    // Custo de aquisição em CENTAVOS inteiros (W4) — base do custo do
    // estoque (custo do lote na data da compra).
    required int costPriceCents,
  }) = _StockLot;

  factory StockLot.fromJson(Map<String, dynamic> json) =>
      _$StockLotFromJson(json);
}
