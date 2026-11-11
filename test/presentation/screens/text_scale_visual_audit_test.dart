import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/golden_fonts.dart';
import '../../helpers/test_app.dart';

import 'package:tareqo/core/ui/haptics.dart';
import 'package:tareqo/domain/entities/app_user.dart';
import 'package:tareqo/domain/entities/auth_event.dart';
import 'package:tareqo/domain/entities/plan.dart';
import 'package:tareqo/domain/entities/plan_request.dart';
import 'package:tareqo/domain/entities/store.dart';
import 'package:tareqo/domain/entities/store_employee.dart';
import 'package:tareqo/domain/entities/tenant.dart';
import 'package:tareqo/domain/repositories/i_auth_repository.dart';
import 'package:tareqo/domain/usecases/get_employees_use_case.dart';
import 'package:tareqo/domain/usecases/get_my_plan_requests_use_case.dart';
import 'package:tareqo/domain/usecases/get_plans_use_case.dart';
import 'package:tareqo/domain/usecases/get_stores_use_case.dart';
import 'package:tareqo/domain/usecases/set_employee_active_use_case.dart';
import 'package:tareqo/presentation/controllers/account_providers.dart';
import 'package:tareqo/presentation/controllers/auth_providers.dart';
import 'package:tareqo/presentation/screens/auth/login_screen.dart';
import 'package:tareqo/presentation/screens/stores/stores_screen.dart';
import 'package:tareqo/presentation/screens/support/support_screen.dart';
import 'package:tareqo/presentation/widgets/detail_row.dart';

/// Auditoria visual da Fase 3.2 (plano UI/UX, docs/pt/21) nas telas
/// migradas pela Fase 2.3 — **login, suporte, lojas e o detalhe de loja**
/// — renderizadas com tipografia dinâmica em 1.3×, 1.6× e 2.0×.
///
/// O que cada caso valida:
///
/// 1. **Nenhuma exceção de layout** — `RenderFlex` overflowed falha o
///    teste automaticamente (`takeException` + falha nativa do framework);
///    é a prova executável de que a migração para tokens não introduziu
///    rigidez em Row/Column.
/// 2. **Captura PNG por tela/escala** (`--update-goldens` para gerar) —
///    revisão visual do impacto do texto ampliado sem subir o app.
///
/// U-03: já não há clamp global no `TareqoApp` (contrato em
/// `accessibility_text_scale_test.dart`) — 2.0× é renderizável e auditado.
///
/// As telas de stores usam os MESMOS fakes de `stores_screen_test.dart`
/// (arquivos de teste não são importáveis entre si sem arrastar `main()`),
/// com a loja de contatos completos para o sheet de detalhe exercitar os
/// `DetailRow` — os widgets justamente mexidos na migração da grelha.
class _FakeAuthRepository implements IAuthRepository {
  final _controller = StreamController<AppUser?>.broadcast();

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async => AppUser(id: '2', email: email, fullName: fullName ?? '');

  @override
  Future<AppUser> signIn({required String email, required String password}) =>
      Future.error(UnimplementedError());

  @override
  Future<void> signOut() async {}

  @override
  Future<void> resetPassword({required String email}) async {}

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {}

  @override
  Future<void> setNewPassword({required String newPassword}) async {}

  @override
  Stream<AppUser?> get authStateChanges => _controller.stream;

  @override
  Stream<AuthEvent> get authEvents => const Stream.empty();
}

class _FakeGetPlansUseCase implements GetPlansUseCase {
  @override
  Future<List<Plan>> call() async => const [
    Plan(id: 'pl2', name: 'Profissional', maxStores: 3, maxEmployees: 10),
  ];
}

class _FakeGetStoresUseCase implements GetStoresUseCase {
  @override
  Future<List<Store>> call(String tenantId) async => const [
    Store(
      id: 'st1',
      tenantId: 'tn1',
      name: 'Loja Centro',
      phone: '+258 84 111 1111',
      email: 'loja@centro.co.mz',
      nuit: '123456789',
      city: 'Maputo',
      address: 'Av. 24 de Julho, 100, Maputo',
    ),
  ];
}

class _FakeGetEmployeesUseCase implements GetEmployeesUseCase {
  @override
  Future<List<StoreEmployee>> call(String tenantId) async => const [
    StoreEmployee(
      id: 'e1',
      tenantId: 'tn1',
      storeId: 'st1',
      userId: 'u2',
      fullName: 'Carlos Manuel Macuácua',
      email: 'carlos@loja.com',
      role: EmployeeRole.manager,
    ),
  ];
}

