import '../entities/plan.dart';
import '../repositories/i_plan_repository.dart';
import 'add_plan_use_case.dart';

/// Caso de uso: atualizar um plano existente (super admin).
///
/// Reutiliza as mesmas validações do [AddPlanUseCase] antes de persistir.
class UpdatePlanUseCase {
  const UpdatePlanUseCase(this._repository);

  final IPlanRepository _repository;

  Future<void> call(Plan plan) async {
    await AddPlanUseCase(_repository).call(plan);
    await _repository.update(plan);
  }
}
