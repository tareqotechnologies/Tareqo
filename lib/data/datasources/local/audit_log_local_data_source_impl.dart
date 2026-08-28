import '../../../domain/entities/audit_entry.dart';
import 'audit_log_local_data_source.dart';

/// Implementação em memória do [AuditLogLocalDataSource] — sem Supabase
/// não existe tabela `audit_log`, então a lista é sempre vazia.
///
/// Usada no modo LOCAL (dev) e em testes.
final class AuditLogLocalDataSourceImpl implements AuditLogLocalDataSource {
  const AuditLogLocalDataSourceImpl();

  @override
  Future<List<AuditEntry>> getAuditLog({int limit = 100}) async =>
      const [];
}
