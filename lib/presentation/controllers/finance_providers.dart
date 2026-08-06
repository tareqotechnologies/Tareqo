import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/service_locator.dart';
import '../../core/utils/period_utils.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../domain/entities/financial_transaction.dart';
import '../../domain/repositories/i_financial_transaction_repository.dart';
import '../../domain/usecases/add_financial_transaction_use_case.dart';
import '../../domain/usecases/get_cash_flow_use_case.dart';
import '../../domain/usecases/mark_transaction_as_paid_use_case.dart';
import 'account_providers.dart';
import 'auth_providers.dart';

/// Período de análise do fluxo de caixa.
enum CashFlowPeriod { today, week, month, all }

extension CashFlowPeriodLabel on CashFlowPeriod {
  String label(AppLocalizations l10n) => switch (this) {
        CashFlowPeriod.today => l10n.periodToday,
        CashFlowPeriod.week => l10n.periodWeek,
        CashFlowPeriod.month => l10n.periodMonth,
        CashFlowPeriod.all => l10n.periodAll,
      };
}

/// Período selecionado na tela de Financeiro.
final cashFlowPeriodProvider =
    NotifierProvider<CashFlowPeriodNotifier, CashFlowPeriod>(
  CashFlowPeriodNotifier.new,
);

class CashFlowPeriodNotifier extends Notifier<CashFlowPeriod> {
  @override
  CashFlowPeriod build() => CashFlowPeriod.month;

  void select(CashFlowPeriod period) => state = period;
}

/// Ponte com o ServiceLocator (GetIt).
final financeRepositoryProvider = Provider<IFinancialTransactionRepository>(
  (ref) => ServiceLocator.instance<IFinancialTransactionRepository>(),
);

final getCashFlowUseCaseProvider = Provider<GetCashFlowUseCase>(
  (ref) => ServiceLocator.instance<GetCashFlowUseCase>(),
);

final addTransactionUseCaseProvider = Provider<AddFinancialTransactionUseCase>(
  (ref) => ServiceLocator.instance<AddFinancialTransactionUseCase>(),
);

/// Marca uma transação pendente como paga (botão "Receber").
final markTransactionAsPaidUseCaseProvider =
    Provider<MarkTransactionAsPaidUseCase>(
  (ref) => ServiceLocator.instance<MarkTransactionAsPaidUseCase>(),
);

/// Estado do fluxo de caixa (entradas, saídas e saldo) para o período
/// selecionado — reconstrói automaticamente quando o período muda.
final cashFlowProvider =
    AsyncNotifierProvider<CashFlowNotifier, CashFlow>(CashFlowNotifier.new);

class CashFlowNotifier extends AsyncNotifier<CashFlow> {
  @override
  Future<CashFlow> build() {
    final period = ref.watch(cashFlowPeriodProvider);
    final now = DateTime.now();
    final user = ref.watch(authStateProvider).value;
    final storeId = user == null ? null : ref.watch(activeStoreIdProvider(user.id));

    final start = switch (period) {
      // Todos os períodos alinhados ao início do dia (semântica única).
      CashFlowPeriod.today => startOfDay(now),
      CashFlowPeriod.week =>
        startOfDay(now.subtract(const Duration(days: 7))),
      CashFlowPeriod.month => DateTime(now.year, now.month, 1),
      CashFlowPeriod.all => DateTime(2000),
    };

    if (storeId == null) {
      return Future.value(const CashFlow(incomeCents: 0, expenseCents: 0));
    }

    return ref
        .read(getCashFlowUseCaseProvider)
        .call(storeId: storeId, start: start, end: now);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

/// Estado da lista de movimentações (mais recentes primeiro).
final transactionsProvider =
    AsyncNotifierProvider<TransactionsNotifier, List<FinancialTransaction>>(
  TransactionsNotifier.new,
);

class TransactionsNotifier extends AsyncNotifier<List<FinancialTransaction>> {
  @override
  Future<List<FinancialTransaction>> build() async {
    final user = ref.watch(authStateProvider).value;
    final storeId = user == null ? null : ref.watch(activeStoreIdProvider(user.id));
    if (storeId == null) return const [];
    // Copia antes de ordenar: o repositório retorna lista imutável.
    final transactions = [
      ...await ref.read(financeRepositoryProvider).getAll(storeId: storeId),
    ]..sort((a, b) => b.date.compareTo(a.date));
    return transactions;
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
