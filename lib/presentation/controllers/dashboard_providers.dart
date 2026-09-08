import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/service_locator.dart';
import '../../core/utils/period_utils.dart';
import '../../data/services/offline_sync_service.dart';
import '../../domain/entities/sale.dart';
import '../../domain/usecases/get_cash_flow_use_case.dart';
import '../../domain/usecases/get_dashboard_kpis_use_case.dart';
import 'account_providers.dart';
import 'auth_providers.dart';
import 'debts_providers.dart';
import 'finance_providers.dart';
import 'products_providers.dart';
import 'sales_providers.dart';

/// Ponte entre o ServiceLocator e o Riverpod para o caso de uso das KPIs.
///
/// `null` quando o use case NÃO está registado (modo local SQLite/memória
/// e testes) — o [DashboardKpisNotifier] cai no fallback client-side.
final getDashboardKpisUseCaseProvider = Provider<GetDashboardKpisUseCase?>(
  (ref) => ServiceLocator.instance.isRegistered<GetDashboardKpisUseCase>()
      ? ServiceLocator.instance<GetDashboardKpisUseCase>()
      : null,
);

/// Ponte com o ServiceLocator: serviço de sincronização offline — `null`
/// quando não registrado (modo local/testes), onde não há outbox.
final offlineSyncServiceProvider = Provider<OfflineSyncService?>(
  (ref) => ServiceLocator.instance.isRegistered<OfflineSyncService>()
      ? ServiceLocator.instance<OfflineSyncService>()
      : null,
);

/// Período do DASHBOARD (pílula "Hoje" do canvas V3) — escopo das
/// métricas Vendas/Caixa do topo da Home. Independente do período do
/// Financeiro ([cashFlowPeriodProvider]): cada tela tem o seu seletor.
final dashboardPeriodProvider =
    NotifierProvider<DashboardPeriodNotifier, CashFlowPeriod>(
      DashboardPeriodNotifier.new,
    );

class DashboardPeriodNotifier extends Notifier<CashFlowPeriod> {
  @override
  CashFlowPeriod build() => CashFlowPeriod.today;

  void select(CashFlowPeriod period) => state = period;
}

/// Fluxo de caixa do período selecionado na pílula do dashboard — a
/// métrica "Caixa" do topo da Home. Mesma semântica do Financeiro (entradas
/// − saídas PAID do período), agora escopada pelo período do dashboard.
final dashboardCashFlowProvider = FutureProvider.autoDispose<CashFlow>((
  ref,
) async {
  final period = ref.watch(dashboardPeriodProvider);
  final now = DateTime.now();
  final user = ref.watch(authStateProvider).value;
  final storeId = user == null
      ? null
      : ref.watch(activeStoreIdProvider(user.id));
  if (storeId == null) {
    return const CashFlow(incomeCents: 0, expenseCents: 0);
  }
  final start = switch (period) {
    CashFlowPeriod.today => startOfDay(now),
    CashFlowPeriod.week => startOfDay(now.subtract(const Duration(days: 7))),
    CashFlowPeriod.month => DateTime(now.year, now.month, 1),
    CashFlowPeriod.all => DateTime(2000),
  };
  return ref
      .read(getCashFlowUseCaseProvider)
      .call(storeId: storeId, start: start, end: now);
});

/// Operações pendentes de sincronização (outbox offline do modo SaaS) —
/// alimenta o banner do dashboard.
///
/// Emite a contagem ATUAL primeiro e depois as mudanças do
/// [OfflineSyncService] (enfileiramento/dreno). Sem o serviço registrado
/// (modo local/testes) vale 0 — o banner simplesmente não aparece.
final pendingOpsCountProvider = StreamProvider<int>((ref) async* {
  final sync = ref.watch(offlineSyncServiceProvider);
  if (sync == null) {
    yield 0;
    return;
  }
  yield await sync.count();
  yield* sync.countChanges;
});

/// KPIs do dashboard (escala W5):
///
/// - **Modo Supabase:** agregação no SERVIDOR — a RPC `get_dashboard_kpis`
/// devolve os 4 indicadores em UMA chamada (em vez de 4 listagens de até
/// 1000 linhas somadas no cliente; agregação exata em NUMERIC no
/// Postgres, sem teto de linhas);
/// - **Modo local:** fallback client-side idêntico ao cálculo anterior,
/// a partir dos mesmos providers (produtos, vendas, caixa e fiado).
final dashboardKpisProvider =
    AsyncNotifierProvider<DashboardKpisNotifier, DashboardKpis>(
      DashboardKpisNotifier.new,
    );

class DashboardKpisNotifier extends AsyncNotifier<DashboardKpis> {
  @override
  Future<DashboardKpis> build() {
    final user = ref.watch(authStateProvider).value;
    final storeId = user == null
        ? null
        : ref.watch(activeStoreIdProvider(user.id));
    if (storeId == null) {
      return Future.value(DashboardKpis.empty);
    }

    // Período do caixa (mesma semântica do financeiro): o período afeta
    // apenas entradas/saídas — vendas, fiado e estoque são totais da loja.
    final period = ref.watch(cashFlowPeriodProvider);
    final now = DateTime.now();
    final start = switch (period) {
      CashFlowPeriod.today => startOfDay(now),
      CashFlowPeriod.week => startOfDay(now.subtract(const Duration(days: 7))),
      CashFlowPeriod.month => DateTime(now.year, now.month, 1),
      CashFlowPeriod.all => DateTime(2000),
    };

    final useCase = ref.watch(getDashboardKpisUseCaseProvider);
    if (useCase != null) {
      // Modo SaaS (use case registado no ServiceLocator): agregação
      // server-side (UMA chamada RPC).
      return useCase.call(storeId: storeId, start: start, end: now);
    }

    // Modo local / testes (use case não registado): fallback client-side
    // (mesmos providers e mesmo cálculo em CENTAVOS do dashboard anterior).
    return _computeLocal(storeId: storeId);
  }

  Future<DashboardKpis> _computeLocal({required String storeId}) async {
    // `ref.watch(...future)` (e não `ref.read`): espera a resolução dos
    // providers subjacentes E re-executa este notifier quando eles mudam —
    // o fallback local fica automaticamente em sincronia com as listas.
    final products = await ref.watch(productsProvider.future);
    final sales = await ref.watch(salesListProvider.future);
    final cashFlow = await ref.watch(cashFlowProvider.future);
    final debts = await ref.watch(pendingDebtsProvider.future);

    // Soma em CENTAVOS inteiros (W4): int é exato — sem Money.sum/round.
    // Vendas ANULADAS não entram no total (o estorno já ajustou o caixa;
    // mesmo critério dos relatórios e da RPC get_dashboard_kpis).
    return DashboardKpis(
      totalSalesCents: sales.fold<int>(
        0,
        (sum, sale) => sale.status == SaleStatus.cancelled
            ? sum
            : sum + sale.totalAmountCents,
      ),
      cashIncomeCents: cashFlow.incomeCents,
      cashExpenseCents: cashFlow.expenseCents,
      pendingTotalCents: debts.fold<int>(
        0,
        (sum, debt) => sum + debt.amountCents,
      ),
      stockTotal: products.fold<int>(
        0,
        (sum, product) => sum + product.stockQuantity,
      ),
    );
  }

  /// Recarrega as KPIs (ex.: após registrar uma venda ou mudar o período).
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
