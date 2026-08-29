import '../repositories/i_invoice_notification_repository.dart';

/// Caso de uso: marcar uma notificação como lida.
class MarkNotificationAsReadUseCase {
  const MarkNotificationAsReadUseCase(this._repository);

  final IInvoiceNotificationRepository _repository;

  Future<void> call(String notificationId) =>
      _repository.markAsRead(notificationId);
}
