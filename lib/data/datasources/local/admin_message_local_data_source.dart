import '../../../domain/entities/admin_message.dart';

/// Interface para armazenamento de mensagens admin→tenant.
///
/// Implementação remota (Supabase) no modo SaaS; local/memória em dev.
abstract class AdminMessageLocalDataSource {
  Future<AdminMessage> create(AdminMessage message);
  Future<List<AdminMessage>> getByTenant(String tenantId);
  Future<int> getUnreadCount(String tenantId);
  Future<void> markAsRead(String messageId);
  Future<void> markAllAsRead(String tenantId);
}
