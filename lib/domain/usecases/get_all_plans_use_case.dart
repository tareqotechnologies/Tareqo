import '../entities/plan.dart';
import '../repositories/i_plan_repository.dart';

/// Caso de uso: listar todos os planos, incluindo inativos (painel do
/// super admin — gestão de planos).
class GetAllPlansUseCase {
  const GetAllPlansUseCase(this._repository);

  final IPlanRepository _repository;

  Future<List<Plan>> call() => _repository.getAllPlans();
}
