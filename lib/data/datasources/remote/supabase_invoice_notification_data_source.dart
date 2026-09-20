import '../../../domain/entities/invoice_notification.dart';
import '../local/invoice_notification_local_data_source.dart';
import 'supabase_datasource_helpers.dart';

/// Implementação remota do [InvoiceNotificationLocalDataSource] sobre o Supabase.
///
/// Notificações são criadas quando facturas são geradas e publicadas no
/// Realtime para notificação instantânea ao dono do tenant.
final class InvoiceNotificationSupabaseDataSourceImpl
    implements InvoiceNotificationLocalDataSource {
  const InvoiceNotificationSupabaseDataSourceImpl();

  static const _table = 'invoice_notifications';
  static const _columns =
      'id, tenant_id, invoice_id, type, title, body, body_params, is_read, created_at, read_at';

  @override
  Future<InvoiceNotification> create(InvoiceNotification notification) async {
    final rows = await supabaseClient
        .from(_table)
        .insert({
          'id': notification.id,
          'tenant_id': notification.tenantId,
          'invoice_id': notification.invoiceId,
          'type': notification.type.name,
          'title': notification.title,
          'body': notification.body,
          'body_params': notification.bodyParams,
          'is_read': notification.isRead,
        })
        .select(_columns);
    return _map(rows.first);
  }

  @override
  Future<List<InvoiceNotification>> getByTenant(String tenantId) async {
    final rows = await supabaseClient
        .from(_table)
        .select(_columns)
        .eq('tenant_id', tenantId)
        .order('created_at', ascending: false)
        .limit(SupabaseQueryLimits.pageSize);
    return List.unmodifiable([for (final row in rows) _map(row)]);
  }

  @override
  Future<List<InvoiceNotification>> getUnreadByTenant(String tenantId) async {
    final rows = await supabaseClient
        .from(_table)
        .select(_columns)
        .eq('tenant_id', tenantId)
        .eq('is_read', false)
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
  Future<void> markAsRead(String notificationId) async {
    final rows = await supabaseClient
        .from(_table)
        .update({
          'is_read': true,
          'read_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', notificationId)
        .select('id');
    if (rows.isEmpty) {
      throw StateError('Notificação $notificationId não encontrada.');
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

  @override
  Future<void> delete(String notificationId) async {
    final rows = await supabaseClient
        .from(_table)
        .delete()
        .eq('id', notificationId)
        .select('id');
    if (rows.isEmpty) {
      throw StateError('Notificação $notificationId não encontrada.');
    }
  }

  InvoiceNotification _map(Map<String, dynamic> row) => InvoiceNotification(
    id: row['id'] as String,
    tenantId: row['tenant_id'] as String,
    invoiceId: row['invoice_id'] as String?,
    type: InvoiceNotificationType.values.byName(row['type'] as String),
    title: row['title'] as String,
    body: row['body'] as String,
    bodyParams: (row['body_params'] as Map<String, dynamic>?)?.map(
      (key, value) => MapEntry(key, value.toString()),
    ),
    isRead: row['is_read'] as bool? ?? false,
    createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
    readAt: row['read_at'] == null
        ? null
        : DateTime.parse(row['read_at'] as String).toLocal(),
  );
}
