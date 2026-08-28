import '../datasources/local/audit_log_local_data_source.dart';
import '../../domain/entities/audit_entry.dart';
import '../../domain/repositories/i_audit_log_repository.dart';

/// Implementação de [IAuditLogRepository] que delega ao datasource.
///
/// No modo Supabase, o datasource é o [SupabaseAuditLogDataSourceImpl]
/// que chama a RPC `get_audit_log`. No modo local, o datasource retorna
/// lista vazia (a tabela não existe sem o banco).
final class AuditLogRepositoryImpl implements IAuditLogRepository {
  const AuditLogRepositoryImpl(this._dataSource);

  final AuditLogLocalDataSource _dataSource;

  @override
  Future<List<AuditEntry>> getAuditLog({int limit = 100}) =>
      _dataSource.getAuditLog(limit: limit);
}
