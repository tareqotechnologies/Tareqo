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
import 'package:dumbhanengue/domain/usecases/get_employees_use_case.dart';
import 'package:dumbhanengue/domain/usecases/get_my_plan_requests_use_case.dart';
import 'package:dumbhanengue/domain/usecases/get_plans_use_case.dart';
import 'package:dumbhanengue/domain/usecases/get_stores_use_case.dart';
import 'package:dumbhanengue/domain/usecases/update_tenant_settings_use_case.dart';
import 'package:dumbhanengue/presentation/controllers/account_providers.dart';
import 'package:dumbhanengue/presentation/controllers/auth_providers.dart';
import 'package:dumbhanengue/presentation/screens/stores/stores_screen.dart';

import '../../helpers/store_context.dart';

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
  Future<List<StoreEmployee>> call(String tenantId) async => const [];
}

class _FakeGetMyPlanRequestsUseCase implements GetMyPlanRequestsUseCase {
  @override
  Future<List<PlanRequest>> call(String tenantId) async => const [];
}

/// Fake do [UpdateTenantSettingsUseCase] que CAPTURA os valores salvos em
/// Lojas → Ajustes (moeda + idioma) — a prova da propagação na escrita.
class _CapturingUpdateTenantSettings implements UpdateTenantSettingsUseCase {
  _CapturingUpdateTenantSettings({this.throwOnSave = false});

  final bool throwOnSave;

  String? tenantId;
  String? currencyCode;
  String? language;

  @override
  Future<void> call({
    required String tenantId,
    required String currencyCode,
    required String language,
  }) async {
    if (throwOnSave) throw StateError('falha simulada');
    this.tenantId = tenantId;
    this.currencyCode = currencyCode;
    this.language = language;
  }
}

/// Lê o estado `selected` do ChoiceChip pelo rótulo (idioma/moeda).
bool _chipSelected(WidgetTester tester, String label) {
  final chip = tester.widget<ChoiceChip>(
    find.ancestor(of: find.text(label), matching: find.byType(ChoiceChip)),
  );
  return chip.selected;
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

  Widget build(_CapturingUpdateTenantSettings settings) => ProviderScope(
        overrides: [
          getPlansUseCaseProvider.overrideWithValue(_FakeGetPlansUseCase()),
          getStoresUseCaseProvider.overrideWithValue(_FakeGetStoresUseCase()),
          getEmployeesUseCaseProvider
              .overrideWithValue(_FakeGetEmployeesUseCase()),
          getMyPlanRequestsUseCaseProvider
              .overrideWithValue(_FakeGetMyPlanRequestsUseCase()),
          updateTenantSettingsUseCaseProvider.overrideWithValue(settings),
          // Sessão + tenant: o save invalida o myTenantProvider do usuário
          // (é assim que o tenantSettingsProvider reage e troca o locale).
          authStateProvider.overrideWith(
            (ref) => Stream.value(AppUser(id: 'u1', email: 'dono@loja.com')),
          ),
          getMyTenantUseCaseProvider
              .overrideWithValue(FakeGetMyTenantUseCase(tenant)),
        ],
        child: testApp(home: StoresScreen(tenant: tenant)),
      );

  Future<void> openSettingsTab(WidgetTester tester) async {
    // Aba Ajustes = índice 3 do TabBar (Lojas, Funcionários, Upgrades...).
    await tester.tap(find.byType(Tab).at(3));
    await tester.pumpAndSettle();
  }

  testWidgets('aba Ajustes exibe idioma/moeda e reflete o estado do tenant',
      (tester) async {
    await tester.pumpWidget(build(_CapturingUpdateTenantSettings()));
    await tester.pumpAndSettle();
    await openSettingsTab(tester);

    expect(find.text('Idioma'), findsOneWidget);
    expect(find.text('Moeda'), findsOneWidget);
    expect(find.text('Salvar ajustes'), findsOneWidget);

    // Tenant atual é pt + BRL → selecionados por padrão.
    expect(_chipSelected(tester, 'Português'), isTrue);
    expect(_chipSelected(tester, 'English'), isFalse);
    expect(_chipSelected(tester, 'Real (BRL)'), isTrue);
    expect(_chipSelected(tester, 'Metical (MZN)'), isFalse);
  });

  testWidgets('salvar inglês + MZN propaga a escolha (use case captura en/MZN) '
      'e confirma com snackbar', (tester) async {
    final settings = _CapturingUpdateTenantSettings();
    await tester.pumpWidget(build(settings));
    await tester.pumpAndSettle();
    await openSettingsTab(tester);

    await tester.tap(find.text('English'));
    await tester.tap(find.text('Metical (MZN)'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Salvar ajustes'));
    await tester.pumpAndSettle();

    // A escolha foi persistida (repositório recebeu en + MZN).
    expect(settings.tenantId, 'tn1');
    expect(settings.language, 'en');
    expect(settings.currencyCode, 'MZN');

    expect(find.text('Ajustes salvos!'), findsOneWidget);
  });

  testWidgets('falha ao salvar mostra erro e não confirma', (tester) async {
    final settings = _CapturingUpdateTenantSettings(throwOnSave: true);
    await tester.pumpWidget(build(settings));
    await tester.pumpAndSettle();
    await openSettingsTab(tester);

    await tester.tap(find.text('English'));
    await tester.tap(find.text('Salvar ajustes'));
    await tester.pumpAndSettle();

    expect(
      find.text('Não foi possível salvar os ajustes. Tente novamente.'),
      findsOneWidget,
    );
    expect(find.text('Ajustes salvos!'), findsNothing);
    expect(settings.language, isNull);
  });
}
