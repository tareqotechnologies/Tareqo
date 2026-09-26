import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';
import '../../helpers/viewport.dart';

import 'package:tareqo/core/theme/app_theme.dart';
import 'package:tareqo/domain/entities/cash_closing.dart';
import 'package:tareqo/domain/entities/financial_transaction.dart';
import 'package:tareqo/domain/repositories/i_cash_closing_summary_repository.dart';
import 'package:tareqo/domain/repositories/i_cash_flow_repository.dart';
import 'package:tareqo/domain/repositories/i_cash_closing_processor.dart';
import 'package:tareqo/domain/repositories/i_financial_transaction_repository.dart';
import 'package:tareqo/domain/usecases/close_cash_register_use_case.dart';
import 'package:tareqo/domain/usecases/get_cash_closing_summary_use_case.dart';
import 'package:tareqo/domain/usecases/get_cash_flow_use_case.dart';
import 'package:tareqo/domain/usecases/mark_transaction_as_paid_use_case.dart';
import 'package:tareqo/presentation/controllers/account_providers.dart';
import 'package:tareqo/presentation/controllers/finance_providers.dart';
import 'package:tareqo/presentation/screens/financial/financial_screen.dart';
import 'package:tareqo/presentation/widgets/skeleton.dart';

import '../../helpers/haptic_spy.dart';
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
  _FakeGetCashFlowUseCase([
    this.cashFlow = const CashFlow(incomeCents: 150000, expenseCents: 45000),
  ]);

  final CashFlow cashFlow;

  @override
  final ICashFlowRepository? serverRepository = null;

  @override
  Future<CashFlow> call({
    required String storeId,
    required DateTime start,
    required DateTime end,
  }) async => cashFlow;
}

/// Use case de fluxo de caixa que SEMPRE falha (simula a RPC indisponível)
/// — verifica que a linha de KPIs nunca mostra zeros falsos.
class _FailingGetCashFlowUseCase implements GetCashFlowUseCase {
  @override
  final ICashFlowRepository? serverRepository = null;

  @override
  Future<CashFlow> call({
    required String storeId,
    required DateTime start,
    required DateTime end,
  }) async => throw Exception('RPC falhou');
}

class _FakeMarkTransactionAsPaidUseCase
    implements MarkTransactionAsPaidUseCase {
  _FakeMarkTransactionAsPaidUseCase(this._repository, {this.threw = false});

  final _FakeFinanceRepository _repository;

  /// Simula falha do servidor (teste do caminho de erro).
  final bool threw;

  @override
  Future<void> call(String transactionId, {required String storeId}) async {
    if (threw) throw Exception('erro de servidor');
    await _repository.markAsPaid(transactionId, storeId: storeId);
  }
}

/// Fake do resumo do dia (Z-report) — retorna um resumo determinístico.
class _FakeGetCashClosingSummaryUseCase
    implements GetCashClosingSummaryUseCase {
  _FakeGetCashClosingSummaryUseCase({this.existingClosing});

  final CashClosing? existingClosing;

  @override
  Future<CashClosingSummary> call({
    required String storeId,
    required DateTime day,
  }) async {
    return CashClosingSummary(
      day: DateTime(day.year, day.month, day.day),
      totalSalesCents: 4050,
      expectedCashCents: 1100,
      salesByMethodCents: const {'cash': 1100, 'mPesa': 2950},
      existingClosing: existingClosing,
    );
  }

  @override
  ICashClosingSummaryRepository? get serverRepository => null;
}

/// Fake do fecho — registra a contagem enviada e devolve o fecho.
class _FakeCloseCashRegisterUseCase implements CloseCashRegisterUseCase {
  final List<int> countedCalls = [];
  bool threw = false;

  // Sem processador atômico nos testes (caminho local/computado).
  @override
  final ICashClosingProcessor? processor = null;

  @override
  Future<CashClosing> call({
    required String storeId,
    required DateTime day,
    required int countedCashCents,
  }) async {
    countedCalls.add(countedCashCents);
    if (threw) throw Exception('erro de servidor');
    return CashClosing(
      id: 'cc-$storeId',
      storeId: storeId,
      day: DateTime(day.year, day.month, day.day),
      totalSalesCents: 4050,
      expectedCashCents: 1100,
      countedCashCents: countedCashCents,
      salesByMethodCents: const {'cash': 1100, 'mPesa': 2950},
      closedAt: DateTime.now(),
    );
  }
}

