import '../../../domain/entities/plan_request.dart';

/// Contrato de armazenamento de pedidos de upgrade (camada de dados).
abstract interface class PlanRequestLocalDataSource {
 /// Pedidos de um tenant (mais recentes primeiro).
 Future<List<PlanRequest>> getByTenant(String tenantId);

 /// Pedido pelo id (ou `null`).
 Future<PlanRequest?> getById(String id);

 /// Pedidos pendentes (super admin).
 Future<List<PlanRequest>> getPending();

 /// Cria um pedido (`status = pending`).
 Future<PlanRequest> create({
 required String tenantId,
 required String currentPlanId,
 required String requestedPlanId,
 });

 /// Decide um pedido (aprova ou rejeita + data da decisão).
 Future<void> decide(String id, {required bool approve});
}
