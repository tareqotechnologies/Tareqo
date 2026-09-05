import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/service_locator.dart';
import '../../data/services/addon_expiry_service.dart';
import 'account_providers.dart';
import 'auth_providers.dart';

/// Verifica a expiração de add-ons e cria notificações in-app
/// sempre que o tenant é conhecido (login, refresh).
final addonExpiryCheckProvider = FutureProvider<void>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return;

  final tenant = ref.watch(myTenantProvider(user.id)).value;
  if (tenant == null) return;

  final service = ServiceLocator.instance<AddOnExpiryService>();

  // 1) Notificações ANTES da desactivação em lote: o aviso de "expirado"
  // só faz sentido enquanto o registo ainda está activo — depois da
  // desactivação a notificação perder-se-ia (e o dono não saberia que o
  // serviço parou por expiração).
  await service.checkAndNotifyForTenant(tenant.id);

  // 2) Desactivar os expirados (global, escopado por RLS no SaaS).
  await service.checkAndDeactivateExpired();
});
