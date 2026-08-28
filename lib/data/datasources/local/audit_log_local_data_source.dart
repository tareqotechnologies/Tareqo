import '../../../domain/entities/audit_entry.dart';

/// Contrato de acesso ao registo de auditoria (camada de dados).
///
/// No modo Supabase, a leitura é feita via RPC `get_audit_log`
/// (SECURITY DEFINER + is_super_admin). No modo local, a tabela não
/// existe e a lista é sempre vazia.
abstract interface class AuditLogLocalDataSource {
  /// Retorna as entradas mais recentes do registo de auditoria.
  Future<List<AuditEntry>> getAuditLog({int limit = 100});
}
