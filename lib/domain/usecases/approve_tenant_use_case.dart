import '../repositories/i_tenant_repository.dart';

/// Caso de uso: aprovar a solicitação de acesso de um tenant (super admin).
///
/// O tenant passa a `approved` e o dono ganha acesso à área de gestão.
class ApproveTenantUseCase {
 const ApproveTenantUseCase(this._repository);

 final ITenantRepository _repository;

 Future<void> call(String tenantId) => _repository.approve(tenantId);
}
