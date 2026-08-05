import '../entities/plan_request.dart';
import '../repositories/i_plan_request_repository.dart';
import '../repositories/i_tenant_repository.dart';

/// Caso de uso: decidir um pedido de upgrade de plano (super admin).
///
/// Ao aprovar, o plano do tenant é trocado para o solicitado; ao rejeitar,
/// apenas o pedido é marcado como `rejected`. Só decide pedidos ainda
/// `pending` — decidir duas vezes é um erro de domínio.
class DecidePlanRequestUseCase {
  const DecidePlanRequestUseCase(
    this._planRequestRepository,
    this._tenantRepository,
  );

  final IPlanRequestRepository _planRequestRepository;
  final ITenantRepository _tenantRepository;

  Future<void> call(String requestId, {required bool approve}) async {
    final request = await _planRequestRepository.getById(requestId);
    if (request == null) {
      throw StateError('Pedido de upgrade não encontrado ($requestId).');
    }
    if (request.status != PlanRequestStatus.pending) {
      throw StateError(
        'Pedido $requestId já foi decidido (${request.status.name}).',
      );
    }
    await _planRequestRepository.decide(requestId, approve: approve);
    if (approve) {
      await _tenantRepository.updatePlan(
        request.tenantId,
        request.requestedPlanId,
      );
    }
  }
}
