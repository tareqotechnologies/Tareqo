import 'package:freezed_annotation/freezed_annotation.dart';

part 'purchase.freezed.dart';
part 'purchase.g.dart';

/// Item de compra: "fotografia" do produto no momento da compra.
///
/// Guarda [productName] e [unitPrice] (preço de compra) na data da compra —
/// mesmo padrão de snapshot do [SaleItem], preservando o histórico.
@freezed
abstract class PurchaseItem with _$PurchaseItem {
  const factory PurchaseItem({
    required String productId,
    required String productName,
    required int quantity,
    required double unitPrice,
  }) = _PurchaseItem;

  factory PurchaseItem.fromJson(Map<String, dynamic> json) =>
      _$PurchaseItemFromJson(json);
}

/// Entidade de domínio que representa uma compra de mercadorias de um
/// fornecedor.
///
/// Diferente da [Sale], a compra **aumenta** o estoque dos produtos e gera
/// uma **saída** no caixa (categoria "Compras") — orquestrado pelo
/// ProcessPurchaseUseCase.
@freezed
abstract class Purchase with _$Purchase {
  const factory Purchase({
    required String id,
    // Loja que realizou a compra (Fase 2 do multi-tenancy) — a entrada
    // de estoque é por loja.
    @Default('st1') String storeId,
    required String supplierName,
    required List<PurchaseItem> items,
    required double totalAmount,
    required DateTime dateTime,
  }) = _Purchase;

  factory Purchase.fromJson(Map<String, dynamic> json) =>
      _$PurchaseFromJson(json);
}
