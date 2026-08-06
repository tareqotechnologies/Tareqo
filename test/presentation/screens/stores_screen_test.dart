import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

import 'package:dumbhanengue/domain/entities/plan.dart';
import 'package:dumbhanengue/domain/entities/plan_request.dart';
import 'package:dumbhanengue/domain/entities/store.dart';
import 'package:dumbhanengue/domain/entities/store_employee.dart';
import 'package:dumbhanengue/domain/entities/tenant.dart';
import 'package:dumbhanengue/domain/usecases/get_my_plan_requests_use_case.dart';
import 'package:dumbhanengue/domain/usecases/get_plans_use_case.dart';
import 'package:dumbhanengue/domain/usecases/get_stores_use_case.dart';
import 'package:dumbhanengue/domain/usecases/get_employees_use_case.dart';
import 'package:dumbhanengue/presentation/controllers/account_providers.dart';
import 'package:dumbhanengue/presentation/screens/stores/stores_screen.dart';

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
  @override
  Future<List<StoreEmployee>> call(String tenantId) async => const [
        StoreEmployee(
          id: 'e1',
          tenantId: 'tn1',
          storeId: 'st1',
          userId: 'u2',
          fullName: 'Carlos',
          email: 'carlos@loja.com',
          role: EmployeeRole.manager,
        ),
      ];
}

class _FakeGetMyPlanRequestsUseCase implements GetMyPlanRequestsUseCase {
  @override
  Future<List<PlanRequest>> call(String tenantId) async => const [];
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

  Widget build() => ProviderScope(
        overrides: [
          getPlansUseCaseProvider.overrideWithValue(_FakeGetPlansUseCase()),
          getStoresUseCaseProvider.overrideWithValue(_FakeGetStoresUseCase()),
          getEmployeesUseCaseProvider
              .overrideWithValue(_FakeGetEmployeesUseCase()),
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

    // Aba Lojas ativa: FAB de nova loja visível (regressão do
    // DefaultTabController — antes quebrava em runtime).
    expect(find.text('Nova loja'), findsOneWidget);
    expect(find.text('Loja Centro'), findsOneWidget);
  });

  testWidgets('FAB alterna entre Nova loja e Novo funcionário por aba',
      (tester) async {
    await tester.pumpWidget(build());
    await tester.pumpAndSettle();

    // Troca para a aba Funcionários (índice 1 do TabBar).
    await tester.tap(find.byType(Tab).at(1));
    await tester.pumpAndSettle();

    expect(find.text('Novo funcionário'), findsOneWidget);
    expect(find.text('Carlos'), findsOneWidget);

    // Aba Upgrades: FAB escondido.
    await tester.tap(find.byType(Tab).at(2));
    await tester.pumpAndSettle();

    expect(find.text('Nova loja'), findsNothing);
    expect(find.text('Novo funcionário'), findsNothing);
  });

  testWidgets(
      'Senha de funcionário exige mínimo de 8 caracteres (auditoria S1/M7)',
      (tester) async {
    await tester.pumpWidget(build());
    await tester.pumpAndSettle();

    // Abre a sheet de novo funcionário.
    await tester.tap(find.byType(Tab).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Novo funcionário'));
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
}
