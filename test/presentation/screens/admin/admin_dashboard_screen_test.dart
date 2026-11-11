import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

import 'package:tareqo/domain/entities/audit_entry.dart';
import 'package:tareqo/domain/entities/plan.dart';
import 'package:tareqo/domain/entities/plan_request.dart';
import 'package:tareqo/domain/entities/tenant.dart';
import 'package:tareqo/domain/usecases/get_all_plans_use_case.dart';
import 'package:tareqo/domain/usecases/get_all_tenants_use_case.dart';
import 'package:tareqo/domain/usecases/get_audit_log_use_case.dart';
import 'package:tareqo/domain/usecases/get_pending_plan_requests_use_case.dart';
import 'package:tareqo/presentation/controllers/admin_providers.dart';
import 'package:tareqo/presentation/screens/admin/admin_dashboard_screen.dart';

class _FakeGetAllTenantsUseCase implements GetAllTenantsUseCase {
  _FakeGetAllTenantsUseCase(this._tenants);

  final List<Tenant> _tenants;
  bool throwOnCall = false;
  int calls = 0;

  @override
  Future<List<Tenant>> call() async {
    calls++;
    if (throwOnCall) throw Exception('falha tenants');
    return _tenants;
  }
}

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

class _FakeGetPendingPlanRequestsUseCase
    implements GetPendingPlanRequestsUseCase {
  _FakeGetPendingPlanRequestsUseCase(this._requests);

  final List<PlanRequest> _requests;
  bool throwOnCall = false;
  int calls = 0;

  @override
  Future<List<PlanRequest>> call() async {
    calls++;
    if (throwOnCall) throw Exception('falha upgrades');
    return _requests;
  }
}

class _FakeGetAuditLogUseCase implements GetAuditLogUseCase {
  _FakeGetAuditLogUseCase(this._entries);

  final List<AuditEntry> _entries;

  @override
  Future<List<AuditEntry>> call({int limit = 100}) async => _entries;
}

const _plans = [
  Plan(id: 'pl1', name: 'Essencial', priceMonthlyCents: 2990),
  Plan(id: 'pl2', name: 'Comercial', priceMonthlyCents: 9900),
];

/// now-1h → dentro da semana/mês correntes (janelas do dashboard);
/// now-100d → fora de ambas. O default NÃO pode ser ~40d: 40 dias atrás
/// cai no mês anterior apenas a partir do dia ~10 de cada mês (flaky
/// dependente da data); 100d garante outside both windows o ano inteiro
/// (máx. ~62 dias para atravessar semana+mês anterior).
Tenant _tenant({
  required String id,
  required TenantStatus status,
  required String planId,
  int daysAgo = 100,
}) => Tenant(
  id: id,
  ownerUserId: 'owner12345',
  businessName: 'Tenant $id',
  planId: planId,
  status: status,
  createdAt: DateTime.now().subtract(Duration(days: daysAgo, hours: 1)),
);

AuditEntry _approvalAudit() => AuditEntry(
  id: 7,
  actorUserId: 'admin9',
  action: 'tenant_decision',
  entityType: 'tenants',
  entityId: 'tn1',
  detail: const {'status': 'approved'},
  createdAt: DateTime.now().subtract(const Duration(hours: 1)),
);

AuditEntry _approvalAudit2() => AuditEntry(
  id: 8,
  actorUserId: 'admin9',
  action: 'tenant_decision',
  entityType: 'tenants',
  entityId: 'tn2',
  detail: const {'status': 'approved'},
  createdAt: DateTime.now().subtract(const Duration(hours: 3)),
);

PlanRequest _upgradeRequest(String id) => PlanRequest(
  id: id,
  tenantId: 'tn1',
  currentPlanId: 'pl1',
  requestedPlanId: 'pl2',
  createdAt: DateTime(2026, 8, 1),
);

Widget _buildApp({
  List<Tenant> tenants = const [],
  List<Plan> plans = _plans,
  List<PlanRequest> pendingRequests = const [],
  List<AuditEntry> auditLog = const [],
  _FakeGetAllTenantsUseCase? allUseCase,
  _FakeGetAllPlansUseCase? plansUseCase,
  _FakeGetPendingPlanRequestsUseCase? pendingUseCase,
  void Function(int)? onNavigateToTab,
  bool disableAutoRetry = false,
}) {
  return ProviderScope(
    // retry: null desativa o retry automático do Riverpod 3 — nos testes de
    // erro ele coloca o provider em loading ANTES do frame de erro renderizar.
    retry: disableAutoRetry ? (_, _) => null : null,
    overrides: [
      getAllTenantsUseCaseProvider.overrideWithValue(
        allUseCase ?? _FakeGetAllTenantsUseCase(tenants),
      ),
      getAllPlansUseCaseProvider.overrideWithValue(
        plansUseCase ?? _FakeGetAllPlansUseCase(plans),
      ),
      getPendingPlanRequestsUseCaseProvider.overrideWithValue(
        pendingUseCase ?? _FakeGetPendingPlanRequestsUseCase(pendingRequests),
      ),
      getAuditLogUseCaseProvider.overrideWithValue(
        _FakeGetAuditLogUseCase(auditLog),
      ),
    ],
    child: testApp(
      home: AdminDashboardScreen(onNavigateToTab: onNavigateToTab),
      // Fonte de teste (Ahem) mais larga que a Outfit — clamp sem afetar
      // as asserções de texto.
      builder: (context, child) =>
          MediaQuery.withClampedTextScaling(maxScaleFactor: 0.8, child: child!),
    ),
  );
}

