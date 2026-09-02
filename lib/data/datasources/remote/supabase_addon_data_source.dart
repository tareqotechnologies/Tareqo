import '../../../domain/entities/addon.dart';
import '../local/addon_local_data_source.dart';
import 'supabase_datasource_helpers.dart';

/// Implementação remota do [AddOnLocalDataSource] sobre o Supabase.
///
/// Tabela: `tenant_addons` (tenant_id, add_on_id, activated_at,
/// expires_at, is_active). RLS: cada tenant só vê os seus próprios
/// add-ons.
final class SupabaseAddOnDataSourceImpl implements AddOnLocalDataSource {
  const SupabaseAddOnDataSourceImpl();

  static const _table = 'tenant_addons';
  static const _columns =
      'id, tenant_id, add_on_id, activated_at, expires_at, is_active';

  @override
  Future<Set<String>> getActiveAddOnIds(String tenantId) async {
    final rows = await supabaseClient
        .from(_table)
        .select(_columns)
        .eq('tenant_id', tenantId)
        .eq('is_active', true)
        .limit(SupabaseQueryLimits.pageSize);

    // Filtrar expirados.
    final now = DateTime.now();
    return Set.unmodifiable(
      rows.where((row) {
        final expiresAt = row['expires_at'] as String?;
        if (expiresAt != null) {
          return DateTime.parse(expiresAt).isAfter(now);
        }
        return true;
      }).map((row) => row['add_on_id'] as String),
    );
  }

  @override
  Future<void> activate(String tenantId, String addOnId) async {
    // Upsert: se já existe, re-activa; senão, insere.
    await supabaseClient.from(_table).upsert({
      'tenant_id': tenantId,
      'add_on_id': addOnId,
      'activated_at': DateTime.now().toUtc().toIso8601String(),
      'is_active': true,
    }, onConflict: 'tenant_id,add_on_id');
  }

  @override
  Future<void> deactivate(String tenantId, String addOnId) async {
    await supabaseClient
        .from(_table)
        .update({'is_active': false})
        .eq('tenant_id', tenantId)
        .eq('add_on_id', addOnId);
  }

  @override
  Future<void> register({
    required String tenantId,
    required String addOnId,
    DateTime? expiresAt,
  }) async {
    await supabaseClient.from(_table).insert({
      'tenant_id': tenantId,
      'add_on_id': addOnId,
      'activated_at': DateTime.now().toUtc().toIso8601String(),
      'expires_at': expiresAt?.toUtc().toIso8601String(),
      'is_active': true,
    });
  }

  @override
  Future<bool> isActive(String tenantId, String addOnId) async {
    final row = await supabaseClient
        .from(_table)
        .select(_columns)
        .eq('tenant_id', tenantId)
        .eq('add_on_id', addOnId)
        .maybeSingle();

    if (row == null || row['is_active'] != true) return false;

    final expiresAt = row['expires_at'] as String?;
    if (expiresAt != null && DateTime.now().isAfter(DateTime.parse(expiresAt))) {
      return false;
    }
    return true;
  }

  @override
  Future<List<TenantAddOn>> getByTenant(String tenantId) async {
    final rows = await supabaseClient
        .from(_table)
        .select(_columns)
        .eq('tenant_id', tenantId)
        .order('activated_at', ascending: false)
        .limit(SupabaseQueryLimits.pageSize);

    return List.unmodifiable([for (final row in rows) _map(row)]);
  }

  TenantAddOn _map(Map<String, dynamic> row) => TenantAddOn(
        id: row['id'] as String,
        tenantId: row['tenant_id'] as String,
        addOnId: row['add_on_id'] as String,
        activatedAt: DateTime.parse(row['activated_at'] as String),
        expiresAt: row['expires_at'] != null
            ? DateTime.parse(row['expires_at'] as String)
            : null,
        isActive: (row['is_active'] as bool?) ?? true,
      );
}
