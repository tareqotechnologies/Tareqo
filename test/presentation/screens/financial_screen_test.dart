import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';
import '../../helpers/viewport.dart';

import 'package:dumbhanengue/core/theme/app_theme.dart';
import 'package:dumbhanengue/domain/entities/financial_transaction.dart';
import 'package:dumbhanengue/domain/repositories/i_cash_flow_repository.dart';
import 'package:dumbhanengue/domain/repositories/i_financial_transaction_repository.dart';
import 'package:dumbhanengue/domain/usecases/get_cash_flow_use_case.dart';
import 'package:dumbhanengue/domain/usecases/mark_transaction_as_paid_use_case.dart';
import 'package:dumbhanengue/presentation/controllers/finance_providers.dart';
import 'package:dumbhanengue/presentation/screens/financial/financial_screen.dart';
import 'package:dumbhanengue/presentation/widgets/skeleton.dart';

import '../../helpers/store_context.dart';

class _FakeFinanceRepository implements IFinancialTransactionRepository {
  _FakeFinanceRepository(this._transactions);

  final List<FinancialTransaction> _transactions;

  @override
  Future<List<FinancialTransaction>> getByPeriod({
    required String storeId,
    required DateTime start,
    required DateTime end,
  }) async {
    return _transactions
        .where((t) => !t.date.isBefore(start) && !t.date.isAfter(end))
        .toList();
  }

  @override
  Future<List<FinancialTransaction>> getAll({required String storeId}) async =>
      List.unmodifiable(_transactions);

  @override
  Future<void> add(FinancialTransaction transaction) async {
    _transactions.add(transaction);
  }

  @override
  Future<void> markAsPaid(String id, {required String storeId}) async {
    final index = _transactions.indexWhere((t) => t.id == id);
    _transactions[index] = _transactions[index].copyWith(
      status: TransactionStatus.paid,
    );
  }
}

class _FakeGetCashFlowUseCase implements GetCashFlowUseCase {
  @override
  final ICashFlowRepository? serverRepository = null;

  @override
  Future<CashFlow> call({
    required String storeId,
    required DateTime start,
    required DateTime end,
  }) async => const CashFlow(incomeCents: 150000, expenseCents: 45000);
}

class _FakeMarkTransactionAsPaidUseCase
    implements MarkTransactionAsPaidUseCase {
  _FakeMarkTransactionAsPaidUseCase(this._repository);

  final _FakeFinanceRepository _repository;

  @override
  Future<void> call(String transactionId, {required String storeId}) =>
      _repository.markAsPaid(transactionId, storeId: storeId);
}

Widget _buildApp(_FakeFinanceRepository repository) {
  return ProviderScope(
    overrides: [
      // Contexto de loja — o Financeiro escopa pela loja ativa.
      ...storeContextOverrides(),
      financeRepositoryProvider.overrideWithValue(repository),
      getCashFlowUseCaseProvider.overrideWithValue(_FakeGetCashFlowUseCase()),
      markTransactionAsPaidUseCaseProvider.overrideWithValue(
        _FakeMarkTransactionAsPaidUseCase(repository),
      ),
    ],
    child: testApp(home: FinancialScreen()),
  );
}

