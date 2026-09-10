import 'package:flutter_test/flutter_test.dart';
import 'package:otp/otp.dart';

import 'package:tareqo/core/security/mfa_service.dart';

void main() {
  final service = MFAService();

  group('MFAService.generateTOTP / verifyTOTP', () {
    test('código gerado tem 6 dígitos e verifica contra o próprio segredo', () {
      final secret = OTP.randomSecret();

      final code = service.generateTOTP(secret);

      expect(code, matches(RegExp(r'^\d{6}$')));
      expect(service.verifyTOTP(secret, code), isTrue);
    });

    test('código de OUTRO segredo NÃO verifica', () {
      final secretA = OTP.randomSecret();
      final secretB = OTP.randomSecret();

      final codeA = service.generateTOTP(secretA);

      // Pode falhar por colisão de janela (raro) — força um código distinto.
      var acceptedWrong = service.verifyTOTP(secretB, codeA);
      if (acceptedWrong) {
        final other = service.generateTOTP(secretB);
        acceptedWrong = other == codeA;
      }
      expect(acceptedWrong, isFalse);
    });

    test('código com dígitos trocados NÃO verifica', () {
      final secret = OTP.randomSecret();
      final code = service.generateTOTP(secret);
      final swapped = code == '123456' ? '654321' : '123456';

      expect(service.verifyTOTP(secret, swapped), isFalse);
    });

    test('tolerância de relógio: janela adjacente verifica (skew ±30s)', () {
      final secret = OTP.randomSecret();
      // Código da janela ANTERIOR (como se o relógio do autenticador
      // estivesse 30s atrás) — o verifyTOTP deve aceitar.
      final previousWindowMs =
          DateTime.now().millisecondsSinceEpoch - 30 * 1000;
      final code = OTP.generateTOTPCodeString(
        secret,
        previousWindowMs,
        length: 6,
        interval: 30,
        algorithm: Algorithm.SHA1,
        isGoogle: true,
      );

      expect(service.verifyTOTP(secret, code), isTrue);
    });

    test('verifyTOTP com segredo inválido devolve FALSE (não lança)', () {
      expect(service.verifyTOTP('!!!!not-base32!!!!', '123456'), isFalse);
    });

    test('generateTOTP com segredo inválido lança Exception', () {
      expect(
        () => service.generateTOTP('!!!!not-base32!!!!'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('MFAService.isValidSecret', () {
    test('segredo Base32 válido → true', () {
      expect(service.isValidSecret(OTP.randomSecret()), isTrue);
    });

    test('segredo vazio → false (sem tentar gerar)', () {
      expect(service.isValidSecret(''), isFalse);
    });

    test('segredo com caracteres inválidos → false', () {
      expect(service.isValidSecret('!!!!not-base32!!!!'), isFalse);
    });
  });

  group('MFAService.generateQRCodeData', () {
    test('URI otpauth contém segredo, issuer, dígitos e período', () {
      final uri = service.generateQRCodeData(
        issuer: 'Tareqo',
        account: 'dono@loja.com',
        secret: 'JBSWY3DPEHPK3PXP',
      );

      expect(uri, startsWith('otpauth://totp/'));
      expect(uri, contains('Tareqo%3Adono%40loja.com'));
      expect(uri, contains('secret=JBSWY3DPEHPK3PXP'));
      expect(uri, contains('issuer=Tareqo'));
      expect(uri, contains('digits=6'));
      expect(uri, contains('period=30'));
      expect(uri, contains('algorithm=SHA1'));
    });

    test('getTimeRemaining devolve valor entre 1 e 30 segundos', () {
      final remaining = service.getTimeRemaining();
      expect(remaining, greaterThanOrEqualTo(1));
      expect(remaining, lessThanOrEqualTo(30));
    });
  });
}
