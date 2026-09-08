import '../entities/plan_request.dart';

/// Contrato de acesso a pedidos de upgrade de plano (camada de domínio).
abstract interface class IPlanRequestRepository {
  /// Pedidos de um tenant (mais recentes primeiro).
  Future<List<PlanRequest>> getByTenant(String tenantId);

  /// Retorna um pedido pelo id.
  Future<PlanRequest?> getById(String id);

  /// Pedidos com status `pending` (painel do super admin).
  Future<List<PlanRequest>> getPending();

  /// Cria um pedido de upgrade (`status = pending`).
  Future<PlanRequest> create({
    required String tenantId,
    required String currentPlanId,
    required String requestedPlanId,
  });

  /// Decide um pedido: `approve = true` aprova (status `approved` e data
  /// da decisão); `false` rejeita.
  Future<void> decide(String id, {required bool approve});
}
