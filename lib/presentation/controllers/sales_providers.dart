import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/service_locator.dart';
import '../../domain/entities/sale.dart';
import '../../domain/repositories/i_sale_repository.dart';
import '../../domain/usecases/process_sale_use_case.dart';
import 'account_providers.dart';
import 'auth_providers.dart';

/// Ponte com o ServiceLocator (GetIt): expõe o repositório de vendas como
/// provider — um único override nos testes cobre toda a cadeia.
final salesRepositoryProvider = Provider<ISaleRepository>(
  (ref) => ServiceLocator.instance<ISaleRepository>(),
);

final processSaleUseCaseProvider = Provider<ProcessSaleUseCase>(
  (ref) => ServiceLocator.instance<ProcessSaleUseCase>(),
);

/// Estado da lista de vendas (mais recentes primeiro).
final salesListProvider =
    AsyncNotifierProvider<SalesNotifier, List<Sale>>(SalesNotifier.new);

class SalesNotifier extends AsyncNotifier<List<Sale>> {
  @override
  Future<List<Sale>> build() async {
    final user = ref.watch(authStateProvider).value;
    final storeId = user == null ? null : ref.watch(activeStoreIdProvider(user.id));
    if (storeId == null) return const [];
    // Copia antes de ordenar: o repositório retorna lista imutável.
    final sales = [...await ref.read(salesRepositoryProvider).getAll(storeId: storeId)]
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return sales;
  }

  /// Recarrega a lista de vendas (ex.: após registrar uma venda).
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
