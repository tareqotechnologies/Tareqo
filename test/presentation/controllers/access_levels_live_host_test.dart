import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:tareqo/core/di/service_locator.dart';
import 'package:tareqo/core/network/supabase_bootstrap.dart';
import 'package:tareqo/domain/entities/app_user.dart';
import 'package:tareqo/domain/entities/store_employee.dart'
    show EmployeeRole, StoreEmployee;
import 'package:tareqo/domain/entities/tenant.dart' show Tenant, TenantStatus;
import 'package:tareqo/domain/repositories/i_auth_repository.dart';
import 'package:tareqo/presentation/controllers/account_providers.dart';
import 'package:tareqo/presentation/controllers/auth_providers.dart';

/// Executa a CADEIA REAL do E2E `access_levels_web_test.dart` na VM do host,
/// sem device — o mesmo padrão dos runners live (`cert_pinning_live_host_test`,
/// `cash_closing_summary_live_host_test`).
///
/// Motivo: nesta máquina os navegadores derrubam a sessão do `flutter drive`
/// logo após o debug service conectar (Chrome/Edge 152) e não há toolchain
/// C++ (Windows) nem imagem de emulador Android. A cadeia verificada aqui é
/// a MESMA que o dashboard usa para decidir a matriz de módulos —
/// `currentAccessLevelProvider` é a ÚNICA entrada da visibilidade de
/// Lojas/Compras/Relatórios (ver menu_screen/dashboard):
///
/// 1. Supabase real de dev inicializado (dart-defines);
/// 2. login REAL para cada papel (dono, gerente, funcionário — as contas
///    de teste criadas via `create_employee_account`);
/// 3. os MESMOS providers do app: authStateProvider → myTenantProvider →
///    employeesProvider → currentAccessLevelProvider;
/// 4. matriz esperada: dono=owner; gerente=manager (vínculo ativo com
///    cargo manager); funcionário=employee;
/// 5. isolamento: os vínculos são os REAIS do banco (nada é simulado) e a
///    sessão do papel anterior é encerrada antes do próximo login.
///
/// O teste é SKIPPED sem credenciais EXPLÍCITAS — o CI hermético não toca na
/// rede. Com credenciais, roda de verdade:
///
///   flutter test test/presentation/controllers/access_levels_live_host_test.dart \
///     --dart-define-from-file=env/dev.env \
///     --dart-define-from-file=env/test_accounts.env
const _ownerEmail = String.fromEnvironment('TEST_OWNER_EMAIL');
const _ownerPassword = String.fromEnvironment('TEST_OWNER_PASSWORD');
const _managerEmail = String.fromEnvironment('TEST_MANAGER_EMAIL');
const _managerPassword = String.fromEnvironment('TEST_MANAGER_PASSWORD');
const _employeeEmail = String.fromEnvironment('TEST_EMPLOYEE_EMAIL');
const _employeePassword = String.fromEnvironment('TEST_EMPLOYEE_PASSWORD');

