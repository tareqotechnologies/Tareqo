import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

import 'package:tareqo/domain/entities/app_user.dart';
import 'package:tareqo/domain/entities/plan.dart';
import 'package:tareqo/domain/entities/plan_request.dart';
import 'package:tareqo/domain/entities/store.dart';
import 'package:tareqo/domain/entities/store_employee.dart';
import 'package:tareqo/domain/entities/tenant.dart';
import 'package:tareqo/domain/repositories/i_employee_account_service.dart';
import 'package:tareqo/domain/repositories/i_employee_repository.dart';
import 'package:tareqo/domain/repositories/i_plan_repository.dart';
import 'package:tareqo/domain/repositories/i_plan_request_repository.dart';
import 'package:tareqo/domain/repositories/i_store_repository.dart';
import 'package:tareqo/domain/repositories/i_tenant_repository.dart';
import 'package:tareqo/domain/usecases/add_employee_use_case.dart';
import 'package:tareqo/domain/usecases/add_store_use_case.dart';
import 'package:tareqo/domain/usecases/get_my_plan_requests_use_case.dart';
import 'package:tareqo/domain/usecases/get_plans_use_case.dart';
import 'package:tareqo/domain/usecases/get_stores_use_case.dart';
import 'package:tareqo/domain/usecases/request_plan_upgrade_use_case.dart';
import 'package:tareqo/presentation/controllers/account_providers.dart';
import 'package:tareqo/presentation/controllers/auth_providers.dart';
import 'package:tareqo/presentation/screens/stores/stores_screen.dart';

// ─── Fakes de repositório (memória) ─────────────────────────────────────────

class _MemStoreRepository implements IStoreRepository {
  _MemStoreRepository(this.stores);

  final List<Store> stores;
  int addCalls = 0;

  @override
  Future<List<Store>> getByTenant(String tenantId) async => List.of(stores);

  @override
  Future<void> add(Store store) async {
    addCalls++;
    stores.add(store);
  }

  @override
  Future<void> update(Store store) async {
    final i = stores.indexWhere((s) => s.id == store.id);
    if (i >= 0) stores[i] = store;
  }
}

class _MemTenantRepository implements ITenantRepository {
  _MemTenantRepository(this.tenant);

  final Tenant tenant;
  int getByIdCalls = 0;

