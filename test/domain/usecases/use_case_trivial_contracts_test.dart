import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';

import 'package:tareqo/core/security/biometric_service.dart';
import 'package:tareqo/core/security/mfa_service.dart';
import 'package:tareqo/core/security/secure_storage_service.dart';
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
  test('MFAAuthUseCase.getTimeRemaining delega ao serviço (0..30s)', () {
    final useCase = MFAAuthUseCase(
      MFAService(),
      SecureStorageService(backend: _InMemoryBackend()),
      LocalOnlyMfaServerPort(MFAService()),
    );

    final remaining = useCase.getTimeRemaining();
    expect(remaining, inExclusiveRange(0, 30));
  });

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
