import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

import 'package:dumbhanengue/domain/entities/debt.dart';
import 'package:dumbhanengue/domain/repositories/i_debt_processor.dart';
import 'package:dumbhanengue/domain/usecases/get_pending_debts_use_case.dart';
import 'package:dumbhanengue/domain/usecases/get_settled_debts_use_case.dart';
import 'package:dumbhanengue/domain/usecases/settle_debt_use_case.dart';
import 'package:dumbhanengue/presentation/controllers/debts_providers.dart';
import 'package:dumbhanengue/presentation/screens/credit/debts_screen.dart';

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
    personName: 'João',
    amount: 25.0,
    dueDate: DateTime(2026, 8, 6),
    isCustomerDebt: true,
  ),
  Debt(
    id: 'd2',
    personName: 'Maria Souza',
    amount: 60.0,
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
    expect(find.text('Registrar fiado'), findsOneWidget);
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

    expect(find.text('Nenhum fiado pendente 🎉'), findsOneWidget);
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
      matching: find.byType(Card),
    );
    await tester.tap(
      find.descendant(of: joaoCard, matching: find.text('Quitar dívida')),
    );
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
            personName: 'Ana Lima',
            amount: 40.0,
            dueDate: DateTime(2026, 7, 15),
            isCustomerDebt: true,
            isPaid: true,
            paidAt: DateTime(2026, 8, 3),
          ),
          // Sem data de baixa (dados migrados) — chip fallback 'Quitada'.
          Debt(
            id: 'd6',
            personName: 'Carlos',
            amount: 15.0,
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
    // Sem ação de quitação no histórico.
    expect(find.text('Quitar dívida'), findsNothing);
  });

  testWidgets('quitar dívida também a registra no histórico (aba Quitadas)',
      (tester) async {
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
      matching: find.byType(Card),
    );
    await tester.tap(
      find.descendant(of: joaoCard, matching: find.text('Quitar dívida')),
    );
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
      matching: find.byType(Card),
    );
    await tester.tap(
      find.descendant(of: joaoCard, matching: find.text('Quitar dívida')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(settle.called, isEmpty);
  });
}