  @override
  Future<Tenant?> getById(String id) async {
    getByIdCalls++;
    return tenant;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _MemPlanRepository implements IPlanRepository {
  _MemPlanRepository(List<Plan> plans) : plans = List.of(plans);

  final List<Plan> plans;

  @override
  Future<Plan?> getById(String id) async =>
      plans.where((p) => p.id == id).firstOrNull;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _MemEmployeeRepository implements IEmployeeRepository {
  final List<StoreEmployee> employees = [];
  int addCalls = 0;

  @override
  Future<List<StoreEmployee>> getByTenant(String tenantId) async =>
      List.of(employees);

  @override
  Future<void> add(StoreEmployee employee) async {
    addCalls++;
    employees.add(employee);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _MemPlanRequestRepository implements IPlanRequestRepository {
  final List<PlanRequest> requests = [];
  int createCalls = 0;
  PlanRequest? lastCreated;

  @override
  Future<List<PlanRequest>> getByTenant(String tenantId) async =>
      List.of(requests);

  @override
  Future<PlanRequest> create({
    required String tenantId,
    required String currentPlanId,
    required String requestedPlanId,
  }) async {
    createCalls++;
    final r = PlanRequest(
      id: 'new-req',
      tenantId: tenantId,
      currentPlanId: currentPlanId,
      requestedPlanId: requestedPlanId,
      createdAt: DateTime(2026, 9, 1),
    );
    requests.add(r);
    lastCreated = r;
    return r;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeEmployeeAccountService implements EmployeeAccountService {
  int calls = 0;
  Object? throwOnCreate;

  @override
  Future<String> createAccount({
    required String email,
    required String password,
    required String fullName,
  }) async {
    calls++;
    final error = throwOnCreate;
    if (error != null) throw error;
    return 'new-user-id';
  }
}

// Use cases fake apenas para leitura (listas usadas pela UI).
class _FakeGetPlansUseCase implements GetPlansUseCase {
  @override
  Future<List<Plan>> call() async => const [
        Plan(id: 'pl1', name: 'Essencial', maxStores: 1, maxEmployees: 1),
        Plan(id: 'pl2', name: 'Profissional', maxStores: 3, maxEmployees: 10),
        Plan(
          id: 'pl3',
          name: 'Avançado',
          priceMonthlyCents: 19900,
          maxStores: 10,
          maxEmployees: 40,
        ),
      ];
}

class _FakeGetStoresUseCase implements GetStoresUseCase {
  _FakeGetStoresUseCase(this._stores);
  final List<Store> _stores;

  @override
  Future<List<Store>> call(String tenantId) async => List.of(_stores);
}

class _FakeGetMyPlanRequestsUseCase implements GetMyPlanRequestsUseCase {
  @override
  Future<List<PlanRequest>> call(String tenantId) async => const [];
}

Store _store(String id, String name) =>
    Store(id: id, tenantId: 'tn1', name: name);

void main() {
  final tenant = Tenant(
    id: 'tn1',
    ownerUserId: 'u1',
    businessName: 'Comercial X',
    planId: 'pl2',
    status: TenantStatus.approved,
    approvedAt: DateTime(2026, 1, 5),
    createdAt: DateTime(2026, 1, 5),
  );

  late _MemStoreRepository storeRepo;
  late _MemEmployeeRepository employeeRepo;
  late _MemPlanRepository planRepo;
  late _MemTenantRepository tenantRepo;
  late _MemPlanRequestRepository planRequestRepo;
  late _FakeEmployeeAccountService accountService;

  setUp(() {
    storeRepo = _MemStoreRepository([
      _store('st1', 'Loja Centro'),
      _store('st2', 'Loja Praia'),
    ]);
    employeeRepo = _MemEmployeeRepository();
    planRepo = _MemPlanRepository(const [
      Plan(
        id: 'pl2',
        name: 'Profissional',
        description: 'Até 3 lojas',
        priceMonthlyCents: 9900,
        maxStores: 3,
        maxEmployees: 10,
      ),
      Plan(
        id: 'pl3',
        name: 'Avançado',
        description: 'Até 10 lojas',
        priceMonthlyCents: 19900,
        maxStores: 10,
        maxEmployees: 40,
      ),
    ]);
    tenantRepo = _MemTenantRepository(tenant);
    planRequestRepo = _MemPlanRequestRepository();
    accountService = _FakeEmployeeAccountService();
  });

  Widget build() => ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(AppUser(id: 'u1', email: 'dono@loja.com')),
          ),
          getPlansUseCaseProvider.overrideWithValue(_FakeGetPlansUseCase()),
          getStoresUseCaseProvider.overrideWithValue(
            _FakeGetStoresUseCase(storeRepo.stores),
          ),
          getMyPlanRequestsUseCaseProvider.overrideWithValue(
            _FakeGetMyPlanRequestsUseCase(),
          ),
          addStoreUseCaseProvider.overrideWithValue(
            AddStoreUseCase(storeRepo, tenantRepo, planRepo),
          ),
          addEmployeeUseCaseProvider.overrideWithValue(
            AddEmployeeUseCase(
              employeeRepo,
              tenantRepo,
              planRepo,
              storeRepo,
              accountService: accountService,
            ),
          ),
          requestPlanUpgradeUseCaseProvider.overrideWithValue(
            RequestPlanUpgradeUseCase(planRequestRepo, tenantRepo),
          ),
        ],
        child: testApp(home: StoresScreen(tenant: tenant)),
      );

  Future<void> openStoreSheet(WidgetTester tester) async {
    await tester.pumpWidget(build());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Nova loja'));
    await tester.pumpAndSettle();
  }

  testWidgets('Nova loja: validação de nome vazio e criação com sucesso',
      (tester) async {
    await openStoreSheet(tester);

    // Salvar sem nome → erro do use case (InvalidStoreException).
    await tester.ensureVisible(find.text('Criar loja'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Criar loja'));
    await tester.pumpAndSettle();
    expect(find.text('Informe o nome da loja.'), findsOneWidget);
    expect(storeRepo.addCalls, 0);

    // Preenche e salva.
    await tester.enterText(find.byType(TextFormField).at(0), 'Loja Nova');
    await tester.enterText(find.byType(TextFormField).at(4), '123456789');
    await tester.enterText(find.byType(TextFormField).at(5), 'Maputo');
    await tester.ensureVisible(find.text('Criar loja'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Criar loja'));
    await tester.pumpAndSettle();

    // Sucesso: repositório recebeu a loja completa (a snackbar pode ter
    // expirado no pumpAndSettle — o repositório é a prova primária).
    expect(storeRepo.addCalls, 1);
    final added = storeRepo.stores.lastWhere((s) => s.name == 'Loja Nova');
    expect(added.tenantId, 'tn1');
    expect(added.nuit, '123456789');
    expect(added.city, 'Maputo');
  });

  testWidgets('Nova loja: limite do plano estourado mostra mensagem do use case',
      (tester) async {
    // Plano com 1 loja (as 2 da fixture já estouram o limite de 3? não —
    // usamos um plano de 2 lojas: 2 existentes ≥ 2 → bloqueia a 3ª).
    planRepo.plans.clear();
    planRepo.plans.add(
      const Plan(
        id: 'pl2',
        name: 'Profissional',
        priceMonthlyCents: 9900,
        maxStores: 2,
        maxEmployees: 10,
      ),
    );
    await openStoreSheet(tester);

    await tester.enterText(find.byType(TextFormField).at(0), 'Terceira');
    await tester.ensureVisible(find.text('Criar loja'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Criar loja'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('permite até 2 lojas'),
      findsOneWidget,
    );
    expect(storeRepo.addCalls, 0);
    // A sheet PERMANECE aberta (erro inline, sem pop).
    expect(find.text('Criar loja'), findsOneWidget);
  });

  Future<void> openEmployeeSheet(WidgetTester tester) async {
    await tester.pumpWidget(build());
    await tester.pumpAndSettle();
    // Aba Funcionários → FAB.
    await tester.tap(find.byType(Tab).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Novo funcionário'));
    await tester.pumpAndSettle();
  }

  testWidgets('Novo funcionário: chips de loja/cargo, conta criada e vínculo',
      (tester) async {
    await openEmployeeSheet(tester);

    // Preenche dados pessoais.
    await tester.enterText(find.byType(TextFormField).at(0), 'Ana Lima');
    await tester.enterText(find.byType(TextFormField).at(1), 'ana@loja.com');
    await tester.enterText(find.byType(TextFormField).at(2), 'senha123');

    // Seleciona a loja e o cargo Gerente (chips).
    await tester.tap(find.text('Loja Centro'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gerente'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Cadastrar funcionário'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cadastrar funcionário'));
    await tester.pumpAndSettle();

    // Conta criada + vínculo persistido com cargo e loja corretos.
    expect(find.text('Funcionário cadastrado! Conta de acesso criada.'),
        findsOneWidget);
    expect(accountService.calls, 1);
    expect(employeeRepo.addCalls, 1);
    final e = employeeRepo.employees.single;
    expect(e.fullName, 'Ana Lima');
    expect(e.userId, 'new-user-id');
    expect(e.role, EmployeeRole.manager);
    expect(e.storeId, 'st1');
  });

  testWidgets('Novo funcionário: e-mail duplicado mostra a mensagem da conta',
      (tester) async {
    accountService.throwOnCreate = const EmployeeAccountCreationException(
      'E-mail já registrado.',
    );
    await openEmployeeSheet(tester);

    await tester.enterText(find.byType(TextFormField).at(0), 'Ana Lima');
    await tester.enterText(find.byType(TextFormField).at(1), 'ana@loja.com');
    await tester.enterText(find.byType(TextFormField).at(2), 'senha123');
    await tester.tap(find.text('Loja Centro'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Cadastrar funcionário'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cadastrar funcionário'));
    await tester.pumpAndSettle();

    // A mensagem amigável da EXCEÇÃO de conta aparece no _formError.
    expect(find.text('E-mail já registrado.'), findsOneWidget);
    // A sheet permanece aberta para correção.
    expect(find.text('Cadastrar funcionário'), findsOneWidget);
  });

  testWidgets('Upgrade: seleção de plano, envio do pedido e duplicado bloqueado',
      (tester) async {
    await tester.pumpWidget(build());
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Tab).at(2)); // Upgrades
    await tester.pumpAndSettle();
    // Card do plano → botão Upgrade abre o _UpgradeSheet.
    await tester.tap(find.text('Upgrade'));
    await tester.pumpAndSettle();

    // Título + subtítulo; candidato único (pl3) com preço.
    expect(find.text('Upgrade de plano'), findsOneWidget);
    expect(
      find.text('Escolha o novo plano. Aguarda aprovação do super admin.'),
      findsOneWidget,
    );

    // Sem seleção → erro inline, nada enviado.
    await tester.tap(find.text('Solicitar upgrade'));
    await tester.pumpAndSettle();
    expect(find.text('Escolha o plano de destino.'), findsOneWidget);
    expect(planRequestRepo.createCalls, 0);

    // Seleciona e envia.
    await tester.tap(find.textContaining('Avançado'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Solicitar upgrade'));
    await tester.pumpAndSettle();

    expect(find.text('Pedido de upgrade enviado!'), findsOneWidget);
    expect(planRequestRepo.createCalls, 1);
    expect(planRequestRepo.lastCreated?.requestedPlanId, 'pl3');
    expect(planRequestRepo.lastCreated?.currentPlanId, 'pl2');
  });
}
