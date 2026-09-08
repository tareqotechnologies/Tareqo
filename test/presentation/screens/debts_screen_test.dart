import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';
import '../../helpers/viewport.dart';

import 'package:tareqo/domain/entities/debt.dart';
import 'package:tareqo/domain/repositories/i_debt_processor.dart';
import 'package:tareqo/domain/usecases/get_pending_debts_use_case.dart';
import 'package:tareqo/domain/usecases/get_settled_debts_use_case.dart';
import 'package:tareqo/domain/usecases/settle_debt_use_case.dart';
import 'package:tareqo/presentation/controllers/debts_providers.dart';
import 'package:tareqo/presentation/screens/credit/debts_screen.dart';
import 'package:tareqo/presentation/widgets/app_card.dart';

import '../../helpers/store_context.dart';

class _FakeGetPendingDebtsUseCase implements GetPendingDebtsUseCase {
  _FakeGetPendingDebtsUseCase(this._debts);

  final List<Debt> _debts;

  // Espelha o filtro do caso de uso real: só cliente e não quitada.
  @override
  Future<List<Debt>> call({required String storeId}) async => List.unmodifiable(
    _debts.where((debt) => debt.isCustomerDebt && !debt.isPaid),
  );
}

class _FakeSettleDebtUseCase implements SettleDebtUseCase {
  _FakeSettleDebtUseCase([this._onSettle]);

  final void Function(String debtId)? _onSettle;
  final List<String> called = [];

  // Processador atômico: não usado nos testes da tela.
  @override
  IDebtAtomicProcessor? get processor => null;

  @override
  Future<void> call(String debtId, {required String storeId}) async {
    called.add(debtId);
    _onSettle?.call(debtId);
  }
}

class _FakeGetSettledDebtsUseCase implements GetSettledDebtsUseCase {
  const _FakeGetSettledDebtsUseCase(this._debts);

  final List<Debt> _debts;

  // Espelha o filtro do caso de uso real: só cliente e já quitada.
  @override
  Future<List<Debt>> call({required String storeId}) async => List.unmodifiable(
    _debts.where((debt) => debt.isCustomerDebt && debt.isPaid),
  );
}

Widget _buildApp({
  required GetPendingDebtsUseCase useCase,
  required SettleDebtUseCase settleUseCase,
  GetSettledDebtsUseCase settledUseCase = const _FakeGetSettledDebtsUseCase([]),
}) {
  return ProviderScope(
    overrides: [
      // Contexto de loja — o fiado escopa pela loja ativa e a baixa
      // carimba a loja no recebimento.
      ...storeContextOverrides(),
      getPendingDebtsUseCaseProvider.overrideWithValue(useCase),
      getSettledDebtsUseCaseProvider.overrideWithValue(settledUseCase),
      settleDebtUseCaseProvider.overrideWithValue(settleUseCase),
    ],
    child: testApp(home: DebtsScreen()),
  );
}

List<Debt> _debts() => [
  Debt(
    id: 'd1',
    number: 1,
    personName: 'João',
    amountCents: 2500,
    dueDate: DateTime(2026, 8, 6),
    isCustomerDebt: true,
  ),
  Debt(
    id: 'd2',
    number: 2,
    personName: 'Maria Souza',
    amountCents: 6000,
    dueDate: DateTime(2026, 8, 1),
    isCustomerDebt: true,
  ),
];

