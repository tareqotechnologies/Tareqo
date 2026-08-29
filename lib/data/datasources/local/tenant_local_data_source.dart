import '../../../domain/entities/tenant.dart';

/// Contrato de armazenamento de tenants (camada de dados).
abstract interface class TenantLocalDataSource {
 /// Tenant do usuário — como dono (`ownerUserId`) ou como funcionário
 /// vinculado. `null` quando o usuário não pertence a nenhum tenant.
 Future<Tenant?> getMyTenant(String userId);

 /// Tenant pelo id (ou `null`).
 Future<Tenant?> getById(String id);

 /// Cria a solicitação de acesso (status `pending`) com as preferências
 /// do dono (moeda e idioma — usadas na formatação e no locale do app).
 Future<Tenant> requestAccess({
 required String ownerUserId,
 required String businessName,
 required String planId,
 required String currencyCode,
 required String language,
 });

 /// Atualiza as preferências de apresentação do tenant (moeda/idioma),
 /// escolhidas pelo dono em Lojas → Ajustes.
 Future<void> updateSettings(
 String id, {
 required String currencyCode,
 required String language,
 });

 /// Aprova o tenant.
 Future<void> approve(String id);

 /// Rejeita o tenant com motivo.
 Future<void> reject(String id, String reason);

 /// Troca o plano do tenant.
 Future<void> updatePlan(String id, String planId);

 /// Tenants pendentes (super admin).
 Future<List<Tenant>> getPending();  /// Todos os tenants (super admin).
  Future<List<Tenant>> getAll();

  /// Actualiza os campos de facturacao do tenant.
  Future<void> updateBilling(
    String id, {
    required DateTime planExpiresAt,
    required DateTime nextInvoiceAt,
  });
}
