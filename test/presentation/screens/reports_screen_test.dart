import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';
import '../../helpers/viewport.dart';
import '../../helpers/store_context.dart';

import 'package:dumbhanengue/domain/repositories/i_sales_report_repository.dart';
import 'package:dumbhanengue/domain/usecases/get_sales_report_use_case.dart';
import 'package:dumbhanengue/presentation/controllers/reports_providers.dart';
import 'package:dumbhanengue/presentation/screens/reports/reports_screen.dart';

class _FakeGetSalesReportUseCase implements GetSalesReportUseCase {
  _FakeGetSalesReportUseCase(this._report);

  final SalesReport _report;

  @override
  final ISalesReportRepository? serverRepository = null;

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
  final ISalesReportRepository? serverRepository = null;

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
    revenueCents: 2400,
  ),
  BestSeller(
    productId: 'p2',
    productName: 'Caderno',
    quantity: 5,
    revenueCents: 3000,
  ),
];

// Vendas por dia com datas RELATIVAS a agora: "Hoje" e "Ontem" (os rótulos
// de [Formatters.day] dependem do relógio real — datas fixas tornariam o
// teste flaky).
DateTime get _today => DateTime.now();
DateTime get _yesterday => DateTime.now().subtract(const Duration(days: 1));

SalesReport _report() => SalesReport(
  totalRevenueCents: 5400,
  totalProfitCents: 1800,
  bestSellers: _bestSellers,
  perDay: [
    DailySales(day: _yesterday, totalCents: 2000),
    DailySales(day: _today, totalCents: 3400),
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
            totalRevenueCents: 0,
            totalProfitCents: 0,
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

  // Rotação (UI): em paisagem o seletor de período renderiza em escala
  // natural (sem o FittedBox encolher) e os três KPIs seguem lado a lado
  // com os Expanded. Overflows de RenderFlex falham o teste via
  // takeException; trocar de período após o giro prova que o seletor
  // continua funcional.
  testWidgets('KPIs e seletor de período sobrevivem à rotação para paisagem',
      (tester) async {
    usePortraitViewport(tester);

    await tester.pumpWidget(_buildApp(_FakeGetSalesReportUseCase(_report())));
    await tester.pumpAndSettle();

    // Retrato: os três KPIs e o seletor de período visíveis.
    expect(find.text('Faturamento'), findsOneWidget);
    expect(find.text('Lucro bruto'), findsOneWidget);
    expect(find.text('Margem'), findsOneWidget);
    expect(find.byType(SegmentedButton<ReportPeriod>), findsOneWidget);
    expect(find.text('Este mês'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Gira para paisagem.
    await rotateToLandscape(tester);

    // Sem overflow; KPIs e seletor seguem presentes após o giro.
    expect(tester.takeException(), isNull);
    expect(find.text('Faturamento'), findsOneWidget);
    expect(find.text('Lucro bruto'), findsOneWidget);
    expect(find.text('R\$ 54,00'), findsOneWidget);
    expect(find.byType(SegmentedButton<ReportPeriod>), findsOneWidget);

    // Trocar de período em paisagem continua funcionando (Tudo).
    await tester.tap(find.text('Tudo'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<SegmentedButton<ReportPeriod>>(
            find.byType(SegmentedButton<ReportPeriod>),
          )
          .selected,
      {ReportPeriod.all},
    );
    expect(tester.takeException(), isNull);
  });
}
