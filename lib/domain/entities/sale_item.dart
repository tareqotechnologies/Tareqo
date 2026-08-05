import 'package:freezed_annotation/freezed_annotation.dart';

part 'sale_item.freezed.dart';
part 'sale_item.g.dart';

/// Item de venda: "fotografia" do produto no momento da venda.
///
/// Guarda o [productName] e o [unitPrice] **na data da venda** (snapshot)
/// — e não apenas o [productId] — para que alterações futuras de preço ou
/// nome no catálogo não corrompam o histórico (ver README).
///
/// A serialização aninhada dentro de [Sale] funciona graças ao
/// `explicit_to_json: true` configurado no `build.yaml`.
@freezed
abstract class SaleItem with _$SaleItem {
  const factory SaleItem({
    required String productId,
    required String productName,
    required int quantity,
    required double unitPrice,
  }) = _SaleItem;

  factory SaleItem.fromJson(Map<String, dynamic> json) =>
      _$SaleItemFromJson(json);
}
