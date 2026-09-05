import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/data/datasources/local/addon_local_data_source.dart';
import 'package:tareqo/data/services/addon_expiry_service.dart';
import 'package:tareqo/domain/entities/addon.dart';
import 'package:tareqo/domain/entities/invoice_notification.dart';
import 'package:tareqo/domain/repositories/i_invoice_notification_repository.dart';

/// DataSource fake — apenas [getByTenant] é usado pelo serviço; os demais
/// métodos não devem ser chamados pelos cenários em teste.
class _FakeAddOnDataSource implements AddOnLocalDataSource {
 _FakeAddOnDataSource(this.records);

 final List<TenantAddOn> records;

 @override
 Future<List<TenantAddOn>> getByTenant(String tenantId) async =>
     records.where((r) => r.tenantId == tenantId).toList();

 @override
 Future<Set<String>> getActiveAddOnIds(String tenantId) async => {};

 @override
 Future<void> activate(String tenantId, String addOnId) async {}

 @override
 Future<void> deactivate(String tenantId, String addOnId) async {}

 @override
 Future<void> register({
  required String tenantId,
  required String addOnId,
  DateTime? expiresAt,
 }) async {}

 @override
 Future<bool> isActive(String tenantId, String addOnId) async => false;

 @override
 Future<int> deactivateExpired() async => 0;

 @override
 Future<List<TenantAddOn>> getExpired() async => [];
}

class _FakeNotificationRepository implements IInvoiceNotificationRepository {
 final List<InvoiceNotification> created = [];

 @override
 Future<InvoiceNotification> create(InvoiceNotification notification) async {
  created.add(notification);
  return notification;
 }

 @override
 Future<List<InvoiceNotification>> getByTenant(String tenantId) async => [];

 @override
 Future<List<InvoiceNotification>> getUnreadByTenant(String tenantId) async =>
     [];

 @override
 Future<int> getUnreadCount(String tenantId) async => 0;

 @override
 Future<void> markAsRead(String notificationId) async {}

 @override
 Future<void> markAllAsRead(String tenantId) async {}

 @override
 Future<void> delete(String notificationId) async {}
}

