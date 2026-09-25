import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/store_context.dart';
import '../../../helpers/test_app.dart';

import 'package:tareqo/domain/entities/customer.dart';
import 'package:tareqo/domain/entities/debt.dart';
import 'package:tareqo/domain/repositories/i_customer_repository.dart';
import 'package:tareqo/domain/usecases/add_customer_use_case.dart';
import 'package:tareqo/domain/usecases/delete_customer_use_case.dart';
import 'package:tareqo/domain/usecases/get_customers_use_case.dart';
import 'package:tareqo/domain/usecases/get_pending_debts_use_case.dart';
import 'package:tareqo/domain/usecases/update_customer_use_case.dart';
import 'package:tareqo/presentation/controllers/customers_providers.dart';
import 'package:tareqo/presentation/controllers/debts_providers.dart';
import 'package:tareqo/presentation/screens/customers/customers_screen.dart';

/// Repositório de clientes em memória com contadores de chamadas.
class _FakeCustomerRepository implements ICustomerRepository {
  _FakeCustomerRepository(this._customers);

  final List<Customer> _customers;
  int addCalls = 0;
  int updateCalls = 0;
  int deleteCalls = 0;
  String? lastDeletedId;
  Customer? lastAdded;
  Customer? lastUpdated;
  bool throwOnAdd = false;
  bool throwOnDelete = false;

  @override
  Future<List<Customer>> getAll({required String storeId}) async => _customers;

  @override
  Future<Customer> add(Customer customer) async {
    addCalls++;
    if (throwOnAdd) throw Exception('falha ao gravar');
    lastAdded = customer;
    _customers.add(customer);
    return customer;
  }

  @override
  Future<Customer> update(Customer customer) async {
    updateCalls++;
    lastUpdated = customer;
    final index = _customers.indexWhere((c) => c.id == customer.id);
    if (index != -1) _customers[index] = customer;
    return customer;
  }

  @override
  Future<void> delete(String customerId) async {
    deleteCalls++;
    if (throwOnDelete) throw Exception('falha ao remover');
    lastDeletedId = customerId;
    _customers.removeWhere((c) => c.id == customerId);
  }
}

class _FakeGetPendingDebtsUseCase implements GetPendingDebtsUseCase {
  _FakeGetPendingDebtsUseCase(this._debts);

  final List<Debt> _debts;

  @override
  Future<List<Debt>> call({required String storeId}) async => _debts;
}

Customer _customer({
  String id = 'c1',
  String name = 'Ana Costa',
  String phone = '841234567',
  String email = '',
}) => Customer(id: id, name: name, phone: phone, email: email);

Debt _debt({required String customerId, int amountCents = 2500}) => Debt(
  id: 'd-$customerId',
  personName: 'Cliente',
  amountCents: amountCents,
  dueDate: DateTime.now().add(const Duration(days: 5)),
  isCustomerDebt: true,
  customerId: customerId,
);

Widget _buildApp({
  required _FakeCustomerRepository repository,
  List<Debt> pendingDebts = const [],
}) {
  return ProviderScope(
    overrides: [
      ...storeContextOverrides(),
      getCustomersUseCaseProvider.overrideWithValue(
        GetCustomersUseCase(repository),
      ),
      addCustomerUseCaseProvider.overrideWithValue(
        AddCustomerUseCase(repository),
      ),
      updateCustomerUseCaseProvider.overrideWithValue(
        UpdateCustomerUseCase(repository),
      ),
      deleteCustomerUseCaseProvider.overrideWithValue(
        DeleteCustomerUseCase(repository),
      ),
      getPendingDebtsUseCaseProvider.overrideWithValue(
        _FakeGetPendingDebtsUseCase(pendingDebts),
      ),
    ],
    child: testApp(
      home: const CustomersScreen(),
      builder: (context, child) =>
          MediaQuery.withClampedTextScaling(maxScaleFactor: 0.7, child: child!),
    ),
  );
}

