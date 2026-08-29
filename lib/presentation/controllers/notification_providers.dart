import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/service_locator.dart';
import '../../domain/entities/invoice_notification.dart';
import '../../domain/usecases/get_tenant_notifications_use_case.dart';
import '../../domain/usecases/mark_notification_as_read_use_case.dart';
import '../../domain/usecases/mark_all_notifications_as_read_use_case.dart';
import '../../domain/usecases/notify_invoice_generated_use_case.dart';
import 'account_providers.dart';
import 'auth_providers.dart';

/// Ponte com o ServiceLocator: casos de uso de notificações como providers.
final getTenantNotificationsUseCaseProvider =
    Provider<GetTenantNotificationsUseCase>(
  (ref) => ServiceLocator.instance<GetTenantNotificationsUseCase>(),
);

final markNotificationAsReadUseCaseProvider =
    Provider<MarkNotificationAsReadUseCase>(
  (ref) => ServiceLocator.instance<MarkNotificationAsReadUseCase>(),
);

final markAllNotificationsAsReadUseCaseProvider =
    Provider<MarkAllNotificationsAsReadUseCase>(
  (ref) => ServiceLocator.instance<MarkAllNotificationsAsReadUseCase>(),
);

final notifyInvoiceGeneratedUseCaseProvider =
    Provider<NotifyInvoiceGeneratedUseCase>(
  (ref) => ServiceLocator.instance<NotifyInvoiceGeneratedUseCase>(),
);

/// Estado: notificações do tenant logado.
final tenantNotificationsProvider = AsyncNotifierProvider<
    TenantNotificationsNotifier, List<InvoiceNotification>>(
  TenantNotificationsNotifier.new,
);

class TenantNotificationsNotifier
    extends AsyncNotifier<List<InvoiceNotification>> {
  @override
  Future<List<InvoiceNotification>> build() async {
    final user = ref.watch(authStateProvider).value;
    if (user == null) return const [];

    // Usa o myTenantProvider existente para obter o tenantId.
    final tenantAsync = ref.watch(myTenantProvider(user.id));
    final tenant = tenantAsync.value;
    if (tenant == null) return const [];

    return ref
        .watch(getTenantNotificationsUseCaseProvider)
        .call(tenant.id);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

/// Estado: contagem de notificações não lidas do tenant logado.
final unreadNotificationsCountProvider =
    FutureProvider<int>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return 0;

  // Usa o myTenantProvider existente para obter o tenantId.
  final tenantAsync = ref.watch(myTenantProvider(user.id));
  final tenant = tenantAsync.value;
  if (tenant == null) return 0;

  final notifications =
      ref.watch(tenantNotificationsProvider).value ?? const [];
  return notifications.where((n) => !n.isRead).length;
});
