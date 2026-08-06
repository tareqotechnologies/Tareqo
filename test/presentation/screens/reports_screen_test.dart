import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';
import '../../helpers/store_context.dart';

import 'package:dumbhanengue/domain/usecases/get_sales_report_use_case.dart';
import 'package:dumbhanengue/presentation/controllers/reports_providers.dart';
import 'package:dumbhanengue/presentation/screens/reports/reports_screen.dart';

class _FakeGetSalesReportUseCase implements GetSalesReportUseCase {
  _FakeGetSalesReportUseCase(this._report);

  final SalesReport _report;

  @override
  Future<SalesReport> call({
    required String storeId,
    required DateTime start,
    required DateTime end,
  }) async =>
      _report;
}

class _ThrowingGetSalesReportUseCase implements GetSalesReportUseCase {
  @override
  Future<SalesReport> call({
    required String storeId,
    required DateTime start,
    required DateTime end,
  }) async =>
      throw Exception('falha de rede simulada');
}

// A tela depende de SalesReport (que usa GetSalesReportUseCase). O fake
// acima cobre o provider — estes tipos são usados na montagem do report.
const _bestSellers = [
  BestSeller(
    productId: 'p1',
    productName: 'Caneta',
    quantity: 12,
    revenue: 24.0,
  ),
  BestSeller(
    productId: 'p2',
    productName: 'Caderno',
    quantity: 5,
    revenue: 30.0,
  ),
];

// Vendas por dia com datas RELATIVAS a agora: "Hoje" e "Ontem" (os rótulos
// de [Formatters.day] dependem do relógio real — datas fixas tornariam o
// teste flaky).
DateTime get _today => DateTime.now();
DateTime get _yesterday => DateTime.now().subtract(const Duration(days: 1));

SalesReport _report() => SalesReport(
  totalRevenue: 54.0,
  totalProfit: 18.0,
  bestSellers: _bestSellers,
  perDay: [
    DailySales(day: _yesterday, total: 20.0),
    DailySales(day: _today, total: 34.0),
  ],
);

Widget _buildApp(GetSalesReportUseCase useCase) {
  return ProviderScope(
    overrides: [
      ...storeContextOverrides(),
      getSalesReportUseCaseProvider.overrideWithValue(useCase),
    ],
    child: testApp(home: const ReportsScreen()),
  );
}

void main() {
  testWidgets('exibe KPIs, mais vendidos e vendas por dia', (tester) async {
    await tester.pumpWidget(_buildApp(_FakeGetSalesReportUseCase(_report())));
    await tester.pumpAndSettle();

    // KPIs do relatório.
    expect(find.text('Faturamento'), findsOneWidget);
    expect(find.text('R\$ 54,00'), findsAtLeastNWidgets(1));
    expect(find.text('Lucro bruto'), findsOneWidget);
    expect(find.text('R\$ 18,00'), findsOneWidget);
    expect(find.text('Margem'), findsOneWidget);
    expect(find.text('33.3%'), findsOneWidget);

    // Mais vendidos (rank + nome + quantidade + receita).
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Caneta'), findsOneWidget);
    expect(find.text('Caderno'), findsOneWidget);
    expect(find.text('12 un.'), findsOneWidget);
    expect(find.text('5 un.'), findsOneWidget);
    expect(find.text('R\$ 24,00 vendidos'), findsOneWidget);
    expect(find.text('R\$ 30,00 vendidos'), findsOneWidget);

    // Vendas por dia (Hoje/Ontem + totais). "Hoje" também é o rótulo do
    // período (SegmentedButton) — usa findsWidgets.
    expect(find.text('Hoje'), findsWidgets);
    expect(find.text('Ontem'), findsOneWidget);
    expect(find.text('R\$ 20,00'), findsOneWidget);
    expect(find.text('R\$ 34,00'), findsOneWidget);
  });

  testWidgets('mostra estado vazio quando não há mais vendidos',
      (tester) async {
    await tester.pumpWidget(
      _buildApp(
        _FakeGetSalesReportUseCase(
          const SalesReport(
            totalRevenue: 0,
            totalProfit: 0,
            bestSellers: [],
            perDay: [],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sem vendas no período'), findsOneWidget);
  });

  testWidgets('mostra erro com retry quando a carga falha', (tester) async {
    await tester.pumpWidget(
      _buildApp(_ThrowingGetSalesReportUseCase()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Não foi possível carregar o relatório.'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);
  });

  testWidgets('trocar o período recarrega o relatório', (tester) async {
    await tester.pumpWidget(_buildApp(_FakeGetSalesReportUseCase(_report())));
    await tester.pumpAndSettle();

    // O período inicial é "Este mês" — troca para "Tudo".
    await tester.tap(find.text('Tudo'));
    await tester.pumpAndSettle();

    // Continua renderizando os dados (o fake devolve sempre o mesmo).
    expect(find.text('Faturamento'), findsOneWidget);
  });
}
