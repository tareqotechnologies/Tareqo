/// Entrada do registo de auditoria — espelho da tabela `audit_log` no
/// Supabase. Cada linha representa uma ação administrativa registada por
/// triggers (`trg_audit_*`) no banco: aprovação/rejeição de tenants,
/// decisões de upgrade, alterações de planos.
///
/// Leitura apenas via RPC `get_audit_log` (exige `is_super_admin()`).
/// A tabela é append-only — ninguém escreve direto.
class AuditEntry {
  const AuditEntry({
    required this.id,
    this.actorUserId,
    required this.action,
    required this.entityType,
    this.entityId,
    this.detail,
    required this.createdAt,
  });

  /// ID sequencial (BIGSERIAL) — não é UUID.
  final int id;

  /// UUID do super admin que executou a ação (resolvido do JWT no trigger).
  final String? actorUserId;

  /// Tipo da ação: `tenant_decision`, `plan_request_decision`, `plan_change`.
  final String action;

  /// Tabela afetada: `tenants`, `plan_requests`, `plans`.
  final String entityType;

  /// ID do registro afetado (texto — compatível com PKs TEXT do schema).
  final String? entityId;

  /// Estado novo da linha (JSONB) — payload completo do registro após a
  /// mutação. Conteúdo varia conforme entityType.
  final Map<String, dynamic>? detail;

  /// Timestamp da ação (servidor).
  final DateTime createdAt;

  factory AuditEntry.fromJson(Map<String, dynamic> json) => AuditEntry(
    id: (json['id'] as num).toInt(),
    actorUserId: json['actor_user_id'] as String?,
    action: json['action'] as String,
    entityType: json['entity_type'] as String,
    entityId: json['entity_id'] as String?,
    detail: json['detail'] as Map<String, dynamic>?,
    createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'actor_user_id': actorUserId,
    'action': action,
    'entity_type': entityType,
    'entity_id': entityId,
    'detail': detail,
    'created_at': createdAt.toUtc().toIso8601String(),
  };

  /// Rótulo legível da ação para exibição na UI.
  String get actionLabel {
    switch (action) {
      case 'tenant_decision':
        return 'Tenant decision';
      case 'plan_request_decision':
        return 'Plan request decision';
      case 'plan_change':
        return 'Plan change';
      default:
        return action;
    }
  }

  /// Ícone correspondente à ação.
  String get entityTypeLabel {
    switch (entityType) {
      case 'tenants':
        return 'Tenant';
      case 'plan_requests':
        return 'Plan request';
      case 'plans':
        return 'Plan';
      default:
        return entityType;
    }
  }
}
