import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

import 'package:tareqo/data/services/offline_sync_service.dart';
import 'package:tareqo/domain/entities/customer.dart';
import 'package:tareqo/domain/entities/debt.dart';
import 'package:tareqo/domain/repositories/i_debt_processor.dart';
import 'package:tareqo/domain/usecases/add_debt_use_case.dart';
import 'package:tareqo/presentation/controllers/customers_providers.dart';
import 'package:tareqo/presentation/controllers/debts_providers.dart';
import 'package:tareqo/presentation/screens/credit/add_debt_sheet.dart';

/// Registra a dívida sem tocar em infraestrutura (o AddDebtUseCase já é
/// coberto por testes de domínio — aqui validamos apenas a orquestração da UI).
class _FakeAddDebtUseCase implements AddDebtUseCase {
  int calls = 0;
  Debt? lastDebt;
  Object? error;

  @override
  Future<void> call(Debt debt) async {
    calls++;
    lastDebt = debt;
    final e = error;
    if (e != null) throw e;
  }

  @override
  IDebtAtomicProcessor? get processor => null;
}

/// Fake do estado de clientes (o notifier real exige auth/store). Two
/// clientes para exercitar os chips de vínculo.
class _FakeCustomersNotifier extends CustomersNotifier {
  @override
  Future<List<Customer>> build() async => const [
    Customer(id: 'c1', name: 'Maria Souza'),
    Customer(id: 'c2', name: 'João Macuácua'),
  ];
}

