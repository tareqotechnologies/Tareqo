import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

import 'package:dumbhanengue/domain/entities/tenant.dart';
import 'package:dumbhanengue/domain/usecases/approve_tenant_use_case.dart';
import 'package:dumbhanengue/domain/usecases/get_all_tenants_use_case.dart';
import 'package:dumbhanengue/domain/usecases/get_pending_tenants_use_case.dart';
import 'package:dumbhanengue/domain/usecases/reject_tenant_use_case.dart';
import 'package:dumbhanengue/presentation/controllers/account_providers.dart';
import 'package:dumbhanengue/presentation/controllers/admin_providers.dart';
import 'package:dumbhanengue/presentation/screens/admin/admin_tenants_screen.dart';

class _FakeGetPendingTenantsUseCase implements GetPendingTenantsUseCase {
  _FakeGetPendingTenantsUseCase(this._tenants);

  final List<Tenant> _tenants;

  @override
  Future<List<Tenant>> call() async => _tenants;
}

class _FakeGetAllTenantsUseCase implements GetAllTenantsUseCase {
  _FakeGetAllTenantsUseCase(this._tenants);

  final List<Tenant> _tenants;

  @override
  Future<List<Tenant>> call() async => _tenants;
}

class _FakeApproveTenantUseCase implements ApproveTenantUseCase {
  int calls = 0;
  String? lastTenantId;

  @override
  Future<void> call(String tenantId) async {
    calls++;
    lastTenantId = tenantId;
  }
}

class _FakeRejectTenantUseCase implements RejectTenantUseCase {
  int calls = 0;
  String? lastTenantId;
  String? lastReason;

  @override
  Future<void> call(String tenantId, String reason) async {
    calls++;
    lastTenantId = tenantId;
    lastReason = reason;
  }
}

Tenant _pendingTenant({String id = 'tn1', String name = 'Comercial Demo'}) =>
    Tenant(
      id: id,
      ownerUserId: '1',
      businessName: name,
      planId: 'pl2',
      status: TenantStatus.pending,
      createdAt: DateTime(2026, 8, 1),
    );

Widget _buildApp({
  required List<Tenant> pending,
  required List<Tenant> all,
  ApproveTenantUseCase? approve,
  RejectTenantUseCase? reject,
}) {
  return ProviderScope(
    overrides: [
      getPendingTenantsUseCaseProvider.overrideWithValue(
        _FakeGetPendingTenantsUseCase(pending),
      ),
      getAllTenantsUseCaseProvider.overrideWithValue(
        _FakeGetAllTenantsUseCase(all),
      ),
      approveTenantUseCaseProvider.overrideWithValue(
        approve ?? _FakeApproveTenantUseCase(),
      ),
      rejectTenantUseCaseProvider.overrideWithValue(
        reject ?? _FakeRejectTenantUseCase(),
      ),
    ],
    child: testApp(home: const AdminTenantsScreen()),
  );
}

void main() {
  testWidgets('exibe os tenants pendentes com contagem', (tester) async {
    final pending = [
      _pendingTenant(name: 'Comercial Demo'),
      _pendingTenant(id: 'tn2', name: 'Mercado Central'),
    ];

    await tester.pumpWidget(_buildApp(pending: pending, all: pending));
    await tester.pumpAndSettle();

    expect(find.text('2 aguardando aprovação'), findsOneWidget);
    expect(find.text('Comercial Demo'), findsOneWidget);
    expect(find.text('Mercado Central'), findsOneWidget);
    expect(find.text('Aprovar'), findsNWidgets(2));
    expect(find.text('Rejeitar'), findsNWidgets(2));
  });

  testWidgets('mostra estado vazio quando não há pendentes', (tester) async {
    await tester.pumpWidget(_buildApp(pending: const [], all: const []));
    await tester.pumpAndSettle();

    expect(find.text('Nada aguardando aprovação'), findsOneWidget);
  });

  testWidgets('aprovar chama o ApproveTenantUseCase e atualiza',
      (tester) async {
    final approve = _FakeApproveTenantUseCase();
    final pending = [_pendingTenant()];

    await tester.pumpWidget(
      _buildApp(pending: pending, all: pending, approve: approve),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Aprovar'));
    await tester.pumpAndSettle();

    expect(approve.calls, 1);
    expect(approve.lastTenantId, 'tn1');
    expect(find.text('Acesso de Comercial Demo aprovado!'), findsOneWidget);
  });

  testWidgets('rejeitar pede o motivo e chama o RejectTenantUseCase',
      (tester) async {
    final reject = _FakeRejectTenantUseCase();
    final pending = [_pendingTenant()];

    await tester.pumpWidget(
      _buildApp(pending: pending, all: pending, reject: reject),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Rejeitar'));
    await tester.pumpAndSettle();

    // Diálogo de motivo.
    expect(find.text('Rejeitar Comercial Demo'), findsOneWidget);
    await tester.enterText(
      find.byType(TextField),
      'Documentação incompleta',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Rejeitar'));
    await tester.pumpAndSettle();

    expect(reject.calls, 1);
    expect(reject.lastTenantId, 'tn1');
    expect(reject.lastReason, 'Documentação incompleta');
    expect(find.text('Solicitação de Comercial Demo rejeitada.'), findsOneWidget);
  });

  testWidgets('alterna para a lista de todos os tenants', (tester) async {
    final approved = Tenant(
      id: 'tn3',
      ownerUserId: '2',
      businessName: 'Farmácia Vida',
      planId: 'pl1',
      status: TenantStatus.approved,
      createdAt: DateTime(2026, 7, 10),
    );

    await tester.pumpWidget(
      _buildApp(pending: const [], all: [approved]),
    );
    await tester.pumpAndSettle();

    // Alterna para "Todos".
    await tester.tap(find.text('Todos'));
    await tester.pumpAndSettle();

    expect(find.text('Farmácia Vida'), findsOneWidget);
    expect(find.text('Aprovado'), findsOneWidget);
  });
}
