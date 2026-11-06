import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';

import 'package:tareqo/core/security/biometric_service.dart';
import 'package:tareqo/core/security/mfa_service.dart';
import 'package:tareqo/core/security/secure_storage_service.dart';
import 'package:tareqo/core/utils/app_clock.dart';
import 'package:tareqo/domain/usecases/biometric_auth_use_case.dart';
import 'package:tareqo/domain/usecases/mfa_auth_use_case.dart';

/// Backend em memória (mesmo padrão dos demais testes de segurança).
class _InMemoryBackend implements SecureStorageBackend {
  @override
  Future<String?> read(String key) async => null;

  @override
  Future<void> write(String key, String value) async {}

  @override
  Future<void> delete(String key) async {}
}

void main() {
  test('MFAAuthUseCase.getTimeRemaining delega ao serviço (1..30s)', () {
    final useCase = MFAAuthUseCase(
      MFAService(),
      SecureStorageService(backend: _InMemoryBackend()),
      LocalOnlyMfaServerPort(MFAService()),
    );

    final remaining = useCase.getTimeRemaining();
    // 1..30 (fechado): no múltiplo exato a janela inteira resta (30),
    // nunca 0 — TOTP nunca fica sem tempo dentro do período corrente.
    expect(remaining, inInclusiveRange(1, 30));
  });

  test(
    'getTimeRemaining: relógio injetado nos limites da janela (flake fix)',
    () {
      final service = MFAService();

      // Instante do bug: múltiplo EXATO de 30s → antes devolvia 30 no
      // limite `inExclusiveRange(0, 30)` (falhava 1 em 30 execuções,
      // conforme o relógio da máquina).
      AppClock.inject(
        () => DateTime.fromMillisecondsSinceEpoch(30 * 1000, isUtc: true),
      );
      addTearDown(AppClock.reset);
      expect(service.getTimeRemaining(), 30); // janela completa, não 0

      // 1s dentro da janela → 29 restantes.
      AppClock.inject(
        () => DateTime.fromMillisecondsSinceEpoch(31 * 1000, isUtc: true),
      );
      expect(service.getTimeRemaining(), 29);
    },
  );

  test(
    'BiometricAuthUseCase.getAvailableBiometrics mapeia tipos para String',
    () async {
      final useCase = BiometricAuthUseCase(
        BiometricService(),
        SecureStorageService(backend: _InMemoryBackend()),
      );

      // Sem plataforma os tipos vêm vazios (fail-closed) — o contrato é
      // o TIPO (List<String>) e a ausência de exceção.
      final types = await useCase.getAvailableBiometrics();
      expect(types, isA<List<String>>());
      expect(types, isEmpty);
      // Prova de tipo do domínio usado pelo serviço real:
      expect(BiometricType.strong, isA<BiometricType>());
    },
  );
}
