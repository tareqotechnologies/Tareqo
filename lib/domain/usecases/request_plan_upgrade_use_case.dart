import '../entities/plan_request.dart';
import '../entities/tenant.dart';
import '../repositories/i_plan_request_repository.dart';
import '../repositories/i_tenant_repository.dart';

/// Exceção de domínio: pedido de upgrade inválido.
final class InvalidPlanRequestException implements Exception {
  const InvalidPlanRequestException(this.message);

  final String message;

  @override
  String toString() => 'InvalidPlanRequestException: $message';
}

/// Caso de uso: solicitar upgrade de plano (dono do tenant).
///
/// Regras:
/// - o tenant precisa estar aprovado;
/// - não pode haver outro pedido `pending` do mesmo tenant;
/// - o plano solicitado deve ser diferente do atual.
class RequestPlanUpgradeUseCase {
  const RequestPlanUpgradeUseCase(
    this._planRequestRepository,
    this._tenantRepository,
  );

  final IPlanRequestRepository _planRequestRepository;
  final ITenantRepository _tenantRepository;

  Future<void> call({
    required String tenantId,
    required String currentPlanId,
    required String requestedPlanId,
  }) async {
    final tenant = await _tenantRepository.getById(tenantId);
    if (tenant == null || tenant.status != TenantStatus.approved) {
      throw const InvalidPlanRequestException(
        'Seu acesso ao ERP ainda não foi aprovado.',
      );
    }
    if (requestedPlanId == currentPlanId) {
      throw const InvalidPlanRequestException(
        'Escolha um plano diferente do atual.',
      );
    }

    final requests = await _planRequestRepository.getByTenant(tenantId);
    final hasPending =
        requests.any((request) => request.status == PlanRequestStatus.pending);
    if (hasPending) {
      throw const InvalidPlanRequestException(
        'Já existe um pedido de upgrade aguardando aprovação.',
      );
    }

    await _planRequestRepository.create(
      tenantId: tenantId,
      currentPlanId: currentPlanId,
      requestedPlanId: requestedPlanId,
    );
  }
}
