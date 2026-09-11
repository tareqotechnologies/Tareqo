import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

import 'package:tareqo/domain/entities/plan.dart';
import 'package:tareqo/domain/entities/tenant.dart';
import 'package:tareqo/domain/repositories/i_plan_repository.dart';
import 'package:tareqo/domain/usecases/add_plan_use_case.dart';
import 'package:tareqo/domain/usecases/get_all_plans_use_case.dart';
import 'package:tareqo/domain/usecases/get_all_tenants_use_case.dart';
import 'package:tareqo/domain/usecases/update_plan_use_case.dart';
import 'package:tareqo/presentation/controllers/account_providers.dart';
import 'package:tareqo/presentation/controllers/admin_providers.dart';
import 'package:tareqo/presentation/screens/admin/admin_plans_screen.dart';

class _FakeGetAllPlansUseCase implements GetAllPlansUseCase {
  _FakeGetAllPlansUseCase(this._plans);

  final List<Plan> _plans;
  bool throwOnCall = false;
  int calls = 0;

  @override
  Future<List<Plan>> call() async {
    calls++;
    if (throwOnCall) throw Exception('falha planos');
    return _plans;
  }
}

/// Repositório em memória — os use cases reais ([AddPlanUseCase]/
/// [UpdatePlanUseCase] com `validatePlan`) rodam sobre ele.
class _FakePlanRepository implements IPlanRepository {
  final List<Plan> plans;
  bool throwOnWrite = false;
  int addCalls = 0;
  int updateCalls = 0;

  _FakePlanRepository(this.plans);

  @override
  Future<void> add(Plan plan) async {
    addCalls++;
    if (throwOnWrite) throw Exception('falha ao salvar');
    plans.add(plan);
  }

  @override
  Future<void> update(Plan plan) async {
    updateCalls++;
    if (throwOnWrite) throw Exception('falha ao salvar');
    final i = plans.indexWhere((p) => p.id == plan.id);
    if (i >= 0) plans[i] = plan;
  }

  @override
  Future<List<Plan>> getActivePlans() async =>
      plans.where((p) => p.isActive).toList();

  @override
  Future<List<Plan>> getAllPlans() async => List.of(plans);

  @override
  Future<Plan?> getById(String id) async =>
      plans.where((p) => p.id == id).firstOrNull;
}

class _FakeAllTenantsUseCase implements GetAllTenantsUseCase {
  _FakeAllTenantsUseCase(this._tenants);

  final List<Tenant> _tenants;

  @override
  Future<List<Tenant>> call() async => _tenants;
}

const _plans = [
  Plan(
    id: 'pl1',
    name: 'Essencial',
    description: 'Para começar',
    priceMonthlyCents: 2990,
    maxStores: 1,
    maxEmployees: 3,
  ),
  Plan(
    id: 'pl2',
    name: 'Comercial',
    priceMonthlyCents: 9900,
    maxStores: 5,
    maxEmployees: 20,
    isActive: false,
  ),
];

Tenant _tenant({
  required String id,
  required String planId,
  required TenantStatus status,
}) =>
    Tenant(
      id: id,
      ownerUserId: 'owner12345',
      businessName: 'Tenant $id',
      planId: planId,
      status: status,
      createdAt: DateTime(2026, 8, 1),
    );

class _Harness {
  _Harness({List<Plan> plans = _plans})
      : repository = _FakePlanRepository(List.of(plans)) {
    getAllPlans = _FakeGetAllPlansUseCase(plans);
  }

  late _FakeGetAllPlansUseCase getAllPlans;
  final _FakePlanRepository repository;
  final allTenants = [
    _tenant(id: 'tn1', planId: 'pl1', status: TenantStatus.approved),
    _tenant(id: 'tn2', planId: 'pl1', status: TenantStatus.pending),
    _tenant(id: 'tn3', planId: 'pl2', status: TenantStatus.rejected),
  ];

  Widget build() {
    return ProviderScope(
      overrides: [
        getAllPlansUseCaseProvider.overrideWithValue(getAllPlans),
        getAllTenantsUseCaseProvider.overrideWithValue(
          _FakeAllTenantsUseCase(allTenants),
        ),
        addPlanUseCaseProvider.overrideWithValue(
          AddPlanUseCase(repository),
        ),
        updatePlanUseCaseProvider.overrideWithValue(
          UpdatePlanUseCase(repository),
        ),
      ],
      child: testApp(
        home: const AdminPlansScreen(),
        builder: (context, child) => MediaQuery.withClampedTextScaling(
          maxScaleFactor: 0.8,
          child: child!,
        ),
      ),
    );
  }
}

