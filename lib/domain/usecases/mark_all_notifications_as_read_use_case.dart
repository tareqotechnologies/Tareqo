import '../repositories/i_invoice_notification_repository.dart';

/// Caso de uso: marcar todas as notificações de um tenant como lidas.
class MarkAllNotificationsAsReadUseCase {
  const MarkAllNotificationsAsReadUseCase(this._repository);

  final IInvoiceNotificationRepository _repository;

  Future<void> call(String tenantId) =>
      _repository.markAllAsRead(tenantId);
}
