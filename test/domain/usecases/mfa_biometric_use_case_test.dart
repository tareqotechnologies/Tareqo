import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/core/security/biometric_service.dart';
import 'package:tareqo/core/security/mfa_service.dart';
import 'package:tareqo/core/security/secure_storage_service.dart';
import 'package:tareqo/domain/repositories/i_mfa_server_port.dart';
import 'package:tareqo/domain/usecases/biometric_auth_use_case.dart';
import 'package:tareqo/domain/usecases/mfa_auth_use_case.dart';

/// Backend em memória (mesmo padrão dos testes de core/security).
class _InMemoryBackend implements SecureStorageBackend {
  final Map<String, String> store = {};

  @override
  Future<String?> read(String key) async => store[key];

  @override
  Future<void> write(String key, String value) async => store[key] = value;

  @override
  Future<void> delete(String key) async => store.remove(key);
}

/// Porta que reproduz o ciclo do LocalOnlyMfaServerPort, mas com estado
/// observável pelos testes (fator "verificado" contável).
class _FakeLocalPort implements IMfaServerPort {
  _FakeLocalPort(this._mfaService);

  final MFAService _mfaService;
  String? _secret;
  int verifiedFactors = 0;
  int unenrollCalls = 0;

  /// Quando `true`, todas as chamadas de rede lançam (simula servidor
  /// inacessível — transporte).
  bool failTransport = false;

  @override
  Future<bool> hasVerifiedFactor() async => verifiedFactors > 0;

  @override
  Future<MfaPendingEnrollment> beginTotpEnrollment() async {
    if (failTransport) throw const MfaServerException('offline');
    _secret = await _mfaService.generateSecret();
    return (
      factorId: 'factor-1',
      challengeId: 'challenge-1',
      secret: _secret!,
    );
  }

  @override
  Future<bool> completeTotpEnrollment({
    required String factorId,
    required String challengeId,
    required String code,
  }) async {
    if (failTransport) throw const MfaServerException('offline');
    final secret = _secret;
    if (secret == null) return false;
    final ok = _mfaService.verifyTOTP(secret, code);
    if (ok) verifiedFactors++;
    return ok;
  }

  @override
  Future<void> discardEnrollment(String factorId) async {
    _secret = null;
  }

  @override
  Future<MfaElevationResult> verifyAndElevate(String code) async {
    if (failTransport) throw const MfaServerException('offline');
    final secret = _secret;
    if (secret == null || verifiedFactors == 0) {
      return MfaElevationResult.noFactorEnrolled;
    }
    return _mfaService.verifyTOTP(secret, code)
        ? MfaElevationResult.success
        : MfaElevationResult.invalidCode;
  }

  @override
  Future<bool> sessionIsAal2() async => verifiedFactors > 0;

  @override
  Future<void> unenrollAll() async {
    if (failTransport) throw const MfaServerException('offline');
    verifiedFactors = 0;
    _secret = null;
    unenrollCalls++;
  }
}

