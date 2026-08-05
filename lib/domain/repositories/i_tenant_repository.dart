import '../entities/tenant.dart';

/// Contrato de acesso a tenants (camada de domínio).
///
/// O dono cria a solicitação (`status = pending`) e consulta o próprio
/// tenant; o super admin lista pendentes e decide (aprova/rejeita).
abstract interface class ITenantRepository {
  /// Tenant do usuário logado (como dono OU como funcionário vinculado),
  /// ou `null` se ainda não pertence a nenhum tenant.
  Future<Tenant?> getMyTenant(String userId);

  /// Retorna um tenant pelo id (dono do tenant ou super admin).
  Future<Tenant?> getById(String id);

  /// Cria a solicitação de acesso de um novo tenant (status `pending`),
  /// com as preferências do dono (moeda e idioma).
  Future<Tenant> requestAccess({
    required String ownerUserId,
    required String businessName,
    required String planId,
    required String currencyCode,
    required String language,
  });

  /// Atualiza as preferências de apresentação do tenant (moeda/idioma).
  Future<void> updateSettings(
    String id, {
    required String currencyCode,
    required String language,
  });

  /// Aprova o tenant (status `approved` + data da aprovação).
  Future<void> approve(String id);

  /// Rejeita o tenant (status `rejected` + motivo).
  Future<void> reject(String id, String reason);

  /// Troca o plano do tenant (usado ao aprovar um upgrade).
  Future<void> updatePlan(String id, String planId);

  /// Lista tenants com status `pending` (painel do super admin).
  Future<List<Tenant>> getPending();

  /// Lista todos os tenants (painel do super admin).
  Future<List<Tenant>> getAll();
}
