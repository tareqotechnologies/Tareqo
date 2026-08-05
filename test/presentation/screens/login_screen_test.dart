import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

import 'package:dumbhanengue/domain/entities/app_user.dart';
import 'package:dumbhanengue/domain/repositories/i_auth_repository.dart';
import 'package:dumbhanengue/presentation/controllers/auth_providers.dart';
import 'package:dumbhanengue/presentation/screens/auth/login_screen.dart';

class _FakeAuthRepository implements IAuthRepository {
  final _controller = StreamController<AppUser?>.broadcast();

  String? lastSignInEmail;
  String? lastSignInPassword;
  Exception? errorToThrow;

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
    if (errorToThrow != null) throw errorToThrow!;
    lastSignInEmail = email;
    lastSignInPassword = password;
    return AppUser(id: '1', email: email);
  }

  @override
  Future<void> signOut() async {}

  @override
  Stream<AppUser?> get authStateChanges => _controller.stream;
}

Widget _buildApp(IAuthRepository repository) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(repository),
    ],
    child: testApp(home: LoginScreen()),
  );
}

void main() {
  testWidgets('chama o signIn com as credenciais informadas', (tester) async {
    final repository = _FakeAuthRepository();
    await tester.pumpWidget(_buildApp(repository));

    await tester.enterText(find.byType(TextFormField).at(0), 'dono@loja.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'segredo123');

    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(repository.lastSignInEmail, 'dono@loja.com');
    expect(repository.lastSignInPassword, 'segredo123');
  });

  testWidgets('exibe erro no SnackBar quando o signIn falha', (tester) async {
    final repository = _FakeAuthRepository()
      ..errorToThrow = Exception('credenciais inválidas');
    await tester.pumpWidget(_buildApp(repository));

    await tester.enterText(find.byType(TextFormField).at(0), 'dono@loja.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'segredo123');

    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Não foi possível entrar'),
      findsOneWidget,
    );
  });

  testWidgets('valida e-mail e senha antes de submeter', (tester) async {
    final repository = _FakeAuthRepository();
    await tester.pumpWidget(_buildApp(repository));

    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Informe um e-mail válido.'), findsOneWidget);
    expect(find.text('A senha deve ter ao menos 8 caracteres.'), findsOneWidget);
    expect(repository.lastSignInEmail, isNull);
  });
}
