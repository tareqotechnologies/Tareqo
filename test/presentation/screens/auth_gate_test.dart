import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

import 'package:tareqo/domain/entities/app_user.dart';
import 'package:tareqo/domain/entities/auth_event.dart';
import 'package:tareqo/domain/entities/plan.dart';
import 'package:tareqo/domain/entities/plan_request.dart';
import 'package:tareqo/domain/entities/store_employee.dart';
import 'package:tareqo/domain/entities/tenant.dart';
import 'package:tareqo/domain/repositories/i_admin_repository.dart';
import 'package:tareqo/domain/usecases/get_all_plans_use_case.dart';
import 'package:tareqo/domain/usecases/get_all_tenants_use_case.dart';
import 'package:tareqo/domain/usecases/get_employees_use_case.dart';
import 'package:tareqo/domain/usecases/get_my_tenant_use_case.dart';
import 'package:tareqo/domain/usecases/get_pending_plan_requests_use_case.dart';
import 'package:tareqo/domain/usecases/get_pending_tenants_use_case.dart';
import 'package:tareqo/domain/usecases/get_plans_use_case.dart';
import 'package:tareqo/presentation/controllers/account_providers.dart';
import 'package:tareqo/presentation/controllers/admin_providers.dart';
import 'package:tareqo/presentation/controllers/auth_providers.dart';
import 'package:tareqo/presentation/screens/auth/auth_gate.dart';
import 'package:tareqo/presentation/screens/auth/login_screen.dart';
import 'package:tareqo/presentation/screens/auth/set_new_password_screen.dart';
import 'package:tareqo/presentation/screens/shell/app_shell.dart';

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
 getPendingTenantsUseCaseProvider.overrideWithValue(
 const _EmptyPendingTenants(),
 ),
 getAllTenantsUseCaseProvider.overrideWithValue(const _EmptyAllTenants()),
 getAllPlansUseCaseProvider.overrideWithValue(const _EmptyAllPlans()),
 getPlansUseCaseProvider.overrideWithValue(const _EmptyPlans()),
 getPendingPlanRequestsUseCaseProvider.overrideWithValue(
 const _EmptyPendingPlanRequests(),
 ),
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
 GetEmployeesUseCase? getEmployees,
 // Intervalo do polling CENTRAL (employeePollIntervalProvider) — curto
 // para os testes dispararem o timer com `tester.pump`.
 Duration pollInterval = const Duration(seconds: 2),
 // Eventos de auth (default: nenhum evento especial — sem recovery).
 Stream<AuthEvent> authEvents = const Stream.empty(),
}) {
 return ProviderScope(
 overrides: [
 authStateProvider.overrideWith((ref) => authStream),
 authEventsProvider.overrideWith((ref) => authEvents),
 adminRepositoryProvider.overrideWithValue(adminRepository),
 employeePollIntervalProvider.overrideWithValue(pollInterval),
 getMyTenantUseCaseProvider.overrideWithValue(
 getMyTenant ?? FakeGetMyTenantUseCase(approvedTenant()),
 ),
 if (getEmployees != null)
 getEmployeesUseCaseProvider.overrideWithValue(getEmployees),
 ..._adminPanelOverrides(),
 ],
 child: testApp(home: const AuthGate()),
 );
}

/// Funcionário com vínculo DESATIVADO (o tenant pertence a outro usuário e
/// o link `store_employees` tem `isActive: false`) — o AuthGate deve
/// bloquear com a tela de acesso suspenso.
class _InactiveEmployeeLink implements GetEmployeesUseCase {
 const _InactiveEmployeeLink();

 @override
 Future<List<StoreEmployee>> call(String tenantId) async => const [
 StoreEmployee(
 id: 'e1',
 tenantId: 'tn1',
 storeId: 'st1',
 userId: 'u1',
 fullName: 'Carlos',
 email: 'carlos@loja.com',
 role: EmployeeRole.employee,
 isActive: false,
 ),
 ];
}

/// Vínculos com CARREGAMENTO LENTO (nunca completam até o teste liberar) —
/// simula a janela em que o tenant já resolveu mas a busca dos vínculos
/// ainda está em andamento. Antes do fix, o AuthGate via `value == null` →
/// lista vazia → bloqueava um funcionário VÁLIDO com "Acesso suspenso".
class _DelayedEmployeeLink implements GetEmployeesUseCase {
 final Completer<List<StoreEmployee>> completer = Completer();

 @override
 Future<List<StoreEmployee>> call(String tenantId) => completer.future;
}

