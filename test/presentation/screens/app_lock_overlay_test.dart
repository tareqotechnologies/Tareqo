import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import '../../helpers/test_app.dart';

import 'package:tareqo/core/security/biometric_service.dart';
import 'package:tareqo/core/security/secure_storage_service.dart';
import 'package:tareqo/domain/entities/app_user.dart';
import 'package:tareqo/domain/usecases/biometric_auth_use_case.dart';
import 'package:tareqo/presentation/controllers/auth_providers.dart';
import 'package:tareqo/presentation/screens/auth/app_lock_overlay.dart';

/// Biometria fake — nunca toca no plugin nativo (inexistente nos testes).
class _FakeBiometricService extends BiometricService {
  /// Número de vezes que o sistema pediu a biometria.
  int attempts = 0;

  /// Resultado programável da próxima autenticação.
  bool Function()? onAuthenticate;

  /// Se definido, a autenticação fica pendente até o teste completar.
  Completer<bool>? pending;

  @override
  Future<bool> get isAvailable async => true;

  @override
  Future<bool> authenticate({
    String localizedReason = '',
    String signInTitle = '',
    String biometricHint = '',
    String cancelButton = '',
    String fallbackTitle = '',
    String goToSettingsButton = '',
    String goToSettingsDescription = '',
    String lockOut = '',
    bool useErrorDialogs = true,
    bool stickyAuth = true,
    bool biometricOnly = false,
  }) {
    attempts++;
    final callback = onAuthenticate;
    if (callback != null) return Future.value(callback());
    final completer = pending;
    if (completer != null) return completer.future;
    return Future.value(true);
  }
}

/// Conteúdo real do app (o que NÃO pode estar visível enquanto bloqueado).
const _areaPrincipal = 'ÁREA PRINCIPAL';
const _lockTitle = 'TAREQO bloqueado';
const _lockError = 'Não foi possível autenticar';

Widget _buildApp({
  required Stream<AppUser?> authStream,
  required _FakeBiometricService service,
  bool bioEnabled = true,
}) {
  registerTestSecureStorage();
  final storage = GetIt.instance<SecureStorageService>();
  final useCase = BiometricAuthUseCase(service, storage);
  // Define o estado da biometria explicitamente em cada teste (o storage
  // em memória é partilhado entre testes do mesmo ficheiro): activa como
  // se o dono tivesse ligado em Configurações → Segurança.
  if (bioEnabled) {
    useCase.enable();
  } else {
    useCase.disable();
  }
  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith((ref) => authStream),
      biometricAuthUseCaseProvider.overrideWithValue(useCase),
    ],
    child: testApp(
      home: const Scaffold(body: Center(child: Text(_areaPrincipal))),
      builder: (context, child) =>
          AppLockOverlay(child: child ?? const SizedBox.shrink()),
    ),
  );
}

