import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/service_locator.dart';
import '../../domain/entities/purchase.dart';
import '../../domain/usecases/add_purchase_use_case.dart';
import '../../domain/usecases/get_purchases_use_case.dart';
import 'account_providers.dart';
import 'auth_providers.dart';

/// Ponte com o ServiceLocator (GetIt).
final getPurchasesUseCaseProvider = Provider<GetPurchasesUseCase>(
 (ref) => ServiceLocator.instance<GetPurchasesUseCase>(),
);

final processPurchaseUseCaseProvider = Provider<ProcessPurchaseUseCase>(
 (ref) => ServiceLocator.instance<ProcessPurchaseUseCase>(),
);

/// Estado da lista de compras (mais recentes primeiro).
final purchasesProvider =
 AsyncNotifierProvider<PurchasesNotifier, List<Purchase>>(
 PurchasesNotifier.new,
);

class PurchasesNotifier extends AsyncNotifier<List<Purchase>> {
 @override
 Future<List<Purchase>> build() async {
 final user = ref.watch(authStateProvider).value;
 final storeId = user == null ? null : ref.watch(activeStoreIdProvider(user.id));
 if (storeId == null) return const [];
 final purchases = [
 ...await ref.read(getPurchasesUseCaseProvider).call(storeId: storeId),
 ]..sort((a, b) => b.dateTime.compareTo(a.dateTime));
 return purchases;
 }

 /// Recarrega a lista de compras (ex.: após registrar uma compra).
 Future<void> refresh() async {
 ref.invalidateSelf();
 await future;
 }
}
