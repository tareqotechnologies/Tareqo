import '../entities/payment_reconciliation.dart';

/// Caso de uso para registar uma transacção mobile money recebida.
class RegisterMobileMoneyPaymentUseCase {
  const RegisterMobileMoneyPaymentUseCase();

  PaymentReconciliation call({
    required MobileMoneyProvider provider,
    required String phone,
    required int amountCents,
    String confirmationCode = '',
    String saleId = '',
    String quotationId = '',
    String customInvoiceId = '',
    String notes = '',
    String rawData = '',
  }) {
    return PaymentReconciliation(
      id: '', // Atribuído pelo banco
      provider: provider,
      phone: phone,
      amountCents: amountCents,
      confirmationCode: confirmationCode,
      saleId: saleId.isNotEmpty ? saleId : null,
      quotationId: quotationId.isNotEmpty ? quotationId : null,
      customInvoiceId: customInvoiceId.isNotEmpty ? customInvoiceId : null,
      notes: notes,
      rawData: rawData,
      createdAt: DateTime.now(),
    );
  }
}

/// Caso de uso para reconciliar (confirmar) uma transacção.
class ReconcilePaymentUseCase {
  const ReconcilePaymentUseCase();

  PaymentReconciliation call(PaymentReconciliation payment) {
    if (payment.status == MobileMoneyStatus.confirmed) {
      throw StateError('Esta transacção já está confirmada.');
    }

    return payment.copyWith(
      status: MobileMoneyStatus.confirmed,
      reconciledAt: DateTime.now(),
    );
  }
}

/// Caso de uso para marcar uma transacção como falhada.
class MarkPaymentFailedUseCase {
  const MarkPaymentFailedUseCase();

  PaymentReconciliation call(PaymentReconciliation payment, String reason) {
    return payment.copyWith(
      status: MobileMoneyStatus.failed,
      notes: reason,
    );
  }
}
