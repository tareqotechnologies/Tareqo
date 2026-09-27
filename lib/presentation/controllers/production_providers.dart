import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/service_locator.dart';
import '../../domain/entities/production_order.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/usecases/process_production_use_case.dart';
import '../../domain/usecases/production_use_cases.dart';
import 'account_providers.dart';
import 'auth_providers.dart';

/// Ponte com o ServiceLocator (GetIt) — casos de uso da produção (Fase 2).
final getRecipesUseCaseProvider = Provider<GetRecipesUseCase>(
  (ref) => ServiceLocator.instance<GetRecipesUseCase>(),
);

final getProductionOrdersUseCaseProvider = Provider<GetProductionOrdersUseCase>(
  (ref) => ServiceLocator.instance<GetProductionOrdersUseCase>(),
);

final saveRecipeUseCaseProvider = Provider<SaveRecipeUseCase>(
  (ref) => ServiceLocator.instance<SaveRecipeUseCase>(),
);

final deleteRecipeUseCaseProvider = Provider<DeleteRecipeUseCase>(
  (ref) => ServiceLocator.instance<DeleteRecipeUseCase>(),
);

final processProductionUseCaseProvider = Provider<ProcessProductionUseCase>(
  (ref) => ServiceLocator.instance<ProcessProductionUseCase>(),
);

/// Estado das fichas técnicas da loja ativa.
final recipesProvider = AsyncNotifierProvider<RecipesNotifier, List<Recipe>>(
  RecipesNotifier.new,
);

class RecipesNotifier extends AsyncNotifier<List<Recipe>> {
  @override
  Future<List<Recipe>> build() async {
    final user = ref.watch(authStateProvider).value;
    final storeId = user == null
        ? null
        : ref.watch(activeStoreIdProvider(user.id));
    if (storeId == null) return const [];
    return ref.read(getRecipesUseCaseProvider).call(storeId: storeId);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

/// Estado do histórico de ordens de produção da loja ativa.
final productionOrdersProvider =
    AsyncNotifierProvider<ProductionOrdersNotifier, List<ProductionOrder>>(
      ProductionOrdersNotifier.new,
    );

class ProductionOrdersNotifier extends AsyncNotifier<List<ProductionOrder>> {
  @override
  Future<List<ProductionOrder>> build() async {
    final user = ref.watch(authStateProvider).value;
    final storeId = user == null
        ? null
        : ref.watch(activeStoreIdProvider(user.id));
    if (storeId == null) return const [];
    final orders = [
      ...await ref
          .read(getProductionOrdersUseCaseProvider)
          .call(storeId: storeId),
    ]..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return orders;
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
