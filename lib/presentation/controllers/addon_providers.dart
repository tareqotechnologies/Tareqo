import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/service_locator.dart';
import '../../data/datasources/local/addon_catalog.dart';
import '../../data/datasources/local/addon_local_data_source.dart';
import '../../domain/entities/addon.dart';
import '../../domain/repositories/i_addon_repository.dart';
import 'account_providers.dart';
import 'auth_providers.dart';

/// Lista de todos os add-ons disponíveis no catálogo.
final addOnCatalogProvider = Provider<List<AddOn>>((ref) {
  return AddOnCatalog.addOns();
});

/// Repositório do catálogo de add-ons (seed + overrides do banco) —
/// substituível em testes.
final addOnRepositoryProvider = Provider<IAddOnRepository>((ref) {
  return ServiceLocator.instance<IAddOnRepository>();
});

/// Catálogo EFECTIVO de add-ons: seed estático mesclado com os overrides
/// persistidos (`add_ons` — preço mensal editado pelo super admin).
/// Fallback: se o banco falhar/estiver vazio, mantém o seed — nunca vazio.
final allAddOnsProvider = AsyncNotifierProvider<AllAddOnsNotifier, List<AddOn>>(
  AllAddOnsNotifier.new,
);

class AllAddOnsNotifier extends AsyncNotifier<List<AddOn>> {
  @override
  Future<List<AddOn>> build() => ref.watch(addOnRepositoryProvider).all();

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  /// Persiste o novo preço mensal (CENTAVOS) de um add-on e actualiza o
  /// estado local imediatamente (a UI reflete sem recarregar o banco).
  Future<void> updatePrice(String addOnId, int priceMonthlyCents) async {
    await ref
        .read(addOnRepositoryProvider)
        .updatePrice(addOnId, priceMonthlyCents);
    final current = state.value ?? const <AddOn>[];
    state = AsyncValue.data([
      for (final addon in current)
        addon.id == addOnId
            ? addon.copyWith(priceMonthlyCents: priceMonthlyCents)
            : addon,
    ]);
  }
}

/// DataSource de add-ons — injeta via ServiceLocator (Supabase ou local).
final addOnDataSourceProvider = Provider<AddOnLocalDataSource>((ref) {
  return ServiceLocator.instance<AddOnLocalDataSource>();
});

/// IDs dos add-ons activos no tenant actual — lidos do banco (Supabase)
/// ou em memória (modo local/testes).
///
/// Auto-dispose: quando o tenant muda (login/logout), o estado é limpo.
final activeAddOnIdsProvider =
    AsyncNotifierProvider<ActiveAddOnsNotifier, Set<String>>(
      ActiveAddOnsNotifier.new,
    );

class ActiveAddOnsNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async {
    final user = ref.watch(authStateProvider).value;
    if (user == null) return {};

    final tenant = ref.watch(myTenantProvider(user.id)).value;
    if (tenant == null) return {};

    final ds = ref.watch(addOnDataSourceProvider);
    return ds.getActiveAddOnIds(tenant.id);
  }

  /// Activa um add-on e persiste no banco.
  Future<void> activate(String addOnId) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final tenant = ref.read(myTenantProvider(user.id)).value;
    if (tenant == null) return;

    final ds = ref.read(addOnDataSourceProvider);
    await ds.activate(tenant.id, addOnId);

    // Refrescar o estado.
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return ds.getActiveAddOnIds(tenant.id);
    });
  }

  /// Desactiva um add-on e persiste no banco.
  Future<void> deactivate(String addOnId) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final tenant = ref.read(myTenantProvider(user.id)).value;
    if (tenant == null) return;

    final ds = ref.read(addOnDataSourceProvider);
    await ds.deactivate(tenant.id, addOnId);

    // Refrescar o estado.
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return ds.getActiveAddOnIds(tenant.id);
    });
  }

  /// Toggle: activa se inactivo, desactiva se activo.
  Future<void> toggle(String addOnId) async {
    final current = state.value ?? {};
    if (current.contains(addOnId)) {
      await deactivate(addOnId);
    } else {
      await activate(addOnId);
    }
  }
}

/// Verifica se um add-on está activo.
final isAddOnActiveProvider = Provider.family<bool, String>((ref, addOnId) {
  final activeIds = ref.watch(activeAddOnIdsProvider).value ?? {};
  return activeIds.contains(addOnId);
});

/// IDs dos add-ons activos de um tenant específico (usado no painel admin
/// para mostrar a contagem de add-ons activos no card do tenant).
final tenantActiveAddOnIdsProvider = FutureProvider.family<Set<String>, String>(
  (ref, tenantId) async {
    final ds = ref.watch(addOnDataSourceProvider);
    return ds.getActiveAddOnIds(tenantId);
  },
);
