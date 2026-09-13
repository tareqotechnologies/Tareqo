import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/data/repositories/admin_repository_impl.dart';
import 'package:tareqo/data/repositories/local_admin_repository.dart';
import 'package:tareqo/data/repositories/supabase_cash_closing_summary_repository.dart';
import 'package:tareqo/data/repositories/supabase_cash_flow_repository.dart';
import 'package:tareqo/data/repositories/supabase_dashboard_kpis_repository.dart';
import 'package:tareqo/data/repositories/supabase_employee_commission_summary_repository.dart';
import 'package:tareqo/data/repositories/supabase_sales_report_repository.dart';

import '../../helpers/supabase_test_harness.dart';

/// Sweep dos repositórios REMOTOS que faltavam: os que agregam via RPC do
/// Supabase (caminho real `supabaseClient.rpc` sobre o stub HTTP) e o
/// `LocalAdminRepository`. O mapeamento dos payloads já é conferido pelos
/// testes com RPC injetada; aqui o objetivo é exercitar o CAMINHO REAL
/// (guard de sessão + serialização da chamada + decodificação).
void main() {
  late StubSupabaseHttp stub;

  setUpAll(() async {
    stub = await initStubbedSupabase();
    await signInStubUser();
  });

  setUp(() {
    stub.handler = null;
    stub.requests.clear();
    stub.failNext = null;
  });

  group('AdminRepositoryImpl / LocalAdminRepository', () {
    test('isSuperAdmin reflete a RPC is_super_admin', () async {
      const repo = AdminRepositoryImpl();

      stub.handler = (path, request) {
        expect(path, contains('rpc/is_super_admin'));
        return FakeResponse(true);
      };
      expect(await repo.isSuperAdmin(), isTrue);

      stub.handler = (path, request) => FakeResponse(false);
      expect(await repo.isSuperAdmin(), isFalse);
    });

    test('LocalAdminRepository nunca é super admin (modo local)', () async {
      expect(await const LocalAdminRepository().isSuperAdmin(), isFalse);
    });
  });

  group('SupabaseDashboardKpisRepository.fetchKpis', () {
    const repo = SupabaseDashboardKpisRepository();

    test('mapeia a linha da RPC (centavos BIGINT → int)', () async {
      stub.handler = (path, request) {
        expect(path, contains('rpc/get_dashboard_kpis'));
        return FakeResponse([
          {
            'total_sales': 150000,
            'cash_income': 120000,
            'cash_expense': 30000,
            'pending_total': 25000,
            'stock_total': 4000,
          },
        ]);
      };

      final kpis = await repo.fetchKpis(
        storeId: 'st1',
        start: DateTime(2026, 9, 1),
        end: DateTime(2026, 9, 10),
      );

      expect(kpis.totalSalesCents, 150000);
      expect(kpis.cashIncomeCents, 120000);
      expect(kpis.cashExpenseCents, 30000);
      expect(kpis.pendingTotalCents, 25000);
      expect(kpis.stockTotal, 4000);
    });

    test('sem linhas → DashboardKpis.empty', () async {
      stub.handler = (path, request) => FakeResponse(<dynamic>[]);

      final kpis = await repo.fetchKpis(
        storeId: 'st1',
        start: DateTime(2026, 9, 1),
        end: DateTime(2026, 9, 10),
      );

      expect(kpis.totalSalesCents, 0);
      expect(kpis.stockTotal, 0);
    });
  });

  group('SupabaseCashFlowRepository.fetchCashFlow', () {
    const repo = SupabaseCashFlowRepository();

    test('mapeia income/expense da RPC', () async {
      stub.handler = (path, request) {
        expect(path, contains('rpc/get_cash_flow'));
        return FakeResponse([
          {'income_cents': 120000, 'expense_cents': 30000},
        ]);
      };

      final flow = await repo.fetchCashFlow(
        storeId: 'st1',
        start: DateTime(2026, 9, 1),
        end: DateTime(2026, 9, 10),
      );

      expect(flow.incomeCents, 120000);
      expect(flow.expenseCents, 30000);
    });

    test('sem linhas → fluxo zerado', () async {
      stub.handler = (path, request) => FakeResponse(<dynamic>[]);

      final flow = await repo.fetchCashFlow(
        storeId: 'st1',
        start: DateTime(2026, 9, 1),
        end: DateTime(2026, 9, 10),
      );

      expect(flow.incomeCents, 0);
      expect(flow.expenseCents, 0);
    });
  });

  group('SupabaseSalesReportRepository.fetchSalesReport', () {
    const repo = SupabaseSalesReportRepository();

    Map<String, dynamic> reportPayload() => {
      'total_revenue_cents': 500000,
      'total_profit_cents': 120000,
      'best_sellers': [
        {
          'product_id': 'p1',
          'product_name': 'Arroz Txitxiri',
          'quantity': 2500,
          'revenue_cents': 150000,
        },
      ],
      'per_day': [
        {'day': '2026-09-10T00:00:00.000Z', 'total_cents': 300000},
      ],
    };

    test('aceita o formato objeto (JSONB da RPC)', () async {
      stub.handler = (path, request) {
        expect(path, contains('rpc/get_sales_report'));
        return FakeResponse(reportPayload());
      };

      final report = await repo.fetchSalesReport(
        storeId: 'st1',
        start: DateTime(2026, 9, 1),
        end: DateTime(2026, 9, 10),
      );

      expect(report.totalRevenueCents, 500000);
      expect(report.totalProfitCents, 120000);
      expect(report.bestSellers.first.productId, 'p1');
      expect(report.bestSellers.first.quantity, 2500);
      expect(report.perDay.first.totalCents, 300000);
    });

    test('aceita o formato lista (defensivo, RETURNS TABLE)', () async {
      stub.handler = (path, request) => FakeResponse([reportPayload()]);

      final report = await repo.fetchSalesReport(
        storeId: 'st1',
        start: DateTime(2026, 9, 1),
        end: DateTime(2026, 9, 10),
      );

      expect(report.totalRevenueCents, 500000);
      expect(report.bestSellers, hasLength(1));
    });

    test('best_sellers/per_day ausentes → listas vazias', () async {
      stub.handler = (path, request) =>
          FakeResponse({'total_revenue_cents': 0, 'total_profit_cents': 0});

      final report = await repo.fetchSalesReport(
        storeId: 'st1',
        start: DateTime(2026, 9, 1),
        end: DateTime(2026, 9, 10),
      );

      expect(report.bestSellers, isEmpty);
      expect(report.perDay, isEmpty);
    });
  });

  group('SupabaseEmployeeCommissionSummaryRepository.getSummary', () {
    const repo = SupabaseEmployeeCommissionSummaryRepository();

    test('mapeia as entradas; fullName nulo → vazio; lista imutável', () async {
      stub.handler = (path, request) {
        expect(path, contains('rpc/get_employee_commission_summary'));
        return FakeResponse([
          {
            'user_id': 'u2',
            'full_name': 'Carlos Silva',
            'sales_cents': 100000,
            'rate_bps': 500,
            'commission_cents': 5000,
          },
          {
            'user_id': 'u3',
            'full_name': null,
            'sales_cents': 50000,
            'rate_bps': 300,
            'commission_cents': 1500,
          },
        ]);
      };

      final entries = await repo.getSummary(storeId: 'st1', month: '2026-09');

      expect(entries, hasLength(2));
      expect(entries.first.fullName, 'Carlos Silva');
      expect(entries.first.commissionCents, 5000);
      expect(entries.last.fullName, '');
      // List.unmodifiable — o contrato é somente-leitura.
      expect(() => entries.add(entries.first), throwsUnsupportedError);
    });
  });

  group('SupabaseCashClosingSummaryRepository (caminho real)', () {
    test('fetchSummary sem RPC injetada passa pelo client real', () async {
      stub.handler = (path, request) {
        expect(path, contains('rpc/get_cash_closing_summary'));
        return FakeResponse({
          'day': '2026-09-10T00:00:00.000Z',
          'total_sales_cents': 4050,
          'expected_cash_cents': 1100,
          'sales_by_method_cents': {'cash': 1100, 'mPesa': 2950},
        });
      };

      const repo = SupabaseCashClosingSummaryRepository();
      final summary = await repo.fetchSummary(
        storeId: 'st1',
        day: DateTime(2026, 9, 10, 14, 30),
      );

      expect(summary.totalSalesCents, 4050);
      expect(summary.expectedCashCents, 1100);
      expect(summary.salesByMethodCents, {'cash': 1100, 'mPesa': 2950});
    });
  });
}
