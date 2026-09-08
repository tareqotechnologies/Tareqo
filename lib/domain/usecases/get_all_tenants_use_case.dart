import '../entities/tenant.dart';
import '../repositories/i_tenant_repository.dart';

/// Caso de uso: listar todos os tenants (painel do super admin).
class GetAllTenantsUseCase {
  const GetAllTenantsUseCase(this._repository);

  final ITenantRepository _repository;

  Future<List<Tenant>> call() => _repository.getAll();
}
