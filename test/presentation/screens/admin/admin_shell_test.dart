import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/store_context.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/viewport.dart';

import 'package:tareqo/domain/entities/app_user.dart';
import 'package:tareqo/domain/entities/invoice.dart';
import 'package:tareqo/domain/entities/plan.dart';
import 'package:tareqo/domain/entities/plan_request.dart';
import 'package:tareqo/domain/entities/tenant.dart';
import 'package:tareqo/domain/repositories/i_invoice_repository.dart';
import 'package:tareqo/domain/usecases/get_all_plans_use_case.dart';
import 'package:tareqo/domain/usecases/get_all_tenants_use_case.dart';
import 'package:tareqo/domain/usecases/get_pending_invoices_use_case.dart';
import 'package:tareqo/domain/usecases/get_pending_plan_requests_use_case.dart';
import 'package:tareqo/domain/usecases/get_pending_tenants_use_case.dart';
import 'package:tareqo/domain/usecases/get_plans_use_case.dart';
import 'package:tareqo/presentation/controllers/account_providers.dart';
import 'package:tareqo/presentation/controllers/admin_providers.dart';
import 'package:tareqo/presentation/controllers/auth_providers.dart';
import 'package:tareqo/presentation/controllers/invoice_providers.dart';
import 'package:tareqo/presentation/screens/admin/admin_shell.dart';

// ── Fakes dos casos de uso do painel ────────────────────────────────────────

class _PendingTenants implements GetPendingTenantsUseCase {
  const _PendingTenants(this._tenants);
  final List<Tenant> _tenants;

  @override
  Future<List<Tenant>> call() async => _tenants;
}

class _AllTenants implements GetAllTenantsUseCase {
  const _AllTenants(this._tenants);
  final List<Tenant> _tenants;

  @override
  Future<List<Tenant>> call() async => _tenants;
}

class _AllPlans implements GetAllPlansUseCase {
  const _AllPlans(this._plans);
  final List<Plan> _plans;

  @override
  Future<List<Plan>> call() async => _plans;
}

class _ActivePlans implements GetPlansUseCase {
  const _ActivePlans(this._plans);
  final List<Plan> _plans;

  @override
  Future<List<Plan>> call() async => _plans;
}

class _PendingPlanRequests implements GetPendingPlanRequestsUseCase {
  const _PendingPlanRequests(this._requests);
  final List<PlanRequest> _requests;

  @override
  Future<List<PlanRequest>> call() async => _requests;
}

/// Repositório de facturas com pendências controladas pelo teste.
class _FakeInvoiceRepository implements IInvoiceRepository {
  const _FakeInvoiceRepository(this._pending);
  final List<Invoice> _pending;

  @override
  Future<List<Invoice>> getPending() async => _pending;

  // Os restantes métodos não são usados pelo painel — expõem uso acidental.
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} não usado no teste');
}

// ── Dados de teste ──────────────────────────────────────────────────────────

Tenant _pendingTenant(String id) => Tenant(
  id: id,
  ownerUserId: 'owner-$id',
  businessName: 'Loja $id',
  planId: 'pl2',
  status: TenantStatus.pending,
  createdAt: DateTime(2026, 9, 1),
);

PlanRequest _pendingRequest(String id) => PlanRequest(
  id: id,
  tenantId: 'tn1',
  currentPlanId: 'pl1',
  requestedPlanId: 'pl3',
  createdAt: DateTime(2026, 9, 1),
);

Invoice _pendingInvoice(String id) => Invoice(
  id: id,
  tenantId: 'tn1',
  planId: 'pl2',
  amountCents: 150000,
  dueDate: DateTime(2026, 9, 30),
  period: 'Setembro 2026',
  createdAt: DateTime(2026, 9, 1),
);

const _plans = [
  Plan(id: 'pl1', name: 'Básico'),
  Plan(id: 'pl2', name: 'Pro'),
  Plan(id: 'pl3', name: 'Premium'),
];