void main() {
 group('AddOnExpiryService.checkAndNotifyForTenant', () {
  test('5 dias restantes → UMA notificação de aviso (não triplica)', () async {
   final notifications = _FakeNotificationRepository();
   final ds = _FakeAddOnDataSource([
    TenantAddOn(
     id: 'x',
     tenantId: 't1',
     addOnId: 'ao_custom_invoice',
     activatedAt: DateTime.now(),
     expiresAt: DateTime.now().add(const Duration(days: 5)),
     isActive: true,
    ),
   ]);
   final service = AddOnExpiryService(
    ds,
    notificationRepository: notifications,
   );

   await service.checkAndNotifyForTenant('t1');
   // Re-check imediato (periódico 30min / novo build): não duplica.
   await service.checkAndNotifyForTenant('t1');

   expect(notifications.created, hasLength(1));
   final n = notifications.created.single;
   expect(n.type, InvoiceNotificationType.addOnExpiringSoon);
   expect(n.body, contains('5 dia(s)'));
  });

  test('escalona as janelas ≤7, ≤3 e ≤1 sem duplicar a mesma janela',
      () async {
   // ≤3 dias → janela 3 (aviso único).
   final threeDays = _FakeNotificationRepository();
   final ds3 = _FakeAddOnDataSource([
    TenantAddOn(
     id: 'x',
     tenantId: 't1',
     addOnId: 'ao_quotation',
     activatedAt: DateTime.now(),
     expiresAt: DateTime.now().add(const Duration(days: 2, hours: 23)),
     isActive: true,
    ),
   ]);
   final service3 = AddOnExpiryService(ds3, notificationRepository: threeDays);
   await service3.checkAndNotifyForTenant('t1');
   await service3.checkAndNotifyForTenant('t1');
   expect(threeDays.created, hasLength(1));
   expect(threeDays.created.single.body, contains('3 dia(s)'));

   // ≤1 dia → janela 1 (nova janela = nova notificação).
   final oneDay = _FakeNotificationRepository();
   final ds1 = _FakeAddOnDataSource([
    TenantAddOn(
     id: 'x',
     tenantId: 't1',
     addOnId: 'ao_quotation',
     activatedAt: DateTime.now(),
     expiresAt: DateTime.now().add(const Duration(days: 1)),
     isActive: true,
    ),
   ]);
   final service1 = AddOnExpiryService(ds1, notificationRepository: oneDay);
   await service1.checkAndNotifyForTenant('t1');
   expect(oneDay.created, hasLength(1));
   expect(oneDay.created.single.body, contains('1 dia(s)'));
  });

  test('mais de 7 dias → ainda sem aviso', () async {
   final notifications = _FakeNotificationRepository();
   final ds = _FakeAddOnDataSource([
    TenantAddOn(
     id: 'x',
     tenantId: 't1',
     addOnId: 'ao_advanced_reports',
     activatedAt: DateTime.now(),
     expiresAt: DateTime.now().add(const Duration(days: 10)),
     isActive: true,
    ),
   ]);
   final service = AddOnExpiryService(ds, notificationRepository: notifications);

   await service.checkAndNotifyForTenant('t1');

   expect(notifications.created, isEmpty);
  });

  test('expirado mas ainda activo → notificação de expiração única', () async {
   final notifications = _FakeNotificationRepository();
   final ds = _FakeAddOnDataSource([
    TenantAddOn(
     id: 'x',
     tenantId: 't1',
     addOnId: 'ao_mobile_money',
     activatedAt: DateTime.now(),
     expiresAt: DateTime.now().subtract(const Duration(hours: 3)),
     isActive: true,
    ),
   ]);
   final service = AddOnExpiryService(ds, notificationRepository: notifications);

   await service.checkAndNotifyForTenant('t1');
   await service.checkAndNotifyForTenant('t1');

   expect(notifications.created, hasLength(1));
   expect(notifications.created.single.type, InvoiceNotificationType.addOnExpired);
   expect(notifications.created.single.body, contains('expirou'));
  });

  test('renovação com nova validade gera novos avisos (chave inclui a data)',
      () async {
   final notifications = _FakeNotificationRepository();
   final records = [
    TenantAddOn(
     id: 'x',
     tenantId: 't1',
     addOnId: 'ao_employee_mgmt',
     activatedAt: DateTime.now(),
     expiresAt: DateTime.now().add(const Duration(days: 1)),
     isActive: true,
    ),
   ];
   final ds = _FakeAddOnDataSource(records);
   final service = AddOnExpiryService(ds, notificationRepository: notifications);

   await service.checkAndNotifyForTenant('t1');
   expect(notifications.created, hasLength(1));

   // Renovação: nova validade (data diferente) → novo ciclo de avisos.
   // Dentro da janela de aviso (≤7 dias), mas noutra data.
   records[0] = records[0].copyWith(
    expiresAt: DateTime.now().add(const Duration(days: 6)),
   );
   await service.checkAndNotifyForTenant('t1');

   expect(notifications.created, hasLength(2));
   expect(
    notifications.created.last.type,
    InvoiceNotificationType.addOnExpiringSoon,
   );
  });

  test('inactivo (desactivado) não gera notificações', () async {
   final notifications = _FakeNotificationRepository();
   final ds = _FakeAddOnDataSource([
    TenantAddOn(
     id: 'x',
     tenantId: 't1',
     addOnId: 'ao_custom_invoice',
     activatedAt: DateTime.now(),
     expiresAt: DateTime.now().add(const Duration(days: 2)),
     isActive: false,
    ),
   ]);
   final service = AddOnExpiryService(ds, notificationRepository: notifications);

   await service.checkAndNotifyForTenant('t1');

   expect(notifications.created, isEmpty);
  });
 });
}
