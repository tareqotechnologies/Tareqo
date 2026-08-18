import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

import 'package:dumbhanengue/domain/entities/plan.dart';
import 'package:dumbhanengue/domain/usecases/add_plan_use_case.dart';
import 'package:dumbhanengue/domain/usecases/get_all_plans_use_case.dart';
import 'package:dumbhanengue/domain/usecases/update_plan_use_case.dart';
import 'package:dumbhanengue/presentation/controllers/account_providers.dart';
import 'package:dumbhanengue/presentation/controllers/admin_providers.dart';
import 'package:dumbhanengue/presentation/screens/admin/admin_plans_screen.dart';

/// Fake do [GetAllPlansUseCase] — a tela nunca toca em GetIt nem em
/// datasources; o provider é sobrescrito no [ProviderScope].
class _FakeGetAllPlansUseCase implements GetAllPlansUseCase {
 _FakeGetAllPlansUseCase(this._plans);

 final List<Plan> _plans;

 @override
 Future<List<Plan>> call() async => _plans;
}

class _FakeAddPlanUseCase implements AddPlanUseCase {
 int calls = 0;
 Plan? lastPlan;

 @override
 Future<void> call(Plan plan) async {
 calls++;
 lastPlan = plan;
 }
}

class _FakeUpdatePlanUseCase implements UpdatePlanUseCase {
 int calls = 0;

 @override
 Future<void> call(Plan plan) async {
 calls++;
 }
}

Widget _buildApp({
 required List<Plan> plans,
 AddPlanUseCase? addPlan,
 UpdatePlanUseCase? updatePlan,
}) {
 return ProviderScope(
 overrides: [
 getAllPlansUseCaseProvider.overrideWithValue(
 _FakeGetAllPlansUseCase(plans),
 ),
 addPlanUseCaseProvider.overrideWithValue(
 addPlan ?? _FakeAddPlanUseCase(),
 ),
 updatePlanUseCaseProvider.overrideWithValue(
 updatePlan ?? _FakeUpdatePlanUseCase(),
 ),
 ],
 child: testApp(home: const AdminPlansScreen()),
 );
}

void main() {
 // O editor é um modal bottom sheet com vários campos — viewport alta
 // garante que o botão de submit fique visível e tocável.
 Future<void> pumpAdmin(WidgetTester tester, Widget app) async {
 tester.view.physicalSize = const Size(800, 1400);
 tester.view.devicePixelRatio = 1.0;
 addTearDown(tester.view.reset);
 await tester.pumpWidget(app);
 await tester.pumpAndSettle();
 }

 testWidgets('exibe os planos com detalhes de preço e limites',
 (tester) async {
 await pumpAdmin(
 tester,
 _buildApp(
 plans: const [
 Plan(
 id: 'pl1',
 name: 'Essencial',
 description: 'Para começar',
 priceMonthlyCents: 2990,
 maxStores: 1,
 maxEmployees: 2,
 isActive: true,
 ),
 Plan(
 id: 'pl2',
 name: 'Comercial',
 description: 'Crescendo',
 priceMonthlyCents: 9900,
 maxStores: 3,
 maxEmployees: 10,
 isActive: false,
 ),
 ],
 ),
 );

 expect(find.text('Essencial'), findsOneWidget);
 expect(find.text('Comercial'), findsOneWidget);
 // Plano inativo exibe o chip "Inativo".
 expect(find.text('Inativo'), findsOneWidget);
 expect(
 find.text('R\$ 29,90/mês · 1 loja(s) · 2 funcionário(s)'),
 findsOneWidget,
 );
 });

 testWidgets('exibe estado vazio quando não há planos', (tester) async {
 await pumpAdmin(tester, _buildApp(plans: const []));

 expect(find.text('Nenhum plano criado'), findsOneWidget);
 });

 testWidgets('abre o editor e cria um plano novo', (tester) async {
 final addPlan = _FakeAddPlanUseCase();

 await pumpAdmin(tester, _buildApp(plans: const [], addPlan: addPlan));

 // Botão de novo plano na AppBar.
 await tester.tap(find.byIcon(Icons.add));
 await tester.pumpAndSettle();

 expect(find.text('Novo plano'), findsWidgets);

 // Preenche o formulário do editor.
 await tester.enterText(
 find.widgetWithText(TextFormField, 'Nome do plano'),
 'Premium',
 );
 await tester.enterText(
 find.widgetWithText(TextFormField, 'Preço mensal'),
 '199.90',
 );
 await tester.enterText(
 find.widgetWithText(TextFormField, 'Máx. lojas'),
 '10',
 );
 await tester.enterText(
 find.widgetWithText(TextFormField, 'Máx. funcionários'),
 '50',
 );

 await tester.tap(find.widgetWithText(FilledButton, 'Criar plano'));
 await tester.pumpAndSettle();

 expect(addPlan.calls, 1);
 expect(addPlan.lastPlan?.name, 'Premium');
 expect(addPlan.lastPlan?.priceMonthlyCents, 19990);
 expect(find.text('Plano Premium criado!'), findsOneWidget);
 });

 testWidgets('valida os campos do editor com mensagens claras',
 (tester) async {
 await pumpAdmin(tester, _buildApp(plans: const []));

 await tester.tap(find.byIcon(Icons.add));
 await tester.pumpAndSettle();

 // Deixa tudo vazio e submete — a validação do nome é a primeira.
 await tester.tap(find.widgetWithText(FilledButton, 'Criar plano'));
 await tester.pumpAndSettle();

 expect(find.text('Informe o nome do plano.'), findsOneWidget);

 // Preenche o nome e submete com preço inválido — validação do preço.
 await tester.enterText(
 find.widgetWithText(TextFormField, 'Nome do plano'),
 'Premium',
 );
 await tester.tap(find.widgetWithText(FilledButton, 'Criar plano'));
 await tester.pumpAndSettle();

 expect(find.text('Informe um preço válido (≥ 0).'), findsOneWidget);
 });
}
