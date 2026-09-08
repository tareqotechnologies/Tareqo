import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

import 'package:tareqo/domain/entities/plan.dart';
import 'package:tareqo/domain/entities/plan_request.dart';
import 'package:tareqo/domain/entities/tenant.dart';
import 'package:tareqo/domain/usecases/decide_plan_request_use_case.dart';
import 'package:tareqo/domain/usecases/get_all_tenants_use_case.dart';
import 'package:tareqo/domain/usecases/get_pending_plan_requests_use_case.dart';
import 'package:tareqo/domain/usecases/get_all_plans_use_case.dart';
import 'package:tareqo/domain/usecases/get_plans_use_case.dart';
import 'package:tareqo/presentation/controllers/account_providers.dart';
import 'package:tareqo/presentation/controllers/admin_providers.dart';
import 'package:tareqo/presentation/screens/admin/admin_plan_requests_screen.dart';

class _FakeGetPendingPlanRequestsUseCase
    implements GetPendingPlanRequestsUseCase {
  _FakeGetPendingPlanRequestsUseCase(this._requests);

  final List<PlanRequest> _requests;

  @override
  Future<List<PlanRequest>> call() async => _requests;
}

class _FakeGetAllTenantsUseCase implements GetAllTenantsUseCase {
  _FakeGetAllTenantsUseCase(this._tenants);

  final List<Tenant> _tenants;

  @override
  Future<List<Tenant>> call() async => _tenants;
}

class _FakeGetPlansUseCase implements GetPlansUseCase {
  _FakeGetPlansUseCase(this._plans);

  final List<Plan> _plans;

  @override
  Future<List<Plan>> call() async => _plans;
}

class _FakeGetAllPlansUseCase implements GetAllPlansUseCase {
  _FakeGetAllPlansUseCase(this._plans);

  final List<Plan> _plans;

  @override
  Future<List<Plan>> call() async => _plans;
}

class _FakeDecidePlanRequestUseCase implements DecidePlanRequestUseCase {
  int calls = 0;
  String? lastRequestId;
  bool? lastApprove;

  @override
  Future<void> call(String requestId, {required bool approve}) async {
    calls++;
    lastRequestId = requestId;
    lastApprove = approve;
  }
}

Widget _buildApp({
  required List<PlanRequest> requests,
  List<Tenant> tenants = const [],
  List<Plan> plans = const [],
  DecidePlanRequestUseCase? decide,
}) {
  return ProviderScope(
    overrides: [
      getPendingPlanRequestsUseCaseProvider.overrideWithValue(
        _FakeGetPendingPlanRequestsUseCase(requests),
      ),
      getAllTenantsUseCaseProvider.overrideWithValue(
        _FakeGetAllTenantsUseCase(tenants),
      ),
      getPlansUseCaseProvider.overrideWithValue(_FakeGetPlansUseCase(plans)),
      getAllPlansUseCaseProvider.overrideWithValue(
        _FakeGetAllPlansUseCase(plans),
      ),
      decidePlanRequestUseCaseProvider.overrideWithValue(
        decide ?? _FakeDecidePlanRequestUseCase(),
      ),
    ],
    child: testApp(home: const AdminPlanRequestsScreen()),
  );
}

void main() {
  final tenant = Tenant(
    id: 'tn1',
    ownerUserId: '1',
    businessName: 'Comercial Demo',
    planId: 'pl1',
    status: TenantStatus.approved,
    createdAt: DateTime(2026, 7, 1),
  );
  const plans = [
    Plan(id: 'pl1', name: 'Essencial', priceMonthlyCents: 2990),
    Plan(id: 'pl2', name: 'Comercial', priceMonthlyCents: 9900),
  ];
  final request = PlanRequest(
    id: 'r1',
    tenantId: 'tn1',
    currentPlanId: 'pl1',
    requestedPlanId: 'pl2',
    createdAt: DateTime(2026, 8, 2),
  );

  testWidgets('exibe os pedidos de upgrade com planos resolvidos', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(requests: [request], tenants: [tenant], plans: plans),
    );
    await tester.pumpAndSettle();

    // Nome do tenant + badges "Atual/Solicitado" com os nomes dos planos.
    expect(find.text('Comercial Demo'), findsOneWidget);
    expect(find.text('Atual'), findsOneWidget);
    expect(find.text('Solicitado'), findsOneWidget);
    expect(find.text('Essencial'), findsOneWidget);
    expect(find.text('Comercial'), findsOneWidget);
    expect(find.text('Aprovar'), findsOneWidget);
    expect(find.text('Rejeitar'), findsOneWidget);
  });

  testWidgets('mostra estado vazio quando não há upgrades pendentes', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp(requests: const []));
    await tester.pumpAndSettle();

    expect(find.text('Nenhum upgrade pendente'), findsOneWidget);
  });

  testWidgets('aprovar o upgrade chama o DecidePlanRequestUseCase', (
    tester,
  ) async {
    final decide = _FakeDecidePlanRequestUseCase();

    await tester.pumpWidget(
      _buildApp(
        requests: [request],
        tenants: [tenant],
        plans: plans,
        decide: decide,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Aprovar'));
    await tester.pumpAndSettle();

    expect(decide.calls, 1);
    expect(decide.lastRequestId, 'r1');
    expect(decide.lastApprove, isTrue);
    expect(find.text('Upgrade aprovado — plano atualizado!'), findsOneWidget);
  });

  testWidgets('rejeitar o upgrade chama o DecidePlanRequestUseCase', (
    tester,
  ) async {
    final decide = _FakeDecidePlanRequestUseCase();

    await tester.pumpWidget(
      _buildApp(
        requests: [request],
        tenants: [tenant],
        plans: plans,
        decide: decide,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Rejeitar'));
    await tester.pumpAndSettle();

    expect(decide.calls, 1);
    expect(decide.lastRequestId, 'r1');
    expect(decide.lastApprove, isFalse);
    expect(find.text('Upgrade rejeitado.'), findsOneWidget);
  });
}