void main() {
  testWidgets('arranque a frio com sessão restaurada + biometria ativa '
      'inicia BLOQUEADO e desbloqueia após a biometria', (tester) async {
    final service = _FakeBiometricService();
    final unlock = Completer<bool>();

    await tester.pumpWidget(
      _buildApp(
        authStream: Stream.value(const AppUser(id: 'u1', email: 'dono@loja.com')),
        service: service,
      ),
    );
    service.pending = unlock;

    // Sessão + estado biométrico resolvem → o ecrã de bloqueio aparece e a
    // biometria é pedida ANTES de qualquer conteúdo da área de gestão.
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text(_lockTitle), findsOneWidget);
    expect(service.attempts, 1);
    // O conteúdo real está montado em baixo, mas coberto pelo bloqueio.
    expect(find.text(_areaPrincipal), findsOneWidget);

    // Biometria aceita → entra na área de gestão, sem novo prompt.
    unlock.complete(true);
    await tester.pumpAndSettle();

    expect(find.text(_lockTitle), findsNothing);
    expect(find.text(_areaPrincipal), findsOneWidget);
    expect(service.attempts, 1);
  });

  testWidgets('biometria DESATIVADA não bloqueia no arranque nem ao voltar '
      'do fundo', (tester) async {
    final service = _FakeBiometricService();
    final auth = StreamController<AppUser?>();

    await tester.pumpWidget(
      _buildApp(authStream: auth.stream, service: service, bioEnabled: false),
    );
    auth.add(const AppUser(id: 'u1', email: 'dono@loja.com'));
    await tester.pumpAndSettle();

    expect(find.text(_lockTitle), findsNothing);
    expect(find.text(_areaPrincipal), findsOneWidget);

    // Fundo → regresso: mesmo assim, sem biometria ativa, não bloqueia.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(find.text(_lockTitle), findsNothing);
    expect(service.attempts, 0);
    await auth.close();
  });

  testWidgets('voltar do fundo com biometria ativa bloqueia e pede a '
      'biometria', (tester) async {
    final service = _FakeBiometricService();
    final auth = StreamController<AppUser?>();
    final unlock = Completer<bool>();

    await tester.pumpWidget(
      _buildApp(authStream: auth.stream, service: service),
    );
    service.pending = unlock;

    // Sem sessão (login) → entra com senha em primeiro plano: NÃO pede a
    // biometria já na hora (só no próximo regresso do fundo / arranque).
    auth.add(null);
    await tester.pumpAndSettle();
    auth.add(const AppUser(id: 'u1', email: 'dono@loja.com'));
    await tester.pumpAndSettle();

    expect(find.text(_lockTitle), findsNothing);
    expect(service.attempts, 0);

    // Vai para o fundo e volta → bloqueia e pede a biometria.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text(_lockTitle), findsOneWidget);
    expect(service.attempts, 1);

    unlock.complete(true);
    await tester.pumpAndSettle();
    expect(find.text(_lockTitle), findsNothing);
    expect(find.text(_areaPrincipal), findsOneWidget);
    await auth.close();
  });

  testWidgets('biometria recusada/cancelada mantém o bloqueio com mensagem '
      'e permite nova tentativa', (tester) async {
    final service = _FakeBiometricService();
    var accept = false; // primeira tentativa falha (cancelamento)
    service.onAuthenticate = () => accept;

    await tester.pumpWidget(
      _buildApp(
        authStream: Stream.value(const AppUser(id: 'u1', email: 'dono@loja.com')),
        service: service,
      ),
    );
    await tester.pumpAndSettle();

    // Falhou → continua no ecrã de bloqueio, com a mensagem de erro.
    expect(find.text(_lockTitle), findsOneWidget);
    expect(find.textContaining(_lockError), findsOneWidget);
    expect(service.attempts, 1);

    // Nova tentativa aceite → desbloqueia.
    accept = true;
    await tester.tap(find.text('Desbloquear'));
    await tester.pumpAndSettle();

    expect(find.text(_lockTitle), findsNothing);
    expect(service.attempts, 2);
  });

  testWidgets('sessão terminada remove o bloqueio (volta ao login)', (
    tester,
  ) async {
    final service = _FakeBiometricService();
    final auth = StreamController<AppUser?>();
    final unlock = Completer<bool>();

    await tester.pumpWidget(
      _buildApp(authStream: auth.stream, service: service),
    );
    service.pending = unlock;
    auth.add(const AppUser(id: 'u1', email: 'dono@loja.com'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text(_lockTitle), findsOneWidget);

    // Sessão cai (ex.: terminar sessão pelo próprio ecrã de bloqueio) →
    // o bloqueio some e o LoginScreen (aqui, o conteúdo de baixo) aparece.
    auth.add(null);
    await tester.pumpAndSettle();

    expect(find.text(_lockTitle), findsNothing);
    expect(find.text(_areaPrincipal), findsOneWidget);
    await auth.close();
  });
}
