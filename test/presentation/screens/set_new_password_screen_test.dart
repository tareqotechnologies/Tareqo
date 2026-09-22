import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../helpers/test_app.dart';

import 'package:tareqo/domain/entities/app_user.dart';
import 'package:tareqo/domain/entities/auth_event.dart';
import 'package:tareqo/domain/repositories/i_auth_repository.dart';
import 'package:tareqo/presentation/controllers/auth_providers.dart';
import 'package:tareqo/presentation/screens/auth/set_new_password_screen.dart';

class _FakeAuthRepository implements IAuthRepository {
  final _controller = StreamController<AppUser?>.broadcast();

  String? lastSetNew;
  Exception? errorToThrow;

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async => throw UnimplementedError();

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async => throw UnimplementedError();

  @override
  Future<void> signOut() async {}

  @override
  Future<void> resetPassword({required String email}) async {}

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async => throw UnimplementedError();

  @override
  Future<void> setNewPassword({required String newPassword}) async {
    if (errorToThrow != null) throw errorToThrow!;
    lastSetNew = newPassword;
  }

  @override
  Stream<AppUser?> get authStateChanges => _controller.stream;

  @override
  Stream<AuthEvent> get authEvents => const Stream.empty();
}

Widget _buildApp(IAuthRepository repository) {
  return ProviderScope(
    overrides: [authRepositoryProvider.overrideWithValue(repository)],
    child: testApp(home: const SetNewPasswordScreen()),
  );
}

void main() {
  testWidgets('define a nova senha (recuperação) com sucesso', (tester) async {
    final repository = _FakeAuthRepository();
    await tester.pumpWidget(_buildApp(repository));

    await tester.enterText(find.byType(TextFormField).at(0), 'NovaSenha2@');
    await tester.enterText(find.byType(TextFormField).at(1), 'NovaSenha2@');

    await tester.ensureVisible(find.text('Guardar nova senha'));
    await tester.tap(find.text('Guardar nova senha'));
    await tester.pumpAndSettle();

    expect(repository.lastSetNew, 'NovaSenha2@');
    expect(find.text('Senha atualizada!'), findsOneWidget);
  });

  testWidgets('senha fraca bloqueia com a política do cadastro', (
    tester,
  ) async {
    final repository = _FakeAuthRepository();
    await tester.pumpWidget(_buildApp(repository));

    await tester.enterText(find.byType(TextFormField).at(0), 'fraca123');
    await tester.enterText(find.byType(TextFormField).at(1), 'fraca123');

    await tester.ensureVisible(find.text('Guardar nova senha'));
    await tester.tap(find.text('Guardar nova senha'));
    await tester.pumpAndSettle();

    expect(
      find.text('A senha deve conter letras, números e símbolos.'),
      findsOneWidget,
    );
    expect(repository.lastSetNew, isNull);
  });

  testWidgets('confirmação diferente bloqueia o envio', (tester) async {
    final repository = _FakeAuthRepository();
    await tester.pumpWidget(_buildApp(repository));

    await tester.enterText(find.byType(TextFormField).at(0), 'NovaSenha2@');
    await tester.enterText(find.byType(TextFormField).at(1), 'OutraSenha3#');

    await tester.ensureVisible(find.text('Guardar nova senha'));
    await tester.tap(find.text('Guardar nova senha'));
    await tester.pumpAndSettle();

    expect(find.text('As senhas não coincidem.'), findsOneWidget);
    expect(repository.lastSetNew, isNull);
  });

  testWidgets('same_password mostra mensagem específica (não o genérico)', (
    tester,
  ) async {
    final repository = _FakeAuthRepository()
      ..errorToThrow = const AuthApiException(
        'New password should be different from the old password.',
        statusCode: '422',
        code: 'same_password',
      );
    await tester.pumpWidget(_buildApp(repository));

    await tester.enterText(find.byType(TextFormField).at(0), 'NovaSenha2@');
    await tester.enterText(find.byType(TextFormField).at(1), 'NovaSenha2@');

    await tester.ensureVisible(find.text('Guardar nova senha'));
    await tester.tap(find.text('Guardar nova senha'));
    await tester.pumpAndSettle();

    expect(
      find.text('A nova senha deve ser diferente da atual.'),
      findsOneWidget,
    );
    expect(
      find.text('Não foi possível atualizar a senha. Tente novamente.'),
      findsNothing,
    );
  });

  testWidgets('sessão de recovery expirada manda pedir novo link', (
    tester,
  ) async {
    final repository = _FakeAuthRepository()
      ..errorToThrow = const AuthApiException(
        'Session not found',
        statusCode: '401',
        code: 'session_missing',
      );
    await tester.pumpWidget(_buildApp(repository));

    await tester.enterText(find.byType(TextFormField).at(0), 'NovaSenha2@');
    await tester.enterText(find.byType(TextFormField).at(1), 'NovaSenha2@');

    await tester.ensureVisible(find.text('Guardar nova senha'));
    await tester.tap(find.text('Guardar nova senha'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'O link de recuperação expirou ou já foi usado. Peça um novo link.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('erro sem mapeamento cai no genérico', (tester) async {
    final repository = _FakeAuthRepository()
      ..errorToThrow = const AuthApiException(
        'boom',
        statusCode: '500',
        code: 'unexpected_failure',
      );
    await tester.pumpWidget(_buildApp(repository));

    await tester.enterText(find.byType(TextFormField).at(0), 'NovaSenha2@');
    await tester.enterText(find.byType(TextFormField).at(1), 'NovaSenha2@');

    await tester.ensureVisible(find.text('Guardar nova senha'));
    await tester.tap(find.text('Guardar nova senha'));
    await tester.pumpAndSettle();

    expect(
      find.text('Não foi possível atualizar a senha. Tente novamente.'),
      findsOneWidget,
    );
  });
}
