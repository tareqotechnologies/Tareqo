import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import '../../../helpers/test_app.dart';

import 'package:tareqo/core/security/biometric_service.dart';
import 'package:tareqo/core/security/mfa_service.dart';
import 'package:tareqo/core/security/secure_storage_service.dart';
import 'package:tareqo/domain/usecases/biometric_auth_use_case.dart';
import 'package:tareqo/domain/usecases/mfa_auth_use_case.dart';
import 'package:tareqo/presentation/controllers/auth_providers.dart';
import 'package:tareqo/presentation/screens/account/security_settings_screen.dart';

/// Cobertura da tela de Segurança (A1 — auditoria: ~1% de cobertura).
///
/// Estratégia: use cases REAIS ([MFAAuthUseCase] / [BiometricAuthUseCase])
/// sobre o secure storage em memória + [BiometricService] fake (mesmo padrão
/// do app_lock_overlay_test — nunca toca no plugin nativo). O estado da tela
/// (switches) é derivado do storage e do "aparelho" simulado.
class _FakeBiometricService extends BiometricService {
  // Campos mutáveis: os testes reprogramam o "aparelho" entre cenários
  // (construtor vazio + atribuição no setUp — os defaults já são os
  // valores iniciais, então o lint unused_element_parameter fica satisfeito).
  bool available = false;
  bool result = true;
  int attempts = 0;

  @override
  Future<bool> get isAvailable async => available;

  @override
  Future<bool> authenticate({
    String localizedReason = '',
    String signInTitle = '',
    String biometricHint = '',
    String cancelButton = '',
    String fallbackTitle = '',
    String goToSettingsButton = '',
    String goToSettingsDescription = '',
    String lockOut = '',
    bool useErrorDialogs = true,
    bool stickyAuth = true,
    bool biometricOnly = false,
  }) async {
    attempts++;
    return result;
  }
}

/// O l10n pt exibe "Autenticação em Dois Fatores" DUAS vezes (título do
/// AppBar da tela raiz do teste + tile). Os finders usam o ÚLTIMO (o tile).
void main() {
  late SecureStorageService storage;
  late MFAAuthUseCase mfaUseCase;
  late _FakeBiometricService bioService;
  late BiometricAuthUseCase bioUseCase;

  setUp(() async {
    registerTestSecureStorage();
    storage = GetIt.instance<SecureStorageService>();
    mfaUseCase = MFAAuthUseCase(MFAService(), storage);
    bioService = _FakeBiometricService();
    bioService
      ..available = false
      ..result = true;
    bioUseCase = BiometricAuthUseCase(bioService, storage);
    // O backend em memória é um singleton GetIt partilhado por TODOS os
    // testes do arquivo — limpa o estado que um teste anterior deixou.
    await storage.delete(SecureStorageKeys.mfaEnabled);
    await storage.delete(SecureStorageKeys.mfaSecret);
    await storage.delete(SecureStorageKeys.biometricEnabled);
  });

  Future<void> openScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mfaAuthUseCaseProvider.overrideWithValue(mfaUseCase),
          biometricAuthUseCaseProvider.overrideWithValue(bioUseCase),
        ],
        child: testApp(home: const SecuritySettingsScreen()),
      ),
    );
    // Flush de _loadSettings (três awaits no secure storage + setState).
    await tester.pump(const Duration(milliseconds: 300));
  }

  Switch tileSwitch(WidgetTester tester, String title) {
    final tile = find
        .ancestor(of: find.text(title).last, matching: find.byType(Row))
        .first;
    return tester.widget<Switch>(
      find.descendant(of: tile, matching: find.byType(Switch)),
    );
  }

  testWidgets('renderiza MFA, troca de senha e biometria indisponível', (
    tester,
  ) async {
    await openScreen(tester); // aparelho SEM leitor biométrico (default)

    expect(find.text('Segurança'), findsOneWidget);
    expect(find.text('Autenticação em Dois Fatores'), findsWidgets);
    expect(find.text('Trocar senha'), findsOneWidget);
    // Sem leitor: tile informativo, SEM switch.
    expect(find.text('Não disponível neste dispositivo'), findsOneWidget);
    expect(
      find.descendant(
        of: find
            .ancestor(
              of: find.text('Não disponível neste dispositivo'),
              matching: find.byType(Container),
            )
            .first,
        matching: find.byType(Switch),
      ),
      findsNothing,
    );
  });

  testWidgets('switch do MFA reflete o estado persistido (ligado)', (
    tester,
  ) async {
    await storage.write(SecureStorageKeys.mfaEnabled, 'true');
    await openScreen(tester);

    final sw = tileSwitch(tester, 'Autenticação em Dois Fatores');
    expect(sw.value, isTrue);
    expect(find.text('Activada — Use um app autenticador'), findsOneWidget);
  });

  testWidgets('desligar o MFA apaga o estado do storage', (tester) async {
    await storage.write(SecureStorageKeys.mfaEnabled, 'true');
    await openScreen(tester);

    await tester.tap(find.byType(Switch).first);
    await tester.pump(const Duration(milliseconds: 300));

    expect(await mfaUseCase.isEnabled(), isFalse);
    expect(find.text('Adicione uma camada extra de segurança'), findsOneWidget);
  });

  testWidgets('ligar o MFA abre o setup (fluxo ativado via pop true)', (
    tester,
  ) async {
    await openScreen(tester);

    // O switch do MFA é o primeiro da tela (biometria indisponível = só ele).
    await tester.tap(find.byType(Switch).first);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));

    // A rota do MFASetupScreen foi empurrada (QR Code visível).
    expect(find.text('Escaneie o QR Code'), findsOneWidget);
  });

  testWidgets('biometria disponível e desligada: ligar EXIGE prompt e grava', (
    tester,
  ) async {
    bioService.available = true;
    await openScreen(tester);

    // Dois switches agora (MFA + biometria) — a biometria é o último.
    expect(find.byType(Switch), findsNWidgets(2));
    await tester.tap(find.byType(Switch).last);
    await tester.pump(const Duration(milliseconds: 300));

    // O prompt FOI exibido e a ativação gravada.
    expect(bioService.attempts, 1);
    expect(await bioUseCase.isEnabled(), isTrue);
    expect(find.text('Activada — Impressão digital ou rosto'), findsOneWidget);
  });

  testWidgets('prompt biométrico NEGADO não ativa a biometria', (tester) async {
    bioService.available = true;
    bioService.result = false;
    await openScreen(tester);

    await tester.tap(find.byType(Switch).last);
    await tester.pump(const Duration(milliseconds: 300));

    expect(bioService.attempts, 1);
    expect(await bioUseCase.isEnabled(), isFalse);
    // O tile permanece no estado desativado.
    expect(
      find.text('Use impressão digital ou reconhecimento facial'),
      findsOneWidget,
    );
  });

  testWidgets('biometria ligada: desligar NÃO pede prompt e limpa storage', (
    tester,
  ) async {
    bioService.available = true;
    await storage.write(SecureStorageKeys.biometricEnabled, 'true');
    await openScreen(tester);

    await tester.tap(find.byType(Switch).last);
    await tester.pump(const Duration(milliseconds: 300));

    // Desligar é local — nunca pede biometria para desativar.
    expect(bioService.attempts, 0);
    expect(await bioUseCase.isEnabled(), isFalse);
    expect(
      find.text('Use impressão digital ou reconhecimento facial'),
      findsOneWidget,
    );
  });
}
