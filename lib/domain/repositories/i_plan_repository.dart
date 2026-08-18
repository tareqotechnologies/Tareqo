import '../entities/plan.dart';

/// Contrato de acesso a planos (camada de domínio).
///
/// Os planos são criados/editados pelo super admin; todos os usuários
/// logados podem listar os ativos (para escolha no cadastro/upgrade).
abstract interface class IPlanRepository {
 /// Retorna os planos ativos (ordem de preço).
 Future<List<Plan>> getActivePlans();

 /// Retorna todos os planos, incluindo inativos (painel do super admin).
 Future<List<Plan>> getAllPlans();

 /// Retorna um plano pelo id.
 Future<Plan?> getById(String id);

 /// Cria um novo plano.
 Future<void> add(Plan plan);

 /// Atualiza um plano existente.
 Future<void> update(Plan plan);
}
