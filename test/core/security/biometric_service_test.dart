import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth_platform_interface/local_auth_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:tareqo/core/security/biometric_service.dart';

/// Fake da plataforma de biometria (mesmo padrão do teste oficial do
/// plugin `local_auth`, que troca [LocalAuthPlatform.instance]): permite
/// simular sucesso, recusa, exceções e os tipos de biometria matriculados.
class _FakeLocalAuthPlatform extends LocalAuthPlatform
    with MockPlatformInterfaceMixin {
  _FakeLocalAuthPlatform({
    this.canCheckBiometrics = false,
    this.deviceSupported = false,
    this.enrolled = const [],
    this.authenticateResult = false,
    this.authenticateError,
    this.getBiometricsError,
    this.stopError,
  });

  final bool canCheckBiometrics;
  final bool deviceSupported;
  final List<BiometricType> enrolled;
  final bool authenticateResult;
  final Object? authenticateError;
  final Object? getBiometricsError;
  final Object? stopError;

  String? capturedLocalizedReason;
  bool stopCalled = false;

  @override
  Future<bool> deviceSupportsBiometrics() async => canCheckBiometrics;

  @override
  Future<bool> isDeviceSupported() async => deviceSupported;

  @override
  Future<List<BiometricType>> getEnrolledBiometrics() async {
    final error = getBiometricsError;
    if (error != null) throw error;
    return enrolled;
  }

  @override
  Future<bool> authenticate({
    required String localizedReason,
    required Iterable<AuthMessages> authMessages,
    AuthenticationOptions options = const AuthenticationOptions(),
  }) async {
    capturedLocalizedReason = localizedReason;
    final error = authenticateError;
    if (error != null) throw error;
    return authenticateResult;
  }

  @override
  Future<bool> stopAuthentication() async {
    stopCalled = true;
    final error = stopError;
    if (error != null) throw error;
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeLocalAuthPlatform platform;
  // Guarda a instância original (canal de método) para restaurar no
  // tearDown — evita vazamento do fake para outros testes do processo.
  final originalPlatform = LocalAuthPlatform.instance;

  setUp(() {
    platform = _FakeLocalAuthPlatform();
    LocalAuthPlatform.instance = platform;
  });

  tearDown(() {
    LocalAuthPlatform.instance = originalPlatform;
  });

  group('BiometricService.isAvailable', () {
    test('deve retornar true quando o dispositivo suporta e há biometria', () {
      // given
      LocalAuthPlatform.instance = _FakeLocalAuthPlatform(
        canCheckBiometrics: true,
        deviceSupported: true,
      );
      final service = BiometricService();

      // when / then
      expect(service.isAvailable, completion(isTrue));
    });

    test(
      'deve retornar false quando a checagem de biometria falha mesmo com dispositivo suportado',
      () {
        // given
        LocalAuthPlatform.instance = _FakeLocalAuthPlatform(
          canCheckBiometrics: false,
          deviceSupported: true,
        );
        final service = BiometricService();

        // when / then
        expect(service.isAvailable, completion(isFalse));
      },
    );

    test(
      'deve retornar false quando o dispositivo não é suportado mesmo com biometria',
      () {
        // given
        LocalAuthPlatform.instance = _FakeLocalAuthPlatform(
          canCheckBiometrics: true,
          deviceSupported: false,
        );
        final service = BiometricService();

        // when / then
        expect(service.isAvailable, completion(isFalse));
      },
    );

    test('deve retornar false quando a plataforma lança exceção', () {
      // given — erro de hardware/plugin não pode propagar para o chamador.
      LocalAuthPlatform.instance = _FakeLocalAuthPlatform(
        canCheckBiometrics: true,
        deviceSupported: true,
      );
      // O getter lança ao ser invocado — simulado através do `authenticate`
      // não é possível; usamos um fake cujo getter de biometria lança e
      // `canCheckBiometrics` do serviço consulta via platform fake abaixo.
      final throwing = _ThrowingPlatform();
      LocalAuthPlatform.instance = throwing;
      final service = BiometricService();

      // when / then
      expect(service.isAvailable, completion(isFalse));
    });
  });

  group('BiometricService.getAvailableBiometrics', () {
    test('deve retornar a lista de biometrias matriculadas', () {
      // given
      LocalAuthPlatform.instance = _FakeLocalAuthPlatform(
        enrolled: const [BiometricType.fingerprint, BiometricType.face],
      );
      final service = BiometricService();

      // when / then
      expect(
        service.getAvailableBiometrics(),
        completion(
          containsAll(<BiometricType>[
            BiometricType.fingerprint,
            BiometricType.face,
          ]),
        ),
      );
    });

    test('deve retornar lista vazia quando a plataforma lança exceção', () {
      // given — dispositivo sem suporte lança no plugin oficial.
      LocalAuthPlatform.instance = _FakeLocalAuthPlatform(
        getBiometricsError: PlatformException(code: 'notAvailable'),
      );
      final service = BiometricService();

      // when / then
      expect(service.getAvailableBiometrics(), completion(isEmpty));
    });
  });

  group('BiometricService.authenticate', () {
    test(
      'deve retornar true quando a autenticação biométrica é bem-sucedida',
      () {
        // given
        LocalAuthPlatform.instance = _FakeLocalAuthPlatform(
          authenticateResult: true,
        );
        final service = BiometricService();

        // when / then
        expect(
          service.authenticate(localizedReason: 'Abrir o app'),
          completion(isTrue),
        );
      },
    );

    test('deve retornar false quando o usuário cancela o prompt', () {
      // given — cancelamento do usuário é recusa (false), não exceção.
      LocalAuthPlatform.instance = _FakeLocalAuthPlatform(
        authenticateResult: false,
      );
      final service = BiometricService();

      // when / then
      expect(
        service.authenticate(localizedReason: 'Abrir o app'),
        completion(isFalse),
      );
    });

    test(
      'deve retornar false (sem propagar) quando a plataforma lança PlatformException',
      () {
        // given — lockout, hardware ausente etc.
        LocalAuthPlatform.instance = _FakeLocalAuthPlatform(
          authenticateError: PlatformException(code: 'lockout'),
        );
        final service = BiometricService();

        // when / then
        expect(
          service.authenticate(localizedReason: 'Abrir o app'),
          completion(isFalse),
        );
      },
    );

    test('deve retornar false quando ocorre erro inesperado', () {
      // given
      LocalAuthPlatform.instance = _FakeLocalAuthPlatform(
        authenticateError: StateError('boom'),
      );
      final service = BiometricService();

      // when / then
      expect(
        service.authenticate(localizedReason: 'Abrir o app'),
        completion(isFalse),
      );
    });

    test(
      'deve encaminhar a razão localizada para o prompt do sistema',
      () async {
        // given — o motivo vem do l10n ativo (auditoria M3); o serviço
        // deve repassá-lo sem alteração.
        final platform = _FakeLocalAuthPlatform(authenticateResult: true);
        LocalAuthPlatform.instance = platform;
        final service = BiometricService();

        // when
        await service.authenticate(localizedReason: 'Confirme sua identidade');

        // then
        expect(platform.capturedLocalizedReason, 'Confirme sua identidade');
      },
    );
  });

  group('BiometricService.hasFingerprint / hasFace / hasIris', () {
    test('deve detectar impressão digital matriculada', () {
      // given
      LocalAuthPlatform.instance = _FakeLocalAuthPlatform(
        enrolled: const [BiometricType.fingerprint],
      );
      final service = BiometricService();

      // when / then
      expect(service.hasFingerprint, completion(isTrue));
      expect(service.hasFace, completion(isFalse));
      expect(service.hasIris, completion(isFalse));
    });

    test('deve tratar biometria forte como impressão digital', () {
      // given — `strong` (classe Android moderna) conta como digital.
      LocalAuthPlatform.instance = _FakeLocalAuthPlatform(
        enrolled: const [BiometricType.strong],
      );
      final service = BiometricService();

      // when / then
      expect(service.hasFingerprint, completion(isTrue));
      expect(service.hasFace, completion(isFalse));
    });

    test('deve detectar reconhecimento facial matriculado', () {
      // given
      LocalAuthPlatform.instance = _FakeLocalAuthPlatform(
        enrolled: const [BiometricType.face],
      );
      final service = BiometricService();

      // when / then
      expect(service.hasFace, completion(isTrue));
      expect(service.hasFingerprint, completion(isFalse));
    });

    test('deve detectar íris matriculada', () {
      // given
      LocalAuthPlatform.instance = _FakeLocalAuthPlatform(
        enrolled: const [BiometricType.iris],
      );
      final service = BiometricService();

      // when / then
      expect(service.hasIris, completion(isTrue));
      expect(service.hasFingerprint, completion(isFalse));
      expect(service.hasFace, completion(isFalse));
    });

    test(
      'deve retornar false para todos quando nenhuma biometria está matriculada',
      () {
        // given — lista vazia (dispositivo sem enrolamento).
        LocalAuthPlatform.instance = _FakeLocalAuthPlatform(enrolled: const []);
        final service = BiometricService();

        // when / then
        expect(service.hasFingerprint, completion(isFalse));
        expect(service.hasFace, completion(isFalse));
        expect(service.hasIris, completion(isFalse));
      },
    );
  });

  group('BiometricService.stopAuthentication', () {
    test('deve encerrar a autenticação em andamento sem erro', () async {
      // given
      final platform = _FakeLocalAuthPlatform();
      LocalAuthPlatform.instance = platform;
      final service = BiometricService();

      // when
      await service.stopAuthentication();

      // then
      expect(platform.stopCalled, isTrue);
    });

    test('deve ignorar erro da plataforma ao encerrar', () async {
      // given — plataformas sem suporte ao cancelamento lançam; o serviço
      // não pode propagar (chamado em dispose/cleanup).
      LocalAuthPlatform.instance = _FakeLocalAuthPlatform(
        stopError: PlatformException(code: 'notAvailable'),
      );
      final service = BiometricService();

      // when / then — não lança.
      await service.stopAuthentication();
    });
  });
}

/// Fake cujo getter de biometria lança (simula erro de canal/hardware).
class _ThrowingPlatform extends LocalAuthPlatform
    with MockPlatformInterfaceMixin {
  @override
  Future<bool> deviceSupportsBiometrics() async {
    throw PlatformException(code: 'channel-error');
  }

  @override
  Future<bool> isDeviceSupported() async => true;
}
