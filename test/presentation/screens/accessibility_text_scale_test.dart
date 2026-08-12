import 'dart:async';

import 'package:flutter/material.dart';
import 'package:dumbhanengue/domain/entities/auth_event.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';
import 'package:dumbhanengue/domain/entities/app_user.dart';
import 'package:dumbhanengue/domain/repositories/i_auth_repository.dart';
import 'package:dumbhanengue/presentation/controllers/auth_providers.dart';
import 'package:dumbhanengue/presentation/screens/auth/login_screen.dart';

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

    expect(find.text('Dumbhanengue'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
