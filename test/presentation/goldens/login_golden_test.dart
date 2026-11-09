import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

import 'package:tareqo/core/theme/app_theme.dart';
import 'package:tareqo/domain/entities/app_user.dart';
import 'package:tareqo/domain/entities/auth_event.dart';
import 'package:tareqo/domain/repositories/i_auth_repository.dart';
import 'package:tareqo/presentation/controllers/auth_providers.dart';
import 'package:tareqo/presentation/screens/auth/login_screen.dart';

/// Baseline visual da tela de login — primeira superfície que o utilizador
/// vê. Capturado no tema escuro (padrão do app) e claro.
///
/// O fake replica o teste funcional de login (login_screen_test.dart) para
/// renderizar a tela real sem backend.
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
      throw UnimplementedError();

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

Widget _buildApp(ThemeData? theme) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
    ],
    child: testApp(theme: theme, home: const LoginScreen()),
  );
}

void main() {
  setUpAll(() async {
    final bytes = File('assets/fonts/Inter-Variable.ttf').readAsBytesSync();
    final loader = FontLoader('Inter')
      ..addFont(Future.value(ByteData.view(bytes.buffer)));
    await loader.load();
  });

  Future<void> pumpLogin(WidgetTester tester, ThemeData theme) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_buildApp(theme));
    // O logo é um asset: descodificar fora do runAsync deixa a primeira
    // captura sem imagem (corrida de decode no harness de goldens).
    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/branding/icon_official.png'),
        tester.element(find.byType(LoginScreen)),
      );
    });
    await tester.pumpAndSettle();
  }

  testWidgets('login — dark', (tester) async {
    await pumpLogin(tester, AppTheme.dark);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/login_dark.png'),
    );
  });

  testWidgets('login — light', (tester) async {
    await pumpLogin(tester, AppTheme.light);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/login_light.png'),
    );
  });
}