/// Overrides do painel — os mesmos de que o AdminShell depende (sem passar
/// pelo AuthGate; aqui montamos o shell diretamente).
List<dynamic> _overrides({
  required int pendingTenants,
  required int pendingUpgrades,
  required int pendingInvoices,
}) {
  final tenants = List.generate(pendingTenants, (i) => _pendingTenant('tn$i'));
  return [
    authStateProvider.overrideWith(
      (ref) => Stream.value(AppUser(id: 'admin-1', email: 'admin@tareqo.com')),
    ),
    adminRepositoryProvider.overrideWithValue(
      const FakeAdminRepository(isAdmin: true),
    ),
    getMyTenantUseCaseProvider.overrideWithValue(
      FakeGetMyTenantUseCase(approvedTenant(ownerUserId: 'admin-1')),
    ),
    getPendingTenantsUseCaseProvider.overrideWithValue(
      _PendingTenants(tenants),
    ),
    getAllTenantsUseCaseProvider.overrideWithValue(_AllTenants(tenants)),
    getAllPlansUseCaseProvider.overrideWithValue(_AllPlans(_plans)),
    getPlansUseCaseProvider.overrideWithValue(_ActivePlans(_plans)),
    getPendingPlanRequestsUseCaseProvider.overrideWithValue(
      _PendingPlanRequests(
        List.generate(pendingUpgrades, (i) => _pendingRequest('pr$i')),
      ),
    ),
    getPendingInvoicesUseCaseProvider.overrideWithValue(
      GetPendingInvoicesUseCase(
        _FakeInvoiceRepository(
          List.generate(pendingInvoices, (i) => _pendingInvoice('inv$i')),
        ),
      ),
    ),
  ];
}

Widget _buildShell({
  required int pendingTenants,
  required int pendingUpgrades,
  required int pendingInvoices,
}) {
  return ProviderScope(
    overrides: [
      ..._overrides(
        pendingTenants: pendingTenants,
        pendingUpgrades: pendingUpgrades,
        pendingInvoices: pendingInvoices,
      ),
    ],
    child: testApp(home: const AdminShell()),
  );
}

void main() {
  /// Badges têm tipografia única no painel: label w600 branco (KPIs e
  /// rótulos são w300/w400 herdados do tema thin).
  Iterable<Text> badgeTexts(WidgetTester tester, String s) => tester
      .widgetList<Text>(find.text(s))
      .where(
        (t) =>
            t.style?.fontWeight == FontWeight.w600 &&
            t.style?.color == Colors.white,
      );

  testWidgets('FAB mostra a secção atual e o total de pendências em badge', (
    tester,
  ) async {
    // Superfície default de teste (800×600) — a mais estreita em que o
    // painel foi desenhado para caber (ver nota de viewport no fim).
    await tester.pumpWidget(
      _buildShell(pendingTenants: 2, pendingUpgrades: 1, pendingInvoices: 1),
    );
    await tester.pumpAndSettle();

    // Secção inicial: Visão Geral (dashboard).
    expect(find.text('Visão Geral'), findsWidgets);

    // Badge total no FAB: 2 tenants + 1 upgrade + 1 invoice = 4.
    expect(badgeTexts(tester, '4').length, 1);

    // Abre a sheet de navegação com todas as secções.
    await tester.tap(find.byIcon(Icons.keyboard_arrow_up_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Solicitações'), findsWidgets);
    expect(find.text('Facturas'), findsWidgets);
    // Badge por item na sheet: 2 solicitações pendentes (w600 branco).
    expect(badgeTexts(tester, '2').length, 1);
  });

  testWidgets('selecionar secção na sheet troca o conteúdo e fecha', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildShell(pendingTenants: 0, pendingUpgrades: 0, pendingInvoices: 1),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.keyboard_arrow_up_rounded));
    await tester.pumpAndSettle();

    // Toca em "Facturas" na sheet (o rótulo também existe na secção montada
    // no IndexedStack — o primeiro é o da sheet, visível por cima).
    await tester.tap(find.text('Facturas').first);
    await tester.pumpAndSettle();

    // O FAB passa a mostrar o rótulo da nova secção.
    expect(find.text('Facturas'), findsWidgets);
  });

  testWidgets('sem pendências o FAB não mostra badge', (tester) async {
    await tester.pumpWidget(
      _buildShell(pendingTenants: 0, pendingUpgrades: 0, pendingInvoices: 0),
    );
    await tester.pumpAndSettle();

    // Sem pendências: nenhum badge w600 com "0" (as KPIs do dashboard
    // também mostram 0, mas em w300).
    expect(badgeTexts(tester, '0'), isEmpty);
  });

  testWidgets('em ecrã largo (≥880px) mostra a sidebar minimalista', (
    tester,
  ) async {
    usePortraitViewport(tester, size: const Size(1200, 900));
    await tester.pumpWidget(
      _buildShell(pendingTenants: 2, pendingUpgrades: 0, pendingInvoices: 0),
    );
    await tester.pumpAndSettle();

    // FAB some, sidebar aparece com o badge de 2 solicitações pendentes.
    expect(find.byIcon(Icons.keyboard_arrow_up_rounded), findsNothing);
    expect(badgeTexts(tester, '2').length, 1);

    // Navegar pela sidebar: o ícone how_to_reg abre as Solicitações.
    await tester.tap(find.byIcon(Icons.how_to_reg_outlined));
    await tester.pumpAndSettle();
    // O ícone fica selecionado (rounded).
    expect(find.byIcon(Icons.how_to_reg_rounded), findsOneWidget);
  });
}
