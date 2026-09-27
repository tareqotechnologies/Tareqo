import 'package:freezed_annotation/freezed_annotation.dart';

part 'production_order.freezed.dart';
part 'production_order.g.dart';

/// Componente CONSUMIDO por uma ordem de produção — snapshot do momento.
///
/// Guarda [productName] e [unitCostCents] (custo do componente na data da
/// produção) — mesmo padrão de snapshot do `SaleItem`/`PurchaseItem`, para
/// que o custo do lote produzido fique auditável mesmo se o catálogo mudar
/// depois. [quantity] em MILÉSIMOS (W11).
@freezed
abstract class ProductionItem with _$ProductionItem {
  const factory ProductionItem({
    required String productId,
    required String productName,
    required int quantity,
    required int unitCostCents,
  }) = _ProductionItem;

  factory ProductionItem.fromJson(Map<String, dynamic> json) =>
      _$ProductionItemFromJson(json);
}

/// Entidade de domínio que representa uma **ORDEM DE PRODUÇÃO** (Fase 2).
///
/// Registra uma execução da ficha técnica: baixou [items] do estoque (em
/// ordem FIFO por lotes) e criou um LOTE do produto acabado [productId] com
/// [quantity] milésimos, ao custo [costPriceCents] por unidade (custo médio
/// dos componentes consumidos). A produção NÃO movimenta o caixa — os
/// componentes já foram pagos na compra; a ordem apenas transforma estoque.
///
/// É um documento HISTÓRICO (imutável): guarda o snapshot do custo e o
/// vínculo opcional com a ficha técnica ([recipeId]) que a originou.
@freezed
abstract class ProductionOrder with _$ProductionOrder {
  const factory ProductionOrder({
    required String id,
    @Default('st1') String storeId,
    // Produto ACABADO produzido.
    required String productId,
    required String productName,
    // Quantidade produzida, em MILÉSIMOS (W11).
    required int quantity,
    // Ficha técnica de origem (null se a produção foi avulsa).
    String? recipeId,
    // Custo por unidade do produto acabado (CENTAVOS, W4) — vira o
    // `cost_price` do lote criado.
    required int costPriceCents,
    // Custo total da ordem (CENTAVOS) = Σ (componente × custo unitário).
    required int totalCostCents,
    required DateTime dateTime,
    // Componentes consumidos (snapshot).
    required List<ProductionItem> items,
  }) = _ProductionOrder;

  factory ProductionOrder.fromJson(Map<String, dynamic> json) =>
      _$ProductionOrderFromJson(json);
}
