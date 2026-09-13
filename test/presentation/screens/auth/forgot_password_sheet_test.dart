import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../helpers/test_app.dart';

import 'package:tareqo/domain/entities/app_user.dart';
import 'package:tareqo/domain/entities/auth_event.dart';
import 'package:tareqo/domain/repositories/i_auth_repository.dart';
import 'package:tareqo/presentation/controllers/auth_providers.dart';
import 'package:tareqo/presentation/screens/auth/forgot_password_sheet.dart';
import 'package:tareqo/presentation/widgets/app_sheet.dart';

/// Repositório falso de auth — grava o e-mail do reset e permite simular
/// os erros do provedor (429 rate limit, erro genérico, exceção de rede).
class _FakeAuthRepository implements IAuthRepository {
  final _controller = StreamController<AppUser?>.broadcast();

  String? lastResetEmail;
  int resetCalls = 0;
  AuthApiException? apiErrorToThrow;
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
  Future<void> resetPassword({required String email}) async {
    lastResetEmail = email;
    resetCalls++;
    if (apiErrorToThrow != null) throw apiErrorToThrow!;
    if (errorToThrow != null) throw errorToThrow!;
  }

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

Widget _buildApp(_FakeAuthRepository repository) {
  return ProviderScope(
    overrides: [authRepositoryProvider.overrideWithValue(repository)],
    child: testApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showAppSheet<void>(
                context,
                builder: (_) => const ForgotPasswordSheet(),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _openAndSubmit(
  WidgetTester tester,
  _FakeAuthRepository repo,
  String email,
) async {
  await tester.pumpWidget(_buildApp(repo));
  await tester.pumpAndSettle();

  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();

  await tester.enterText(find.byType(TextField).first, email);
  await tester.tap(find.text('Enviar link'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('fluxo de sucesso: envia o link com o e-mail trimmed e fecha', (
    tester,
  ) async {
    final repo = _FakeAuthRepository();
    await _openAndSubmit(tester, repo, '  dono@test.local  ');

    // then — o e-mail chega ao repositório sem espaços e a sheet fecha.
    expect(repo.resetCalls, 1);
    expect(repo.lastResetEmail, 'dono@test.local');
    // Sheet fechada: mensagem de sucesso visível.
    expect(
      find.text('Se existir uma conta, enviamos um link.'),
      findsOneWidget,
    );
  });

  testWidgets('e-mail inválido é bloqueado pela validação do formulário', (
    tester,
  ) async {
    final repo = _FakeAuthRepository();
    await tester.pumpWidget(_buildApp(repo));
    await tester.pumpAndSettle();
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'nao-e-email');
    await tester.tap(find.text('Enviar link'));
    await tester.pumpAndSettle();

    // Nada foi enviado (o Form não valida) e a sheet segue aberta.
    expect(repo.resetCalls, 0);
    expect(find.text('Enviar link'), findsOneWidget);
  });

  testWidgets('erro 429 do provedor mostra a mensagem de rate limit', (
    tester,
  ) async {
    final repo = _FakeAuthRepository()
      ..apiErrorToThrow = const AuthApiException(
        'Too many requests',
        statusCode: '429',
      );
    await _openAndSubmit(tester, repo, 'dono@test.local');

    expect(
      find.text('Muitas tentativas. Aguarde 1 hora e tente novamente.'),
      findsOneWidget,
    );
    // Sem mensagem de sucesso.
    expect(find.text('Se existir uma conta, enviamos um link.'), findsNothing);
  });

  testWidgets('erro 400 genérico do provedor mostra a mensagem de erro', (
    tester,
  ) async {
    final repo = _FakeAuthRepository()
      ..apiErrorToThrow = const AuthApiException(
        'bad request',
        statusCode: '400',
      );
    await _openAndSubmit(tester, repo, 'dono@test.local');

    // O ramo de erro do AuthApiException anexa o detalhe da API à mensagem
    // localizada ("mensagem\n(detalhe)").
    expect(
      find.textContaining('Não foi possível enviar o link'),
      findsOneWidget,
    );
    expect(find.textContaining('bad request'), findsOneWidget);
    expect(find.text('Se existir uma conta, enviamos um link.'), findsNothing);
  });

  testWidgets('exceção inesperada (sem rede) mostra a mensagem de erro', (
    tester,
  ) async {
    final repo = _FakeAuthRepository()
      ..errorToThrow = Exception('SocketException');
    await _openAndSubmit(tester, repo, 'dono@test.local');

    expect(
      find.text('Não foi possível enviar o link. Tente novamente.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'anti-enumeração: a resposta de erro NUNCA inclui o e-mail (PII)',
    (tester) async {
      // Erro 404 (conta inexistente): o snackbar mostra a mensagem
      // localizada + detalhe da API, mas NUNCA o e-mail digitado. A
      // neutralidade do SUCESSO é asserção do teste de sucesso acima
      // ("Se existir uma conta...").
      final repo = _FakeAuthRepository()
        ..apiErrorToThrow = const AuthApiException(
          'user not found',
          statusCode: '404',
        );
      await _openAndSubmit(tester, repo, 'dono@test.local');

      final snackTexts = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byType(SnackBar),
              matching: find.byType(Text),
            ),
          )
          .map((t) => t.data ?? '')
          .join('\n');
      expect(snackTexts, contains('Não foi possível enviar o link'));
      expect(snackTexts, contains('user not found'));
      expect(snackTexts, isNot(contains('dono@test.local')));
    },
  );
}
