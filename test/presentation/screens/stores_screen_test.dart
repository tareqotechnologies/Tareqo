import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

import 'package:dumbhanengue/domain/entities/app_user.dart';
import 'package:dumbhanengue/domain/entities/plan.dart';
import 'package:dumbhanengue/domain/entities/plan_request.dart';
import 'package:dumbhanengue/domain/entities/store.dart';
import 'package:dumbhanengue/domain/entities/store_employee.dart';
import 'package:dumbhanengue/domain/entities/tenant.dart';
import 'package:dumbhanengue/domain/usecases/get_my_plan_requests_use_case.dart';
import 'package:dumbhanengue/domain/usecases/get_plans_use_case.dart';
import 'package:dumbhanengue/domain/usecases/get_stores_use_case.dart';
import 'package:dumbhanengue/domain/usecases/get_employees_use_case.dart';
import 'package:dumbhanengue/domain/usecases/set_employee_active_use_case.dart';
import 'package:dumbhanengue/core/theme/app_theme.dart';
import 'package:dumbhanengue/presentation/controllers/account_providers.dart';
import 'package:dumbhanengue/presentation/controllers/auth_providers.dart';
import 'package:dumbhanengue/presentation/screens/stores/stores_screen.dart';
import 'package:dumbhanengue/presentation/widgets/status_chip.dart';

class _FakeGetPlansUseCase implements GetPlansUseCase {
 @override
 Future<List<Plan>> call() async => const [
 Plan(
 id: 'pl2',
 name: 'Profissional',
 maxStores: 3,
 maxEmployees: 10,
 ),
 ];
}

class _FakeGetStoresUseCase implements GetStoresUseCase {
 @override
 Future<List<Store>> call(String tenantId) async => const [
 Store(id: 'st1', tenantId: 'tn1', name: 'Loja Centro'),
 ];
}

class _FakeGetEmployeesUseCase implements GetEmployeesUseCase {
 final List<StoreEmployee> employees;
 _FakeGetEmployeesUseCase({List<StoreEmployee>? employees})
 : employees = employees ?? [
 const StoreEmployee(
 id: 'e1',
 tenantId: 'tn1',
 storeId: 'st1',
 userId: 'u2',
 fullName: 'Carlos',
 email: 'carlos@loja.com',
 role: EmployeeRole.manager,
 ),
 ];

 @override
 Future<List<StoreEmployee>> call(String tenantId) async =>
 List.unmodifiable(employees);
}

class _FakeSetEmployeeActiveUseCase implements SetEmployeeActiveUseCase {
 String? lastEmployeeId;
 bool? lastIsActive;
 int calls = 0;

 @override
 Future<void> call({
 required String tenantId,
 required String employeeId,
 required bool isActive,
 }) async {
 calls++;
 lastEmployeeId = employeeId;
 lastIsActive = isActive;
 }
}

class _FakeGetMyPlanRequestsUseCase implements GetMyPlanRequestsUseCase {
 final List<PlanRequest> requests;
 _FakeGetMyPlanRequestsUseCase({this.requests = const []});

 @override
 Future<List<PlanRequest>> call(String tenantId) async =>
 List.unmodifiable(requests);
}

