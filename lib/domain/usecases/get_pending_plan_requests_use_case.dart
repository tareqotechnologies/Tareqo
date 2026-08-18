import '../entities/plan_request.dart';
import '../repositories/i_plan_request_repository.dart';

/// Caso de uso: listar pedidos de upgrade aguardando decisão (super admin).
class GetPendingPlanRequestsUseCase {
 const GetPendingPlanRequestsUseCase(this._repository);

 final IPlanRequestRepository _repository;

 Future<List<PlanRequest>> call() => _repository.getPending();
}
