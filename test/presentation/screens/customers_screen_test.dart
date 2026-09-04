import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';
import '../../helpers/viewport.dart';
import '../../helpers/store_context.dart';

import 'package:tareqo/domain/entities/customer.dart';
import 'package:tareqo/domain/entities/debt.dart';
import 'package:tareqo/domain/usecases/get_customers_use_case.dart';
import 'package:tareqo/domain/usecases/get_pending_debts_use_case.dart';
import 'package:tareqo/presentation/controllers/customers_providers.dart';
import 'package:tareqo/presentation/controllers/debts_providers.dart';
import 'package:tareqo/presentation/screens/customers/customers_screen.dart';

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
 // CTA ÚNICO: no estado vazio o FAB some e o EmptyState traz o botão.
 expect(find.text('Novo cliente'), findsOneWidget);
 expect(find.byType(FloatingActionButton), findsNothing);
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
 amountCents: 5000,
 dueDate: DateTime.now(),
 isCustomerDebt: true,
 ),
 Debt(
 id: 'd2',
 customerId: 'c1',
 personName: 'Ana Souza',
 amountCents: 2550,
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

 // Regressão (UI): o chip de fiado ficava sem Flexível — com escala de
 // texto 2.0 em tela estreita e um total grande, o Row do card estourava.
 // Agora o chip encolhe (ellipsis); overflows de RenderFlex falham o
 // teste via takeException.
 testWidgets('não estoura com escala de texto 2.0 em tela estreita', (
 tester,
 ) async {
 tester.platformDispatcher.textScaleFactorTestValue = 2.0;
 addTearDown(tester.platformDispatcher.clearAllTestValues);

 // Estreita (360) porém alta: garante que o tile seja construído/pintado
 // com escala 2.0 (abaixo do fold o overflow ficaria mascarado).
 tester.view.physicalSize = const Size(360, 2000);
 tester.view.devicePixelRatio = 1.0;
 addTearDown(tester.view.reset);

 await tester.pumpWidget(
 _buildApp(
 customers: const [
 Customer(
 id: 'c1',
 name: 'Empresa de Equipamentos Industriais Ltda',
 phone: '11999990000',
 email: 'contato@empresa.com.br',
 ),
 ],
 debts: [
 Debt(
 id: 'd1',
 customerId: 'c1',
 personName: 'Empresa de Equipamentos Industriais Ltda',
 amountCents: 999999999,
 dueDate: DateTime.now(),
 isCustomerDebt: true,
 ),
 ],
 ),
 );
 await tester.pumpAndSettle();

 // O cliente continua visível e nenhum overflow foi registrado.
 expect(
 find.text('Empresa de Equipamentos Industriais Ltda'),
 findsOneWidget,
 );
 // Âncora com o valor COMPLETO visível mesmo com escala 2.0 (o chip
 // quebra em linhas em vez de truncar com '...').
 expect(find.text('Fiado R\$ 9.999.999,99'), findsOneWidget);
 expect(tester.takeException(), isNull);
 });

 // Formulário: o email é OPCIONAL, mas se preenchido precisa ter formato
 // válido — emails inválidos não entram na base.
 testWidgets('email inválido bloqueia o cadastro com mensagem clara', (
 tester,
 ) async {
 await tester.pumpWidget(_buildApp(customers: _customers));
 await tester.pumpAndSettle();

 // Abre o cadastro (FAB com dados presentes).
 await tester.tap(find.byType(FloatingActionButton));
 await tester.pumpAndSettle();

 await tester.enterText(
 find.widgetWithText(TextFormField, 'Nome').first,
 'Carlos',
 );
 await tester.enterText(
 find.widgetWithText(TextFormField, 'E-mail (opcional)').first,
 'email-invalido',
 );
 await tester.tap(find.widgetWithText(FilledButton, 'Cadastrar cliente'));
 await tester.pumpAndSettle();
    expect(find.text('Informe um e-mail válido.'), findsOneWidget);
    // O sheet continua aberto (não submeteu) — o botão de envio segue lá.
    expect(
      find.widgetWithText(FilledButton, 'Cadastrar cliente'),
      findsOneWidget,
    );
 });

 // Rotação (UI): aba Clientes em paisagem — busca e lista seguem
 // íntegras após o giro, sem overflow. Overflows de RenderFlex falham
 // o teste via takeException.
 testWidgets('clientes sobrevivem à rotação para paisagem', (tester) async {
 usePortraitViewport(tester);

 await tester.pumpWidget(_buildApp(customers: _customers));
 await tester.pumpAndSettle();

 // Retrato: busca e os dois clientes visíveis.
 expect(find.byType(TextField), findsOneWidget);
 expect(find.text('Ana Souza'), findsOneWidget);
 expect(find.text('Bruno Lima'), findsOneWidget);
 expect(tester.takeException(), isNull);

 // Gira para paisagem.
 await rotateToLandscape(tester);

 // Sem overflow; busca e clientes seguem presentes após o giro.
 expect(tester.takeException(), isNull);
 expect(find.byType(TextField), findsOneWidget);
 expect(find.text('Ana Souza'), findsOneWidget);
 expect(find.text('Bruno Lima'), findsOneWidget);
 });
}
