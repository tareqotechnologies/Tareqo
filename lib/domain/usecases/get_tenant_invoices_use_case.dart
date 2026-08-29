import '../entities/invoice.dart';
import '../repositories/i_invoice_repository.dart';

/// Caso de uso: listar facturas de um tenant específico.
///
/// Usado pelo dono do tenant para ver o histórico de cobranças e pelo
/// super admin para verificar facturas de um tenant específico.
class GetTenantInvoicesUseCase {
  const GetTenantInvoicesUseCase(this._repository);

  final IInvoiceRepository _repository;

  Future<List<Invoice>> call(String tenantId) =>
      _repository.getByTenant(tenantId);
}