void main() {
  // Binding de integration test: permite rede REAL (o binding puro de widget
  // test intercepta todo HttpClient com 400 falsos — mataria o login).
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // O persistence do Supabase usa o canal do flutter_secure_storage; na VM
  // do host o canal precisa de um backend em memória (mesmo contrato).
  const secureChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  final secureStore = <String, String>{};
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(secureChannel, (call) async {
        switch (call.method) {
          case 'write':
            final args = call.arguments as Map<Object?, Object?>;
            secureStore[args['key'] as String] = args['value'] as String;
            return null;
          case 'read':
            final args = call.arguments as Map<Object?, Object?>;
            return secureStore[args['key'] as String];
          case 'readAll':
            return Map<String, String>.of(secureStore);
          case 'delete':
            final args = call.arguments as Map<Object?, Object?>;
            secureStore.remove(args['key'] as String);
            return null;
          case 'deleteAll':
            secureStore.clear();
            return null;
          case 'containsKey':
            final args = call.arguments as Map<Object?, Object?>;
            return secureStore.containsKey(args['key'] as String);
          default:
            return null;
        }
      });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureChannel, null);
  });

  test(
    'matriz de níveis de acesso contra o Supabase de dev: dono=owner, '
    'gerente=manager, funcionário=employee (cadeia real de providers)',
    () async {
      final creds = [
        (_ownerEmail, _ownerPassword),
        (_managerEmail, _managerPassword),
        (_employeeEmail, _employeePassword),
      ];
      if (creds.any((c) => c.$1.isEmpty || c.$2.isEmpty)) {
        // Sem as SEIS credenciais o teste NÃO toca na rede (CI hermético).
        // ignore: avoid_print
        print(
          'SKIPPED (credenciais ausentes): passe --dart-define-from-file='
          'env/dev.env + env/test_accounts.env (dono, gerente e funcionário).',
        );
        return;
      }

      await SupabaseBootstrap.initialize();
      await ServiceLocator.initialize();
      final auth = ServiceLocator.instance<IAuthRepository>();

      Future<void> expectAccessLevel(
        String email,
        String password,
        UserAccessLevel expected,
      ) async {
        await auth.signIn(email: email, password: password);

        // Um ProviderContainer NOVO por fase: no app o fluxo é o mesmo —
        // a árvore de widgets (e os providers) nasce de novo a cada sign-in
        // (AuthGate). Reaproveitar o container entre fases servia a lista
        // CACHEADA da fase anterior (autoDispose não descarta com listener
        // ativo) e o nível resolvia errado. Aqui não há cache: cada fase
        // re-busca tudo do servidor com a sessão da vez (RLS vigia).
        final container = ProviderContainer();
        addTearDown(container.dispose);

        // Espera o authStateProvider (stream REAL do repositório) emitir o
        // utilizador — a mesma condição do AuthGate antes de resolver o nível.
        // O provider só assina o stream quando EXISTE listener (no app quem
        // assina é o widget). container.read inicializa sem assinar —
        // authStateChanges emite no onListen, então SEM listener fica em
        // AsyncLoading para sempre. Cria a assinatura persistente aqui.
        container.listen(authStateProvider, (_, _) {});

        AppUser? user;
        final deadline = DateTime.now().add(const Duration(seconds: 30));
        var logged = 0;
        while (DateTime.now().isBefore(deadline)) {
          final state = container.read(authStateProvider);
          user = state.value;
          if (user != null && user.email == email) break;
          if (logged < 3) {
            logged++;
            // ignore: avoid_print
            print('authState aguardando $email: $state');
          }
          await Future<void>.delayed(const Duration(milliseconds: 250));
        }
        if (user == null || user.email != email) {
          fail('authStateProvider não emitiu o utilizador $email em 30s');
        }
        final currentUser = user;

        // Cadeia REAL do app: tenant → vínculos → nível de acesso.
        // myTenantProvider/employeesProvider são autoDispose: sem LISTENER,
        // o read(.future) inicializa e descarta — o currentAccessLevel
        // re-inicializaria em AsyncLoading (value=null). Assina a cadeia
        // INTEIRA (como os widgets fazem) e faz polling dos .value.
        container.listen(myTenantProvider(currentUser.id), (_, _) {});

        Tenant? tenant;
        final tenantDeadline = DateTime.now().add(const Duration(seconds: 30));
        while (DateTime.now().isBefore(tenantDeadline)) {
          tenant = container.read(myTenantProvider(currentUser.id)).value;
          if (tenant != null) break;
          await Future<void>.delayed(const Duration(milliseconds: 250));
        }
        final resolvedTenant = tenant;
        if (resolvedTenant == null) {
          fail('$email não tem tenant em dev');
        }
        expect(
          resolvedTenant.status,
          TenantStatus.approved,
          reason: 'tenant de dev está aprovado',
        );

        // Regra de resolução real (account_providers.dart):
        //  - owner: tenant.ownerUserId == user.id — NÃO há vínculo;
        //  - manager/employee: vínculo(s) em store_employees com cargo,
        //    valendo o MAIOR cargo entre os vínculos ativos.
        var isOwner = false;
        String? roleOfLink;
        if (resolvedTenant.ownerUserId == currentUser.id) {
          isOwner = true;
        } else {
          container.listen(employeesProvider(resolvedTenant.id), (_, _) {});
          List<StoreEmployee> employees = const [];
          final empDeadline = DateTime.now().add(const Duration(seconds: 30));
          while (DateTime.now().isBefore(empDeadline)) {
            final state = container
                .read(employeesProvider(resolvedTenant.id))
                .value;
            if (state != null) {
              employees = state;
              break;
            }
            await Future<void>.delayed(const Duration(milliseconds: 250));
          }
          final links = employees
              .where((e) => e.userId == currentUser.id)
              .toList();
          expect(
            links,
            isNotEmpty,
            reason: '$email (não-dono) tem vínculo em store_employees',
          );
          expect(
            links.any((e) => e.isActive),
            isTrue,
            reason: 'vínculo ATIVO para $email',
          );
          roleOfLink =
              links.any((e) => e.isActive && e.role == EmployeeRole.manager)
              ? 'manager'
              : 'employee';
        }

        // Mantém o GRAFO inteiro assinado (como os widgets fazem) —
        // currentAccessLevelProvider lê os outros providers via watch.
        final level = container.read(currentAccessLevelProvider);
        expect(
          level,
          expected,
          reason:
              '$email deve resolver $expected '
              '(owner=$isOwner, cargo=${roleOfLink ?? 'dono'})',
        );

        // Isolamento de sessão: encerra e espera o stream emitir null antes
        // do próximo login (a sessão é única no cliente Supabase).
        await auth.signOut();
        final nullDeadline = DateTime.now().add(const Duration(seconds: 30));
        while (DateTime.now().isBefore(nullDeadline)) {
          final current = container.read(authStateProvider).value;
          if (current == null) return;
          await Future<void>.delayed(const Duration(milliseconds: 250));
        }
        fail('sessão não foi encerrada (authStateProvider não emitiu null)');
      }

      // A MESMA matriz que o E2E de browser valida na UI:
      await expectAccessLevel(
        _ownerEmail,
        _ownerPassword,
        UserAccessLevel.owner,
      );
      await expectAccessLevel(
        _managerEmail,
        _managerPassword,
        UserAccessLevel.manager,
      );
      await expectAccessLevel(
        _employeeEmail,
        _employeePassword,
        UserAccessLevel.employee,
      );
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
