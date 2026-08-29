import '../../../domain/entities/invoice_notification.dart';

/// Contrato de armazenamento de notificações de facturas (camada de dados).
abstract interface class InvoiceNotificationLocalDataSource {
  /// Cria uma nova notificação.
  Future<InvoiceNotification> create(InvoiceNotification notification);

  /// Notificações de um tenant (ordenadas por data desc).
  Future<List<InvoiceNotification>> getByTenant(String tenantId);

  /// Notificações não lidas de um tenant.
  Future<List<InvoiceNotification>> getUnreadByTenant(String tenantId);

  /// Contagem de não lidas.
  Future<int> getUnreadCount(String tenantId);

  /// Marca como lida.
  Future<void> markAsRead(String notificationId);

  /// Marca todas como lidas.
  Future<void> markAllAsRead(String tenantId);

  /// Elimina uma notificação.
  Future<void> delete(String notificationId);
}
