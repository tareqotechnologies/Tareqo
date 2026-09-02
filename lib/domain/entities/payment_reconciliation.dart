import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment_reconciliation.freezed.dart';
part 'payment_reconciliation.g.dart';

/// Estado de uma transacção mobile money.
enum MobileMoneyStatus {
  pending('Pendente'),
  confirmed('Confirmada'),
  failed('Falhou'),
  reconciled('Reconciliada');

  const MobileMoneyStatus(this.label);
  final String label;
}

/// Canal de mobile money.
enum MobileMoneyProvider {
  mPesa('M-Pesa'),
  eMola('E-Mola');

  const MobileMoneyProvider(this.label);
  final String label;
}

/// Transacção de mobile money recebida e reconciliada.
@freezed
abstract class PaymentReconciliation with _$PaymentReconciliation {
  const factory PaymentReconciliation({
    required String id,
    required MobileMoneyProvider provider,
    /// Número de telefone do remetente.
    required String phone,
    /// Código de confirmação do provedor (ex.: MP123456).
    @Default('') String confirmationCode,
    /// Valor em centavos.
    required int amountCents,
    @Default(MobileMoneyStatus.pending) MobileMoneyStatus status,
    /// ID da venda associada (se reconciliada automaticamente).
    String? saleId,
    /// ID da cotação associada (se pagamento de cotação).
    String? quotationId,
    /// ID da factura associada (se pagamento de factura).
    String? customInvoiceId,
    /// Notas do operador.
    @Default('') String notes,
    /// Dados raw da notificação push/API (JSON serializado).
    @Default('') String rawData,
    required DateTime createdAt,
    DateTime? reconciledAt,
  }) = _PaymentReconciliation;

  factory PaymentReconciliation.fromJson(Map<String, dynamic> json) =>
      _$PaymentReconciliationFromJson(json);
}
