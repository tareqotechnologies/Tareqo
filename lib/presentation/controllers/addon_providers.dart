import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/local/addon_catalog.dart';
import '../../domain/entities/addon.dart';

/// Lista de todos os add-ons disponíveis no catálogo.
final addOnCatalogProvider = Provider<List<AddOn>>((ref) {
  return AddOnCatalog.addOns();
});

/// IDs dos add-ons activos no tenant actual (armazenados em memória;
/// em produção viria do banco via Supabase).
/// Para fins de demo, podemos activar/desactivar add-ons em runtime.
final activeAddOnIdsProvider =
    NotifierProvider<ActiveAddOnsNotifier, Set<String>>(
  ActiveAddOnsNotifier.new,
);

class ActiveAddOnsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void toggle(String addOnId) {
    if (state.contains(addOnId)) {
      state = {...state}..remove(addOnId);
    } else {
      state = {...state, addOnId};
    }
  }

  void activate(String addOnId) {
    state = {...state, addOnId};
  }

  void deactivate(String addOnId) {
    state = {...state}..remove(addOnId);
  }

  bool isActive(String addOnId) => state.contains(addOnId);
}

/// Verifica se um add-on está activo.
final isAddOnActiveProvider = Provider.family<bool, String>((ref, addOnId) {
  final activeIds = ref.watch(activeAddOnIdsProvider);
  return activeIds.contains(addOnId);
});