Widget _buildApp(
  _FakeFinanceRepository repository, {
  GetCashFlowUseCase? cashFlowUseCase,
  _FakeGetCashClosingSummaryUseCase? summaryUseCase,
  _FakeCloseCashRegisterUseCase? closeUseCase,
  bool isEmployee = false,
}) {
  return ProviderScope(
    overrides: [
      // Contexto de loja — o Financeiro escopa pela loja ativa.
      ...storeContextOverrides(),
      financeRepositoryProvider.overrideWithValue(repository),
      getCashFlowUseCaseProvider.overrideWithValue(
        cashFlowUseCase ?? _FakeGetCashFlowUseCase(),
      ),
      markTransactionAsPaidUseCaseProvider.overrideWithValue(
        _FakeMarkTransactionAsPaidUseCase(repository),
      ),
      // Fecho de caixa: use cases fake (sem ServiceLocator nos testes).
      getCashClosingSummaryUseCaseProvider.overrideWithValue(
        summaryUseCase ?? _FakeGetCashClosingSummaryUseCase(),
      ),
      closeCashRegisterUseCaseProvider.overrideWithValue(
        closeUseCase ?? _FakeCloseCashRegisterUseCase(),
      ),
      if (isEmployee)
        currentAccessLevelProvider.overrideWithValue(UserAccessLevel.employee),
    ],
    child: testApp(home: const FinancialScreen()),
  );
}

