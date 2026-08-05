import '../entities/tenant.dart';
import '../repositories/i_tenant_repository.dart';

/// Caso de uso: obter o tenant do usuário logado.
///
/// Resolve o tenant tanto quando o usuário é o **dono** quanto quando é um
/// **funcionário** vinculado a uma loja do tenant. Retorna `null` quando o
/// usuário ainda não pertence a nenhum tenant (fluxo de onboarding).
class GetMyTenantUseCase {
  const GetMyTenantUseCase(this._repository);

  final ITenantRepository _repository;

  Future<Tenant?> call(String userId) => _repository.getMyTenant(userId);
}