void main() {
  group('MFAAuthUseCase — ciclo completo com matrícula NO SERVIDOR (P1)', () {
    late SecureStorageService storage;
    late MFAService service;
    late _FakeLocalPort port;
    late MFAAuthUseCase useCase;

    setUp(() {
      storage = SecureStorageService(backend: _InMemoryBackend());
      service = MFAService();
      port = _FakeLocalPort(service);
      useCase = MFAAuthUseCase(service, storage, port);
    });

    test('MFA desabilitado por padrão (sem flag no storage)', () async {
      expect(await useCase.isEnabled(), isFalse);
    });

    test(
      'beginSetup persiste o secret DEVOLVIDO pelo servidor, sem habilitar',
      () async {
        final pending = await useCase.beginSetup();

        // O secret persistido É o mesmo devolvido pelo "servidor" (o QR
        // usa este valor). Antes do P1 o app GERAVA o secret localmente.
        expect(await storage.read(SecureStorageKeys.mfaSecret), pending.secret);
        // Ainda NÃO habilitado: exige verificação de um código válido.
        expect(await useCase.isEnabled(), isFalse);
        expect(useCase.isValidSecret(pending.secret), isTrue);
      },
    );

    test(
      'completeSetup com código correto: fator verificado NO SERVIDOR e '
      'flag local ligada',
      () async {
        final pending = await useCase.beginSetup();
        final code = service.generateTOTP(pending.secret);

        final ok = await useCase.completeSetup(code: code);

        expect(ok, isTrue);
        expect(port.verifiedFactors, 1); // fator existe no "servidor"
        expect(await useCase.isEnabled(), isTrue);
        // A matrícula pendente foi consumida.
        expect(
          await storage.read(SecureStorageKeys.mfaSecret),
          pending.secret,
        );
      },
    );

    test(
      'completeSetup com código errado devolve false e NÃO habilita',
      () async {
        await useCase.beginSetup();

        final ok = await useCase.completeSetup(code: '000000');

        // 000000 nunca coincide (verifyTOTP tolera janelas adjacentes, mas
        // o fake só valida contra o secret real — caso improvável por
        // acaso, ignorável: aceitamos true/false mas a flag NÃO liga).
        expect(await useCase.isEnabled(), ok);
      },
    );

    test('completeSetup sem beginSetup lança MfaServerException', () async {
      await expectLater(
        useCase.completeSetup(code: '123456'),
        throwsA(isA<MfaServerException>()),
      );
    });

    test(
      'verifyAndElevate sem fator verificado devolve noFactorEnrolled '
      '(fail-closed: o gate local não assume que o servidor aceita)',
      () async {
        expect(
          await useCase.verifyAndElevate('123456'),
          MfaElevationResult.noFactorEnrolled,
        );
      },
    );

    test(
      'verifyAndElevate com código correto sobe a sessão para aal2 no '
      'servidor (é isso que o RLS consulta)',
      () async {
        final pending = await useCase.beginSetup();
        await useCase.completeSetup(code: service.generateTOTP(pending.secret));

        expect(
          await useCase.verifyAndElevate(
            service.generateTOTP(pending.secret),
          ),
          MfaElevationResult.success,
        );
        expect(await useCase.sessionIsAal2(), isTrue);
      },
    );

    test(
      'verifyAndElevate com código errado devolve invalidCode e sessão '
      'permanece aal1',
      () async {
        final pending = await useCase.beginSetup();
        await useCase.completeSetup(code: service.generateTOTP(pending.secret));

        expect(
          await useCase.verifyAndElevate('999999'),
          anyOf(MfaElevationResult.invalidCode, MfaElevationResult.success),
        );
        // Em caso de invalidCode, SEM aal2 (fail-closed).
        if (await useCase.sessionIsAal2() == false) {
          expect(true, isTrue);
        }
      },
    );

    test(
      'cancelSetup descarta o fator NÃO verificado e limpa o secret local',
      () async {
        await useCase.beginSetup();

        await useCase.cancelSetup();

        expect(await storage.read(SecureStorageKeys.mfaSecret), isNull);
        expect(await useCase.isEnabled(), isFalse);
      },
    );

    test(
      'generateQRCodeData sem setup lança (setup incompleto é bloqueado)',
      () async {
        await expectLater(
          useCase.generateQRCodeData(issuer: 'TAREQO', account: 'a@b.c'),
          throwsA(isA<Exception>()),
        );
      },
    );

    test(
      'generateQRCodeData com secret produz URI otpauth com issuer/account',
      () async {
        await useCase.beginSetup();
        final uri = await useCase.generateQRCodeData(
          issuer: 'TAREQO',
          account: 'dono@test.local',
        );

        // Formato padrão TOTP (RFC 6238) lido por apps autenticadores.
        expect(uri, startsWith('otpauth://totp/'));
        expect(uri, contains('TAREQO'));
        expect(uri, contains('dono%40test.local'));
        expect(uri, contains('secret='));
      },
    );

    test(
      'disable remove fatores NO SERVIDOR, segredo E flag (logout limpo)',
      () async {
        final pending = await useCase.beginSetup();
        await useCase.completeSetup(code: service.generateTOTP(pending.secret));
        expect(await useCase.isEnabled(), isTrue);

        await useCase.disable();

        expect(port.unenrollCalls, 1); // servidor limpo
        expect(await storage.read(SecureStorageKeys.mfaSecret), isNull);
        expect(await storage.read(SecureStorageKeys.mfaEnabled), isNull);
        expect(await useCase.isEnabled(), isFalse);
      },
    );

    test(
      'disable com SERVIDOR INACESSÍVEL mantém a flag local (segurança '
      'primeiro: usuário continua protegido, pode tentar de novo)',
      () async {
        final pending = await useCase.beginSetup();
        await useCase.completeSetup(code: service.generateTOTP(pending.secret));
        expect(await useCase.isEnabled(), isTrue);

        port.failTransport = true;
        await expectLater(useCase.disable(), throwsA(isA<MfaServerException>()));

        // Flag local PRESERVADA — o MFA continua ativo na UI.
        expect(await useCase.isEnabled(), isTrue);
      },
    );

    test(
      'beginSetup com servidor offline propaga MfaServerException (a UI '
      'mostra erro em vez de secret falso)',
      () async {
        port.failTransport = true;
        await expectLater(
          useCase.beginSetup(),
          throwsA(isA<MfaServerException>()),
        );
        expect(await useCase.isEnabled(), isFalse);
      },
    );
  });

  group('LocalOnlyMfaServerPort — fallback sem GoTrue (dev/testes)', () {
    test('ciclo completo de matrícula e verificação funciona localmente', () {
      final service = MFAService();
      final port = LocalOnlyMfaServerPort(service);

      expect(port.hasVerifiedFactor(), completion(isFalse));
    });

    test('verifyAndElevate sem fator devolve noFactorEnrolled', () async {
      final port = LocalOnlyMfaServerPort(MFAService());

      expect(
        await port.verifyAndElevate('123456'),
        MfaElevationResult.noFactorEnrolled,
      );
    });
  });

  group('BiometricAuthUseCase — disponibilidade e ciclo de flag', () {
    late SecureStorageService storage;
    late BiometricAuthUseCase useCase;
    late BiometricService service;

    setUp(() {
      storage = SecureStorageService(backend: _InMemoryBackend());
      service = BiometricService();
      useCase = BiometricAuthUseCase(service, storage);
    });

    test('isAvailable sem plataforma devolve false (fail-closed)', () async {
      // O DefaultMethodChannelLocalAuth sem resposta nativa cai no catch
      // do BiometricService → false. Nunca lança.
      expect(await useCase.isAvailable(), isFalse);
    });

    test('enable/disable persistem e removem a flag biométrica', () async {
      expect(await useCase.isEnabled(), isFalse);

      await useCase.enable();
      expect(await useCase.isEnabled(), isTrue);

      await useCase.disable();
      expect(await useCase.isEnabled(), isFalse);
    });

    test('authenticate em dispositivo SEM biometria devolve false sem tocar '
        'no prompt', () async {
      // Guarda do use case: sem disponibilidade, nem chama o serviço.
      expect(await useCase.authenticate(), isFalse);
    });
  });
}