void main() {
  // A11y (Fase 6): saldo, pílula de período, linhas de movimentação e botão
  // de fecho passam nos guidelines de toque (≥48dp) e contraste de texto.
  testWidgets('a11y: caixa passa nos guidelines de toque e contraste', (
    tester,
  ) async {
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
        ]),
      ),
    );
    await tester.pumpAndSettle();

    final handle = tester.ensureSemantics();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });

  late HapticSpy spy;
  setUp(() => spy = HapticSpy()..install());
  tearDown(() => spy.uninstall());

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
    // Estado inicial: carregando (skeleton do card stack + das
    // movimentações).
    expect(find.byType(Skeleton), findsNWidgets(2));

    await tester.pumpAndSettle();

    // O card da lista mostra a CATEGORIA (a descrição só aparece no sheet
    // de detalhes, ao tocar no card).
    expect(find.text('Vendas'), findsOneWidget);
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

    // Card stack do fluxo de caixa (vindos do use case fake): cartão de
    // Entradas à frente, Saídas atrás e a faixa de saldo do período.
    expect(find.text('Entradas'), findsOneWidget);
    expect(find.text('Saídas'), findsOneWidget);
    expect(find.text('Saldo líquido do período'), findsOneWidget);
    // Sub-linhas com sinal e SEM o símbolo repetido (a moeda fica na
    // pílula + saldo); o saldo mantém o formato completo.
    expect(find.text('+1.500,00'), findsOneWidget);
    expect(find.text('-450,00'), findsOneWidget);
    expect(find.text('R\$ 1.050,00'), findsOneWidget);
    // Movimentações — o card stack é mais alto que a antiga linha de KPIs,
    // então a lista fica abaixo do fold no viewport do teste (800×600).
    await tester.scrollUntilVisible(
      find.text('Fiado'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    // Cada card da lista mostra a categoria da transação.
    expect(find.text('Vendas'), findsOneWidget);
    expect(find.text('Contas'), findsOneWidget);
    expect(find.text('Fiado'), findsOneWidget);
    // Valores com sinal e moeda em cada card.
    expect(find.text('+ R\$ 1.000,00'), findsOneWidget);
    expect(find.text('- R\$ 200,00'), findsOneWidget);
    expect(find.text('+ R\$ 25,00'), findsOneWidget);
    // A pendência é sinalizada no subtítulo da seção.
    expect(find.text('Pendente (fiado) · 1'), findsOneWidget);
    // Hora do movimento em cada card.
    expect(find.text('10:00'), findsNWidgets(3));

    // As cores semânticas resolvem para a variante ESCURA no tema escuro
    // (testApp aplica AppTheme.dark — V3) — texto de valor com AA sobre o card.
    final incomeText = tester.widget<Text>(find.text('+ R\$ 1.000,00'));
    expect(incomeText.style?.color, AppColors.income);
    final expenseText = tester.widget<Text>(find.text('- R\$ 200,00'));
    expect(expenseText.style?.color, AppColors.expense);
  });

  testWidgets('botão Pagar marca a saída pendente como paga', (tester) async {
    final now = DateTime(2024, 1, 10, 10);
    final repository = _FakeFinanceRepository([
      FinancialTransaction(
        id: 't4',
        description: 'Conta de luz',
        amountCents: 5000,
        type: TransactionType.expense,
        category: 'Contas',
        date: now,
        status: TransactionStatus.pending,
      ),
    ]);
    await tester.pumpWidget(_buildApp(repository));
    await tester.pumpAndSettle();

    // A saída pendente é sinalizada no subtítulo da seção.
    expect(find.text('Pendente (fiado) · 1'), findsOneWidget);
    expect(find.text('Receber'), findsNothing);

    // Abre o detalhe da pendência (a descrição e o estado ficam no sheet).
    await tester.tap(find.text('Contas'));
    await tester.pumpAndSettle();
    expect(find.text('Conta de luz'), findsOneWidget);
    expect(find.text('Pendente'), findsOneWidget);
    // A saída pendente oferece a quitação (não o recebimento).
    expect(find.text('Pagar'), findsOneWidget);
    expect(find.text('Receber'), findsNothing);

    // A ação fecha o sheet e abre a confirmação.
    await tester.tap(find.text('Pagar'));
    await tester.pumpAndSettle();
    expect(find.text('Pagar pendência?'), findsOneWidget);

    // Confirma o pagamento.
    await tester.tap(find.widgetWithText(FilledButton, 'Pagar'));
    await tester.pumpAndSettle();

    expect(find.text('Saída paga!'), findsOneWidget);

    // Após invalidar, a transação está paga — reabre o detalhe: estado
    // 'Pago' e sem ação de quitação (sem botão para transações pagas).
    await tester.tap(find.text('Contas'));
    await tester.pumpAndSettle();
    expect(find.text('Pendente'), findsNothing);
    expect(find.text('Pagar'), findsNothing);
    expect(find.text('Pago'), findsOneWidget);
  });

  testWidgets('erro ao pagar mostra a mensagem de falha', (tester) async {
    final now = DateTime(2024, 1, 10, 10);
    final repository = _FakeFinanceRepository([
      FinancialTransaction(
        id: 't4',
        description: 'Conta de luz',
        amountCents: 5000,
        type: TransactionType.expense,
        category: 'Contas',
        date: now,
        status: TransactionStatus.pending,
      ),
    ]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...storeContextOverrides(),
          financeRepositoryProvider.overrideWithValue(repository),
          getCashFlowUseCaseProvider.overrideWithValue(
            _FakeGetCashFlowUseCase(),
          ),
          // Quitação com FALHA simulada (servidor indisponível).
          markTransactionAsPaidUseCaseProvider.overrideWithValue(
            _FakeMarkTransactionAsPaidUseCase(repository, threw: true),
          ),
          getCashClosingSummaryUseCaseProvider.overrideWithValue(
            _FakeGetCashClosingSummaryUseCase(),
          ),
          closeCashRegisterUseCaseProvider.overrideWithValue(
            _FakeCloseCashRegisterUseCase(),
          ),
        ],
        child: testApp(home: const FinancialScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Abre o detalhe da saída pendente e tenta quitar.
    await tester.tap(find.text('Contas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pagar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Pagar'));
    await tester.pumpAndSettle();

    // O erro aparece e a pendência continua pendente (não foi quitada).
    expect(
      find.text('Não foi possível pagar a pendência. Tente novamente.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Contas'));
    await tester.pumpAndSettle();
    expect(find.text('Pendente'), findsOneWidget);
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

    expect(find.text('Pendente (fiado) · 1'), findsOneWidget);

    // Abre o detalhe da entrada pendente.
    await tester.tap(find.text('Fiado'));
    await tester.pumpAndSettle();
    expect(find.text('Venda fiado (João)'), findsOneWidget);
    expect(find.text('Pendente'), findsOneWidget);

    // A ação fecha o sheet e abre a confirmação.
    await tester.tap(find.text('Receber'));
    await tester.pumpAndSettle();
    expect(find.text('Receber pendência?'), findsOneWidget);

    // Confirma o recebimento.
    await tester.tap(find.widgetWithText(FilledButton, 'Receber'));
    await tester.pumpAndSettle();

    expect(find.text('Movimentação recebida!'), findsOneWidget);

    // Após invalidar, a transação está paga — reabre o detalhe: estado
    // 'Pago' e o estado pendente some.
    await tester.tap(find.text('Fiado'));
    await tester.pumpAndSettle();
    expect(find.text('Pendente'), findsNothing);
    expect(find.text('Pago'), findsOneWidget);
  });

  // Semântica de caixa (UI): o valor da faixa de saldo segue o SINAL —
  // verde (income) para saldos ≥ 0, vermelho (expense) para negativos.
  // Saldo negativo em verde seria informação errada num produto financeiro.
  Color saldoColor(WidgetTester tester) {
    final text = tester.widget<Text>(find.text('R\$ 1.050,00'));
    return text.style?.color ?? const Color(0x00000000);
  }

  testWidgets('saldo positivo usa a cor de entrada (verde)', (tester) async {
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
        ]),
      ),
    );
    await tester.pumpAndSettle();

    // Saldo POSITIVO (padrão: 150000 − 45000 = 105000) → verde.
    expect(saldoColor(tester), AppColors.income);
  });

  testWidgets('saldo negativo usa a cor de saída (vermelho)', (tester) async {
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
        ]),
        // Saldo NEGATIVO (10000 − 20000 = −100) → vermelho.
        cashFlowUseCase: _FakeGetCashFlowUseCase(
          const CashFlow(incomeCents: 10000, expenseCents: 20000),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Saldo NEGATIVO (10000 − 20000 = −100) → o valor na faixa fica vermelho.
    final text = tester.widget<Text>(find.text('R\$ -100,00'));
    expect(text.style?.color, AppColors.expense);
    expect(tester.takeException(), isNull);
  });

  // Regressão (UX): a RPC do fluxo de caixa falhar sem dados anteriores
  // fazia os três KPIs exibirem "R$ 0,00" — números falsos parecendo
  // reais. Agora a linha dá lugar a um aviso com retry; as movimentações
  // (provider próprio) seguem funcionando.
  testWidgets(
    'falha no fluxo de caixa mostra aviso com retry em vez de zeros',
    (tester) async {
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
          ]),
          cashFlowUseCase: _FailingGetCashFlowUseCase(),
        ),
      );
      await tester.pumpAndSettle();

      // Aviso com retry no lugar da linha de KPIs.
      expect(
        find.text('Não foi possível carregar o fluxo de caixa.'),
        findsOneWidget,
      );
      expect(find.text('Tentar novamente'), findsOneWidget);
      // Nenhum rótulo do card stack com zero falso.
      expect(find.text('Entradas'), findsNothing);
      expect(find.text('Saídas'), findsNothing);
      expect(find.text('Saldo do período'), findsNothing);
      // As movimentações continuam funcionando (provider próprio) — o card
      // da lista mostra a categoria.
      expect(find.text('Vendas'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  // Rotação (UI): em paisagem a largura maior permite o SegmentedButton de
  // período renderizar sem o FittedBox encolher (escala natural) e os três
  // KPIs seguem lado a lado com os Expanded. Overflows de RenderFlex
  // falham o teste via takeException; trocar de período após o giro prova
  // que o seletor continua funcional.
  testWidgets('KPIs e seletor de período sobrevivem à rotação para paisagem', (
    tester,
  ) async {
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

    // Retrato: o card stack e o seletor de período visíveis.
    expect(find.text('Entradas'), findsOneWidget);
    expect(find.text('Saídas'), findsOneWidget);
    expect(find.text('Saldo líquido do período'), findsOneWidget);
    expect(find.byType(SegmentedButton<CashFlowPeriod>), findsOneWidget);
    expect(find.text('Este mês'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Gira para paisagem.
    await rotateToLandscape(tester);

    // Sem overflow; card stack e seletor seguem presentes após o giro.
    expect(tester.takeException(), isNull);
    expect(find.text('Entradas'), findsOneWidget);
    expect(find.text('Saídas'), findsOneWidget);
    expect(find.text('Saldo líquido do período'), findsOneWidget);
    expect(find.text('+1.500,00'), findsOneWidget);
    expect(find.text('-450,00'), findsOneWidget);
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

  group('Fecho de caixa (Z-report)', () {
    testWidgets('dono/gerente vê o botão de fecho no AppBar', (tester) async {
      // Dono (padrão do storeContextOverrides) → operação GERENCIAL visível.
      await tester.pumpWidget(_buildApp(_FakeFinanceRepository(const [])));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Fecho de caixa'), findsOneWidget);
    });

    testWidgets('funcionário comum NÃO vê o botão (operação gerencial)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(_FakeFinanceRepository(const []), isEmployee: true),
      );
      await tester.pumpAndSettle();
      // A autoridade é o servidor (RPC close_cash_register); aqui só a
      // navegação é orientada pelo nível de acesso.
      expect(find.byTooltip('Fecho de caixa'), findsNothing);
    });

    testWidgets(
      'abre o sheet com resumo do dia, abertura por forma e contagem',
      (tester) async {
        await tester.pumpWidget(_buildApp(_FakeFinanceRepository(const [])));
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Fecho de caixa'));
        await tester.pumpAndSettle();

        // Título + resumo do dia.
        expect(find.text('Fecho de caixa do dia'), findsOneWidget);
        expect(find.text('Resumo do dia'), findsOneWidget);
        expect(find.text('Vendas do dia'), findsOneWidget);
        // Total 4050 → R$ 40,50 (todas as formas); esperado 1100 → R$ 11,00.
        expect(find.text('R\$ 40,50'), findsOneWidget);
        expect(find.text('R\$ 11,00'), findsWidgets);
        // Abertura por forma: Dinheiro (1100) e M-Pesa (2950).
        expect(find.text('Por forma de pagamento'), findsOneWidget);
        expect(find.text('Dinheiro'), findsOneWidget);
        expect(find.text('M-Pesa'), findsOneWidget);
        expect(find.text('R\$ 29,50'), findsOneWidget);
        // Campo da conferência física + botão de confirmar.
        expect(find.text('Dinheiro contado'), findsOneWidget);
        expect(find.text('Confirmar fecho'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'diferença ao vivo: confere, sobra e falta conforme a contagem',
      (tester) async {
        await tester.pumpWidget(_buildApp(_FakeFinanceRepository(const [])));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Fecho de caixa'));
        await tester.pumpAndSettle();

        final countedField = find.byType(TextField);

        // Esperado (1100): caixa confere.
        await tester.enterText(countedField, '11.00');
        await tester.pump();
        expect(find.text('Caixa confere'), findsOneWidget);

        // Sobra: contado (1200) > esperado (1100).
        await tester.enterText(countedField, '12.00');
        await tester.pump();
        expect(find.text('Sobra de R\$ 1,00'), findsOneWidget);

        // Falta: contado (1000) < esperado (1100).
        await tester.enterText(countedField, '10.00');
        await tester.pump();
        expect(find.text('Falta de R\$ 1,00'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Confirmar fecho envia a contagem e mostra o sucesso', (
      tester,
    ) async {
      final closeUseCase = _FakeCloseCashRegisterUseCase();
      await tester.pumpWidget(
        _buildApp(_FakeFinanceRepository(const []), closeUseCase: closeUseCase),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Fecho de caixa'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '11.00');
      await tester.pump();
      await tester.tap(find.text('Confirmar fecho'));
      await tester.pumpAndSettle();

      // A contagem digitada (1100 centavos) chegou ao use case.
      expect(closeUseCase.countedCalls, [1100]);
      expect(find.text('Caixa fechado!'), findsWidgets);
      // Confirmação tátil do fecho (operação gerencial).
      expect(spy.mediumImpacts, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('dia já fechado: chip de horário + botão Atualizar fecho', (
      tester,
    ) async {
      final existing = CashClosing(
        id: 'cc-st1-20260810',
        storeId: 'st1',
        day: DateTime(2026, 8, 10),
        totalSalesCents: 4050,
        expectedCashCents: 1100,
        countedCashCents: 1100,
        salesByMethodCents: const {'cash': 1100, 'mPesa': 2950},
        closedAt: DateTime(2026, 8, 10, 19, 30),
      );
      await tester.pumpWidget(
        _buildApp(
          _FakeFinanceRepository(const []),
          summaryUseCase: _FakeGetCashClosingSummaryUseCase(
            existingClosing: existing,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Fecho de caixa'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Fechado em'), findsOneWidget);
      expect(find.text('Atualizar fecho'), findsOneWidget);
      expect(find.text('Confirmar fecho'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
