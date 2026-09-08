import '../../../domain/entities/plan.dart';

/// Contrato de armazenamento de planos (camada de dados).
///
/// Implementações possíveis: memória, SQLite, Supabase... O repositório
/// depende desta abstração, e não de uma implementação.
abstract interface class PlanLocalDataSource {
  /// Planos ativos (ordem de preço).
  Future<List<Plan>> getActivePlans();

  /// Todos os planos, incluindo inativos (painel do super admin).
  Future<List<Plan>> getAllPlans();

  /// Plano pelo id (ou `null`).
  Future<Plan?> getById(String id);

  /// Cria um plano.
  Future<void> add(Plan plan);

  /// Atualiza um plano.
  Future<void> update(Plan plan);
}