/// Viewport largo e alto — a fonte Ahem estoura Rows de cards/barras em
/// viewports padrão.
void _useWideViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1250, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets(
    'stats strip, banner de pendências e navegação para a tab de tenants',
    (tester) async {
      _useWideViewport(tester);
      final tabs = <int>[];
      await tester.pumpWidget(
        _buildApp(
          tenants: [
            _tenant(
              id: 'tn1',
              status: TenantStatus.approved,
              planId: 'pl1',
              daysAgo: 0,
            ),
            _tenant(id: 'tn2', status: TenantStatus.pending, planId: 'pl1'),
            _tenant(id: 'tn3', status: TenantStatus.rejected, planId: 'pl2'),
          ],
          pendingRequests: [_upgradeRequest('pr1'), _upgradeRequest('pr2')],
          onNavigateToTab: tabs.add,
        ),
      );
      await tester.pumpAndSettle();

      // Stats: 3 tenants, 1 activo, 1 pendente, 2 planos, 2 upgrades.
      expect(find.text('Total de tenants'), findsOneWidget);
      expect(find.text('Activos'), findsOneWidget);
      expect(find.text('Aguardando aprovação'), findsOneWidget);
      expect(find.text('Planos'), findsOneWidget);
      expect(find.text('Upgrades pendentes'), findsOneWidget);

      // Banner consolidado: 1 pendente + 2 upgrades = 3 ações.
      expect(find.text('3 ações necessárias'), findsOneWidget);

      // pendingTenants > 0 → navega para a tab 1 (tenants).
      await tester.tap(find.text('3 ações necessárias'));
      await tester.pump();
      expect(tabs, [1]);
    },
  );

  testWidgets('growth summary: comparativas semana/mês e tendência +1', (
    tester,
  ) async {
    _useWideViewport(tester);
    await tester.pumpWidget(
      _buildApp(
        tenants: [
          _tenant(
            id: 'tn1',
            status: TenantStatus.approved,
            planId: 'pl1',
            daysAgo: 0,
          ),
          _tenant(id: 'tn2', status: TenantStatus.pending, planId: 'pl1'),
        ],
        // 2 aprovações nesta semana → sublabel da KPI de aprovações
        // DIFERE da de tenants (ambas seriam 1/0).
        auditLog: [_approvalAudit(), _approvalAudit2()],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tendências de Crescimento'), findsOneWidget);
    // Novos tenants: esta semana 1 (tn1), semana passada 0 → diff +1.
    expect(
      find.text('Novos tenants Esta semana: 1 · Semana passada: 0'),
      findsNothing,
    ); // o sublabel é um Text próprio, sem o label junto.
    expect(find.text('Esta semana: 1 · Semana passada: 0'), findsOneWidget);
    // Aprovações: 2 nesta semana, 0 na passada → +2.
    expect(find.text('Esta semana: 2 · Semana passada: 0'), findsOneWidget);
    // tn1 foi criado hoje → conta na semana E no mês correntes; ambos os
    // KPIs (semanal e mensal) calculam diff +1, logo "+1" aparece 2×.
    expect(find.text('+1'), findsNWidgets(2));
    expect(find.text('+2'), findsOneWidget);
    // Tendências 8 semanas com dados → sem mensagem de vazio.
    expect(
      find.text('Dados insuficientes para mostrar tendências'),
      findsNothing,
    );
  });

  testWidgets('distribuição: taxa de aprovação e barras por plano', (
    tester,
  ) async {
    _useWideViewport(tester);
    await tester.pumpWidget(
      _buildApp(
        tenants: [
          _tenant(
            id: 'tn1',
            status: TenantStatus.approved,
            planId: 'pl1',
            daysAgo: 0,
          ),
          _tenant(id: 'tn2', status: TenantStatus.pending, planId: 'pl1'),
          _tenant(id: 'tn3', status: TenantStatus.rejected, planId: 'pl2'),
        ],
      ),
    );
    await tester.pumpAndSettle();

    // 1/3 aprovado → 33%.
    expect(find.text('33%'), findsOneWidget);
    // Legenda de status (counts).
    expect(find.text('Distribuição de planos'), findsOneWidget);
    // Plano Essencial: 2 tenants (tn1, tn2); Comercial: 1 (tn3).
    expect(find.text('Essencial'), findsOneWidget);
    expect(find.text('Comercial'), findsOneWidget);
  });

  testWidgets('feed de actividade + acções rápidas navegam para as tabs', (
    tester,
  ) async {
    _useWideViewport(tester);
    final tabs = <int>[];
    await tester.pumpWidget(
      _buildApp(
        tenants: [
          _tenant(
            id: 'tn1',
            status: TenantStatus.approved,
            planId: 'pl1',
            daysAgo: 0,
          ),
        ],
        auditLog: [
          _approvalAudit(),
          AuditEntry(
            id: 8,
            action: 'plan_change',
            entityType: 'plans',
            entityId: 'pl1',
            createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          ),
        ],
        onNavigateToTab: tabs.add,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Atividade recente'), findsOneWidget);
    // actionLabel do AuditEntry.
    expect(find.text('Tenant decision'), findsOneWidget);
    expect(find.text('Plan change'), findsOneWidget);
    // Com audit não-vazio, o TextButton "Ver Registo de Auditoria" existe
    // (além do quick action com o mesmo rótulo).
    expect(
      find.widgetWithText(TextButton, 'Ver Registo de Auditoria'),
      findsOneWidget,
    );

    await tester.tap(find.text('Gerir Planos'));
    await tester.pump();
    expect(tabs, [2]);
  });

  testWidgets(
    'audit vazio: mensagem de feed vazio, tendências sem dados e "Sem alteração"',
    (tester) async {
      _useWideViewport(tester);
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      // Feed de actividade fica abaixo da dobra — arrasta a lista até o fim.
      await tester.drag(find.byType(ListView), const Offset(0, -800));
      await tester.pumpAndSettle();

      expect(find.textContaining('Nenhuma ação'), findsOneWidget);
      // Sem audit, o TextButton de auditoria NÃO existe (quick action com
      // o mesmo rótulo continua).
      expect(
        find.widgetWithText(TextButton, 'Ver Registo de Auditoria'),
        findsNothing,
      );
      // Gráficos sem dados (×2: registos + actividade).
      expect(
        find.text('Dados insuficientes para mostrar tendências'),
        findsNWidgets(2),
      );
      // diff 0 → "Sem alteração" (novos tenants + aprovações + mês).
      expect(find.text('Sem alteração'), findsNWidgets(3));
      // Banner de pendências só com pendências.
      expect(find.textContaining('ações necessárias'), findsNothing);
    },
  );

  testWidgets('erro de carga mostra ErrorView com retry', (tester) async {
    _useWideViewport(tester);
    final allUseCase = _FakeGetAllTenantsUseCase(const [])..throwOnCall = true;
    await tester.pumpWidget(
      _buildApp(allUseCase: allUseCase, disableAutoRetry: true),
    );
    // retry desativado: o estado AsyncError fica estável — sem a corrida
    // com o retry automático do Riverpod 3 (timer < 10ms esconde o frame).
    await tester.pumpAndSettle();

    expect(
      find.text('Não foi possível carregar a visão geral.'),
      findsOneWidget,
    );
    final callsAfterInitial = allUseCase.calls;
    expect(callsAfterInitial, greaterThanOrEqualTo(1));

    // Retry com o use case ainda falhando → o erro persiste.
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(
      find.text('Não foi possível carregar a visão geral.'),
      findsOneWidget,
    );
    expect(allUseCase.calls, greaterThan(callsAfterInitial));
    expect(
      find.text('Não foi possível carregar a visão geral.'),
      findsOneWidget,
    );
    expect(allUseCase.calls, greaterThan(1));
  });

  testWidgets('loading: esqueleto no lugar dos stats até os dados chegarem', (
    tester,
  ) async {
    _useWideViewport(tester);
    final gate = Completer<List<Tenant>>();
    // Sobrescreve o comportamento: pendura o primeiro build.
    final pending = Completer<List<Plan>>();
    final plansUseCase = _FakeGetAllPlansUseCase(_plans);
    final pendingUseCase = _FakeGetPendingPlanRequestsUseCase(const []);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          getAllTenantsUseCaseProvider.overrideWithValue(
            _GateableAllTenants(gate),
          ),
          getAllPlansUseCaseProvider.overrideWithValue(plansUseCase),
          getPendingPlanRequestsUseCaseProvider.overrideWithValue(
            pendingUseCase,
          ),
          getAuditLogUseCaseProvider.overrideWithValue(
            _FakeGetAuditLogUseCase(const []),
          ),
        ],
        child: testApp(
          home: const AdminDashboardScreen(),
          builder: (context, child) => MediaQuery.withClampedTextScaling(
            maxScaleFactor: 0.8,
            child: child!,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));

    // Loading: stats viram esqueleto (sem valores).
    expect(find.text('Total de tenants'), findsNothing);

    gate.complete([
      Tenant(
        id: 'tn1',
        ownerUserId: 'owner12345',
        businessName: 'Tenant tn1',
        planId: 'pl1',
        status: TenantStatus.approved,
        createdAt: DateTime(2026, 8, 1),
      ),
    ]);
    pending.complete(_plans);
    await tester.pumpAndSettle();

    expect(find.text('Total de tenants'), findsOneWidget);
    expect(find.text('1'), findsWidgets);
  });
}

/// Use case de tenants que aguarda um [Completer] (estado de loading).
class _GateableAllTenants implements GetAllTenantsUseCase {
  _GateableAllTenants(this._gate);

  final Completer<List<Tenant>> _gate;

  @override
  Future<List<Tenant>> call() => _gate.future;
}
