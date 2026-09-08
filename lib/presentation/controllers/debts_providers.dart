import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/service_locator.dart';
import '../../domain/entities/debt.dart';
import '../../domain/repositories/i_debt_repository.dart';
import '../../domain/usecases/add_debt_use_case.dart';
import '../../domain/usecases/get_pending_debts_use_case.dart';
import '../../domain/usecases/get_settled_debts_use_case.dart';
import '../../domain/usecases/settle_debt_use_case.dart';
import 'account_providers.dart';
import 'auth_providers.dart';

/// Ponte com o ServiceLocator (GetIt).
final debtsRepositoryProvider = Provider<IDebtRepository>(
  (ref) => ServiceLocator.instance<IDebtRepository>(),
);

final getPendingDebtsUseCaseProvider = Provider<GetPendingDebtsUseCase>(
  (ref) => ServiceLocator.instance<GetPendingDebtsUseCase>(),
);

final addDebtUseCaseProvider = Provider<AddDebtUseCase>(
  (ref) => ServiceLocator.instance<AddDebtUseCase>(),
);

final getSettledDebtsUseCaseProvider = Provider<GetSettledDebtsUseCase>(
  (ref) => ServiceLocator.instance<GetSettledDebtsUseCase>(),
);

final settleDebtUseCaseProvider = Provider<SettleDebtUseCase>(
  (ref) => ServiceLocator.instance<SettleDebtUseCase>(),
);

/// Estado das dívidas a receber de clientes (\"fiado\"), por vencimento.
final pendingDebtsProvider =
    AsyncNotifierProvider<PendingDebtsNotifier, List<Debt>>(
      PendingDebtsNotifier.new,
    );

class PendingDebtsNotifier extends AsyncNotifier<List<Debt>> {
  @override
  Future<List<Debt>> build() async {
    final user = ref.watch(authStateProvider).value;
    final storeId = user == null
        ? null
        : ref.watch(activeStoreIdProvider(user.id));
    if (storeId == null) return const [];
    // Copia antes de ordenar: o caso de uso pode retornar lista imutável.
    final debts = [
      ...await ref.read(getPendingDebtsUseCaseProvider).call(storeId: storeId),
    ]..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return debts;
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

/// Estado do histórico de dívidas quitadas (mais recentes primeiro).
final settledDebtsProvider =
    AsyncNotifierProvider<SettledDebtsNotifier, List<Debt>>(
      SettledDebtsNotifier.new,
    );

class SettledDebtsNotifier extends AsyncNotifier<List<Debt>> {
  @override
  Future<List<Debt>> build() async {
    final user = ref.watch(authStateProvider).value;
    final storeId = user == null
        ? null
        : ref.watch(activeStoreIdProvider(user.id));
    if (storeId == null) return const [];
    // Mais recentes primeiro; sem data de baixa (dados antigos), usa o
    // vencimento como fallback de ordenação.
    final debts = [
      ...await ref.read(getSettledDebtsUseCaseProvider).call(storeId: storeId),
    ]..sort((a, b) => (b.paidAt ?? b.dueDate).compareTo(a.paidAt ?? a.dueDate));
    return debts;
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
