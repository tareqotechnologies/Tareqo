import '../entities/plan.dart';
import '../repositories/i_plan_repository.dart';

/// Exceção de domínio: plano inválido.
///
/// [code] identifica a variante de validação (estável, para a UI localizar
/// a mensagem); [message] permanece como fallback/legado (PT).
final class InvalidPlanException implements Exception {
  const InvalidPlanException(this.message, {this.code = ''});

  final String message;

  /// Variante: emptyName | minStores | minEmployees | negativePrice.
  final String code;

  @override
  String toString() => 'InvalidPlanException: $message';
}

/// Validações comuns de um plano (criação e edição — super admin).
///
/// Extraída para reuso: [AddPlanUseCase] (criar) e [UpdatePlanUseCase]
/// (editar) aplicam exatamente as mesmas regras antes de persistir.
void validatePlan(Plan plan) {
  if (plan.name.trim().isEmpty) {
    throw const InvalidPlanException(
      'Informe o nome do plano.',
      code: 'emptyName',
    );
  }
  if (plan.maxStores < 1) {
    throw const InvalidPlanException(
      'O plano deve permitir ao menos 1 loja.',
      code: 'minStores',
    );
  }
  if (plan.maxEmployees < 1) {
    throw const InvalidPlanException(
      'O plano deve permitir ao menos 1 funcionário.',
      code: 'minEmployees',
    );
  }
  if (plan.priceMonthlyCents < 0) {
    throw const InvalidPlanException(
      'O preço não pode ser negativo.',
      code: 'negativePrice',
    );
  }
}

/// Caso de uso: criar um plano (super admin).
///
/// Valida nome e limites estruturais antes de persistir.
class AddPlanUseCase {
  const AddPlanUseCase(this._repository);

  final IPlanRepository _repository;

  Future<void> call(Plan plan) async {
    validatePlan(plan);
    await _repository.add(plan);
  }
}
