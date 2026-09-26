import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../helpers/test_app.dart';

import 'package:tareqo/core/theme/app_theme.dart';
import 'package:tareqo/domain/entities/app_user.dart';
import 'package:tareqo/domain/entities/auth_event.dart';
import 'package:tareqo/domain/repositories/i_auth_repository.dart';
import 'package:tareqo/presentation/controllers/auth_providers.dart';
import 'package:tareqo/presentation/screens/auth/forgot_password_sheet.dart';
import 'package:tareqo/presentation/screens/auth/login_screen.dart';

class _FakeAuthRepository implements IAuthRepository {
  final _controller = StreamController<AppUser?>.broadcast();

  String? lastSignInEmail;
  String? lastSignInPassword;
  String? lastResetEmail;
  String? lastChangedTo;
  Exception? errorToThrow;
  Exception? signUpErrorToThrow;
  Exception? resetErrorToThrow;

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    if (signUpErrorToThrow != null) throw signUpErrorToThrow!;
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
  Future<void> resetPassword({required String email}) async {
    if (resetErrorToThrow != null) throw resetErrorToThrow!;
    lastResetEmail = email;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    lastChangedTo = newPassword;
  }

  @override
  Future<void> setNewPassword({required String newPassword}) async {}

  @override
  Stream<AppUser?> get authStateChanges => _controller.stream;

  @override
  Stream<AuthEvent> get authEvents => const Stream.empty();
}

Widget _buildApp(IAuthRepository repository, {ThemeData? theme}) {
  return ProviderScope(
    overrides: [authRepositoryProvider.overrideWithValue(repository)],
    child: testApp(theme: theme, home: const LoginScreen()),
  );
}

