import '../entities/invoice.dart';
import '../repositories/i_invoice_repository.dart';

/// Caso de uso: listar facturas pendentes no sistema (painel do super admin).
class GetPendingInvoicesUseCase {
  const GetPendingInvoicesUseCase(this._repository);

  final IInvoiceRepository _repository;

  Future<List<Invoice>> call() => _repository.getPending();
}
