import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tareqo/domain/entities/auth_event.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';
import 'package:tareqo/app.dart';
import 'package:tareqo/domain/entities/app_user.dart';
import 'package:tareqo/domain/repositories/i_auth_repository.dart';
import 'package:tareqo/presentation/controllers/auth_providers.dart';
import 'package:tareqo/presentation/screens/auth/login_screen.dart';

class _FakeAuthRepository implements IAuthRepository {
  final _controller = StreamController<AppUser?>.broadcast();

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    return AppUser(id: '2', email: email, fullName: fullName ?? '');
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    return AppUser(id: '1', email: email);
  }

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

Widget _buildApp() {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
    ],
    child: testApp(home: const LoginScreen()),
  );
}

void main() {
  // W8 (acessibilidade): a escala de texto (fonte grande) não pode rebentar
  // o layout — a tela usa SingleChildScrollView e Material 3. Este teste
  // regressa se um Text/Card passar a estourar com textScaler 2.0 (os
  // overflows de RenderFlex falham o teste automaticamente).
  testWidgets('ecrã de login renderiza com escala de texto 2.0', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearAllTestValues);

    await tester.pumpWidget(_buildApp());
    await tester.pump();

    expect(find.text('TAREQO'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  // A11y (Fase 6): campos, botões e links do login passam nos guidelines
  // de toque (≥48dp) e contraste de texto.
  testWidgets('a11y: login passa nos guidelines de toque e contraste', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    final handle = tester.ensureSemantics();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });

  // A11y (plano UI/UX — Fase 3.2): o builder do [TareqoApp] aplica teto
  // global de 1.6× na escala de texto — o sistema pede 2.0, o app entrega
  // 1.6 (legibilidade ampliada SEM layouts quebrados).
  testWidgets('app aplica teto global de 1.6x na escala de texto', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearAllTestValues);

    // App completo sem sessão (stream sem emissão → splash do AuthGate):
    // o builder do MaterialApp roda para QUALQUER tela filha, incluindo
    // login/splash — não exige o bootstrap do shell logado.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        ],
        child: const TareqoApp(),
      ),
    );
    await tester.pump();

    // O app entrega 1.6 (o sistema pediu 2.0): um bodyMedium (14) renderiza a 22.4 (não 28) e um
    // labelSmall (11) a 17.6 — probe abaixo do builder (AppLockOverlay),
    // onde a MediaQuery mais próxima já é a do clamp.
    final navigatorContext = tester.element(find.byType(Navigator).first);
    final scaler = MediaQuery.of(navigatorContext).textScaler;
    expect(scaler.scale(14), closeTo(22.4, 0.01));
    expect(scaler.scale(11), closeTo(17.6, 0.01));

    // Nada estourou com o teto aplicado (overflows de RenderFlex falham
    // o teste automaticamente).
    expect(tester.takeException(), isNull);
  });
}
