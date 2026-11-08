import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

import 'package:tareqo/core/theme/app_colors.dart';
import 'package:tareqo/domain/entities/financial_transaction.dart';
import 'package:tareqo/presentation/screens/financial/financial_widgets.dart';

/// Transação de fixture: data fixa no passado para o rótulo de dia nunca
/// depender da data real da execução do teste.
FinancialTransaction _tx({
  String id = 't1',
  String description = 'Venda PIX',
  int amountCents = 100000,
  TransactionType type = TransactionType.income,
  String category = 'Vendas',
  TransactionStatus status = TransactionStatus.paid,
}) => FinancialTransaction(
  id: id,
  description: description,
  amountCents: amountCents,
  type: type,
  category: category,
  date: DateTime(2024, 1, 10, 10),
  status: status,
);

void main() {
  // ---------------------------------------------------------------------------
  // TransactionCard — a linha da lista de movimentações.
  // ---------------------------------------------------------------------------
  group('TransactionCard', () {
    testWidgets('mostra categoria, hora e valor com sinal', (tester) async {
      await tester.pumpWidget(
        testApp(
          home: Scaffold(body: TransactionCard(transaction: _tx())),
        ),
      );

      expect(find.text('Vendas'), findsOneWidget);
      expect(find.text('10:00'), findsOneWidget);
      expect(find.text('+ R\$ 1.000,00'), findsOneWidget);
    });

    testWidgets('saída usa a cor semântica de despesa', (tester) async {
      await tester.pumpWidget(
        testApp(
          home: Scaffold(
            body: TransactionCard(
              transaction: _tx(
                type: TransactionType.expense,
                category: 'Contas',
                amountCents: 20000,
              ),
            ),
          ),
        ),
      );

      final value = tester.widget<Text>(find.text('- R\$ 200,00'));
      expect(value.style?.color, AppColors.expenseDark);
    });

    testWidgets('o toque abre o detalhe (onTap)', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        testApp(
          home: Scaffold(
            body: TransactionCard(transaction: _tx(), onTap: () => taps++),
          ),
        ),
      );

      await tester.tap(find.text('Vendas'));
      await tester.pumpAndSettle();
      expect(taps, 1);
    });
  });

  // ---------------------------------------------------------------------------
  // DateSectionHeader — cabeçalho do grupo de um dia.
  // ---------------------------------------------------------------------------
  group('DateSectionHeader', () {
    testWidgets('mostra o dia e o total assinado', (tester) async {
      await tester.pumpWidget(
        testApp(
          home: const Scaffold(
            body: DateSectionHeader(label: '10/01', totalCents: 150000),
          ),
        ),
      );

      expect(find.text('10/01'), findsOneWidget);
      expect(find.text('+1.500,00'), findsOneWidget);
    });

    testWidgets('total negativo usa a cor de despesa', (tester) async {
      await tester.pumpWidget(
        testApp(
          home: const Scaffold(
            body: DateSectionHeader(label: '10/01', totalCents: -45000),
          ),
        ),
      );

      final total = tester.widget<Text>(find.text('-450,00'));
      expect(total.style?.color, AppColors.expenseDark);
    });
  });

  // ---------------------------------------------------------------------------
  // TransactionDetailSheet — detalhe + quitação de pendências.
  // ---------------------------------------------------------------------------
  group('TransactionDetailSheet', () {
    testWidgets('entrada pendente mostra os detalhes e oferece Receber', (
      tester,
    ) async {
      var received = 0;
      await tester.pumpWidget(
        testApp(
          home: Scaffold(
            body: TransactionDetailSheet(
              transaction: _tx(
                status: TransactionStatus.pending,
                description: 'Venda fiado (João)',
                category: 'Fiado',
              ),
              onReceive: () => received++,
            ),
          ),
        ),
      );

      expect(find.text('Venda fiado (João)'), findsOneWidget);
      // 'Fiado' aparece no header (categoria) e na linha de detalhes
      expect(find.text('Fiado'), findsExactly(2));
      expect(find.text('Pendente'), findsOneWidget);
      expect(find.text('Data e hora'), findsOneWidget);

      await tester.tap(find.text('Receber'));
      await tester.pumpAndSettle();
      expect(received, 1);
    });

    testWidgets('saída pendente oferece Pagar (nunca Receber)', (tester) async {
      await tester.pumpWidget(
        testApp(
          home: Scaffold(
            body: TransactionDetailSheet(
              transaction: _tx(
                type: TransactionType.expense,
                status: TransactionStatus.pending,
                category: 'Contas',
                description: 'Conta de luz',
              ),
              onPay: () {},
            ),
          ),
        ),
      );

      expect(find.text('Pagar'), findsOneWidget);
      expect(find.text('Receber'), findsNothing);
    });

    testWidgets('movimentação concluída não oferece ação de quitação', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          home: Scaffold(body: TransactionDetailSheet(transaction: _tx())),
        ),
      );

      expect(find.text('Pago'), findsOneWidget);
      expect(find.text('Receber'), findsNothing);
      expect(find.text('Pagar'), findsNothing);
    });
  });
}
