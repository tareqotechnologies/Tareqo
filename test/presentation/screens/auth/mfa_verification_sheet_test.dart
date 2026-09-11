import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import '../../../helpers/test_app.dart';

import 'package:tareqo/core/security/mfa_service.dart';
import 'package:tareqo/core/security/secure_storage_service.dart';
import 'package:tareqo/domain/usecases/mfa_auth_use_case.dart';
import 'package:tareqo/presentation/controllers/auth_providers.dart';
import 'package:tareqo/presentation/screens/auth/mfa_verification_sheet.dart';

/// Fake que SEMPRE lança — cobre o caminho de exceção do `_verifyCode`
/// (snackbar de erro, sheet permanece aberta). Lança SINCRONAMENTE: o
/// `try/catch` da tela trata igual erro síncrono e assíncrono, e assim o
/// FakeAsync do teste nunca vê um erro não tratado.
/// `noSuchMethod` satisfaz a interface inteira sem reimplementar 8 métodos.
class _ThrowingMFAUseCase implements MFAAuthUseCase {
  int calls = 0;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #verifyCode) {
      calls++;
      throw Exception('boom');
    }
    return null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerTestSecureStorage();
  });

  late SecureStorageService storage;
  late MFAAuthUseCase mfaUseCase;

  setUp(() async {
    // O backend em memória é um singleton GetIt partilhado — limpa o estado
    // que um teste anterior deixou (mesmo padrão do mfa_setup_screen_test).
    storage = GetIt.instance<SecureStorageService>();
    await storage.delete(SecureStorageKeys.mfaEnabled);
    await storage.delete(SecureStorageKeys.mfaSecret);
    await storage.delete(SecureStorageKeys.biometricEnabled);
    mfaUseCase = MFAAuthUseCase(MFAService(), storage);
  });

  /// Apresenta o sheet por `push<bool>` de uma rota-base (em produção é
  /// `showAppSheet<bool>` a partir do [AuthGate]) — o pop tem para onde
  /// voltar.
  Future<void> openSheet(
    WidgetTester tester, {
    MFAAuthUseCase? useCase,
  }) async {
    // SEMPRE exatamente um override — Riverpod 3 lança se o mesmo provider
    // for sobrescrito duas vezes no mesmo container.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mfaAuthUseCaseProvider.overrideWithValue(useCase ?? mfaUseCase),
        ],
        child: testApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () async {
                    await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        // O [showAppSheet] de produção entrega o Material
                        // ancestor (Scaffold/bottom sheet) que o TextField
                        // exige — a rota de teste faz o mesmo.
                        builder: (_) => const Scaffold(
                          body: SafeArea(child: MFAVerificationSheet()),
                        ),
                      ),
                    );
                  },
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('renderiza título, dica, campo e os dois botões', (tester) async {
    await openSheet(tester);

    expect(find.text('Autenticação em Dois Fatores'), findsOneWidget);
    expect(
      find.text('Digite o código de 6 dígitos do seu aplicativo autenticador:'),
      findsOneWidget,
    );
    expect(find.text('Código MFA'), findsOneWidget);
    expect(find.text('Verificar'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
  });

  testWidgets('código curto mostra erro de tamanho e NÃO verifica',
      (tester) async {
    await openSheet(tester);

    await tester.enterText(find.byType(TextFormField), '123');
    await tester.tap(find.text('Verificar'));
    await tester.pump();

    expect(find.text('Digite o código de 6 dígitos'), findsOneWidget);
    // O sheet permanece aberto (nenhum pop).
    expect(find.text('Código MFA'), findsOneWidget);
  });

  testWidgets('código TOTP inválido mostra snackbar e permanece aberto',
      (tester) async {
    await mfaUseCase.generateSecret(); // segredo real, código errado
    await openSheet(tester);

    await tester.enterText(find.byType(TextFormField), '000000');
    await tester.tap(find.text('Verificar'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Código inválido. Tente novamente.'), findsOneWidget);
    expect(find.text('Código MFA'), findsOneWidget);
  });

  testWidgets('código TOTP REAL confirma e faz pop(true)', (tester) async {
    await mfaUseCase.generateSecret();
    await openSheet(tester);

    // Mesmo segredo + mesma janela de 30s → código válido.
    final secret = await storage.read(SecureStorageKeys.mfaSecret);
    final code = MFAService().generateTOTP(secret!);

    await tester.enterText(find.byType(TextFormField), code);
    await tester.tap(find.text('Verificar'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // pop(true) devolve o controle à rota-base.
    expect(find.text('Código MFA'), findsNothing);
  });

  testWidgets('Cancelar faz pop(false)', (tester) async {
    await openSheet(tester);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('Código MFA'), findsNothing);
  });

  testWidgets('exceção do use case mostra snackbar com o erro e reseta o spinner',
      (tester) async {
    final throwing = _ThrowingMFAUseCase();
    await openSheet(tester, useCase: throwing);

    await tester.enterText(find.byType(TextFormField), '123456');
    await tester.tap(find.text('Verificar'), warnIfMissed: true);
    await tester.pump(const Duration(milliseconds: 100));

    // O tap chegou ao botão: o use case foi invocado (e lançou).
    expect(throwing.calls, 1);

    await tester.pump(const Duration(milliseconds: 200));

    expect(
      find.textContaining('Erro ao verificar código'),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
    // Permanece aberto para nova tentativa.
    expect(find.text('Código MFA'), findsOneWidget);
  });
}