void _useWideViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1250, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('estado vazio com CTA "Novo cliente" e sem FAB', (tester) async {
    _useWideViewport(tester);
    await tester.pumpWidget(_buildApp(repository: _FakeCustomerRepository([])));
    await tester.pumpAndSettle();

    expect(find.text('Nenhum cliente cadastrado'), findsOneWidget);
    expect(find.text('Novo cliente'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('lista clientes com iniciais, contato e header de contagem', (
    tester,
  ) async {
    _useWideViewport(tester);
    await tester.pumpWidget(
      _buildApp(
        repository: _FakeCustomerRepository([
          _customer(),
          _customer(id: 'c2', name: 'Bruno Lopes', phone: '879999999'),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    // Header: "2 clientes".
    expect(find.text('2 clientes'), findsOneWidget);
    expect(find.text('Ana Costa'), findsOneWidget);
    expect(find.text('Bruno Lopes'), findsOneWidget);
    expect(find.text('841234567'), findsOneWidget);
    // Com clientes o FAB aparece.
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('fiado pendente do cliente vira chip "Fiado 25,00"', (
    tester,
  ) async {
    _useWideViewport(tester);
    await tester.pumpWidget(
      _buildApp(
        repository: _FakeCustomerRepository([_customer()]),
        pendingDebts: [_debt(customerId: 'c1', amountCents: 2500)],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Fiado'), findsOneWidget);
  });

  testWidgets('busca filtra por nome e telefone; vazio mostra sem resultado', (
    tester,
  ) async {
    _useWideViewport(tester);
    await tester.pumpWidget(
      _buildApp(
        repository: _FakeCustomerRepository([
          _customer(),
          _customer(id: 'c2', name: 'Bruno Lopes', phone: '879999999'),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    // Por nome (maiúsculas contra minúsculas — busca normalizada).
    await tester.enterText(find.byType(TextField), 'ANA');
    await tester.pumpAndSettle();
    expect(find.text('Ana Costa'), findsOneWidget);
    expect(find.text('Bruno Lopes'), findsNothing);

    // Por telefone.
    await tester.enterText(find.byType(TextField), '8799');
    await tester.pumpAndSettle();
    expect(find.text('Bruno Lopes'), findsOneWidget);
    expect(find.text('Ana Costa'), findsNothing);

    // Sem resultado.
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('Nenhum resultado'), findsOneWidget);
  });

  testWidgets('cadastrar cliente via sheet persiste e mostra snackbar', (
    tester,
  ) async {
    _useWideViewport(tester);
    final repository = _FakeCustomerRepository([]);
    await tester.pumpWidget(_buildApp(repository: repository));
    await tester.pumpAndSettle();

    // CTA do estado vazio.
    await tester.tap(find.text('Novo cliente'));
    await tester.pumpAndSettle();

    // Form com nome obrigatório, telefone e email opcionais. O .at(0)
    // é o SearchField da tela por baixo — os campos da sheet começam .at(1).
    await tester.enterText(find.byType(TextField).at(1), 'Maria Costa');
    await tester.enterText(find.byType(TextField).at(2), '879999999');
    await tester.tap(find.text('Cadastrar cliente'));
    await tester.pumpAndSettle();

    expect(repository.addCalls, 1);
    expect(repository.lastAdded?.name, 'Maria Costa');
    expect(repository.lastAdded?.storeId, 'st1');
    expect(find.text('Cliente Maria Costa cadastrado!'), findsOneWidget);
  });

  testWidgets('email inválido no cadastro mostra erro de validação', (
    tester,
  ) async {
    _useWideViewport(tester);
    final repository = _FakeCustomerRepository([]);
    await tester.pumpWidget(_buildApp(repository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Novo cliente'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(1), 'Maria Costa');
    await tester.enterText(find.byType(TextField).at(3), 'email-invalido');
    await tester.tap(find.text('Cadastrar cliente'));
    await tester.pumpAndSettle();

    expect(find.text('Informe um e-mail válido.'), findsOneWidget);
    expect(repository.addCalls, 0);
  });

  testWidgets('editar cliente via menu ⋮ atualiza o nome', (tester) async {
    _useWideViewport(tester);
    final repository = _FakeCustomerRepository([_customer()]);
    await tester.pumpWidget(_buildApp(repository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar cliente'));
    await tester.pumpAndSettle();

    // Sheet de edição vem preenchida (nome em .at(1) — depois do busca).
    expect(find.text('Guardar alterações'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(1), 'Ana Costa Vidal');
    await tester.tap(find.text('Guardar alterações'));
    await tester.pumpAndSettle();

    expect(repository.updateCalls, 1);
    expect(repository.lastUpdated?.name, 'Ana Costa Vidal');
    expect(find.text('Cliente Ana Costa Vidal atualizado!'), findsOneWidget);
  });

  testWidgets('remover cliente com confirmação chama o use case', (
    tester,
  ) async {
    _useWideViewport(tester);
    final repository = _FakeCustomerRepository([_customer()]);
    await tester.pumpWidget(_buildApp(repository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apagar'));
    await tester.pumpAndSettle();

    // Dialog de confirmação com o nome interpolado.
    expect(find.text('Remover cliente?'), findsOneWidget);
    expect(
      find.textContaining('será removido permanentemente'),
      findsOneWidget,
    );

    await tester.tap(find.text('Apagar').last);
    await tester.pumpAndSettle();

    expect(repository.deleteCalls, 1);
    expect(repository.lastDeletedId, 'c1');
    expect(find.text('Cliente removido.'), findsOneWidget);
  });

  testWidgets('erro ao remover mostra snackbar de erro', (tester) async {
    _useWideViewport(tester);
    final repository = _FakeCustomerRepository([_customer()])
      ..throwOnDelete = true;
    await tester.pumpWidget(_buildApp(repository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apagar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apagar').last);
    await tester.pumpAndSettle();

    expect(
      find.text('Não foi possível remover o cliente. Tente novamente.'),
      findsOneWidget,
    );
    expect(find.text('Cliente removido.'), findsNothing);
  });

  testWidgets('undo do snackbar de remoção recadastra o cliente', (
    tester,
  ) async {
    _useWideViewport(tester);
    final repository = _FakeCustomerRepository([_customer()]);
    await tester.pumpWidget(_buildApp(repository: repository));
    await tester.pumpAndSettle();

    // Remove com confirmação.
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apagar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apagar').last);
    await tester.pumpAndSettle();

    // Removido com snackbar + undo disponível (a lista local do fake
    // não tem mais o cliente).
    expect(repository.deleteCalls, 1);
    expect(find.text('Cliente removido.'), findsOneWidget);
    expect(find.text('Desfazer'), findsOneWidget);
    expect(repository._customers, isEmpty);

    // Toca em Desfazer: o cliente volta (regravado com o MESMO snapshot).
    await tester.tap(find.text('Desfazer'));
    await tester.pumpAndSettle();

    expect(repository.addCalls, 1);
    expect(repository.lastAdded?.id, 'c1');
    expect(repository.lastAdded?.name, 'Ana Costa');
    expect(repository.lastAdded?.phone, '841234567');
    expect(find.text('Ana Costa'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
