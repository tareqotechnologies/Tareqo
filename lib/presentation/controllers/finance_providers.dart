import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/service_locator.dart';
import '../../core/utils/app_clock.dart';
import '../../core/utils/period_utils.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../domain/entities/financial_transaction.dart';
import '../../domain/repositories/i_cash_closing_repository.dart';
import '../../domain/repositories/i_financial_transaction_repository.dart';
import '../../domain/usecases/add_financial_transaction_use_case.dart';
import '../../domain/usecases/close_cash_register_use_case.dart';
import '../../domain/usecases/get_cash_closing_summary_use_case.dart';
import '../../domain/usecases/get_cash_flow_use_case.dart';
import '../../domain/usecases/mark_transaction_as_paid_use_case.dart';
import '../../domain/entities/cash_closing.dart';
import 'account_providers.dart';
import 'auth_providers.dart';

/// Período de análise do fluxo de caixa.
enum CashFlowPeriod { today, week, month, all }

/// Início do PERIODO (inclusive) — REGRA ÚNICA para dashboard/financeiro.
///
/// Substitui as 4 cópias do switch `CashFlowPeriod → DateTime` que
/// existiam em `finance_providers` (x1), `dashboard_providers` (x2) e
/// `dashboard_screen` (x1) — cópias essas que já haviam divergido no
/// Uso do relógio ([AppClock.now] vs `DateTime.now()`).
extension CashFlowPeriodStart on CashFlowPeriod {
  /// Início do período (inclusive): hoje → [startOfDay]; semana → 7 dias
  /// atrás alinhado ao início do dia; mês → dia 1 do mês; tudo → 2000.
  DateTime startOf(DateTime now) {
    final todayStart = startOfDay(now);
    return switch (this) {
      CashFlowPeriod.today => todayStart,
      CashFlowPeriod.week => todayStart.subtract(const Duration(days: 7)),
      CashFlowPeriod.month => DateTime(now.year, now.month, 1),
      CashFlowPeriod.all => DateTime(2000),
    };
  }

  /// Início do período ANTERIOR (para o delta "+18%" do dashboard);
  /// `null` em `all` (não há "tudo anterior").
  DateTime? previousStartOf(DateTime now) {
    final todayStart = startOfDay(now);
    return switch (this) {
      CashFlowPeriod.today => todayStart.subtract(const Duration(days: 1)),
      CashFlowPeriod.week => todayStart.subtract(const Duration(days: 14)),
      CashFlowPeriod.month => DateTime(now.year, now.month - 1, 1),
      CashFlowPeriod.all => null,
    };
  }
}

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

/// Ponte com o ServiceLocator: use cases do fecho de caixa (Z-report).
/// O repositório também ganha um bridge (padrão do financeRepositoryProvider)
/// — o histórico o usa via `ref.watch`, permitindo override em testes.
final cashClosingRepositoryProvider = Provider<ICashClosingRepository>(
  (ref) => ServiceLocator.instance<ICashClosingRepository>(),
);

final getCashClosingSummaryUseCaseProvider =
    Provider<GetCashClosingSummaryUseCase>(
      (ref) => ServiceLocator.instance<GetCashClosingSummaryUseCase>(),
    );

final closeCashRegisterUseCaseProvider = Provider<CloseCashRegisterUseCase>(
  (ref) => ServiceLocator.instance<CloseCashRegisterUseCase>(),
);

/// Fecho de caixa é operação GERENCIAL (dono/gerente) — mesma matriz da
/// anulação de venda e das compras. O servidor (RPC close_cash_register)
/// é a autoridade; este provider só orienta a navegação/UX.
final canCloseCashRegisterProvider = Provider<bool>((ref) {
  final access = ref.watch(currentAccessLevelProvider);
  return access == UserAccessLevel.owner || access == UserAccessLevel.manager;
});

/// Fecho de caixa do DIA atual da loja ativa: resumo do dia (vendas por
/// forma, total, esperado na gaveta) + fecho já registrado (se houver).
/// `null` enquanto a loja não estiver resolvida.
final cashClosingSummaryProvider =
    FutureProvider.autoDispose<CashClosingSummary?>((ref) async {
      final user = ref.watch(authStateProvider).value;
      if (user == null) return null;
      final storeId = ref.watch(activeStoreIdProvider(user.id));
      if (storeId == null) return null;
      return ref
          .read(getCashClosingSummaryUseCaseProvider)
          .call(storeId: storeId, day: DateTime.now());
    });

/// Histórico de fechos da loja ativa (mais recentes primeiro).
final cashClosingHistoryProvider =
    FutureProvider.autoDispose<List<CashClosing>?>((ref) async {
      final user = ref.watch(authStateProvider).value;
      if (user == null) return null;
      final storeId = ref.watch(activeStoreIdProvider(user.id));
      if (storeId == null) return null;
      return ref.read(cashClosingRepositoryProvider).getAll(storeId: storeId);
    });

/// Estado do fluxo de caixa (entradas, saídas e saldo) para o período
/// selecionado — reconstrói automaticamente quando o período muda.
final cashFlowProvider = AsyncNotifierProvider<CashFlowNotifier, CashFlow>(
  CashFlowNotifier.new,
);

class CashFlowNotifier extends AsyncNotifier<CashFlow> {
  @override
  Future<CashFlow> build() {
    final period = ref.watch(cashFlowPeriodProvider);
    // AppClock (relógio injetável nos testes) — é a regra do projeto para
    // código de UI (ver core/utils/app_clock.dart).
    final now = AppClock.now();
    final user = ref.watch(authStateProvider).value;
    final storeId = user == null
        ? null
        : ref.watch(activeStoreIdProvider(user.id));

    final start = period.startOf(now);

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
    final storeId = user == null
        ? null
        : ref.watch(activeStoreIdProvider(user.id));
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

/// Movimentações recortadas pelo PERÍODO selecionado — mesmo recorte do
/// fluxo de caixa (ver [CashFlowPeriodStart.startOf]), para que a lista
/// "Movimentos do período" acompanhe o seletor em vez de mostrar sempre o
/// histórico completo.
final periodTransactionsProvider =
    Provider<AsyncValue<List<FinancialTransaction>>>((ref) {
      final start = ref.watch(cashFlowPeriodProvider).startOf(AppClock.now());
      return ref
          .watch(transactionsProvider)
          .whenData(
            (all) => [
              for (final transaction in all)
                if (!transaction.date.isBefore(start)) transaction,
            ],
          );
    });
