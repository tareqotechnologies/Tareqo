import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';
import '../../helpers/viewport.dart';
import 'package:tareqo/core/theme/app_theme.dart';
import 'package:tareqo/core/theme/app_colors.dart';
import 'package:tareqo/presentation/screens/financial/financial_screen.dart';
import 'package:tareqo/presentation/screens/financial/financial_widgets.dart';

void main() {
  // ---------------------------------------------------------------------------
  // FinanceHeader
  // ---------------------------------------------------------------------------
  group('FinanceHeader', () {
    testWidgets('renders FinanceHeader widget', (tester) async {
      Widget testWidget() => MaterialApp(home: FinanceHeader());

      await tester.pumpWidget(testWidget());

      expect(tester.widgetList<Widget>(find.byType(FinanceHeader)).length, 1);
    });
  });

  // ---------------------------------------------------------------------------
  // FinanceFilterPills / FilterPill
  // ---------------------------------------------------------------------------
  group('FinanceFilterPills', () {
    testWidgets('renders FinanceFilterPills com 4 pills', (tester) async {
      Widget testWidget() => MaterialApp(home: FinanceFilterPills());

      await tester.pumpWidget(testWidget());

      expect(find.byType(FilterPill), findsNWidgets(4));

      expect(find.text('Hoje'), findsOneWidget);
      expect(find.text('Esta semana'), findsOneWidget);
      expect(find.text('Este mês'), findsOneWidget);
      expect(find.text('Tudo'), findsOneWidget);
    });

    testWidgets('pill "Este mês" é renderizada', (tester) async {
      Widget testWidget() => MaterialApp(home: FinanceFilterPills());

      await tester.pumpWidget(testWidget());

      expect(find.text('Este mês'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // FinanceSummaryCard
  // ---------------------------------------------------------------------------
  group('FinanceSummaryCard', () {
    testWidgets('rends FinanceSummaryCard com dados', (tester) async {
      Widget testWidget() => MaterialApp(
            home: FinanceSummaryCard(
              incomeCents: 424000,
              expenseCents: 100000,
            ),
          );

      await tester.pumpWidget(testWidget());

      expect(find.text('Saldo líquido do período'), findsOneWidget);
      expect(find.text('MZN 4.240,00'), findsOneWidget);
      expect(find.text('Entradas'), findsOneWidget);
      expect(find.text('Saídas'), findsOneWidget);
    });

    testWidgets('widgets de saldo existem', (tester) async {
      Widget testWidget() => MaterialApp(
            home: FinanceSummaryCard(
              incomeCents: 424000,
              expenseCents: 100000,
            ),
          );

      await tester.pumpWidget(testWidget());

      final saldoText =
          tester.widget<Text>(find.text('MZN 4.240,00'));
      expect(saldoText, isNotNull);
    });
  });

  // ---------------------------------------------------------------------------
  // FinanceRowIconLabel
  // ---------------------------------------------------------------------------
  group('FinanceRowIconLabel', () {
    testWidgets('rends FinanceRowIconLabel com ícone rótulo e valor', (tester) async {
      Widget testWidget() => MaterialApp(
            home: FinanceRowIconLabel(
              icon: Icons.arrow_upward_rounded,
              label: 'Entradas',
              value: '+4.240,00',
              color: AppColors.accentOrange,
            ),
          );

      await tester.pumpWidget(testWidget());

      expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);
      expect(find.text('Entradas'), findsOneWidget);
      expect(find.text('+4.240,00'), findsOneWidget);
    });

    testWidgets('linha de saídas tem ícone rótulo e valor', (tester) async {
      Widget testWidget() => MaterialApp(
            home: FinanceRowIconLabel(
              icon: Icons.arrow_downward_rounded,
              label: 'Saídas',
              value: '-1.000,00',
              color: AppColors.expense,
            ),
          );

      await tester.pumpWidget(testWidget());

      expect(find.byIcon(Icons.arrow_downward_rounded), findsOneWidget);
      expect(find.text('Saídas'), findsOneWidget);
      expect(find.text('-1.000,00'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // MovementsHeader
  // ---------------------------------------------------------------------------
  group('MovementsHeader', () {
    testWidgets('rends MovementsHeader com título e subtítulo', (tester) async {
      Widget testWidget() => MaterialApp(
            home: MovementsHeader(subtitle: 'Pendente (fiado) · 1'),
          );

      await tester.pumpWidget(testWidget());

      expect(find.text('Movimentos do período'), findsOneWidget);
      expect(find.text('Pendente (fiado) · 1'), findsOneWidget);
    });

    testWidgets('widgets de header estão presentes', (tester) async {
      Widget testWidget() => MaterialApp(
            home: MovementsHeader(subtitle: 'Pendente (fiado) · 1'),
          );

      await tester.pumpWidget(testWidget());

      expect(find.text('Movimentos do período'), findsOneWidget);
      expect(find.text('Pendente (fiado) · 1'), findsOneWidget);
    });
  });
}