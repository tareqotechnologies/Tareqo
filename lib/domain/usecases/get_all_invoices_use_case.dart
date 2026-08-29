import '../entities/invoice.dart';
import '../repositories/i_invoice_repository.dart';

/// Caso de uso: listar todas as facturas no sistema (painel do super admin).
class GetAllInvoicesUseCase {
  const GetAllInvoicesUseCase(this._repository);

  final IInvoiceRepository _repository;

  Future<List<Invoice>> call() => _repository.getAll();
}
