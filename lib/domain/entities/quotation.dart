import 'package:freezed_annotation/freezed_annotation.dart';

part 'quotation.freezed.dart';
part 'quotation.g.dart';

/// Estado de uma cotação/orçamento.
enum QuotationStatus {
  draft('Rascunho'),
  sent('Enviada'),
  accepted('Aceite'),
  rejected('Rejeitada'),
  expired('Expirada'),
  converted('Convertida em Venda');

  const QuotationStatus(this.label);
  final String label;
}

/// Cotação/orçamento enviado a um cliente antes da venda.
///
/// Permite ao lojista criar uma proposta comercial com itens, preços e
/// validade. O cliente pode aceitar ou rejeitar; se aceitar, a cotação
/// converte-se automaticamente numa venda.
@freezed
abstract class Quotation with _$Quotation {
  const factory Quotation({
    required String id,
    @Default(0) int number,
    required String storeId,
    required String customerId,
    required String customerName,
    @Default('') String customerPhone,
    @Default(<QuotationItem>[]) List<QuotationItem> items,
    /// Valor total em centavos.
    required int totalAmountCents,
    @Default(QuotationStatus.draft) QuotationStatus status,
    /// Desconto global em centavos (opcional).
    @Default(0) int discountCents,
    /// Notas/observações visíveis ao cliente.
    @Default('') String notes,
    /// Data de validade da cotação.
    required DateTime validUntil,
    DateTime? sentAt,
    DateTime? acceptedAt,
    DateTime? rejectedAt,
    /// ID da venda gerada quando a cotação é convertida.
    String? convertedSaleId,
    required DateTime createdAt,
  }) = _Quotation;

  factory Quotation.fromJson(Map<String, dynamic> json) =>
      _$QuotationFromJson(json);
}

/// Item de uma cotação — snapshot do produto no momento da cotação.
@freezed
abstract class QuotationItem with _$QuotationItem {
  const factory QuotationItem({
    required String productId,
    required String productName,
    /// Quantidade em milésimos (1000 = 1 unidade).
    required int quantity,
    /// Preço unitário proposto em centavos.
    required int unitPriceCents,
  }) = _QuotationItem;

  factory QuotationItem.fromJson(Map<String, dynamic> json) =>
      _$QuotationItemFromJson(json);
}