void main() {
  testWidgets('mostra o total a receber e as dívidas pendentes', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        useCase: _FakeGetPendingDebtsUseCase(_debts()),
        settleUseCase: _FakeSettleDebtUseCase(),
      ),
    );

    await tester.pumpAndSettle();

    // Total a receber = 25 + 60.
    expect(find.text('R\$ 85,00'), findsOneWidget);
    expect(find.text('João'), findsOneWidget);
    expect(find.text('Maria Souza'), findsOneWidget);
    // Número SEQUENCIAL do fiado na loja na descrição do card (V3).
    expect(find.textContaining('D-00001'), findsOneWidget); // d1 (João)
    expect(find.textContaining('D-00002'), findsOneWidget); // d2 (Maria)
    // Resumo V3: total a receber + stat de atrasados ao lado.
    expect(find.text('Atrasados'), findsOneWidget);
    // Sem FAB próprio (canvas V3 — a criação de fiado vive no FAB central).
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.text('Quitar dívida'), findsNWidgets(2));
  });

  testWidgets('mostra estado vazio quando ninguém deve', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        useCase: _FakeGetPendingDebtsUseCase(const []),
        settleUseCase: _FakeSettleDebtUseCase(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Nenhum fiado pendente'), findsOneWidget);
    // Empty state sóbrio ("tudo em dia" — check, sem ícone de festa).
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    // CTA ÚNICO (canvas V3): sem FAB próprio na tela, o estado vazio traz
    // sempre o botão "Registrar fiado".
    expect(find.text('Registrar fiado'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('quitar dívida confirma, chama o use case e a dívida some', (
    tester,
  ) async {
    // A baixa muta a lista de dívidas do fake de pendências (como o
    // datasource real faria) — a tela deve re-renderizar sem o item.
    final debts = _debts();
    final settle = _FakeSettleDebtUseCase((debtId) {
      final index = debts.indexWhere((debt) => debt.id == debtId);
      debts[index] = debts[index].copyWith(isPaid: true);
    });
    await tester.pumpWidget(
      _buildApp(
        useCase: _FakeGetPendingDebtsUseCase(debts),
        settleUseCase: settle,
      ),
    );
    await tester.pumpAndSettle();

    // Toca no botão 'Quitar dívida' do card do João (a lista é ordenada
    // por vencimento: Maria, que vence antes, aparece primeiro).
    final joaoCard = find.ancestor(
      of: find.text('João'),
      matching: find.byType(AppCard),
    );
    // O campo de busca desceu o card — garante o botão visível antes do
    // toque (a lista rola até ele).
    final settleButton = find.descendant(
      of: joaoCard,
      matching: find.text('Quitar dívida'),
    );
    await tester.ensureVisible(settleButton);
    // O salto do ensureVisible só renderiza no próximo frame — sem o pump
    // o tap miraria a posição antiga (fora da viewport).
    await tester.pumpAndSettle();
    await tester.tap(settleButton);
    await tester.pumpAndSettle();

    // Diálogo de confirmação aparece com o valor e a pessoa certos.
    expect(find.text('Quitar dívida?'), findsOneWidget);
    expect(find.textContaining('Receber R\$ 25,00 de João'), findsOneWidget);

    await tester.tap(find.text('Quitar'));
    await tester.pumpAndSettle();

    expect(settle.called, ['d1']);
    expect(find.textContaining('no caixa'), findsOneWidget);

    // João foi quitado e sai da lista pendente; Maria permanece.
    expect(find.text('João'), findsNothing);
    expect(find.text('Maria Souza'), findsOneWidget);
    expect(find.text('Quitar dívida'), findsOneWidget);
  });

  testWidgets('aba Quitadas mostra o histórico de quitações', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        useCase: _FakeGetPendingDebtsUseCase(_debts()),
        settleUseCase: _FakeSettleDebtUseCase(),
        settledUseCase: _FakeGetSettledDebtsUseCase([
          Debt(
            id: 'd5',
            number: 1,
            personName: 'Ana Lima',
            amountCents: 4000,
            dueDate: DateTime(2026, 7, 15),
            isCustomerDebt: true,
            isPaid: true,
            paidAt: DateTime(2026, 8, 3),
          ),
          // Sem data de baixa (dados migrados) — chip fallback 'Quitada'.
          Debt(
            id: 'd6',
            number: 2,
            personName: 'Carlos',
            amountCents: 1500,
            dueDate: DateTime(2026, 7, 1),
            isCustomerDebt: true,
            isPaid: true,
          ),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    // Aba de pendentes é a padrão — a quitada não aparece aqui.
    expect(find.text('Ana Lima'), findsNothing);

    await tester.tap(find.text('Quitadas'));
    await tester.pumpAndSettle();

    expect(find.text('Total quitado'), findsOneWidget);
    expect(find.text('R\$ 55,00'), findsOneWidget); // resumo (40 + 15)
    expect(find.text('R\$ 40,00'), findsOneWidget); // card Ana
    expect(find.text('R\$ 15,00'), findsOneWidget); // card Carlos
    expect(find.text('Ana Lima'), findsOneWidget);
    expect(find.text('Quitada em 03/08/2026'), findsOneWidget);
    expect(find.text('Carlos'), findsOneWidget);
    expect(find.text('Quitada'), findsOneWidget); // fallback sem data
    // Número SEQUENCIAL também no histórico de quitações.
    expect(find.text('D-00001'), findsOneWidget); // d5 (Ana Lima)
    expect(find.text('D-00002'), findsOneWidget); // d6 (Carlos)
    // Sem ação de quitação no histórico.
    expect(find.text('Quitar dívida'), findsNothing);
  });

  testWidgets('quitar dívida também a registra no histórico (aba Quitadas)', (
    tester,
  ) async {
    // Lista compartilhada: a baixa muta a dívida e os fakes refletem.
    final debts = _debts();
    final settle = _FakeSettleDebtUseCase((debtId) {
      final index = debts.indexWhere((debt) => debt.id == debtId);
      debts[index] = debts[index].copyWith(
        isPaid: true,
        paidAt: DateTime(2026, 8, 3),
      );
    });
    await tester.pumpWidget(
      _buildApp(
        useCase: _FakeGetPendingDebtsUseCase(debts),
        settleUseCase: settle,
        settledUseCase: _FakeGetSettledDebtsUseCase(debts),
      ),
    );
    await tester.pumpAndSettle();

    // Antes da baixa, o histórico está vazio.
    await tester.tap(find.text('Quitadas'));
    await tester.pumpAndSettle();
    expect(find.text('Nenhuma quitação ainda'), findsOneWidget);

    // Volta para Pendentes e quita a dívida do João.
    await tester.tap(find.text('Pendentes'));
    await tester.pumpAndSettle();
    final joaoCard = find.ancestor(
      of: find.text('João'),
      matching: find.byType(AppCard),
    );
    // O campo de busca desceu o card — garante o botão visível antes do
    // toque (a lista rola até ele).
    final settleButton = find.descendant(
      of: joaoCard,
      matching: find.text('Quitar dívida'),
    );
    await tester.ensureVisible(settleButton);
    // O salto do ensureVisible só renderiza no próximo frame — sem o pump
    // o tap miraria a posição antiga (fora da viewport).
    await tester.pumpAndSettle();
    await tester.tap(settleButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quitar'));
    await tester.pumpAndSettle();

    // O João sai de pendentes e entra no histórico com a data da baixa.
    await tester.tap(find.text('Quitadas'));
    await tester.pumpAndSettle();
    expect(find.text('João'), findsOneWidget);
    expect(find.text('Quitada em 03/08/2026'), findsOneWidget);
    expect(find.text('Nenhuma quitação ainda'), findsNothing);
  });

  testWidgets('busca filtra fiado pendente pelo nome do devedor', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        useCase: _FakeGetPendingDebtsUseCase(_debts()),
        settleUseCase: _FakeSettleDebtUseCase(),
      ),
    );
    await tester.pumpAndSettle();

    // Ambos visíveis antes da busca.
    expect(find.text('João'), findsOneWidget);
    expect(find.text('Maria Souza'), findsOneWidget);
    expect(find.text('R\$ 85,00'), findsOneWidget); // resumo (25 + 60)

    // Case-insensitive: 'JO' acha 'João'.
    await tester.enterText(find.byType(TextField), 'JO');
    await tester.pumpAndSettle();

    expect(find.text('João'), findsOneWidget);
    expect(find.text('Maria Souza'), findsNothing);
    // Resumo V3 reflete o filtro: total (25,00) + stat de atrasados.
    expect(find.text('Atrasados'), findsOneWidget);
    // 'R\$ 25,00' aparece duas vezes: resumo filtrado + card do João.
    expect(find.text('R\$ 25,00'), findsNWidgets(2));
  });

  testWidgets('busca sem resultado mostra o estado próprio (sem CTA)', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        useCase: _FakeGetPendingDebtsUseCase(_debts()),
        settleUseCase: _FakeSettleDebtUseCase(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();

    expect(find.text('Nenhum resultado'), findsOneWidget);
    expect(find.text('João'), findsNothing);
    expect(find.text('Maria Souza'), findsNothing);
    // Busca vazia NÃO oferece o CTA de registrar fiado (a busca é sobre a
    // lista carregada, não sobre a loja) — e não há FAB próprio (canvas).
    expect(find.text('Registrar fiado'), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('busca filtra também o histórico de quitações', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        useCase: _FakeGetPendingDebtsUseCase(_debts()),
        settleUseCase: _FakeSettleDebtUseCase(),
        settledUseCase: _FakeGetSettledDebtsUseCase([
          Debt(
            id: 'd5',
            number: 1,
            personName: 'Ana Lima',
            amountCents: 4000,
            dueDate: DateTime(2026, 7, 15),
            isCustomerDebt: true,
            isPaid: true,
            paidAt: DateTime(2026, 8, 3),
          ),
          Debt(
            id: 'd6',
            number: 2,
            personName: 'Carlos',
            amountCents: 1500,
            dueDate: DateTime(2026, 7, 1),
            isCustomerDebt: true,
            isPaid: true,
          ),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Quitadas'));
    await tester.pumpAndSettle();
    expect(find.text('Ana Lima'), findsOneWidget);
    expect(find.text('Carlos'), findsOneWidget);

    // 'ANA' (maiúsculas) acha 'Ana Lima' e esconde 'Carlos'.
    await tester.enterText(find.byType(TextField), 'ANA');
    await tester.pumpAndSettle();

    expect(find.text('Ana Lima'), findsOneWidget);
    expect(find.text('Carlos'), findsNothing);
    // Total quitado filtrado: só Ana (40,00) — resumo + card.
    expect(find.text('R\$ 40,00'), findsNWidgets(2));
    // Resumo V3: stat de baixas ao lado do total.
    expect(find.text('Baixas'), findsOneWidget);
  });

  testWidgets('aba Quitadas vazia mostra estado sem quitações', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        useCase: _FakeGetPendingDebtsUseCase(_debts()),
        settleUseCase: _FakeSettleDebtUseCase(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Quitadas'));
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma quitação ainda'), findsOneWidget);
  });

  testWidgets('cancelar no diálogo não quita a dívida', (tester) async {
    final settle = _FakeSettleDebtUseCase();
    await tester.pumpWidget(
      _buildApp(
        useCase: _FakeGetPendingDebtsUseCase(_debts()),
        settleUseCase: settle,
      ),
    );
    await tester.pumpAndSettle();

    final joaoCard = find.ancestor(
      of: find.text('João'),
      matching: find.byType(AppCard),
    );
    // O campo de busca desceu o card — garante o botão visível antes do
    // toque (a lista rola até ele).
    final settleButton = find.descendant(
      of: joaoCard,
      matching: find.text('Quitar dívida'),
    );
    await tester.ensureVisible(settleButton);
    // O salto do ensureVisible só renderiza no próximo frame — sem o pump
    // o tap miraria a posição antiga (fora da viewport).
    await tester.pumpAndSettle();
    await tester.tap(settleButton);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(settle.called, isEmpty);
  });

  // Regressão (UI): os valores dos cards e o seletor de abas ficavam sem
  // Flexível/FittedBox — com escala de texto 2.0 em tela estreita, os Rows
  // estouravam. Agora os valores encolhem (ellipsis) e as abas escalam;
  // overflows de RenderFlex falham o teste via takeException.
  testWidgets('não estoura com escala de texto 2.0 em tela estreita', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearAllTestValues);

    // Estreita (360) porém alta: garante que resumo e cards sejam
    // construídos/pintados com escala 2.0 (abaixo do fold o overflow
    // ficaria mascarado).
    tester.view.physicalSize = const Size(360, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _buildApp(
        useCase: _FakeGetPendingDebtsUseCase([
          Debt(
            id: 'd1',
            personName: 'Estabelecimento Comercial Santana de Parnaíba',
            amountCents: 999999999,
            dueDate: DateTime(2026, 8, 1),
            isCustomerDebt: true,
          ),
        ]),
        settleUseCase: _FakeSettleDebtUseCase(),
      ),
    );
    await tester.pumpAndSettle();

    // Resumo e card seguem renderizados, sem overflow (sem FAB próprio —
    // canvas V3).
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(tester.takeException(), isNull);
  });

  // Rotação (UI): aba Fiado em paisagem — abas Pendentes/Quitadas,
  // resumo e cards seguem íntegros após o giro; trocar de aba em
  // paisagem continua funcionando. Overflows de RenderFlex falham o
  // teste via takeException.
  testWidgets('fiado sobrevive à rotação para paisagem', (tester) async {
    usePortraitViewport(tester);

    await tester.pumpWidget(
      _buildApp(
        useCase: _FakeGetPendingDebtsUseCase(_debts()),
        settleUseCase: _FakeSettleDebtUseCase(),
      ),
    );
    await tester.pumpAndSettle();

    // Retrato: abas + resumo + dívidas pendentes.
    expect(find.text('Pendentes'), findsOneWidget);
    expect(find.text('Quitadas'), findsOneWidget);
    expect(find.text('João'), findsOneWidget);
    expect(find.text('Maria Souza'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Gira para paisagem.
    await rotateToLandscape(tester);

    // Sem overflow; abas e dívidas seguem presentes após o giro.
    expect(tester.takeException(), isNull);
    expect(find.text('Pendentes'), findsOneWidget);
    expect(find.text('João'), findsOneWidget);
    expect(find.text('Maria Souza'), findsOneWidget);

    // Trocar para Quitadas em paisagem continua funcionando.
    await tester.tap(find.text('Quitadas'));
    await tester.pumpAndSettle();
    expect(find.text('Histórico de quitações'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
