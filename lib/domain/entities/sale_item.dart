import 'package:freezed_annotation/freezed_annotation.dart';

part 'sale_item.freezed.dart';
part 'sale_item.g.dart';

/// Item de venda: \"fotografia\" do produto no momento da venda.
///
/// [quantity] está em MILÉSIMOS de unidade (W11 — 1000 = 1 unidade).
///
/// Guarda [productName] e [unitPriceCents] (preço cobrado) na data da
/// venda — mesmo que o preço atual do catálogo mude depois, o histórico
/// não é afetado.
@freezed
abstract class SaleItem with _$SaleItem {
 const factory SaleItem({
 required String productId,
 required String productName,
 // Quantidade em MILÉSIMOS de unidade (W11): 1000 = 1 unidade/kg.
 required int quantity,
 // Preço unitário cobrado em CENTAVOS inteiros (W4).
 required int unitPriceCents,
 }) = _SaleItem;

 factory SaleItem.fromJson(Map<String, dynamic> json) =>
 _$SaleItemFromJson(json);
}
