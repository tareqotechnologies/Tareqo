import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

import 'package:tareqo/core/utils/formatters.dart';
import 'package:tareqo/presentation/widgets/period_comparison_card.dart';

PeriodComparisonMetric _metric({
  String label = 'Receita',
  int currentCents = 5400,
  int previousCents = 4000,
}) => PeriodComparisonMetric(
  label: label,
  currentCents: currentCents,
  previousCents: previousCents,
);

Widget _buildCard(List<PeriodComparisonMetric> metrics) => testApp(
  home: Scaffold(
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: PeriodComparisonCard(metrics: metrics),
    ),
  ),
);

void main() {
  setUp(() {
    Formatters.applySettings(currencyCode: 'BRL', language: 'pt');
  });

  testWidgets(
    'delta positivo mostra sinal +, percentual e tendência de subida',
    (tester) async {
      await tester.pumpWidget(_buildCard([_metric()]));

      expect(find.text('Comparação com o período anterior'), findsOneWidget);
      expect(find.text('Receita'), findsOneWidget);
      expect(
        find.text(r'+R$ 14,00 · +35.0% vs. período anterior'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.trending_up_rounded), findsOneWidget);
    },
  );

  testWidgets(
    'delta negativo mostra sinal −, percentual e tendência de descida',
    (tester) async {
      await tester.pumpWidget(
        _buildCard([_metric(currentCents: 3000, previousCents: 4000)]),
      );

      expect(
        find.text(r'−R$ 10,00 · −25.0% vs. período anterior'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.trending_down_rounded), findsOneWidget);
    },
  );

  testWidgets('delta zero fica neutro e não leva sinal', (tester) async {
    await tester.pumpWidget(
      _buildCard([_metric(currentCents: 1000, previousCents: 1000)]),
    );

    expect(find.text(r'R$ 0,00 · 0.0% vs. período anterior'), findsOneWidget);
    expect(find.byIcon(Icons.trending_flat_rounded), findsOneWidget);
    expect(find.textContaining(r'+R$'), findsNothing);
    expect(find.textContaining(r'−R$'), findsNothing);
  });

  testWidgets('sem período anterior mostra a mensagem de ausência de base', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildCard([_metric(currentCents: 2500, previousCents: 0)]),
    );

    expect(
      find.text('Sem dados do período anterior para comparar.'),
      findsOneWidget,
    );
    expect(find.textContaining('vs. período anterior'), findsNothing);
    expect(find.byIcon(Icons.trending_up_rounded), findsOneWidget);
  });

  testWidgets('renderiza várias métricas com os respetivos rótulos e valores', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildCard([
        _metric(),
        _metric(label: 'Lucro bruto', currentCents: 3000, previousCents: 4000),
      ]),
    );

    expect(find.text('Receita'), findsOneWidget);
    expect(find.text('Lucro bruto'), findsOneWidget);
    expect(
      find.text(r'+R$ 14,00 · +35.0% vs. período anterior'),
      findsOneWidget,
    );
    expect(
      find.text(r'−R$ 10,00 · −25.0% vs. período anterior'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.trending_up_rounded), findsOneWidget);
    expect(find.byIcon(Icons.trending_down_rounded), findsOneWidget);
  });
}
