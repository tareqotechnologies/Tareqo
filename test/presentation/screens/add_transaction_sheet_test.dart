import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';
import '../../helpers/store_context.dart';

import 'package:tareqo/domain/entities/financial_transaction.dart';
import 'package:tareqo/domain/usecases/add_financial_transaction_use_case.dart';
import 'package:tareqo/presentation/controllers/finance_providers.dart';
import 'package:tareqo/presentation/screens/financial/add_transaction_sheet.dart';
import 'package:tareqo/presentation/widgets/app_sheet.dart';

/// Fake do [AddFinancialTransactionUseCase] que registra a chamada.
class _FakeAddTransactionUseCase implements AddFinancialTransactionUseCase {
  int calls = 0;
  FinancialTransaction? lastTransaction;

  @override
  Future<void> call(FinancialTransaction transaction) async {
    calls++;
    lastTransaction = transaction;
  }
}

/// Fake que lança [InvalidAmountException] (validação do domínio).
class _InvalidAmountUseCase implements AddFinancialTransactionUseCase {
  @override
  Future<void> call(FinancialTransaction transaction) async =>
      throw const InvalidAmountException('Valor inválido.');
}

/// Fake que lança um erro inesperado (falha de infraestrutura).
class _ThrowingUseCase implements AddFinancialTransactionUseCase {
  @override
  Future<void> call(FinancialTransaction transaction) async =>
      throw Exception('falha de rede');
}

/// Monta um host com um botão que abre a sheet via [showAppSheet] — o mesmo
/// caminho da app real. A sheet fica numa rota por cima do host, então o
/// `Navigator.pop()` interno do submit funciona.
Widget _buildApp(AddFinancialTransactionUseCase useCase) {
  return ProviderScope(
    overrides: [
      ...storeContextOverrides(),
      addTransactionUseCaseProvider.overrideWithValue(useCase),
    ],
    child: testApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: FilledButton(
              onPressed: () => showAppSheet<void>(
                context,
                builder: (_) => const AddTransactionSheet(),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('registrar entrada chama o caso de uso e mostra o snackbar', (
    tester,
  ) async {
    final useCase = _FakeAddTransactionUseCase();

    await tester.pumpWidget(_buildApp(useCase));
    await _openSheet(tester);

    // O SegmentedButton seleciona "Entrada" por padrão.
    expect(find.text('Entrada'), findsWidgets);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Descrição').first,
      'Venda à vista',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Valor').first,
      '120,50',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Registrar'));
    await tester.pumpAndSettle();

    expect(useCase.calls, 1);
    expect(useCase.lastTransaction?.description, 'Venda à vista');
    expect(useCase.lastTransaction?.amountCents, 12050);
    expect(useCase.lastTransaction?.type, TransactionType.income);
    expect(useCase.lastTransaction?.category, 'Vendas');
    expect(useCase.lastTransaction?.status, TransactionStatus.paid);
    expect(find.text('Movimentação registrada!'), findsOneWidget);
  });

  testWidgets('valida descrição e valor maiores que zero', (tester) async {
    final useCase = _FakeAddTransactionUseCase();

    await tester.pumpWidget(_buildApp(useCase));
    await _openSheet(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Registrar'));
    await tester.pumpAndSettle();

    expect(find.text('Informe a descrição.'), findsOneWidget);
    expect(find.text('Informe um valor maior que zero.'), findsOneWidget);
    expect(useCase.calls, 0);
  });

  testWidgets('exibe a mensagem do InvalidAmountException', (tester) async {
    await tester.pumpWidget(_buildApp(_InvalidAmountUseCase()));
    await _openSheet(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Descrição').first,
      'Compra de material',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Valor').first,
      '10',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Registrar'));
    await tester.pumpAndSettle();

    expect(find.text('Valor inválido.'), findsOneWidget);
  });

  testWidgets('exibe erro genérico quando a infraestrutura falha', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp(_ThrowingUseCase()));
    await _openSheet(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Descrição').first,
      'Compra de material',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Valor').first,
      '10',
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Registrar'));
    await tester.pumpAndSettle();
    expect(
      find.text('Não foi possível registrar. Tente novamente.'),
      findsOneWidget,
    );
  });

  testWidgets('marcar como pendente envia status pending', (tester) async {
    final useCase = _FakeAddTransactionUseCase();

    await tester.pumpWidget(_buildApp(useCase));
    await _openSheet(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Descrição').first,
      'Fiado do cliente',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Valor').first,
      '30',
    );

    // Ativa o switch "Pendente (fiado)" (pode estar abaixo da dobra —
    // a sheet é rolável, então garante visibilidade antes do toque).
    await tester.ensureVisible(find.text('Pendente (fiado)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pendente (fiado)'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Registrar'));
    await tester.pumpAndSettle();

    expect(useCase.lastTransaction?.status, TransactionStatus.pending);
  });

  testWidgets(
    'a11y: alvos de toque ≥48dp e contraste AA na sheet de transação',
    (tester) async {
      await tester.pumpWidget(_buildApp(_FakeAddTransactionUseCase()));
      await _openSheet(tester);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    },
  );
}
