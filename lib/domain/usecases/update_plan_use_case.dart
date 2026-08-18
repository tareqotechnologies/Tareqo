import '../entities/plan.dart';
import '../repositories/i_plan_repository.dart';
import 'add_plan_use_case.dart';

/// Caso de uso: atualizar um plano existente (super admin).
///
/// Aplica as mesmas validações de criação ([validatePlan]) antes de
/// persistir — sem nunca inserir (o UPDATE não deve chamar o INSERT).
class UpdatePlanUseCase {
 const UpdatePlanUseCase(this._repository);

 final IPlanRepository _repository;

 Future<void> call(Plan plan) async {
 validatePlan(plan);
 await _repository.update(plan);
 }
}
