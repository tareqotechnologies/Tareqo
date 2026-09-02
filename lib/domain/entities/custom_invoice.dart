import 'package:freezed_annotation/freezed_annotation.dart';

part 'custom_invoice.freezed.dart';
part 'custom_invoice.g.dart';

/// Factura personalizada gerada para um cliente.
///
/// Diferente da [Invoice] do sistema (factura de cobrança do plano), esta
/// é uma factura comercial que o lojista envia ao cliente com layout
/// customizável, logotipo e campos adicionais.
@freezed
abstract class CustomInvoice with _$CustomInvoice {
  const factory CustomInvoice({
    required String id,
    @Default(0) int number,
    required String storeId,
    /// Dados do cliente na factura (snapshot — pode não ter Customer entity).
    required String clientName,
    @Default('') String clientPhone,
    @Default('') String clientEmail,
    @Default('') String clientAddress,
    /// NIF/ NUIT do cliente (opcional).
    @Default('') String clientTaxId,
    @Default(<CustomInvoiceItem>[]) List<CustomInvoiceItem> items,
    /// Valor total em centavos.
    required int totalAmountCents,
    /// Desconto em centavos.
    @Default(0) int discountCents,
    /// Imposto (IVA) em centavos.
    @Default(0) int taxCents,
    /// Notas visíveis ao cliente (rodapé da factura).
    @Default('') String notes,
    /// Forma de pagamento registada.
    @Default('') String paymentMethod,
    /// Referência de pagamento (ex.: M-Pesa confirmation code).
    @Default('') String paymentReference,
    /// Se foi exportada/exportável como PDF.
    @Default(false) bool exportedPdf,
    required DateTime createdAt,
  }) = _CustomInvoice;

  factory CustomInvoice.fromJson(Map<String, dynamic> json) =>
      _$CustomInvoiceFromJson(json);
}

/// Item de uma factura personalizada.
@freezed
abstract class CustomInvoiceItem with _$CustomInvoiceItem {
  const factory CustomInvoiceItem({
    required String productName,
    /// Quantidade em milésimos.
    required int quantity,
    /// Preço unitário em centavos.
    required int unitPriceCents,
    /// Subtotal (quantity * unitPrice) em centavos.
    required int subtotalCents,
    /// Unidade (un, kg, l, etc).
    @Default('un') String unit,
  }) = _CustomInvoiceItem;

  factory CustomInvoiceItem.fromJson(Map<String, dynamic> json) =>
      _$CustomInvoiceItemFromJson(json);
}
