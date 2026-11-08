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

  // A11y (U-03): a escala de texto do sistema é RESPEITADA sem clamp
  // global — sistema pedindo 2.0 entrega 2.0 (WCAG 1.4.4, 200%). Sem o
  // teto de 1.6× anterior.
  testWidgets('app respeita a escala de texto do sistema sem clamp', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearAllTestValues);

    // App completo sem sessão (stream sem emissão → splash do AuthGate).
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        ],
        child: const TareqoApp(),
      ),
    );
    await tester.pump();

    // Escala integral: bodyMedium (14) → 28, labelSmall (11) → 22.
    final navigatorContext = tester.element(find.byType(Navigator).first);
    final scaler = MediaQuery.of(navigatorContext).textScaler;
    expect(scaler.scale(14), closeTo(28.0, 0.01));
    expect(scaler.scale(11), closeTo(22.0, 0.01));

    // Nada estourou (overflows de RenderFlex falham o teste).
    expect(tester.takeException(), isNull);
  });
}
