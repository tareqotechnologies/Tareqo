import '../../../domain/entities/addon.dart';

/// Contrato de armazenamento de add-ons activos por tenant.
///
/// Implementações: in-memory (local/testes) e Supabase (SaaS).
abstract interface class AddOnLocalDataSource {
  /// IDs dos add-ons activos para um tenant.
  Future<Set<String>> getActiveAddOnIds(String tenantId);

  /// Activa um add-on para um tenant.
  Future<void> activate(String tenantId, String addOnId);

  /// Desactiva um add-on para um tenant.
  Future<void> deactivate(String tenantId, String addOnId);

  /// Registra um novo add-on activo com data de expiração opcional.
  Future<void> register({
    required String tenantId,
    required String addOnId,
    DateTime? expiresAt,
  });

  /// Verifica se um add-on está activo para um tenant.
  Future<bool> isActive(String tenantId, String addOnId);

  /// Lista todos os TenantAddOns de um tenant.
  Future<List<TenantAddOn>> getByTenant(String tenantId);
}
