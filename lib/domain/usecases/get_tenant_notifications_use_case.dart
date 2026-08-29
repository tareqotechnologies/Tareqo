import '../entities/invoice_notification.dart';
import '../repositories/i_invoice_notification_repository.dart';

/// Caso de uso: listar notificações de facturas de um tenant.
class GetTenantNotificationsUseCase {
  const GetTenantNotificationsUseCase(this._repository);

  final IInvoiceNotificationRepository _repository;

  Future<List<InvoiceNotification>> call(String tenantId) =>
      _repository.getByTenant(tenantId);
}