/// Busca de vínculos com FALHA transitória (rede) — o AuthGate deve ser
/// fail-open (o servidor segue autoritativo; RLS/RPCs negam quem está
/// realmente suspenso), nunca bloquear um funcionário válido por um erro.
class _ThrowingEmployeeLink implements GetEmployeesUseCase {
 const _ThrowingEmployeeLink();

 @override
 Future<List<StoreEmployee>> call(String tenantId) async =>
 throw StateError('falha de rede simulada');
}

/// Estoque MUTÁVEL de vínculos — simula a mudança feita pelo DONO em
/// OUTRO dispositivo (o próximo poll do AuthGate re-busca e reavalia).
class _MutableEmployeeLink implements GetEmployeesUseCase {
 // ignore: prefer_initializing_formals
 _MutableEmployeeLink({bool isActive = true}) : _isActive = isActive;

 bool _isActive;

 /// Número de chamadas a `call()` — prova que o polling CENTRAL dispara
 /// refreshes dos vínculos (e que PARA no sign-out).
 int calls = 0;

 void setActive(bool isActive) => _isActive = isActive;

 @override
 Future<List<StoreEmployee>> call(String tenantId) async {
 calls++;
 return [
 StoreEmployee(
 id: 'e1',
 tenantId: 'tn1',
 storeId: 'st1',
 userId: 'u1',
 fullName: 'Carlos',
 email: 'carlos@loja.com',
 role: EmployeeRole.employee,
 isActive: _isActive,
 ),
 ];
 }
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
 AppUser(id: 'u1', email: 'admin@tareqo.com'),
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
 AppUser(id: 'admin-1', email: 'admin@tareqo.com'),
 ),
 adminRepository: const FakeAdminRepository(isAdmin: true),
 getMyTenant: FakeGetMyTenantUseCase(
 _pendingTenant(ownerUserId: 'admin-1'),
 ),
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

 testWidgets('funcionário DESATIVADO vê a tela de acesso suspenso', (
 tester,
 ) async {
 await tester.pumpWidget(
 _buildApp(
 authStream: Stream.value(AppUser(id: 'u1', email: 'carlos@loja.com')),
 adminRepository: const FakeAdminRepository(),
 // Tenant APROVADO de OUTRO dono + vínculo inativo → bloqueado.
 getMyTenant: FakeGetMyTenantUseCase(approvedTenant(ownerUserId: '9')),
 getEmployees: const _InactiveEmployeeLink(),
 ),
 );
 await tester.pumpAndSettle();

 expect(find.text('Acesso suspenso'), findsOneWidget);
 expect(find.textContaining('desativada pelo dono'), findsOneWidget);
 // NÃO cai no AppShell (bloqueio total).
 expect(find.byType(AppShell), findsNothing);
 });

 testWidgets('funcionário ATIVO não vê "Acesso suspenso" enquanto os '
 'vínculos ainda carregam (falso positivo fixo)', (tester) async {
 final links = _DelayedEmployeeLink();
 await tester.pumpWidget(
 _buildApp(
 authStream: Stream.value(AppUser(id: 'u1', email: 'carlos@loja.com')),
 adminRepository: const FakeAdminRepository(),
 // Tenant aprovado de OUTRO dono — funcionário legítimo cujo
 // vínculo ainda não chegou do servidor.
 getMyTenant: FakeGetMyTenantUseCase(approvedTenant(ownerUserId: '9')),
 getEmployees: links,
 ),
 );
 // Tenant resolveu, vínculos ainda carregando: NÃO bloquear — a tela
 // fica no splash (nada de "Acesso suspenso" por um instante).
 // pump() em vez de pumpAndSettle(): o splash tem um spinner infinito
 // (CircularProgressIndicator) e o vínculo está pendente — pumpAndSettle
 // nunca assentaria; avançamos frames manualmente.
 await tester.pump(); // emite o stream de auth
 await tester.pump(); // resolve papel (admin) + tenant (futures)
 await tester.pump(const Duration(milliseconds: 50)); // frame do splash
 expect(find.text('Acesso suspenso'), findsNothing);
 expect(find.byType(AppShell), findsNothing);
 // Ainda no splash aguardando os vínculos.
 expect(find.byType(CircularProgressIndicator), findsOneWidget);

 // O vínculo ATIVO chega → acesso normal, nunca bloqueado.
 links.completer.complete(const [
 StoreEmployee(
 id: 'e1',
 tenantId: 'tn1',
 storeId: 'st1',
 userId: 'u1',
 fullName: 'Carlos',
 email: 'carlos@loja.com',
 role: EmployeeRole.employee,
 isActive: true,
 ),
 ]);
 await tester.pumpAndSettle();

 expect(find.byType(AppShell), findsOneWidget);
 expect(find.text('Acesso suspenso'), findsNothing);
 });

 testWidgets('refresh do poll NÃO pisca o splash para funcionário ativo '
 '(Riverpod mantém o valor anterior durante o refresh)', (tester) async {
 final links = _MutableEmployeeLink(isActive: true);
 await tester.pumpWidget(
 _buildApp(
 authStream: Stream.value(AppUser(id: 'u1', email: 'carlos@loja.com')),
 adminRepository: const FakeAdminRepository(),
 getMyTenant: FakeGetMyTenantUseCase(approvedTenant(ownerUserId: '9')),
 getEmployees: links,
 pollInterval: const Duration(seconds: 2),
 ),
 );
 await tester.pumpAndSettle();
 expect(find.byType(AppShell), findsOneWidget);

 // Dispara um tick do poll (2s): o refresh re-busca os vínculos — como
 // o Riverpod mantém o valor anterior durante o refresh, o AppShell
 // CONTINUA visível e o splash NÃO aparece (sem flash a cada 30s em
 // produção). Se o refresh descartasse o valor, o splash piscaria aqui.
 await tester.pump(const Duration(seconds: 2));
 await tester.pump(const Duration(milliseconds: 100));

 expect(find.byType(AppShell), findsOneWidget);
 expect(find.byType(CircularProgressIndicator), findsNothing);
 expect(find.text('Acesso suspenso'), findsNothing);
 });

 testWidgets('falha transitória na busca dos vínculos NÃO bloqueia o '
 'funcionário (fail-open; o servidor segue autoritativo)', (tester) async {
 await tester.pumpWidget(
 _buildApp(
 authStream: Stream.value(AppUser(id: 'u1', email: 'carlos@loja.com')),
 adminRepository: const FakeAdminRepository(),
 getMyTenant: FakeGetMyTenantUseCase(approvedTenant(ownerUserId: '9')),
 getEmployees: const _ThrowingEmployeeLink(),
 ),
 );
 await tester.pumpAndSettle();

 // Sem dados de vínculo, um erro de rede não pode decidir um bloqueio:
 // o acesso segue (o servidor negaria operações se o usuário estivesse
 // realmente suspenso; o polling reavalia em seguida).
 expect(find.text('Acesso suspenso'), findsNothing);
 expect(find.byType(AppShell), findsOneWidget);
 });

 testWidgets('funcionário é bloqueado REATIVAMENTE quando o dono desativa '
 'em outro dispositivo', (tester) async {
 final links = _MutableEmployeeLink(isActive: true);
 await tester.pumpWidget(
 _buildApp(
 authStream: Stream.value(AppUser(id: 'u1', email: 'carlos@loja.com')),
 adminRepository: const FakeAdminRepository(),
 // Tenant aprovado de OUTRO dono + vínculo ATIVO no início.
 getMyTenant: FakeGetMyTenantUseCase(approvedTenant(ownerUserId: '9')),
 getEmployees: links,
 // Intervalo curto para o teste (produção: 30s).
 pollInterval: const Duration(seconds: 2),
 ),
 );
 await tester.pumpAndSettle();

 // Começa com acesso normal (AppShell).
 expect(find.byType(AppShell), findsOneWidget);

 // O DONO desativa o funcionário em OUTRO dispositivo: o próximo poll
 // re-busca o vínculo e o AuthGate troca para a tela de suspensão SEM
 // reiniciar o app.
 links.setActive(false);
 await tester.pump(const Duration(seconds: 2)); // dispara o timer
 await tester.pumpAndSettle(); // refresh + rebuild

 expect(find.text('Acesso suspenso'), findsOneWidget);
 expect(find.byType(AppShell), findsNothing);

 // Reativação (dono reverter em outro dispositivo): o próximo poll
 // devolve o acesso, de novo sem reiniciar.
 links.setActive(true);
 await tester.pump(const Duration(seconds: 2));
 await tester.pumpAndSettle();

 expect(find.byType(AppShell), findsOneWidget);
 expect(find.text('Acesso suspenso'), findsNothing);
 });

 testWidgets('sign-out encerra o polling CENTRAL (autoDispose cancela o '
 'timer e o Realtime)', (tester) async {
 final auth = StreamController<AppUser?>();
 final links = _MutableEmployeeLink(isActive: true);
 await tester.pumpWidget(
 _buildApp(
 authStream: auth.stream,
 adminRepository: const FakeAdminRepository(),
 getMyTenant: FakeGetMyTenantUseCase(approvedTenant(ownerUserId: '9')),
 getEmployees: links,
 ),
 );
 auth.add(AppUser(id: 'u1', email: 'carlos@loja.com'));
 await tester.pumpAndSettle();

 expect(find.byType(AppShell), findsOneWidget);

 // Um tick do timer dispara a re-busca dos vínculos (contagem sobe).
 final callsBefore = links.calls;
 await tester.pump(const Duration(seconds: 2));
 await tester.pumpAndSettle();
 expect(links.calls, greaterThan(callsBefore));

 // Sign-out: o AuthGate para de observar o provider → autoDispose
 // descarta o provider e CANCELA o timer de fallback + o Realtime.
 auth.add(null);
 await tester.pumpAndSettle();
 expect(find.byType(LoginScreen), findsOneWidget);

 final callsAtSignOut = links.calls;
 // Avança MUITO além do intervalo: se o timer continuasse vivo, a
 // contagem subiria (e o teste falharia com "Timer is still pending").
 await tester.pump(const Duration(seconds: 10));
 await tester.pumpAndSettle();

 expect(links.calls, callsAtSignOut);
 await auth.close();
 });

 testWidgets('sessão criada por link de RECUPERAÇÃO exige a nova senha '
 'antes da área de gestão (evento passwordRecovery)', (tester) async {
 final auth = StreamController<AppUser?>();
 final events = StreamController<AuthEvent>();
 await tester.pumpWidget(
 _buildApp(
 authStream: auth.stream,
 authEvents: events.stream,
 adminRepository: const FakeAdminRepository(),
 getMyTenant: FakeGetMyTenantUseCase(approvedTenant()),
 ),
 );

 // O gotrue emite passwordRecovery ANTES de assentar a sessão do link.
 events.add(AuthEvent.passwordRecovery);
 auth.add(AppUser(id: 'u1', email: 'dono@loja.com'));
 await tester.pump();
 await tester.pump();

 // NÃO entra no AppShell: a tela de definir nova senha vem primeiro.
 expect(find.byType(SetNewPasswordScreen), findsOneWidget);
 expect(find.byType(AppShell), findsNothing);

 // Sessão normal (sem evento de recovery) NÃO mantém o flag — no
 // próximo login o app segue direto para a gestão.
 events.add(AuthEvent.other);
 await tester.pump();
 auth.add(null); // sign-out limpa o sinal de recovery
 await tester.pumpAndSettle();
 expect(find.byType(LoginScreen), findsOneWidget);
 auth.add(AppUser(id: 'u1', email: 'dono@loja.com'));
 await tester.pumpAndSettle();

 expect(find.byType(SetNewPasswordScreen), findsNothing);
 expect(find.byType(AppShell), findsOneWidget);

 await auth.close();
 await events.close();
 });

 testWidgets('sign-out LIMPA o sinal de recovery — reabrir com sessão '
 'normal não mostra a tela de nova senha', (tester) async {
 final auth = StreamController<AppUser?>();
 final events = StreamController<AuthEvent>();
 await tester.pumpWidget(
 _buildApp(
 authStream: auth.stream,
 authEvents: events.stream,
 adminRepository: const FakeAdminRepository(),
 getMyTenant: FakeGetMyTenantUseCase(approvedTenant()),
 ),
 );

 // Usuário entra via link de recuperação (flag marcado).
 events.add(AuthEvent.passwordRecovery);
 auth.add(AppUser(id: 'u1', email: 'dono@loja.com'));
 await tester.pump();
 await tester.pump();
 expect(find.byType(SetNewPasswordScreen), findsOneWidget);

 // Sai da conta: flag limpo pelo AuthGate no caminho de user == null.
 auth.add(null);
 await tester.pump();
 await tester.pump();
 expect(find.byType(LoginScreen), findsOneWidget);

 // Novo login NORMAL (sem evento de recovery) entra direto na gestão —
 // o sinal não vazou do sign-out anterior.
 auth.add(AppUser(id: 'u1', email: 'dono@loja.com'));
 await tester.pump();
 await tester.pump();
 await tester.pump();

 expect(find.byType(SetNewPasswordScreen), findsNothing);
 expect(find.byType(AppShell), findsOneWidget);

 await auth.close();
 await events.close();
 });
}
