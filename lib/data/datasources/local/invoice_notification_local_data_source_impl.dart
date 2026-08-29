import '../../../core/utils/ids.dart';
import '../../../domain/entities/invoice_notification.dart';
import 'invoice_notification_local_data_source.dart';

/// Implementação em memória do [InvoiceNotificationLocalDataSource].
///
/// Usada em testes e no modo local (sem Supabase). Inicia vazia por padrão.
final class InvoiceNotificationLocalDataSourceImpl
    implements InvoiceNotificationLocalDataSource {
  InvoiceNotificationLocalDataSourceImpl({List<InvoiceNotification> seed = const []})
      : _notifications = [...seed];

  final List<InvoiceNotification> _notifications;

  @override
  Future<InvoiceNotification> create(InvoiceNotification notification) async {
    final created = notification.copyWith(
      id: notification.id.isEmpty
          ? AppIds.newId('inv_notif')
          : notification.id,
    );
    _notifications.add(created);
    return created;
  }

  @override
  Future<List<InvoiceNotification>> getByTenant(String tenantId) async =>
      List.unmodifiable(
        _notifications
            .where((n) => n.tenantId == tenantId)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      );

  @override
  Future<List<InvoiceNotification>> getUnreadByTenant(String tenantId) async =>
      List.unmodifiable(
        _notifications
            .where((n) => n.tenantId == tenantId && !n.isRead)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      );

  @override
  Future<int> getUnreadCount(String tenantId) async =>
      _notifications.where((n) => n.tenantId == tenantId && !n.isRead).length;

  @override
  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index < 0) {
      throw StateError('Notificação $notificationId não encontrada.');
    }
    _notifications[index] = _notifications[index].copyWith(
      isRead: true,
      readAt: DateTime.now(),
    );
  }

  @override
  Future<void> markAllAsRead(String tenantId) async {
    for (var i = 0; i < _notifications.length; i++) {
      if (_notifications[i].tenantId == tenantId && !_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(
          isRead: true,
          readAt: DateTime.now(),
        );
      }
    }
  }

  @override
  Future<void> delete(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index < 0) {
      throw StateError('Notificação $notificationId não encontrada.');
    }
    _notifications.removeAt(index);
  }
}
