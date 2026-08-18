import '../repositories/i_tenant_repository.dart';

/// Caso de uso: rejeitar a solicitação de acesso de um tenant (super admin).
class RejectTenantUseCase {
 const RejectTenantUseCase(this._repository);

 final ITenantRepository _repository;

 Future<void> call(String tenantId, String reason) =>
 _repository.reject(tenantId, reason);
}
