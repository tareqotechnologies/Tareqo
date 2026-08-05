import '../entities/tenant.dart';
import '../repositories/i_tenant_repository.dart';

/// Exceção de domínio: solicitação de acesso inválida.
final class InvalidTenantRequestException implements Exception {
  const InvalidTenantRequestException(this.message);

  final String message;

  @override
  String toString() => 'InvalidTenantRequestException: $message';
}

/// Caso de uso: criar a solicitação de acesso de um novo tenant.
///
/// O dono informa o nome do negócio e escolhe o plano; a solicitação nasce
/// com `status = pending`, aguardando a aprovação manual do super admin
/// (prazo de até 24h).
class RequestTenantAccessUseCase {
  const RequestTenantAccessUseCase(this._repository);

  final ITenantRepository _repository;

  Future<Tenant> call({
    required String ownerUserId,
    required String businessName,
    required String planId,
    required String currencyCode,
    required String language,
  }) async {
    if (businessName.trim().isEmpty) {
      throw const InvalidTenantRequestException(
        'Informe o nome do seu negócio.',
      );
    }
    if (planId.isEmpty) {
      throw const InvalidTenantRequestException('Escolha um plano.');
    }
    return _repository.requestAccess(
      ownerUserId: ownerUserId,
      businessName: businessName.trim(),
      planId: planId,
      currencyCode: currencyCode,
      language: language,
    );
  }
}
