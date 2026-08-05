import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

import 'package:dumbhanengue/domain/entities/app_user.dart';
import 'package:dumbhanengue/domain/entities/plan.dart';
import 'package:dumbhanengue/domain/entities/plan_request.dart';
import 'package:dumbhanengue/domain/entities/tenant.dart';
import 'package:dumbhanengue/domain/repositories/i_admin_repository.dart';
import 'package:dumbhanengue/domain/usecases/get_all_plans_use_case.dart';
import 'package:dumbhanengue/domain/usecases/get_all_tenants_use_case.dart';
import 'package:dumbhanengue/domain/usecases/get_my_tenant_use_case.dart';
import 'package:dumbhanengue/domain/usecases/get_pending_plan_requests_use_case.dart';
import 'package:dumbhanengue/domain/usecases/get_pending_tenants_use_case.dart';
import 'package:dumbhanengue/domain/usecases/get_plans_use_case.dart';
import 'package:dumbhanengue/presentation/controllers/account_providers.dart';
import 'package:dumbhanengue/presentation/controllers/admin_providers.dart';
import 'package:dumbhanengue/presentation/controllers/auth_providers.dart';
import 'package:dumbhanengue/presentation/screens/auth/auth_gate.dart';

import '../../helpers/store_context.dart';

/// Repositório que simula falha transitória na consulta do papel (rede).
class _ThrowingAdminRepository implements IAdminRepository {
  const _ThrowingAdminRepository();

  @override
  Future<bool> isSuperAdmin() async =>
      throw StateError('falha de rede simulada');
}

/// Fakes dos casos de uso do painel administrativo (lista vazia) — o
/// [AdminShell] renderiza as 3 abas no IndexedStack, então os providers
/// precisam existir mesmo sem dados.
class _EmptyPendingTenants implements GetPendingTenantsUseCase {
  const _EmptyPendingTenants();

  @override
  Future<List<Tenant>> call() async => const [];
}

class _EmptyAllTenants implements GetAllTenantsUseCase {
  const _EmptyAllTenants();

  @override
  Future<List<Tenant>> call() async => const [];
}

class _EmptyAllPlans implements GetAllPlansUseCase {
  const _EmptyAllPlans();

  @override
  Future<List<Plan>> call() async => const [];
}

class _EmptyPlans implements GetPlansUseCase {
  const _EmptyPlans();

  @override
  Future<List<Plan>> call() async => const [];
}

class _EmptyPendingPlanRequests implements GetPendingPlanRequestsUseCase {
  const _EmptyPendingPlanRequests();

  @override
  Future<List<PlanRequest>> call() async => const [];
}

/// Overrides do painel do super admin (vazios) — o AdminShell precisa de
/// todos para renderizar as abas sem depender do ServiceLocator.
List<dynamic> _adminPanelOverrides() => [
      getPendingTenantsUseCaseProvider
          .overrideWithValue(const _EmptyPendingTenants()),
      getAllTenantsUseCaseProvider.overrideWithValue(const _EmptyAllTenants()),
      getAllPlansUseCaseProvider.overrideWithValue(const _EmptyAllPlans()),
      getPlansUseCaseProvider.overrideWithValue(const _EmptyPlans()),
      getPendingPlanRequestsUseCaseProvider
          .overrideWithValue(const _EmptyPendingPlanRequests()),
    ];

/// Tenant PENDING (fluxo do dono aguardando aprovação) — alvo limpo do
/// caminho "não-admin" (não depende dos providers dos módulos do ERP).
Tenant _pendingTenant({String ownerUserId = 'u1'}) => Tenant(
      id: 'tn1',
      ownerUserId: ownerUserId,
      businessName: 'Comercial Demo',
      planId: 'pl2',
      status: TenantStatus.pending,
      createdAt: DateTime.now(),
    );

