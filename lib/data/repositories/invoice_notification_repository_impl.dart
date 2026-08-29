import '../../domain/entities/invoice_notification.dart';
import '../../domain/repositories/i_invoice_notification_repository.dart';
import '../datasources/local/invoice_notification_local_data_source.dart';

/// Implementação de [IInvoiceNotificationRepository] sobre um
/// [InvoiceNotificationLocalDataSource].
final class InvoiceNotificationRepositoryImpl
    implements IInvoiceNotificationRepository {
  const InvoiceNotificationRepositoryImpl(this._localDataSource);

  final InvoiceNotificationLocalDataSource _localDataSource;

  @override
  Future<InvoiceNotification> create(InvoiceNotification notification) =>
      _localDataSource.create(notification);

  @override
  Future<List<InvoiceNotification>> getByTenant(String tenantId) =>
      _localDataSource.getByTenant(tenantId);

  @override
  Future<List<InvoiceNotification>> getUnreadByTenant(String tenantId) =>
      _localDataSource.getUnreadByTenant(tenantId);

  @override
  Future<int> getUnreadCount(String tenantId) =>
      _localDataSource.getUnreadCount(tenantId);

  @override
  Future<void> markAsRead(String notificationId) =>
      _localDataSource.markAsRead(notificationId);

  @override
  Future<void> markAllAsRead(String tenantId) =>
      _localDataSource.markAllAsRead(tenantId);

  @override
  Future<void> delete(String notificationId) =>
      _localDataSource.delete(notificationId);
}