Future<ProviderContainer> _pump(
  WidgetTester tester,
  _FakeAddDebtUseCase addDebt,
) async {
  final container = ProviderContainer(
    overrides: [
      addDebtUseCaseProvider.overrideWithValue(addDebt),
      customersProvider.overrideWith(_FakeCustomersNotifier.new),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      // O sheet é PUSHADO como rota real: os fluxos de sucesso/offline
      // dão pop antes do snackbar — sem rota base, o snackbar fica sem
      // Scaffold e some.
      child: testApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const Scaffold(body: AddDebtSheet()),
                  ),
                ),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('registar fiado chama o AddDebtUseCase e mostra o snackbar', (
    tester,
  ) async {
    final addDebt = _FakeAddDebtUseCase();
    await _pump(tester, addDebt);

    // Nome e valor (o campo de vencimento é um seletor, não um TextFormField).
    await tester.enterText(find.byType(TextFormField).at(0), 'Maria Souza');
    await tester.enterText(find.byType(TextFormField).at(1), '50,00');

    // O cabeçalho também se chama 'Registar fiado' — toca no botão.
    await tester.tap(find.widgetWithText(FilledButton, 'Registar fiado'));
    await tester.pumpAndSettle();

    expect(addDebt.calls, 1);
    expect(addDebt.lastDebt?.personName, 'Maria Souza');
    expect(addDebt.lastDebt?.amountCents, 5000);
    expect(addDebt.lastDebt?.isCustomerDebt, isTrue);
  });

  testWidgets('vincular cliente preenche o nome e grava o customerId', (
    tester,
  ) async {
    // given — módulo de clientes com 2 cadastrados: os chips aparecem.
    final addDebt = _FakeAddDebtUseCase();
    await _pump(tester, addDebt);

    expect(find.text('Cliente vinculado (opcional)'), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNWidgets(3)); // Sem vínculo + 2.

    // when — seleciona "João Macuácua" e envia (nome é preenchido).
    await tester.tap(find.text('João Macuácua'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, 'João Macuácua'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(1), '75,50');
    await tester.tap(find.widgetWithText(FilledButton, 'Registar fiado'));
    await tester.pumpAndSettle();

    // then — snapshot do nome + vínculo persistidos.
    expect(addDebt.lastDebt?.personName, 'João Macuácua');
    expect(addDebt.lastDebt?.customerId, 'c2');
    expect(addDebt.lastDebt?.amountCents, 7550);
  });

  testWidgets('voltar para "Sem vínculo" limpa o customerId (fiado avulso)', (
    tester,
  ) async {
    // given
    final addDebt = _FakeAddDebtUseCase();
    await _pump(tester, addDebt);
    await tester.tap(find.text('Maria Souza'));
    await tester.pumpAndSettle();

    // when — desseleciona: chip "Sem vínculo" volta a ser o ativo.
    await tester.tap(find.text('Sem vínculo'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Cliente Avulso');
    await tester.enterText(find.byType(TextFormField).at(1), '10,00');
    await tester.tap(find.widgetWithText(FilledButton, 'Registar fiado'));
    await tester.pumpAndSettle();

    // then — dívida sem vínculo, nome digitado manualmente preservado.
    expect(addDebt.lastDebt?.customerId, isNull);
    expect(addDebt.lastDebt?.personName, 'Cliente Avulso');
  });

  testWidgets('valor inválido ou zero bloqueia o envio com mensagem', (
    tester,
  ) async {
    // given — validação client-side: amount <= 0 não chega ao use case.
    final addDebt = _FakeAddDebtUseCase();
    await _pump(tester, addDebt);

    await tester.enterText(find.byType(TextFormField).at(0), 'Maria');
    await tester.enterText(find.byType(TextFormField).at(1), '0,00');
    await tester.tap(find.widgetWithText(FilledButton, 'Registar fiado'));
    await tester.pumpAndSettle();

    // then — use case NÃO é chamado; mensagem de validação visível.
    expect(addDebt.calls, 0);
    expect(find.text('Informe um valor maior que zero.'), findsOneWidget);
  });

  testWidgets('OfflineEnqueuedException mostra "salvo offline" e fecha', (
    tester,
  ) async {
    // given — modo SaaS sem conexão: o fiado vai para o outbox.
    final addDebt = _FakeAddDebtUseCase()
      ..error = const OfflineEnqueuedException('register_debt');
    await _pump(tester, addDebt);

    await tester.enterText(find.byType(TextFormField).at(0), 'Maria');
    await tester.enterText(find.byType(TextFormField).at(1), '50,00');
    await tester.tap(find.widgetWithText(FilledButton, 'Registar fiado'));
    await tester.pumpAndSettle();

    // then — mensagem de sucesso offline (NÃO é erro para o utilizador).
    expect(find.textContaining('salva e será sincronizada'), findsOneWidget);
    expect(addDebt.calls, 1);
  });

  testWidgets('falha da pendência não sugere retry (evita duplicar o fiado)', (
    tester,
  ) async {
    // given — a dívida FOI registada; só a entrada do caixa falhou.
    final addDebt = _FakeAddDebtUseCase()
      ..error = PendingEntryRegistrationException(StateError('x'));
    await _pump(tester, addDebt);

    await tester.enterText(find.byType(TextFormField).at(0), 'Maria');
    await tester.enterText(find.byType(TextFormField).at(1), '50,00');
    await tester.tap(find.widgetWithText(FilledButton, 'Registar fiado'));
    await tester.pumpAndSettle();

    // then — orienta conferir o Financeiro (não "tente novamente").
    expect(
      find.text('Fiado registado, mas a pendência não pôde ser criada.'),
      findsOneWidget,
    );
    // O formulário permanece aberto (sem pop) para o utilizador ver o erro.
    expect(find.byType(AddDebtSheet), findsOneWidget);
  });

  testWidgets('erro genérico mostra mensagem e mantém o formulário aberto', (
    tester,
  ) async {
    // given
    final addDebt = _FakeAddDebtUseCase()..error = StateError('boom');
    await _pump(tester, addDebt);

    await tester.enterText(find.byType(TextFormField).at(0), 'Maria');
    await tester.enterText(find.byType(TextFormField).at(1), '50,00');
    await tester.tap(find.widgetWithText(FilledButton, 'Registar fiado'));
    await tester.pumpAndSettle();

    // then — mensagem amigável; sheet aberto para nova tentativa.
    expect(
      find.text('Não foi possível registar o fiado. Tente novamente.'),
      findsOneWidget,
    );
    expect(find.byType(AddDebtSheet), findsOneWidget);
  });
}
