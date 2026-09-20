import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/service_locator.dart';
import '../../domain/entities/admin_message.dart';
import '../../domain/usecases/send_admin_message_use_case.dart';
import '../../domain/usecases/get_tenant_admin_messages_use_case.dart';
import '../../domain/usecases/mark_admin_message_as_read_use_case.dart';
import '../../domain/usecases/mark_all_admin_messages_as_read_use_case.dart';
import 'account_providers.dart';
import 'auth_providers.dart';

// ---------------------------------------------------------------------------
// Providers de casos de uso
// ---------------------------------------------------------------------------

final sendAdminMessageUseCaseProvider = Provider<SendAdminMessageUseCase>(
  (ref) => ServiceLocator.instance<SendAdminMessageUseCase>(),
);

final getTenantAdminMessagesUseCaseProvider =
    Provider<GetTenantAdminMessagesUseCase>(
      (ref) => ServiceLocator.instance<GetTenantAdminMessagesUseCase>(),
    );

final markAdminMessageAsReadUseCaseProvider =
    Provider<MarkAdminMessageAsReadUseCase>(
      (ref) => ServiceLocator.instance<MarkAdminMessageAsReadUseCase>(),
    );

final markAllAdminMessagesAsReadUseCaseProvider =
    Provider<MarkAllAdminMessagesAsReadUseCase>(
      (ref) => ServiceLocator.instance<MarkAllAdminMessagesAsReadUseCase>(),
    );

// ---------------------------------------------------------------------------
// Estado: mensagens admin do tenant logado
// ---------------------------------------------------------------------------

final tenantAdminMessagesProvider =
    AsyncNotifierProvider<TenantAdminMessagesNotifier, List<AdminMessage>>(
      TenantAdminMessagesNotifier.new,
    );

class TenantAdminMessagesNotifier extends AsyncNotifier<List<AdminMessage>> {
  @override
  Future<List<AdminMessage>> build() async {
    final user = ref.watch(authStateProvider).value;
    if (user == null) return const [];

    final tenantAsync = ref.watch(myTenantProvider(user.id));
    final tenant = tenantAsync.value;
    if (tenant == null) return const [];

    return ref.watch(getTenantAdminMessagesUseCaseProvider).call(tenant.id);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

// ---------------------------------------------------------------------------
// Estado: contagem de mensagens não lidas do admin
// ---------------------------------------------------------------------------

/// Contagem de mensagens não lidas — derivada da FONTE ÚNICA (a lista do
/// notifier acima, que já devolve lista vazia sem sessão/tenant). Await
/// explícito no future da lista: leitura de snapshot `.value` aqui devolveria
/// 0 provisório enquanto a lista carrega (corrida que travava o teste).
final unreadAdminMessagesCountProvider = FutureProvider<int>((ref) async {
  final messages = await ref.watch(tenantAdminMessagesProvider.future);
  return messages.where((m) => !m.isRead).length;
});