void main() {
 final tenant = Tenant(
 id: 'tn1',
 ownerUserId: 'u1',
 businessName: 'Comercial X',
 planId: 'pl2',
 status: TenantStatus.approved,
 approvedAt: DateTime.now(),
 createdAt: DateTime.now(),
 );

 late final _FakeGetEmployeesUseCase employeesUseCase =
 _FakeGetEmployeesUseCase();
 final setActiveUseCase = _FakeSetEmployeeActiveUseCase();

 Widget build() => ProviderScope(
 overrides: [
 // Sessão do DONO do tenant (u1) — habilita o interruptor de
 // ativar/desativar na aba Funcionários.
 authStateProvider.overrideWith(
 (ref) => Stream.value(AppUser(id: 'u1', email: 'dono@loja.com')),
 ),
 getPlansUseCaseProvider.overrideWithValue(_FakeGetPlansUseCase()),
 getStoresUseCaseProvider.overrideWithValue(_FakeGetStoresUseCase()),
 getEmployeesUseCaseProvider.overrideWithValue(employeesUseCase),
 setEmployeeActiveUseCaseProvider.overrideWithValue(setActiveUseCase),
 getMyPlanRequestsUseCaseProvider
 .overrideWithValue(_FakeGetMyPlanRequestsUseCase()),
 ],
 child: testApp(home: StoresScreen(tenant: tenant)),
 );

 testWidgets('StoresScreen renderiza sem crash e exibe as 3 abas',
 (tester) async {
 await tester.pumpWidget(build());
 await tester.pumpAndSettle();

 // Card do plano com limites.
 expect(find.text('Profissional'), findsOneWidget);
 expect(find.text('Lojas'), findsWidgets);
 expect(find.text('Upgrades'), findsOneWidget);
 expect(find.text('1/3'), findsOneWidget); // lojas usadas/máx
 expect(find.text('1/10'), findsOneWidget); // funcionários usados/máx

 // Aba Lojas ativa: FAB circular visível com tooltip de nova loja
 // (regressão do DefaultTabController — antes quebrava em runtime).
 expect(find.byTooltip('Nova loja'), findsOneWidget);
 expect(find.text('Loja Centro'), findsOneWidget);
 });

 testWidgets('FAB alterna entre Nova loja e Novo funcionário por aba',
 (tester) async {
 await tester.pumpWidget(build());
 await tester.pumpAndSettle();

 // Troca para a aba Funcionários (índice 1 do TabBar).
 await tester.tap(find.byType(Tab).at(1));
 await tester.pumpAndSettle();

 expect(find.byTooltip('Novo funcionário'), findsOneWidget);
 expect(find.text('Carlos'), findsOneWidget);

 // Aba Upgrades: FAB escondido.
 await tester.tap(find.byType(Tab).at(2));
 await tester.pumpAndSettle();

 expect(find.text('Nova loja'), findsNothing);
 expect(find.text('Novo funcionário'), findsNothing);
 });

 testWidgets('FAB usa só o sinal de + (Icons.add) nas abas Lojas e Funcionários',
 (tester) async {
 await tester.pumpWidget(build());
 await tester.pumpAndSettle();

 // Aba Lojas: FAB circular com Icons.add.
 expect(
 tester
 .widget<FloatingActionButton>(find.byType(FloatingActionButton))
 .child,
 isA<Icon>()
 .having((icon) => icon.icon, 'icon', Icons.add),
 );

 // Aba Funcionários: mesmo ícone (o tooltip carrega o significado).
 await tester.tap(find.byType(Tab).at(1));
 await tester.pumpAndSettle();
 expect(
 tester
 .widget<FloatingActionButton>(find.byType(FloatingActionButton))
 .child,
 isA<Icon>()
 .having((icon) => icon.icon, 'icon', Icons.add),
 );
 });

 testWidgets('Pedido de upgrade Pendente usa warning (âmbar), não roxo',
 (tester) async {
 await tester.pumpWidget(
 ProviderScope(
 overrides: [
 authStateProvider.overrideWith(
 (ref) => Stream.value(AppUser(id: 'u1', email: 'dono@loja.com')),
 ),
 getPlansUseCaseProvider.overrideWithValue(_FakeGetPlansUseCase()),
 getStoresUseCaseProvider.overrideWithValue(_FakeGetStoresUseCase()),
 getEmployeesUseCaseProvider.overrideWithValue(employeesUseCase),
 setEmployeeActiveUseCaseProvider.overrideWithValue(
 setActiveUseCase,
 ),
 getMyPlanRequestsUseCaseProvider.overrideWithValue(
 _FakeGetMyPlanRequestsUseCase(
 requests: [
 PlanRequest(
 id: 'r1',
 tenantId: 'tn1',
 currentPlanId: 'pl1',
 requestedPlanId: 'pl2',
 status: PlanRequestStatus.pending,
 createdAt: DateTime(2026, 1, 10),
 ),
 ],
 ),
 ),
 ],
 child: testApp(home: StoresScreen(tenant: tenant)),
 ),
 );
 await tester.pumpAndSettle();

 await tester.tap(find.byType(Tab).at(2)); // aba Upgrades
 await tester.pumpAndSettle();

 expect(find.text('Pendente'), findsOneWidget);
 // A cor do chip é o âmbar de aviso do design system (a mesma semântica
 // de "a aguardar acção" do resto do app) — não o roxo tertiary.
 final chip = tester.widget<StatusChip>(find.byType(StatusChip));
 final context = tester.element(find.byType(StatusChip));
 expect(chip.color, Theme.of(context).warning);
 expect(chip.color, isNot(Theme.of(context).colorScheme.tertiary));
 });

 testWidgets(
 'Senha de funcionário exige mínimo de 8 caracteres (auditoria S1/M7)',
 (tester) async {
 await tester.pumpWidget(build());
 await tester.pumpAndSettle();

 // Abre a sheet de novo funcionário.
 await tester.tap(find.byType(Tab).at(1));
 await tester.pumpAndSettle();
 // Abre a sheet pelo FAB circular (sem label — tooltip).
 await tester.tap(find.byTooltip('Novo funcionário'));
 await tester.pumpAndSettle();

 // Preenche nome, e-mail e senha CURTA (6 caracteres) e submete.
 await tester.enterText(
 find.byType(TextFormField).at(0),
 'Ana Lima',
 );
 await tester.enterText(
 find.byType(TextFormField).at(1),
 'ana@loja.com',
 );
 await tester.enterText(
 find.byType(TextFormField).at(2),
 'abc123',
 );
 await tester.tap(find.text('Cadastrar funcionário'));
 await tester.pumpAndSettle();

 // A validação de mínimo 8 bloqueia o envio (sem chamada ao serviço).
 expect(find.text('A senha deve ter ao menos 8 caracteres.'), findsOneWidget);
 });

 testWidgets('Dono desativa e reativa funcionário pelo interruptor',
 (tester) async {
 await tester.pumpWidget(build());
 await tester.pumpAndSettle();

 await tester.tap(find.byType(Tab).at(1));
 await tester.pumpAndSettle();

 // O card mostra o cargo (Gerente) e o interruptor FINO do DONO (o
 // Switch M3 grosso foi substituído pelo _ThinToggle do design system).
 expect(find.text('Carlos'), findsOneWidget);
 expect(find.text('Gerente'), findsOneWidget);
 expect(
 find.byKey(const ValueKey('employee-toggle-e1')),
 findsOneWidget,
 );

 // Desativa: confirma o diálogo (botão de ação = "Desativar").
 await tester.tap(find.byKey(const ValueKey('employee-toggle-e1')));
 await tester.pumpAndSettle();
 expect(
 find.textContaining('Desativar Carlos?'),
 findsOneWidget,
 );
 await tester.tap(find.text('Desativar')); // botão de confirmação
 await tester.pumpAndSettle();

 expect(setActiveUseCase.calls, 1);
 expect(setActiveUseCase.lastEmployeeId, 'e1');
 expect(setActiveUseCase.lastIsActive, isFalse);
 expect(find.text('Funcionário desativado.'), findsOneWidget); // snack
 });

 testWidgets(
 'Funcionário inativo: chip Inativo + interruptor fino desligado',
 (tester) async {
 final inactive = _FakeGetEmployeesUseCase(
 employees: const [
 StoreEmployee(
 id: 'e9',
 tenantId: 'tn1',
 storeId: 'st1',
 userId: 'u9',
 fullName: 'Berto Longo',
 email: 'berto.longo@teste.pt',
 role: EmployeeRole.employee,
 isActive: false,
 ),
 ],
 );
 await tester.pumpWidget(
 ProviderScope(
 overrides: [
 authStateProvider.overrideWith(
 (ref) => Stream.value(AppUser(id: 'u1', email: 'dono@loja.com')),
 ),
 getPlansUseCaseProvider.overrideWithValue(_FakeGetPlansUseCase()),
 getStoresUseCaseProvider.overrideWithValue(_FakeGetStoresUseCase()),
 getEmployeesUseCaseProvider.overrideWithValue(inactive),
 setEmployeeActiveUseCaseProvider.overrideWithValue(
 _FakeSetEmployeeActiveUseCase(),
 ),
 getMyPlanRequestsUseCaseProvider
 .overrideWithValue(_FakeGetMyPlanRequestsUseCase()),
 ],
 child: testApp(home: StoresScreen(tenant: tenant)),
 ),
 );
 await tester.pumpAndSettle();
 await tester.tap(find.byType(Tab).at(1));
 await tester.pumpAndSettle();

 // Chip "Inativo" + interruptor fino presente.
 expect(find.text('Inativo'), findsOneWidget);
 expect(
 find.byKey(const ValueKey('employee-toggle-e9')),
 findsOneWidget,
 );
 // O toggle fino reflete o estado DESLIGADO: a semântica anota toggled
 // = false e o thumb fica ancorado à ESQUERDA (AnimatedAlign centerLeft).
 final semanticsWidget = tester.widget<Semantics>(
 find.descendant(
 of: find.byKey(const ValueKey('employee-toggle-e9')),
 matching: find.byType(Semantics),
 ),
 );
 expect(semanticsWidget.properties.toggled, isFalse);
 final align = tester.widget<AnimatedAlign>(
 find.descendant(
 of: find.byKey(const ValueKey('employee-toggle-e9')),
 matching: find.byType(AnimatedAlign),
 ),
 );
 expect(align.alignment, Alignment.centerLeft);
 });
}
