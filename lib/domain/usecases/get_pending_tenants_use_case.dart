import '../entities/tenant.dart';
import '../repositories/i_tenant_repository.dart';

/// Caso de uso: listar tenants aguardando aprovação (painel do super admin).
class GetPendingTenantsUseCase {
  const GetPendingTenantsUseCase(this._repository);

  final ITenantRepository _repository;

  Future<List<Tenant>> call() => _repository.getPending();
}
