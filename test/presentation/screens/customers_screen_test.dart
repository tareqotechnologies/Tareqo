import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';
import '../../helpers/store_context.dart';

import 'package:dumbhanengue/domain/entities/customer.dart';
import 'package:dumbhanengue/domain/entities/debt.dart';
import 'package:dumbhanengue/domain/usecases/get_customers_use_case.dart';
import 'package:dumbhanengue/domain/usecases/get_pending_debts_use_case.dart';
import 'package:dumbhanengue/presentation/controllers/customers_providers.dart';
import 'package:dumbhanengue/presentation/controllers/debts_providers.dart';
import 'package:dumbhanengue/presentation/screens/customers/customers_screen.dart';

class _FakeGetCustomersUseCase implements GetCustomersUseCase {
  _FakeGetCustomersUseCase(this._customers);

  final List<Customer> _customers;

  @override
  Future<List<Customer>> call({required String storeId}) async => _customers;
}

class _FakeGetPendingDebtsUseCase implements GetPendingDebtsUseCase {
  _FakeGetPendingDebtsUseCase(this._debts);

  final List<Debt> _debts;

  @override
  Future<List<Debt>> call({required String storeId}) async => _debts;
}

Widget _buildApp({
  required List<Customer> customers,
  List<Debt> debts = const [],
}) {
  return ProviderScope(
    overrides: [
      ...storeContextOverrides(),
      getCustomersUseCaseProvider.overrideWithValue(
        _FakeGetCustomersUseCase(customers),
      ),
      getPendingDebtsUseCaseProvider.overrideWithValue(
        _FakeGetPendingDebtsUseCase(debts),
      ),
    ],
    child: testApp(home: const CustomersScreen()),
  );
}

const _customers = [
  Customer(id: 'c1', name: 'Ana Souza', phone: '11999990000'),
  Customer(id: 'c2', name: 'Bruno Lima', email: 'bruno@exemplo.com'),
];

void main() {
  testWidgets('exibe a lista de clientes', (tester) async {
    await tester.pumpWidget(_buildApp(customers: _customers));
    await tester.pumpAndSettle();

    expect(find.text('Ana Souza'), findsOneWidget);
    expect(find.text('Bruno Lima'), findsOneWidget);
    // Ordenação alfabética (o notifier ordena) — Ana antes de Bruno.
    final anaY = tester.getTopLeft(find.text('Ana Souza')).dy;
    final brunoY = tester.getTopLeft(find.text('Bruno Lima')).dy;
    expect(anaY, lessThan(brunoY));
  });

  testWidgets('busca filtra os clientes pelo nome', (tester) async {
    await tester.pumpWidget(_buildApp(customers: _customers));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'ana');
    await tester.pumpAndSettle();

    expect(find.text('Ana Souza'), findsOneWidget);
    expect(find.text('Bruno Lima'), findsNothing);
  });

  testWidgets('exibe estado vazio quando não há clientes', (tester) async {
    await tester.pumpWidget(_buildApp(customers: const []));
    await tester.pumpAndSettle();

    expect(find.text('Nenhum cliente cadastrado'), findsOneWidget);
    // O EmptyState não tem ação — o botão "Novo cliente" é o FAB.
    expect(find.text('Novo cliente'), findsOneWidget);
  });

  testWidgets('exibe o total pendente de fiado por cliente', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        customers: _customers,
        debts: [
          Debt(
            id: 'd1',
            customerId: 'c1',
            personName: 'Ana Souza',
            amount: 50.0,
            dueDate: DateTime.now(),
            isCustomerDebt: true,
          ),
          Debt(
            id: 'd2',
            customerId: 'c1',
            personName: 'Ana Souza',
            amount: 25.5,
            dueDate: DateTime.now(),
            isCustomerDebt: true,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    // Ana tem 50 + 25.5 = R$ 75,50 pendentes (chip "Fiado R$ 75,50");
    // Bruno não tem fiado (sem chip).
    expect(find.text('Fiado R\$ 75,50'), findsOneWidget);
  });
}
