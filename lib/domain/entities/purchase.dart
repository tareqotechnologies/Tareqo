import 'package:freezed_annotation/freezed_annotation.dart';

import 'sale.dart' show PaymentMethod;

part 'purchase.freezed.dart';
part 'purchase.g.dart';

/// Item de compra: "fotografia" do produto no momento da compra.
///
/// [quantity] está em MILÉSIMOS de unidade (W11 — mesma convenção da
/// [SaleItem]); [expiryDate] alimenta o lote FIFO criado na entrada.
///
/// Guarda [productName] e [unitPriceCents] (preço de compra) na data da
/// compra — mesmo padrão de snapshot do [SaleItem], preservando o
/// histórico.
@freezed
abstract class PurchaseItem with _$PurchaseItem {
 const factory PurchaseItem({
 required String productId,
 required String productName,
 // Quantidade em MILÉSIMOS de unidade (W11): 1000 = 1 unidade/kg.
 required int quantity,
 // Preço unitário de compra em CENTAVOS inteiros (W4).
 required int unitPriceCents,
 // Data de VALIDADE do lote criado por este item (W11 — FIFO).
 // `null` para produtos sem validade (não perecíveis): o lote entra no
 // FIFO pela data de ENTRADA.
 DateTime? expiryDate,
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
 // Número SEQUENCIAL da compra DENTRO da loja (ex.: C-00001, C-00002).
 // Atribuído pelo banco no insert — SQLite: MAX+1 por loja dentro da
 // transação; Supabase: RPC process_purchase com advisory lock por loja.
 // O default 0 nunca é persistido (é substituído na gravação).
 @Default(0) int number,
 // Loja que realizou a compra (Fase 2 do multi-tenancy) — a entrada
 // de estoque é por loja.
 @Default('st1') String storeId,
 required String supplierName,
 required List<PurchaseItem> items,
 // Valor TOTAL da compra em CENTAVOS inteiros (W4).
 required int totalAmountCents,
 // Forma de pagamento usada para pagar o fornecedor (mesmo enum de
 // Vendas). DEFAULT cash: compras antigas não registravam o método —
 // a migração interpreta como pagamento à vista.
 @Default(PaymentMethod.cash) PaymentMethod paymentMethod,
 required DateTime dateTime,
 }) = _Purchase;

 factory Purchase.fromJson(Map<String, dynamic> json) =>
 _$PurchaseFromJson(json);
}
