import '../../../domain/entities/audit_entry.dart';
import '../local/audit_log_local_data_source.dart';
import 'supabase_datasource_helpers.dart';

/// Implementação remota do [AuditLogLocalDataSource] sobre o Supabase.
///
/// A RPC `get_audit_log` é SECURITY DEFINER e valida `is_super_admin()`
/// antes de retornar dados. A tabela `audit_log` é append-only —
/// escrita exclusiva por triggers no banco.
final class SupabaseAuditLogDataSourceImpl
    implements AuditLogLocalDataSource {
  const SupabaseAuditLogDataSourceImpl();

  @override
  Future<List<AuditEntry>> getAuditLog({int limit = 100}) async {
    final safeLimit = limit.clamp(1, SupabaseQueryLimits.pageSize);
    final rows = await supabaseClient
        .rpc('get_audit_log', params: {'p_limit': safeLimit});
    return List.unmodifiable([
      for (final row in rows as List) AuditEntry.fromJson(row as Map<String, dynamic>),
    ]);
  }
}
