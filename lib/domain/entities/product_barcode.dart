import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/utils/quantity.dart';

part 'product_barcode.freezed.dart';
part 'product_barcode.g.dart';

/// Código de barras adicional de um produto.
///
/// O stock continua a ser controlado na MENOR unidade do produto. Por isso
/// [qtyFactor] representa quantas unidades base a embalagem contém:
///
/// - unidade: 1
/// - caixa: 30
/// - fardo: 180
///
/// A conversão para milésimos (W11) acontece em [baseQuantityMilli] e nunca
/// é persistida no fator — evita dupla conversão no POS.
@freezed
abstract class ProductBarcode with _$ProductBarcode {
  const factory ProductBarcode({
    required String id,
    @Default('st1') String storeId,
    required String productId,
    required String barcode,
    @Default(1) int qtyFactor,
    @Default('') String description,
    @Default(true) bool isActive,
  }) = _ProductBarcode;

  factory ProductBarcode.fromJson(Map<String, dynamic> json) =>
      _$ProductBarcodeFromJson(json);
}

extension ProductBarcodeQuantity on ProductBarcode {
  /// Quantidade em MILÉSIMOS que esta embalagem representa no stock.
  ///
  /// Ex.: caixa com fator 30 → 30.000 milésimos (30 unidades).
  int get baseQuantityMilli => qtyFactor * Quantity.milliFactor;

  /// Chave de comparação usada pelo scanner: sem espaços e sem caixa.
  /// Mantém a mesma semântica de `_codeKey` do PDV.
  String get normalizedCode =>
      barcode.replaceAll(RegExp(r'\s+'), '').toLowerCase();
}
