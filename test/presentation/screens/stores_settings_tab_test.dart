import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';
import '../../helpers/viewport.dart';

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
    Plan(id: 'pl2', name: 'Profissional', maxStores: 3, maxEmployees: 10),
  ];
}

class _FakeGetStoresUseCase implements GetStoresUseCase {
  _FakeGetStoresUseCase({
    this.stores = const [
      Store(id: 'st1', tenantId: 'tn1', name: 'Loja Centro'),
    ],
  });

  final List<Store> stores;

  @override
  Future<List<Store>> call(String tenantId) async => List.unmodifiable(stores);
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
  // Fixture com BRL EXPLÍCITO: o padrão de novos tenants é MZN (metical),
  // mas este teste cobre um tenant legado/ajustado para Real — a aba deve
  // refletir o estado SALVO do tenant, não o padrão.
  final tenant = Tenant(
    id: 'tn1',
    ownerUserId: 'u1',
    businessName: 'Comercial X',
    planId: 'pl2',
    status: TenantStatus.approved,
    approvedAt: DateTime.now(),
    createdAt: DateTime.now(),
    currencyCode: 'BRL',
  );

  Widget build(
    _CapturingUpdateTenantSettings settings, {
    List<Store> stores = const [
      Store(id: 'st1', tenantId: 'tn1', name: 'Loja Centro'),
    ],
  }) => ProviderScope(
    overrides: [
      getPlansUseCaseProvider.overrideWithValue(_FakeGetPlansUseCase()),
      getStoresUseCaseProvider.overrideWithValue(
        _FakeGetStoresUseCase(stores: stores),
      ),
      getEmployeesUseCaseProvider.overrideWithValue(_FakeGetEmployeesUseCase()),
      getMyPlanRequestsUseCaseProvider.overrideWithValue(
        _FakeGetMyPlanRequestsUseCase(),
      ),
      updateTenantSettingsUseCaseProvider.overrideWithValue(settings),
      // Sessão + tenant: o save invalida o myTenantProvider do usuário
      // (é assim que o tenantSettingsProvider reage e troca o locale).
      authStateProvider.overrideWith(
        (ref) => Stream.value(AppUser(id: 'u1', email: 'dono@loja.com')),
      ),
      getMyTenantUseCaseProvider.overrideWithValue(
        FakeGetMyTenantUseCase(tenant),
      ),
    ],
    child: testApp(home: StoresScreen(tenant: tenant)),
  );

  Future<void> openSettingsTab(WidgetTester tester) async {
    // Aba Ajustes = índice 3 do TabBar (Lojas, Funcionários, Upgrades...).
    await tester.tap(find.byType(Tab).at(3));
    await tester.pumpAndSettle();
  }

  testWidgets('aba Ajustes exibe idioma/moeda e reflete o estado do tenant', (
    tester,
  ) async {
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

  testWidgets('aba Ajustes: seção Loja ativa aparece com 2+ lojas e troca '
      'a loja ativa', (tester) async {
    final stores = const [
      Store(id: 'st1', tenantId: 'tn1', name: 'Loja Centro'),
      Store(id: 'st2', tenantId: 'tn1', name: 'Loja Shopping'),
    ];
    await tester.pumpWidget(
      build(_CapturingUpdateTenantSettings(), stores: stores),
    );
    await tester.pumpAndSettle();
    await openSettingsTab(tester);

    // Seção "Loja ativa" com as duas lojas — a primeira é a ativa.
    expect(find.text('Loja ativa'), findsOneWidget);
    expect(_chipSelected(tester, 'Loja Centro'), isTrue);
    expect(_chipSelected(tester, 'Loja Shopping'), isFalse);

    // Tocar na Loja Shopping troca a loja ativa.
    await tester.tap(find.text('Loja Shopping'));
    await tester.pumpAndSettle();

    expect(_chipSelected(tester, 'Loja Centro'), isFalse);
    expect(_chipSelected(tester, 'Loja Shopping'), isTrue);
  });

  testWidgets('aba Ajustes: sem seção Loja ativa com uma única loja', (
    tester,
  ) async {
    final settings = _CapturingUpdateTenantSettings();
    await tester.pumpWidget(build(settings)); // 1 loja (fake padrão)
    await tester.pumpAndSettle();
    await openSettingsTab(tester);

    expect(find.text('Loja ativa'), findsNothing);
    expect(find.text('Idioma'), findsOneWidget);
  });

  testWidgets('aba Ajustes: seção Segurança abre a sheet de troca de senha', (
    tester,
  ) async {
    // Viewport alto: a seção Segurança fica abaixo da dobra padrão (600px).
    tester.view.physicalSize = const Size(600, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(build(_CapturingUpdateTenantSettings()));
    await tester.pumpAndSettle();
    await openSettingsTab(tester);

    // Seção Segurança com a entrada de troca de senha.
    expect(find.text('Segurança'), findsOneWidget);
    expect(find.text('Trocar senha'), findsOneWidget);
    expect(find.text('Atualize a senha da sua conta'), findsOneWidget);

    // Abre a sheet de troca de senha.
    await tester.tap(find.text('Trocar senha'));
    await tester.pumpAndSettle();
    expect(find.text('Senha atual'), findsOneWidget);
    expect(find.text('Nova senha'), findsOneWidget);
    expect(find.text('Alterar senha'), findsOneWidget);
  });

  // Rotação (UI): a tela Lojas (pushed) tem TabBar com 4 abas — em
  // paisagem as abas e o conteúdo da aba Ajustes (idioma/moeda) seguem
  // íntegros; voltar para a aba Lojas em paisagem também funciona.
  // Overflows de RenderFlex falham o teste via takeException.
  testWidgets('Lojas/Ajustes sobrevivem à rotação para paisagem', (
    tester,
  ) async {
    usePortraitViewport(tester);

    await tester.pumpWidget(build(_CapturingUpdateTenantSettings()));
    await tester.pumpAndSettle();

    // Retrato: aba Lojas com a loja do tenant visível.
    expect(find.text('Loja Centro'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Gira para paisagem.
    await rotateToLandscape(tester);

    // Sem overflow; as quatro abas e a loja seguem presentes após o giro.
    expect(tester.takeException(), isNull);
    expect(find.text('Loja Centro'), findsOneWidget);

    // Abrir a aba Ajustes em paisagem funciona.
    await openSettingsTab(tester);
    expect(find.text('Idioma'), findsOneWidget);
    expect(find.text('Moeda'), findsOneWidget);
    expect(find.text('Salvar ajustes'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Voltar para a aba Lojas em paisagem também funciona.
    await tester.tap(find.byType(Tab).at(0));
    await tester.pumpAndSettle();
    expect(find.text('Loja Centro'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
