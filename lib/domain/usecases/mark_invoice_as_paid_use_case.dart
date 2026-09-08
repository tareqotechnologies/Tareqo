import '../repositories/i_invoice_repository.dart';

/// Caso de uso: marcar uma factura como paga (super admin).
///
/// Chamado quando o tenant confirma o pagamento ou quando o super admin
/// regista manualmente o recebimento.
class MarkInvoiceAsPaidUseCase {
  const MarkInvoiceAsPaidUseCase(this._repository);

  final IInvoiceRepository _repository;

  Future<void> call(String invoiceId) => _repository.markAsPaid(invoiceId);
}
