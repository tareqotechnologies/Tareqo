import '../entities/plan.dart';
import '../repositories/i_plan_repository.dart';

/// Caso de uso: listar os planos ativos (para escolha no cadastro e no
/// pedido de upgrade). Ordenados por preço.
class GetPlansUseCase {
  const GetPlansUseCase(this._repository);

  final IPlanRepository _repository;

  Future<List<Plan>> call() async => _repository.getActivePlans();
}