class _FakeSetEmployeeActiveUseCase implements SetEmployeeActiveUseCase {
  @override
  Future<void> call({
    required String tenantId,
    required String employeeId,
    required bool isActive,
  }) async {}
}

class _FakeGetMyPlanRequestsUseCase implements GetMyPlanRequestsUseCase {
  @override
  Future<List<PlanRequest>> call(String tenantId) async => const [];
}

/// Superfície portrait de telemóvel + textScaler injetado ACIMA do
/// MaterialApp (a MediaQuery do app herda — todas as telas o leem).
Future<void> _pump(WidgetTester tester, double scale, Widget child) async {
  tester.view.physicalSize = const Size(800, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(scale)),
      child: child,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _capture(WidgetTester tester, String name) async {
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('goldens/text_scale_audit/$name.png'),
  );
}

String _tag(double scale) => '${scale}x'.replaceAll('.', '_');

Widget _login() => ProviderScope(
  overrides: [authRepositoryProvider.overrideWithValue(_FakeAuthRepository())],
  child: testApp(home: const LoginScreen()),
);

Widget _support() => testApp(home: const SupportScreen());

Widget _stores(Tenant tenant) => ProviderScope(
  overrides: [
    authStateProvider.overrideWith(
      (ref) => Stream.value(const AppUser(id: 'u1', email: 'dono@loja.com')),
    ),
    getPlansUseCaseProvider.overrideWithValue(_FakeGetPlansUseCase()),
    getStoresUseCaseProvider.overrideWithValue(_FakeGetStoresUseCase()),
    getEmployeesUseCaseProvider.overrideWithValue(_FakeGetEmployeesUseCase()),
    setEmployeeActiveUseCaseProvider.overrideWithValue(
      _FakeSetEmployeeActiveUseCase(),
    ),
    getMyPlanRequestsUseCaseProvider.overrideWithValue(
      _FakeGetMyPlanRequestsUseCase(),
    ),
  ],
  child: testApp(home: StoresScreen(tenant: tenant)),
);

void main() {
  // Fontes reais (Outfit + MaterialIcons) também nesta auditoria: sem isso
  // os PNGs mostram o texto em blocos Ahem e os ícones em quadrados.
  setUpAll(loadGoldenFonts);

  Haptics.debugOverrideEnabled = false;

  final tenant = Tenant(
    id: 'tn1',
    ownerUserId: 'u1',
    businessName: 'Comercial X',
    planId: 'pl2',
    status: TenantStatus.approved,
    approvedAt: DateTime.now(),
    createdAt: DateTime.now(),
  );

  for (final scale in const <double>[1.3, 1.6, 2.0]) {
    group('auditoria visual — textScaler $scale', () {
      testWidgets('login', (tester) async {
        await _pump(tester, scale, _login());

        expect(find.text('TAREQO'), findsOneWidget);
        expect(find.text('Entrar'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await _capture(tester, 'login_${_tag(scale)}');
      });

      testWidgets('suporte', (tester) async {
        await _pump(tester, scale, _support());

        expect(find.byType(SupportScreen), findsOneWidget);
        expect(find.byType(TextField), findsOneWidget); // busca
        expect(tester.takeException(), isNull);
        await _capture(tester, 'suporte_${_tag(scale)}');
      });

      testWidgets('lojas', (tester) async {
        await _pump(tester, scale, _stores(tenant));

        expect(find.text('Profissional'), findsOneWidget);
        expect(find.text('Loja Centro'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await _capture(tester, 'lojas_${_tag(scale)}');
      });

      testWidgets('detalhe da loja (sheet de contatos)', (tester) async {
        await _pump(tester, scale, _stores(tenant));

        await tester.tap(find.text('Loja Centro'));
        // Animação da rota + futures dos fakes — pumps fixos (o sheet tem
        // conteúdo assíncrono e `pumpAndSettle` podia esterilizar frames
        // de verdade com a escala aplicada).
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 400));

        // Os DetailRow são o ponto mexido na Fase 2.3 (vertical: 5 →
        // token): com texto ampliado, valor precisa quebrar em linha —
        // nunca estourar.
        expect(find.byType(DetailRow), findsWidgets);
        expect(tester.takeException(), isNull);
        await _capture(tester, 'loja_detalhe_${_tag(scale)}');
      });
    });
  }
}
