import '../entities/plan_request.dart';
import '../repositories/i_plan_request_repository.dart';

/// Caso de uso: listar os pedidos de upgrade do tenant do dono.
class GetMyPlanRequestsUseCase {
 const GetMyPlanRequestsUseCase(this._repository);

 final IPlanRequestRepository _repository;

 Future<List<PlanRequest>> call(String tenantId) =>
 _repository.getByTenant(tenantId);
}