void main() {
  testWidgets('mostra skeleton enquanto as movimentações carregam', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        _FakeFinanceRepository([
          FinancialTransaction(
            id: 't1',
            description: 'Venda PIX',
            amountCents: 100000,
            type: TransactionType.income,
            category: 'Vendas',
            date: DateTime(2024, 1, 10, 10),
          ),
        ]),
      ),
    );

    // Estado inicial: carregando (skeleton no lugar dos cards).
    expect(find.byType(Skeleton), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('Venda PIX'), findsOneWidget);
    expect(find.byType(Skeleton), findsNothing);
  });

  testWidgets('mostra entradas, saídas, saldo e as movimentações', (
    tester,
  ) async {
    // Data fixa no PASSADO: o rótulo de dia (10/01) nunca é afetado pela
    // data real da execução do teste (determinístico).
    final now = DateTime(2024, 1, 10, 10);
    await tester.pumpWidget(
      _buildApp(
        _FakeFinanceRepository([
          FinancialTransaction(
            id: 't1',
            description: 'Venda PIX',
            amountCents: 100000,
            type: TransactionType.income,
            category: 'Vendas',
            date: now,
          ),
          FinancialTransaction(
            id: 't2',
            description: 'Aluguel da loja',
            amountCents: 20000,
            type: TransactionType.expense,
            category: 'Contas',
            date: now,
          ),
          FinancialTransaction(
            id: 't3',
            description: 'Venda fiado (João)',
            amountCents: 2500,
            type: TransactionType.income,
            category: 'Fiado',
            date: now,
            status: TransactionStatus.pending,
          ),
        ]),
      ),
    );

    await tester.pumpAndSettle();

    // KPIs do fluxo de caixa (vindos do use case fake).
    expect(find.text('Entradas'), findsOneWidget);
    expect(find.text('Saídas'), findsOneWidget);
    expect(find.text('Saldo'), findsOneWidget);
    expect(find.text('R\$ 1.500,00'), findsOneWidget);
    expect(find.text('R\$ 450,00'), findsOneWidget);
    expect(find.text('R\$ 1.050,00'), findsOneWidget);

    // Movimentações.
    expect(find.text('Venda PIX'), findsOneWidget);
    expect(find.text('Aluguel da loja'), findsOneWidget);
    expect(find.text('Venda fiado (João)'), findsOneWidget);
    // Número amigável (derivado do id) em cada movimentação.
    expect(find.textContaining('#734806'), findsOneWidget); // t1
    expect(find.textContaining('#957187'), findsOneWidget); // t2
    expect(find.textContaining('#179568'), findsOneWidget); // t3
    expect(find.text('Pendente'), findsOneWidget);
    // Entrada pendente oferece o recebimento.
    expect(find.text('Receber'), findsOneWidget);
    // Data inteligente em cada card: '10/01 • 10:00' (dia + hora).
    expect(find.text('10/01 • 10:00'), findsNWidgets(3));

    // As cores semânticas resolvem para a variante CLARA no tema claro
    // (testApp aplica AppTheme.light) — texto de valor com AA sobre o card.
    final incomeText = tester.widget<Text>(find.text('+ R\$ 1.000,00'));
    expect(incomeText.style?.color, AppColors.incomeLight);
    final expenseText = tester.widget<Text>(find.text('- R\$ 200,00'));
    expect(expenseText.style?.color, AppColors.expenseLight);
  });

  testWidgets('botão Receber marca a entrada pendente como paga', (
    tester,
  ) async {
    final now = DateTime(2024, 1, 10, 10);
    final repository = _FakeFinanceRepository([
      FinancialTransaction(
        id: 't3',
        description: 'Venda fiado (João)',
        amountCents: 2500,
        type: TransactionType.income,
        category: 'Fiado',
        date: now,
        status: TransactionStatus.pending,
      ),
    ]);
    await tester.pumpWidget(_buildApp(repository));
    await tester.pumpAndSettle();

    expect(find.text('Pendente'), findsOneWidget);

    // Abre a confirmação.
    await tester.tap(find.text('Receber'));
    await tester.pumpAndSettle();
    expect(find.text('Receber pendência?'), findsOneWidget);

    // Confirma o recebimento.
    await tester.tap(find.widgetWithText(FilledButton, 'Receber'));
    await tester.pumpAndSettle();

    expect(find.text('Movimentação recebida!'), findsOneWidget);

    // Após invalidar, a transação está paga — o chip 'Pendente' some.
    expect(find.text('Pendente'), findsNothing);
  });

  // Rotação (UI): em paisagem a largura maior permite o SegmentedButton de
  // período renderizar sem o FittedBox encolher (escala natural) e os três
  // KPIs seguem lado a lado com os Expanded. Overflows de RenderFlex
  // falham o teste via takeException; trocar de período após o giro prova
  // que o seletor continua funcional.
  testWidgets('KPIs e seletor de período sobrevivem à rotação para paisagem',
      (tester) async {
    // Retrato estreito: KPIs empilhados em Expanded + seletor encolhido
    // pelo FittedBox.
    usePortraitViewport(tester);

    final now = DateTime(2024, 1, 10, 10);
    await tester.pumpWidget(
      _buildApp(
        _FakeFinanceRepository([
          FinancialTransaction(
            id: 't1',
            description: 'Venda PIX',
            amountCents: 100000,
            type: TransactionType.income,
            category: 'Vendas',
            date: now,
          ),
          FinancialTransaction(
            id: 't2',
            description: 'Aluguel da loja',
            amountCents: 20000,
            type: TransactionType.expense,
            category: 'Contas',
            date: now,
          ),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    // Retrato: os três KPIs e o seletor de período visíveis.
    expect(find.text('Entradas'), findsOneWidget);
    expect(find.text('Saídas'), findsOneWidget);
    expect(find.text('Saldo'), findsOneWidget);
    expect(find.byType(SegmentedButton<CashFlowPeriod>), findsOneWidget);
    expect(find.text('Este mês'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Gira para paisagem.
    await rotateToLandscape(tester);

    // Sem overflow; KPIs e seletor seguem presentes após o giro.
    expect(tester.takeException(), isNull);
    expect(find.text('Entradas'), findsOneWidget);
    expect(find.text('Saídas'), findsOneWidget);
    expect(find.text('Saldo'), findsOneWidget);
    expect(find.text('R\$ 1.500,00'), findsOneWidget);
    expect(find.text('R\$ 450,00'), findsOneWidget);
    expect(find.byType(SegmentedButton<CashFlowPeriod>), findsOneWidget);

    // Trocar de período em paisagem continua funcionando (Tudo).
    await tester.tap(find.text('Tudo'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<SegmentedButton<CashFlowPeriod>>(
            find.byType(SegmentedButton<CashFlowPeriod>),
          )
          .selected,
      {CashFlowPeriod.all},
    );
    expect(tester.takeException(), isNull);
  });

  // Regressão (UI): a coluna de valor/chip e o seletor de período ficavam
  // sem Flexível/FittedBox — com escala de texto 2.0 em tela estreita, a
  // tela estourava. Overflows de RenderFlex falham o teste via takeException.
  testWidgets('não estoura com escala de texto 2.0 em tela estreita', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearAllTestValues);

    // Estreita (360) porém alta: garante que KPIs, seletor e cards de
    // movimentação sejam construídos/pintados com escala 2.0 (abaixo do
    // fold o overflow ficaria mascarado).
    tester.view.physicalSize = const Size(360, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final now = DateTime(2024, 1, 10, 10);
    await tester.pumpWidget(
      _buildApp(
        _FakeFinanceRepository([
          FinancialTransaction(
            id: 't1',
            description:
                'Recebimento de venda fiado com um nome extremamente comprido',
            amountCents: 999999999,
            type: TransactionType.income,
            category: 'Vendas',
            date: now,
          ),
          FinancialTransaction(
            id: 't2',
            description: 'Pagamento de fornecedor atacadista',
            amountCents: 999999999,
            type: TransactionType.expense,
            category: 'Contas',
            date: now,
            status: TransactionStatus.pending,
          ),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    // KPIs e o seletor de período seguem visíveis, sem overflow.
    expect(find.text('Entradas'), findsOneWidget);
    expect(find.text('Hoje'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