Widget _buildApp({
  required Stream<AppUser?> authStream,
  required IAdminRepository adminRepository,
  GetMyTenantUseCase? getMyTenant,
}) {
  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith((ref) => authStream),
      adminRepositoryProvider.overrideWithValue(adminRepository),
      getMyTenantUseCaseProvider.overrideWithValue(
        getMyTenant ?? FakeGetMyTenantUseCase(approvedTenant()),
      ),
      ..._adminPanelOverrides(),
    ],
    child: testApp(home: AuthGate()),
  );
}

void main() {
  testWidgets('super admin por papel (banco) abre o AdminShell — o e-mail '
      'da conta não decide mais', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        // E-mail comum de dono, mas o papel (tabela super_admins) é true:
        // o roteamento agora é pelo papel, não pelo e-mail (auditoria C3).
        authStream: Stream.value(
          AppUser(id: 'admin-1', email: 'dono@loja.com'),
        ),
        adminRepository: const FakeAdminRepository(isAdmin: true),
        getMyTenant: FakeGetMyTenantUseCase(
          approvedTenant(ownerUserId: 'admin-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Painel do Super Admin'), findsOneWidget);
    // Abas do painel administrativo.
    expect(find.text('Solicitações'), findsOneWidget);
    expect(find.text('Planos'), findsOneWidget);
    expect(find.text('Upgrades'), findsOneWidget);
    // Não caiu no fluxo do tenant.
    expect(find.text('Aguardando aprovação'), findsNothing);
  });

  testWidgets('sem o papel de super admin, segue para o fluxo do tenant — '
      'mesmo com e-mail de admin', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        // O caso inverso do teste anterior: e-mail que seria admin no
        // esquema antigo NÃO abre o painel — o banco é a autoridade.
        authStream: Stream.value(
          AppUser(id: 'u1', email: 'admin@dumbhanengue.com'),
        ),
        adminRepository: const FakeAdminRepository(isAdmin: false),
        getMyTenant: FakeGetMyTenantUseCase(_pendingTenant(ownerUserId: 'u1')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Painel do Super Admin'), findsNothing);
    expect(find.text('Aguardando aprovação'), findsOneWidget);
  });

  testWidgets('falha transitória ao verificar o papel cai no fluxo do tenant '
      '(fail-open na navegação; o banco segue autoritativo)', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        authStream: Stream.value(AppUser(id: 'u1', email: 'dono@loja.com')),
        adminRepository: const _ThrowingAdminRepository(),
        getMyTenant: FakeGetMyTenantUseCase(_pendingTenant(ownerUserId: 'u1')),
      ),
    );
    await tester.pumpAndSettle();

    // Nada de painel admin e nada de tela de erro bloqueante — o app segue
    // para o fluxo do tenant (qualquer ação de admin seria negada no RLS).
    expect(find.text('Painel do Super Admin'), findsNothing);
    expect(find.text('Aguardando aprovação'), findsOneWidget);
  });

  testWidgets('super admin com tenant PENDENTE abre o AdminShell — o papel '
      'ignora o portão do tenant', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        // Caso extremo da auditoria C3: mesmo com o tenant ainda pendente
        // (que levaria um dono comum à tela de espera), o super admin vai
        // direto ao painel — o ramo admin precede o _tenantGate no AuthGate.
        authStream: Stream.value(
          AppUser(id: 'admin-1', email: 'admin@dumbhanengue.com'),
        ),
        adminRepository: const FakeAdminRepository(isAdmin: true),
        getMyTenant: FakeGetMyTenantUseCase(_pendingTenant(ownerUserId: 'admin-1')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Painel do Super Admin'), findsOneWidget);
    expect(find.text('Aguardando aprovação'), findsNothing);
  });

  testWidgets('deslogado vê o LoginScreen', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        authStream: Stream.value(null),
        adminRepository: const FakeAdminRepository(isAdmin: true),
        getMyTenant: FakeGetMyTenantUseCase(approvedTenant()),
      ),
    );
    await tester.pumpAndSettle();

    // Botão de entrar do LoginScreen — nem AdminShell nem fluxo de tenant.
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Painel do Super Admin'), findsNothing);
    expect(find.text('Aguardando aprovação'), findsNothing);
  });
}
