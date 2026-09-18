import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../helpers/test_app.dart';

import 'package:tareqo/core/security/mfa_service.dart';
import 'package:tareqo/core/security/secure_storage_service.dart';
import 'package:tareqo/domain/usecases/mfa_auth_use_case.dart';
import 'package:tareqo/presentation/controllers/auth_providers.dart';
import 'package:tareqo/presentation/screens/auth/mfa_setup_screen.dart';

/// Cobertura do fluxo de SETUP de MFA (A1 — auditoria: a tela tinha ~1% de
/// cobertura). Usa o [MFAAuthUseCase] REAL sobre o secure storage em memória
/// ([registerTestSecureStorage]) e o [MFAService] real (TOTP via package:otp
/// — puro Dart, sem plataforma): o teste valida o contrato TOTP de verdade.
///
/// ⚠️ A tela roda um Timer.periodic de 1s (contador "expira em") — NUNCA use
/// `pumpAndSettle` (nunca assentaria). Use `pump(duração)`.
void main() {
  late SecureStorageService storage;
  late MFAAuthUseCase mfaUseCase;

  setUp(() async {
    registerTestSecureStorage();
    storage = GetIt.instance<SecureStorageService>();
    // P1: o use case orquestra o servidor — nos testes, o fallback local.
    mfaUseCase = MFAAuthUseCase(
      MFAService(),
      storage,
      LocalOnlyMfaServerPort(MFAService()),
    );
    // O backend em memória é um singleton GetIt partilhado por TODOS os
    // testes do arquivo — limpa o estado que um teste anterior deixou.
    await storage.delete(SecureStorageKeys.mfaEnabled);
    await storage.delete(SecureStorageKeys.mfaSecret);
    await storage.delete(SecureStorageKeys.biometricEnabled);
  });

  Future<void> openSetup(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [mfaAuthUseCaseProvider.overrideWithValue(mfaUseCase)],
        child: testApp(home: const MFASetupScreen()),
      ),
    );
    // Flush de _initializeMFA (generateSecret + generateQRCodeData + setState
    // + _startTimer).
    await tester.pump(const Duration(milliseconds: 200));
  }

  testWidgets('renderiza o setup completo: QR, segredo manual e campo', (
    tester,
  ) async {
    await openSetup(tester);

    expect(
      find.text('Configurar Autenticação em Dois Fatores'),
      findsOneWidget,
    );
    expect(find.text('Escaneie o QR Code'), findsOneWidget);
    // O segredo gerado aparece para entrada manual (base32, ≥16 chars).
    expect(find.text('Ou digite este código manualmente:'), findsOneWidget);
    expect(
      find.text('Digite o código do aplicativo para confirmar:'),
      findsOneWidget,
    );
    expect(find.text('Código de 6 dígitos'), findsOneWidget);
    expect(find.text('Verificar e Activar'), findsOneWidget);
    // O QR Code foi renderizado de fato.
    expect(find.byType(QrImageView), findsOneWidget);
  });

  testWidgets('a11y: o botão fechar do AppBar tem tooltip', (tester) async {
    await openSetup(tester);

    // Leitor de ecrã anuncia a ação (mesmo padrão das outras telas).
    expect(find.byTooltip('Fechar'), findsOneWidget);
  });

  testWidgets('grava o segredo no storage ANTES de marcar MFA como ativo', (
    tester,
  ) async {
    await openSetup(tester);

    // O segredo existe no storage (persistido no generateSecret)…
    expect(await storage.read(SecureStorageKeys.mfaSecret), isNotNull);
    // …mas o MFA ainda NÃO está ativado (só após verificar um código —
    // invariante de segurança: setup ≠ ativação).
    expect(await mfaUseCase.isEnabled(), isFalse);
  });

  testWidgets('código com menos de 6 dígitos mostra erro e não ativa', (
    tester,
  ) async {
    await openSetup(tester);

    await tester.enterText(find.byType(TextFormField), '123');
    await tester.ensureVisible(find.byType(FilledButton));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byType(FilledButton));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Digite o código de 6 dígitos'), findsOneWidget);
    // Continua na tela (não houve pop) e MFA segue desativado.
    expect(
      find.text('Configurar Autenticação em Dois Fatores'),
      findsOneWidget,
    );
    expect(await mfaUseCase.isEnabled(), isFalse);
  });

  testWidgets('código TOTP inválido mostra erro e não ativa nem popa', (
    tester,
  ) async {
    await openSetup(tester);

    await tester.enterText(find.byType(TextFormField), '000000');
    await tester.ensureVisible(find.byType(FilledButton));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byType(FilledButton));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Código inválido. Tente novamente.'), findsOneWidget);
    expect(
      find.text('Configurar Autenticação em Dois Fatores'),
      findsOneWidget,
    );
    expect(await mfaUseCase.isEnabled(), isFalse);
  });

  testWidgets('código TOTP válido confirma e ativa o MFA (pop true)', (
    tester,
  ) async {
    // A tela é empurrada de uma rota-base — capturamos o resultado do pop
    // (SecuritySettingsScreen usa `push<bool>` e espera `true`).
    bool? setupResult;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [mfaAuthUseCaseProvider.overrideWithValue(mfaUseCase)],
        child: testApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () async {
                    setupResult = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(builder: (_) => const MFASetupScreen()),
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
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));

    // Código TOTP REAL do segredo persistido (mesma janela de 30s).
    final secret = await storage.read(SecureStorageKeys.mfaSecret);
    final code = MFAService().generateTOTP(secret!);

    // O SelectableText do segredo manual também é um EditableText — o
    // finder de TextFormField isola o campo do código (único na rota).
    await tester.enterText(find.byType(TextFormField), code);
    await tester.ensureVisible(find.byType(FilledButton));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byType(FilledButton));
    await tester.pump(const Duration(milliseconds: 400));

    // Sucesso: pop(true) — a rota-base reaparece. A snackbar fica no
    // ScaffoldMessenger (persiste no pop) e é entregue ao Scaffold raiz;
    // dá tempo dela entrar ANTES do pump do timer (o app falso também
    // tem um TextButton 'abrir' — same finder do botão-base).
    expect(find.textContaining('MFA configurado com sucesso'), findsWidgets);
    expect(find.text('abrir'), findsOneWidget);
    expect(setupResult, isTrue);
    // O MFA agora está ATIVO no storage.
    expect(await mfaUseCase.isEnabled(), isTrue);
  });

  testWidgets(
    'contador "expira em" avança com o timer de 1s (determinístico)',
    (tester) async {
      // O contador da tela lê `MFAAuthUseCase.getTimeRemaining()`, que é
      // baseado em DateTime.now() REAL — o pump(2s) do framework só avança o
      // relógio FAKE, então o teste original dependia de um segundo real
      // passar durante a execução (flaky sob carga). Aqui o use case é
      // espiado: o timer PERIÓDICO de 1s continua sendo o comportamento em
      // teste, mas a fonte de tempo é controlada pelo teste.
      // A tela nasce com 30 (valor padrão do initState) e o primeiro tick
      // do Timer.periodic de 1s traz o valor do use case.
      var remaining = 28;
      final controlled = _ControlledTimeMfaUseCase(
        MFAService(),
        storage,
        LocalOnlyMfaServerPort(MFAService()),
        () => remaining,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [mfaAuthUseCaseProvider.overrideWithValue(controlled)],
          child: testApp(home: const MFASetupScreen()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.textContaining('Código expira em'), findsOneWidget);
      final before = tester
          .widget<Text>(find.textContaining('Código expira em').first)
          .data!;
      expect(before, contains('30'));

      // Ticks do relógio fake: 1s traz o 28 controlado; 2s traz o 26.
      remaining = 28;
      await tester.pump(const Duration(seconds: 1));
      expect(
        tester
            .widget<Text>(find.textContaining('Código expira em').first)
            .data!,
        contains('28'),
        reason: 'o primeiro tick deve puxar o valor do use case',
      );

      remaining = 26;
      await tester.pump(const Duration(seconds: 1));

      final after = tester
          .widget<Text>(find.textContaining('Código expira em').first)
          .data!;
      expect(after, contains('26'), reason: 'o contador deve re-renderizar');
    },
  );
}

/// Subclasse que controla apenas `getTimeRemaining` (fonte de tempo do
/// contador); todo o resto delega ao use case real sobre o storage em
/// memória — o fluxo TOTP de verdade continua exercitado nos demais testes.
class _ControlledTimeMfaUseCase extends MFAAuthUseCase {
  _ControlledTimeMfaUseCase(
    super.mfaService,
    super.secureStorage,
    super.serverPort,
    this._remaining,
  );

  final int Function() _remaining;

  @override
  int getTimeRemaining() => _remaining();
}