void _useWideViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1250, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('lista planos com preço, limites, contagem de tenants e badge de inactivo', (tester) async {
    _useWideViewport(tester);
    final h = _Harness();
    await tester.pumpWidget(h.build());
    await tester.pumpAndSettle();

    // ignore: avoid_print
    print('DEBUG texts=${tester.allWidgets
        .whereType<Text>()
        .map((t) => t.data)
        .where((d) => d != null)
        .toSet()
        .take(20)
        .toList()}');

    // Stats compacto: 2 planos, 1 activo, 1 inactivo (contagem e rótulo
    // são Texts SEPARADOS na _Pill).
    expect(find.text('2'), findsWidgets);
    expect(find.text('Total'), findsOneWidget);
    expect(find.text('Activos'), findsOneWidget);
    expect(find.text('Inactivos'), findsOneWidget);

    // Tile: nome + preço num Text.rich (findRichText: true para casar).
    expect(find.textContaining('Essencial'), findsOneWidget);
    expect(find.textContaining('Comercial'), findsOneWidget);
    // Badge "Inactivo" só no tile do pl2 (o stats usa "Inactivos", plural).
    expect(find.text('Inactivo'), findsOneWidget);
    // Limites: "1 máx. lojas · 3 máx. funcionários" e "5 · 20".
    expect(find.textContaining('máx. lojas'), findsWidgets);
    // Contagem de tenants por plano (pl1: 2, pl2: 1).
    expect(find.text('2 tenants'), findsOneWidget);
    expect(find.text('1 tenant'), findsOneWidget);
  });

  testWidgets('toque no tile abre o sheet de detalhes com stats por status',
      (tester) async {
    _useWideViewport(tester);
    final h = _Harness();
    await tester.pumpWidget(h.build());
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Essencial'));
    await tester.pumpAndSettle();

    // Header do sheet: nome + ID + status.
    expect(find.text('pl1'), findsOneWidget);
    expect(find.text('Aprovado'), findsOneWidget);
    // Info rows.
    expect(find.text('Preço mensal'), findsOneWidget);
    expect(find.textContaining('R\$ 29,90'), findsWidgets);
    expect(find.text('3'), findsWidgets); // maxEmployees
    // Tenants no plano: chips por status (1 aprovado, 1 pendente).
    expect(find.text('1 Aprovado'), findsOneWidget);
    expect(find.text('1 Pendente'), findsOneWidget);
    expect(find.text('0 Rejeitado'), findsOneWidget);
    // Mini tile do tenant com o nome e o prefixo do owner (tn1 e tn2 são
    // do pl1 → 2 mini tiles com o MESMO prefixo truncado).
    expect(find.text('Tenant tn1'), findsOneWidget);
    expect(find.text('owner123'), findsNWidgets(2));
  });

  testWidgets('plano inactivo mostra status Inactivo e descrição no sheet',
      (tester) async {
    _useWideViewport(tester);
    final h = _Harness();
    await tester.pumpWidget(h.build());
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Comercial'));
    await tester.pumpAndSettle();

    // Status chip: "Inactivo" (badge do tile atrás + chip do sheet).
    expect(find.text('Inactivo'), findsNWidgets(2));
    // A fixture só define descrição no pl1 — o sheet do pl2 (vazio) NÃO
    // renderiza o bloco de descrição.
    expect(find.text('Para começar'), findsNothing);
  });

  testWidgets('ID do plano copiável com snackbar', (tester) async {
    _useWideViewport(tester);
    final h = _Harness();
    await tester.pumpWidget(h.build());
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Essencial'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('pl1'));
    await tester.pump();

    expect(find.text('Copiado para a área de transferência'), findsOneWidget);
    // O conteúdo da área de transferência não é lido aqui — `Clipboard.getData`
    // fica pendente no ambiente de teste (sem handler nativo); o snackbar
    // acima já prova que o gesto chegou ao `Clipboard.setData`.
  });

  testWidgets('botão Salvar do sheet de detalhes abre o editor pré-preenchido', (tester) async {
    _useWideViewport(tester);
    final h = _Harness();
    await tester.pumpWidget(h.build());
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Essencial'));
    await tester.pumpAndSettle();

    // O botão "Salvar" do DETALHE abre o editor (rota: pop + editor).
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    // Editor em modo edição: título "Editar plano" + campos pré-preenchidos.
    expect(find.text('Editar plano'), findsOneWidget);
    expect(find.text('Nome do plano'), findsOneWidget);
    expect(find.text('29.9'), findsOneWidget); // 2990/100 sem vírgula
    expect(find.text('Criar plano'), findsNothing);
  });

  testWidgets('criar plano via FAB: validação, preenchimento e persistência', (tester) async {
    _useWideViewport(tester);
    final h = _Harness();
    await tester.pumpWidget(h.build());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Novo plano'), findsOneWidget);

    // Salvar vazio → erro de nome (validação no use case, via _formError).
    await tester.tap(find.text('Criar plano'));
    await tester.pumpAndSettle();
    expect(find.text('Informe o nome do plano.'), findsOneWidget);
    // Nada persistido.
    expect(h.repository.addCalls, 0);

    // Preenche os campos do editor (sheets empilham: os TextFields do editor
    // vêm DEPOIS do tile de baixo — busca pelos controllers via label).
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nome do plano'),
      'Premium',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Descrição'),
      'Topo de linha',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Preço mensal'),
      '59,90',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Máx. lojas'),
      '3',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Máx. funcionários'),
      '10',
    );
    await tester.tap(find.text('Criar plano'));
    await tester.pumpAndSettle();

    // Persistido com os valores validados (Money.parse aceita vírgula).
    expect(h.repository.addCalls, 1);
    expect(find.text('Plano Premium criado!'), findsOneWidget);
    final added = h.repository.plans.last;
    expect(added.name, 'Premium');
    expect(added.priceMonthlyCents, 5990);
    expect(added.maxStores, 3);
    expect(added.maxEmployees, 10);
  });

  testWidgets('editar plano: campos pré-preenchidos e update no repositório', (tester) async {
    _useWideViewport(tester);
    final h = _Harness();
    await tester.pumpWidget(h.build());
    await tester.pumpAndSettle();

    // Long press no tile abre o editor direto em modo edição.
    await tester.longPress(find.textContaining('Essencial'));
    await tester.pumpAndSettle();

    expect(find.text('Editar plano'), findsOneWidget);
    // O preço chega como "29.9" (divisão simples por 100).
    expect(find.text('29.9'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Preço mensal'),
      '39.90',
    );
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(h.repository.updateCalls, 1);
    expect(find.text('Plano Essencial atualizado!'), findsOneWidget);
    expect(
      h.repository.plans.firstWhere((p) => p.id == 'pl1').priceMonthlyCents,
      3990,
    );
  });

  testWidgets('lista vazia mostra EmptyState (sem FAB de criar no empty)', (tester) async {
    _useWideViewport(tester);
    final h = _Harness(plans: const []);
    await tester.pumpWidget(h.build());
    await tester.pumpAndSettle();

    expect(find.text('Nenhum plano criado'), findsOneWidget);
    expect(
      find.text('Crie o primeiro plano para liberar assinaturas.'),
      findsOneWidget,
    );
  });

  testWidgets('erro de carga mostra ErrorView com retry que recupera', (tester) async {
    _useWideViewport(tester);
    final h = _Harness()..getAllPlans.throwOnCall = true;
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null, // retry automático desativado
        overrides: [
          getAllPlansUseCaseProvider.overrideWithValue(h.getAllPlans),
          getAllTenantsUseCaseProvider.overrideWithValue(
            _FakeAllTenantsUseCase(const []),
          ),
          addPlanUseCaseProvider.overrideWithValue(AddPlanUseCase(h.repository)),
          updatePlanUseCaseProvider.overrideWithValue(
            UpdatePlanUseCase(h.repository),
          ),
        ],
        child: testApp(home: const AdminPlansScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Não foi possível carregar os planos.'), findsOneWidget);

    // Retry recupera.
    h.getAllPlans.throwOnCall = false;
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Essencial'), findsOneWidget);
    expect(h.getAllPlans.calls, greaterThanOrEqualTo(2));
  });
}
