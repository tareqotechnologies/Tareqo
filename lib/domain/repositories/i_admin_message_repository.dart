import '../entities/admin_message.dart';

/// Repositório de mensagens admin→tenant.
abstract class IAdminMessageRepository {
  Future<AdminMessage> create(AdminMessage message);
  Future<List<AdminMessage>> getByTenant(String tenantId);
  Future<int> getUnreadCount(String tenantId);
  Future<void> markAsRead(String messageId);
  Future<void> markAllAsRead(String tenantId);
}
