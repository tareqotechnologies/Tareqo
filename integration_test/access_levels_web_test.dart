import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:dumbhanengue/l10n/generated/app_localizations.dart';
import 'package:dumbhanengue/main.dart' as app;

/// Credenciais REAIS fornecidas em tempo de execução via --dart-define
/// (nunca versionadas — o ficheiro só contém os nomes dos defines):
///
///   flutter drive --driver=test_driver/integration_test.dart \
///     --target=integration_test/access_levels_web_test.dart -d chrome \
///     --dart-define-from-file=env/dev.env \
///     --dart-define=TEST_OWNER_EMAIL=... --dart-define=TEST_OWNER_PASSWORD=... \
///     --dart-define=TEST_MANAGER_EMAIL=... --dart-define=TEST_MANAGER_PASSWORD=... \
///     --dart-define=TEST_EMPLOYEE_EMAIL=... --dart-define=TEST_EMPLOYEE_PASSWORD=...
const _ownerEmail = String.fromEnvironment('TEST_OWNER_EMAIL');
const _ownerPassword = String.fromEnvironment('TEST_OWNER_PASSWORD');
const _managerEmail = String.fromEnvironment('TEST_MANAGER_EMAIL');
const _managerPassword = String.fromEnvironment('TEST_MANAGER_PASSWORD');
const _employeeEmail = String.fromEnvironment('TEST_EMPLOYEE_EMAIL');
const _employeePassword = String.fromEnvironment('TEST_EMPLOYEE_PASSWORD');

/// Marcador do ecrã de login, independente de idioma (título da app).
const _loginTitle = 'Dumbhanengue';

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 60),
  required String reason,
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (condition()) return;
  }
  throw TestFailure('Timeout à espera de: $reason');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  if (_ownerEmail.isEmpty ||
      _managerEmail.isEmpty ||
      _employeeEmail.isEmpty ||
      _ownerPassword.isEmpty ||
      _managerPassword.isEmpty ||
      _employeePassword.isEmpty) {
    throw StateError(
      'Faltam as credenciais: passe --dart-define=TEST_OWNER_EMAIL, '
      'TEST_OWNER_PASSWORD, TEST_MANAGER_EMAIL, TEST_MANAGER_PASSWORD, '
      'TEST_EMPLOYEE_EMAIL e TEST_EMPLOYEE_PASSWORD.',
    );
  }

  // Resolve o texto localizado ATUAL da app a partir de um contexto ABAIXO
  // do widget Localizations (o contexto do próprio MaterialApp devolve
  // null). O anchor tem de ser um widget renderizado nessa altura — o
  // título do login ou qualquer Text já no ecrã.
  AppLocalizations l10nOf(WidgetTester tester, {Finder? anchor}) {
    final finder = anchor ?? find.byType(Text).first;
    return AppLocalizations.of(tester.element(finder));
  }

  /// Espera até um rótulo localizado aparecer — re-resolve o l10n a cada
  /// iteração para absorver a troca de idioma (pt → en) após o login.
  Future<void> waitForLabel(
    WidgetTester tester,
    String Function(AppLocalizations) label, {
    required String reason,
  }) async {
    final end = DateTime.now().add(const Duration(seconds: 60));
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 250));
      final l10n = l10nOf(tester);
      if (find.text(label(l10n)).evaluate().isNotEmpty) return;
    }
    throw TestFailure('Timeout à espera de: $reason');
  }

  Future<void> doLogin(
    WidgetTester tester,
    String email,
    String password,
  ) async {
    await _pumpUntil(
      tester,
      () => find.text(_loginTitle).evaluate().isNotEmpty,
      reason: 'ecrã de login',
    );
    final l10n = l10nOf(tester, anchor: find.text(_loginTitle).first);
    await tester.enterText(
      find.widgetWithText(TextFormField, l10n.loginEmailLabel),
      email,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, l10n.loginPasswordLabel),
      password,
    );
    await tester.tap(find.text(l10n.loginSignIn));
    // Dashboard carregado = botão de sair (ícone) visível — independente
    // de idioma e só existe na barra superior do dashboard.
    await _pumpUntil(
      tester,
      () => find.byIcon(Icons.logout).evaluate().isNotEmpty,
      reason: 'dashboard após login',
    );
  }

  Future<void> doSignOut(WidgetTester tester) async {
    await _pumpUntil(
      tester,
      () => find.byIcon(Icons.logout).evaluate().isNotEmpty,
      reason: 'botão de sair',
    );
    await tester.tap(find.byIcon(Icons.logout));
    await _pumpUntil(
      tester,
      () => find.text(_loginTitle).evaluate().isNotEmpty,
      reason: 'volta ao ecrã de login após sair',
    );
  }

  testWidgets(
    'matriz de acesso no dashboard: dono vê tudo, gerente vê compras/'
    'relatórios sem lojas, funcionário vê só a operação',
    (tester) async {
      await app.main();
      await tester.pump(const Duration(seconds: 3));

      // ── DONO: todos os módulos, incluindo Lojas (gestão) ──
      await doLogin(tester, _ownerEmail, _ownerPassword);
      await waitForLabel(
        tester,
        (l) => l.dashboardModuleStores,
        reason: 'dono vê o card Lojas',
      );
      await waitForLabel(
        tester,
        (l) => l.dashboardModulePurchases,
        reason: 'dono vê o card Compras',
      );
      await waitForLabel(
        tester,
        (l) => l.dashboardModuleReports,
        reason: 'dono vê o card Relatórios',
      );

      // ── GERENTE: compras + relatórios sim; gestão (Lojas) NÃO ──
      await doSignOut(tester);
      await doLogin(tester, _managerEmail, _managerPassword);
      await waitForLabel(
        tester,
        (l) => l.dashboardModulePurchases,
        reason: 'gerente vê o card Compras',
      );
      await waitForLabel(
        tester,
        (l) => l.dashboardModuleReports,
        reason: 'gerente vê o card Relatórios',
      );
      // Após o dashboard renderizado com o papel do gerente resolvido,
      // Lojas não pode existir (findsNothing é robusto ao idioma).
      expect(
        find.text(l10nOf(tester).dashboardModuleStores),
        findsNothing,
        reason: 'gerente NÃO vê o card Lojas',
      );

      // ── FUNCIONÁRIO: só a operação — nada de gerencial/gestão ──
      await doSignOut(tester);
      await doLogin(tester, _employeeEmail, _employeePassword);
      await waitForLabel(
        tester,
        (l) => l.dashboardModuleCustomers,
        reason: 'funcionário vê a operação (Clientes)',
      );
      final l10n = l10nOf(tester);
      expect(find.text(l10n.dashboardModulePurchases), findsNothing,
          reason: 'funcionário NÃO vê o card Compras');
      expect(find.text(l10n.dashboardModuleReports), findsNothing,
          reason: 'funcionário NÃO vê o card Relatórios');
      expect(find.text(l10n.dashboardModuleStores), findsNothing,
          reason: 'funcionário NÃO vê o card Lojas');
    },
  );
}
