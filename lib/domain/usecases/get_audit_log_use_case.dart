import '../entities/audit_entry.dart';
import '../repositories/i_audit_log_repository.dart';

/// Caso de uso: listar o registo de auditoria (painel do super admin).
///
/// Retorna as [limit] entradas mais recentes em ordem decrescente.
/// A RPC `get_audit_log` no banco valida `is_super_admin()`.
class GetAuditLogUseCase {
  const GetAuditLogUseCase(this._repository);

  final IAuditLogRepository _repository;

  Future<List<AuditEntry>> call({int limit = 100}) =>
      _repository.getAuditLog(limit: limit);
}
