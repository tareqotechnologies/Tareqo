import '../entities/invoice_notification.dart';

/// Contrato de acesso a notificações de facturas (camada de domínio).
///
/// Notificações são geradas quando facturas são criadas, pagas ou expiram.
/// O dono do tenant vê as notificações no dashboard e pode marcá-las como
/// lidas.
abstract interface class IInvoiceNotificationRepository {
  /// Cria uma nova notificação.
  Future<InvoiceNotification> create(InvoiceNotification notification);

  /// Retorna todas as notificações de um tenant (ordenadas por data desc).
  Future<List<InvoiceNotification>> getByTenant(String tenantId);

  /// Retorna notificações não lidas de um tenant.
  Future<List<InvoiceNotification>> getUnreadByTenant(String tenantId);

  /// Retorna a contagem de notificações não lidas de um tenant.
  Future<int> getUnreadCount(String tenantId);

  /// Marca uma notificação como lida.
  Future<void> markAsRead(String notificationId);

  /// Marca todas as notificações de um tenant como lidas.
  Future<void> markAllAsRead(String tenantId);

  /// Elimina uma notificação.
  Future<void> delete(String notificationId);
}