void main() {
  testWidgets('chama o signIn com as credenciais informadas', (tester) async {
    final repository = _FakeAuthRepository();
    await tester.pumpWidget(_buildApp(repository));
    await tester.enterText(find.byType(TextField).at(0), 'dono@loja.com');
    await tester.enterText(find.byType(TextField).at(1), 'segredo123');

    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(repository.lastSignInEmail, 'dono@loja.com');
    expect(repository.lastSignInPassword, 'segredo123');
  });

  testWidgets('exibe erro no SnackBar quando o signIn falha', (tester) async {
    final repository = _FakeAuthRepository()
      ..errorToThrow = Exception('credenciais inválidas');
    await tester.pumpWidget(_buildApp(repository));
    await tester.enterText(find.byType(TextField).at(0), 'dono@loja.com');
    await tester.enterText(find.byType(TextField).at(1), 'segredo123');

    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Não foi possível entrar'), findsOneWidget);
  });

  testWidgets('valida e-mail e senha antes de submeter', (tester) async {
    final repository = _FakeAuthRepository();
    await tester.pumpWidget(_buildApp(repository));

    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    // A validação virou NOTIFICAÇÃO (SnackBar): a primeira regra violada
    // aparece como aviso — sem texto fixo/truncado sob os campos.
    expect(find.text('Informe um e-mail válido.'), findsOneWidget);
    expect(find.text('A senha deve ter ao menos 8 caracteres.'), findsNothing);
    expect(repository.lastSignInEmail, isNull);
  });

  testWidgets('valida a força da senha no cadastro (4 classes)', (
    tester,
  ) async {
    final repository = _FakeAuthRepository();
    await tester.pumpWidget(
      _buildApp(repository),
    ); // Muda para o modo cadastro (link é um RichText; pode estar abaixo da
    // viewport de teste — rola até ele antes de tocar).
    final signUpLink = find.textContaining(
      'Ainda não tem uma conta?',
      findRichText: true,
    );
    await tester.ensureVisible(signUpLink);
    await tester.tap(signUpLink);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'Dono Teste');
    await tester.enterText(find.byType(TextField).at(1), 'dono@loja.com');
    // sem maiúscula e sem símbolo → falha a política do provedor.
    await tester.enterText(find.byType(TextField).at(2), 'senha123');
    await tester.enterText(find.byType(TextField).at(3), 'senha123');

    // O formulário de cadastro fica num SingleChildScrollView e o botão pode
    // estar abaixo da viewport de teste (600px) — rola até ele antes de tocar.
    await tester.ensureVisible(find.text('Cadastrar'));
    await tester.tap(find.text('Cadastrar'));
    await tester.pumpAndSettle();
    expect(
      find.text('A senha deve conter letras, números e símbolos.'),
      findsOneWidget,
    );
    // Nada foi enviado ao repositório.
    expect(repository.signUpErrorToThrow, isNull);
  });

  testWidgets(
    'mostra a política de senha quando o servidor rejeita senha fraca',
    (tester) async {
      final repository = _FakeAuthRepository()
        ..signUpErrorToThrow = AuthWeakPasswordException(
          message:
              'Password should contain at least one character of each class',
          statusCode: '422',
          reasons: ['characters'],
        );
      await tester.pumpWidget(
        _buildApp(repository),
      ); // Muda para o modo cadastro (link é um RichText; pode estar abaixo da
      // viewport de teste — rola até ele antes de tocar).
      final signUpLink = find.textContaining(
        'Ainda não tem uma conta?',
        findRichText: true,
      );
      await tester.ensureVisible(signUpLink);
      await tester.tap(signUpLink);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'Dono Teste');
      await tester.enterText(find.byType(TextField).at(1), 'dono@loja.com');
      // Senha forte passa na validação local; o servidor (fake) rejeita.
      await tester.enterText(find.byType(TextField).at(2), 'Senha1234!');
      await tester.enterText(find.byType(TextField).at(3), 'Senha1234!');

      await tester.ensureVisible(find.text('Cadastrar'));
      await tester.tap(find.text('Cadastrar'));
      await tester.pumpAndSettle();
      expect(
        find.text('A senha deve conter letras, números e símbolos.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Esqueceu a senha? envia o link de redefinição (e valida o e-mail)',
    (tester) async {
      final repository = _FakeAuthRepository();
      await tester.pumpWidget(
        _buildApp(repository),
      ); // O link só existe no modo login (cadastro não tem redefinição).
      // O link é um RichText — busca por trecho do texto.
      await tester.ensureVisible(
        find.textContaining('Ainda não tem uma conta?', findRichText: true),
      );
      await tester.tap(
        find.textContaining('Ainda não tem uma conta?', findRichText: true),
      );
      await tester.pumpAndSettle();
      expect(find.text('Esqueceu sua senha?'), findsNothing);

      // De volta ao login: o link aparece e abre a sheet.
      await tester.ensureVisible(
        find.textContaining('Já tem uma conta?', findRichText: true),
      );
      await tester.tap(
        find.textContaining('Já tem uma conta?', findRichText: true),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Esqueceu sua senha?'));
      await tester.tap(find.text('Esqueceu sua senha?'));
      await tester.pumpAndSettle();

      expect(find.byType(ForgotPasswordSheet), findsOneWidget);

      // E-mail inválido: bloqueia o envio com a mensagem do campo.
      await tester.enterText(
        find.descendant(
          of: find.byType(ForgotPasswordSheet),
          matching: find.byType(TextFormField),
        ),
        'nao-e-mail',
      );
      await tester.tap(find.text('Enviar link'));
      await tester.pumpAndSettle();
      expect(find.text('Informe um e-mail válido.'), findsOneWidget);
      expect(repository.lastResetEmail, isNull);

      // E-mail válido: envia o link e mostra a confirmação.
      await tester.enterText(
        find.descendant(
          of: find.byType(ForgotPasswordSheet),
          matching: find.byType(TextFormField),
        ),
        'dono@loja.com',
      );
      await tester.tap(find.text('Enviar link'));
      await tester.pumpAndSettle();

      expect(repository.lastResetEmail, 'dono@loja.com');
      expect(
        find.textContaining('Se existir uma conta, enviamos um link'),
        findsOneWidget,
      );
    },
  );

  testWidgets('mostra aviso de limite quando o servidor responde 429', (
    tester,
  ) async {
    final repository = _FakeAuthRepository()
      ..signUpErrorToThrow = const AuthApiException(
        'email rate limit exceeded',
        statusCode: '429',
      );
    await tester.pumpWidget(
      _buildApp(repository),
    ); // Muda para o modo cadastro (link é um RichText; pode estar abaixo da
    // viewport de teste — rola até ele antes de tocar).
    final signUpLink = find.textContaining(
      'Ainda não tem uma conta?',
      findRichText: true,
    );
    await tester.ensureVisible(signUpLink);
    await tester.tap(signUpLink);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'Dono Teste');
    await tester.enterText(find.byType(TextField).at(1), 'dono@loja.com');
    await tester.enterText(find.byType(TextField).at(2), 'Senha1234!');
    await tester.enterText(find.byType(TextField).at(3), 'Senha1234!');

    await tester.ensureVisible(find.text('Cadastrar'));
    await tester.tap(find.text('Cadastrar'));
    await tester.pumpAndSettle();
    expect(
      find.text('Muitas tentativas. Aguarde 1 hora e tente novamente.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'modo claro: fundo claro, texto escuro e ícones de sistema escuros',
    (tester) async {
      final repository = _FakeAuthRepository();
      await tester.pumpWidget(_buildApp(repository, theme: AppTheme.light));
      await tester.pumpAndSettle();

      // Fundo do scaffold = neutro claro do AppTheme.light.
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, const Color(0xFFFAFAFA));

      // Título em texto escuro (não o branco do dark premium).
      final title = tester.widget<Text>(find.text('TAREQO'));
      expect(title.style?.color, AppColors.onSurfaceLight);

      // System UI (status bar / navegação) com ícones escuros sobre claro.
      final overlay = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
        find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
      );
      expect(overlay.value.statusBarIconBrightness, Brightness.dark);
      expect(overlay.value.systemNavigationBarColor, const Color(0xFFFAFAFA));
      expect(overlay.value.systemNavigationBarIconBrightness, Brightness.dark);
    },
  );

  testWidgets('modo escuro: mantém o dark premium e ícones claros', (
    tester,
  ) async {
    final repository = _FakeAuthRepository();
    await tester.pumpWidget(_buildApp(repository, theme: AppTheme.dark));
    await tester.pumpAndSettle();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, AppColors.backgroundDark);      // Título na escala (Large Title 4.5): a cor vem do scheme — branco
      // quase puro do tema escuro (mesmo par auditado de contraste).
      final title = tester.widget<Text>(find.text('TAREQO'));
      expect(title.style?.color, AppTheme.dark.colorScheme.onSurface);

    final overlay = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
      find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
    );
    expect(overlay.value.statusBarIconBrightness, Brightness.light);
    expect(overlay.value.systemNavigationBarColor, AppColors.backgroundDark);
    expect(overlay.value.systemNavigationBarIconBrightness, Brightness.light);
  });

  testWidgets(
    'Large Title (4.5): título segue a escala (displaySmall 34/w300) e o '
    'header desliza a meia velocidade do conteúdo (parallax)',
    (tester) async {
      final repository = _FakeAuthRepository();
      await tester.pumpWidget(_buildApp(repository));
      await tester.pumpAndSettle();

      // Título na escala tipográfica — o papel "Large Title —
      // login/boas-vindas" do `displaySmall` (34/w300, tracking negativo).
      final title = tester.widget<Text>(find.text('TAREQO'));
      expect(title.style?.fontSize, 34);
      expect(title.style?.fontWeight, FontWeight.w300);

      // Em repouso (sem scroll) o translate é 0 — a página renderiza
      // pixel-idêntica ao layout estático.
      Transform headerAtRest() => tester.widget<Transform>(
        find
            .ancestor(of: find.text('TAREQO'), matching: find.byType(Transform))
            .first,
      );
      expect(headerAtRest().transform.getRow(1)[3], 0.0);

      // Viewport curta → scroll real; arrastar 120px desliza o header
      // só 60px (0.5× — profundidade iOS do item 4.5 do plano).
      tester.view.physicalSize = const Size(800, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpAndSettle();

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -120),
      );
      await tester.pumpAndSettle();

      expect(headerAtRest().transform.getRow(1)[3], 60.0);
    },
  );

  testWidgets(
    'disableAnimations (acessibilidade): parallax desligado — o header rola '
    'à velocidade normal, nada se move sozinho',
    (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );

      final repository = _FakeAuthRepository();
      tester.view.physicalSize = const Size(800, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_buildApp(repository));
      await tester.pumpAndSettle();

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -120),
      );
      await tester.pumpAndSettle();

      final header = tester.widget<Transform>(
        find
            .ancestor(of: find.text('TAREQO'), matching: find.byType(Transform))
            .first,
      );
      expect(header.transform.getRow(1)[3], 0.0);
    },
  );
}
