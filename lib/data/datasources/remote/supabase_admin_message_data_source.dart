import '../../../domain/entities/admin_message.dart';
import '../local/admin_message_local_data_source.dart';
import 'supabase_datasource_helpers.dart';

/// Implementação remota do [AdminMessageLocalDataSource] sobre o Supabase.
///
/// Mensagens são criadas pelo super admin e publicadas no Realtime
/// para notificação instantânea ao dono do tenant.
final class AdminMessageSupabaseDataSourceImpl
    implements AdminMessageLocalDataSource {
  const AdminMessageSupabaseDataSourceImpl();

  static const _table = 'admin_messages';
  static const _columns =
      'id, tenant_id, type, title, body, is_read, created_at, read_at';

  @override
  Future<AdminMessage> create(AdminMessage message) async {
    final rows = await supabaseClient
        .from(_table)
        .insert({
          'id': message.id,
          'tenant_id': message.tenantId,
          'type': message.type.name,
          'title': message.title,
          'body': message.body,
        })
        .select(_columns);
    return _map(rows.first);
  }

  @override
  Future<List<AdminMessage>> getByTenant(String tenantId) async {
    final rows = await supabaseClient
        .from(_table)
        .select(_columns)
        .eq('tenant_id', tenantId)
        .order('created_at', ascending: false)
        .limit(SupabaseQueryLimits.pageSize);
    return List.unmodifiable([for (final row in rows) _map(row)]);
  }

  @override
  Future<int> getUnreadCount(String tenantId) async {
    final rows = await supabaseClient
        .from(_table)
        .select('id')
        .eq('tenant_id', tenantId)
        .eq('is_read', false);
    return rows.length;
  }

  @override
  Future<void> markAsRead(String messageId) async {
    final rows = await supabaseClient
        .from(_table)
        .update({
          'is_read': true,
          'read_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', messageId)
        .select('id');
    if (rows.isEmpty) {
      throw StateError('Mensagem $messageId não encontrada.');
    }
  }

  @override
  Future<void> markAllAsRead(String tenantId) async {
    await supabaseClient
        .from(_table)
        .update({
          'is_read': true,
          'read_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('tenant_id', tenantId)
        .eq('is_read', false);
  }

  AdminMessage _map(Map<String, dynamic> row) => AdminMessage(
        id: row['id'] as String,
        tenantId: row['tenant_id'] as String,
        type: AdminMessageType.values.byName(row['type'] as String),
        title: row['title'] as String,
        body: row['body'] as String,
        isRead: row['is_read'] as bool? ?? false,
        createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
        readAt: row['read_at'] == null
            ? null
            : DateTime.parse(row['read_at'] as String).toLocal(),
      );
}
