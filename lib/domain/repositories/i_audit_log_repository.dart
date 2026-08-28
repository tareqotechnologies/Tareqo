import '../entities/audit_entry.dart';

/// Contrato de acesso ao registo de auditoria (camada de domínio).
///
/// A leitura é restrita ao super admin — a RPC `get_audit_log` no banco
/// valida `is_super_admin()` antes de retornar dados. A tabela
/// `audit_log` é append-only (escrita exclusiva por triggers no banco).
abstract interface class IAuditLogRepository {
  /// Retorna as entradas mais recentes do registo de auditoria.
  ///
  /// [limit] controla quantas entradas são retornadas (default 100,
  /// máximo 500). Ordem decrescente por ID (mais recente primeiro).
  Future<List<AuditEntry>> getAuditLog({int limit = 100});
}
