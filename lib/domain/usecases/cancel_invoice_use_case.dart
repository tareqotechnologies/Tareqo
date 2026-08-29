import '../repositories/i_invoice_repository.dart';

/// Caso de uso: cancelar uma factura (super admin).
///
/// Usado quando a factura já não é necessária ou foi gerada por erro.
class CancelInvoiceUseCase {
  const CancelInvoiceUseCase(this._repository);

  final IInvoiceRepository _repository;

  Future<void> call(String invoiceId) => _repository.cancel(invoiceId);
}
