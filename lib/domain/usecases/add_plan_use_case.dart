import '../entities/plan.dart';
import '../repositories/i_plan_repository.dart';

/// Exceção de domínio: plano inválido.
final class InvalidPlanException implements Exception {
  const InvalidPlanException(this.message);

  final String message;

  @override
  String toString() => 'InvalidPlanException: $message';
}

/// Caso de uso: criar um plano (super admin).
///
/// Valida nome e limites estruturais antes de persistir.
class AddPlanUseCase {
  const AddPlanUseCase(this._repository);

  final IPlanRepository _repository;

  Future<void> call(Plan plan) async {
    if (plan.name.trim().isEmpty) {
      throw const InvalidPlanException('Informe o nome do plano.');
    }
    if (plan.maxStores < 1) {
      throw const InvalidPlanException(
        'O plano deve permitir ao menos 1 loja.',
      );
    }
    if (plan.maxEmployees < 1) {
      throw const InvalidPlanException(
        'O plano deve permitir ao menos 1 funcionário.',
      );
    }
    if (plan.priceMonthlyCents < 0) {
      throw const InvalidPlanException('O preço não pode ser negativo.');
    }
    await _repository.add(plan);
  }
}
