import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/core/network/cert_pinning_io.dart';

/// Extrai o DER de um certificado PEM (strip dos marcadores + base64).
List<int> _pemToDer(String pem) {
  final b64 = pem
      .replaceAll('-----BEGIN CERTIFICATE-----', '')
      .replaceAll('-----END CERTIFICATE-----', '')
      .replaceAll(RegExp(r'\s'), '');
  return base64Decode(b64);
}

DateTime? _extractNotAfter(List<int> der) {
  final times = <DateTime>[];
  for (var i = 0; i < der.length - 15; i++) {
    if (der[i] == 0x17 && der[i + 1] == 13) {
      final str = ascii.decode(der.sublist(i + 2, i + 2 + 13));
      if (str.endsWith('Z')) {
        final year = int.parse(str.substring(0, 2));
        final fullYear = year >= 50 ? 1900 + year : 2000 + year;
        final month = int.parse(str.substring(2, 4));
        final day = int.parse(str.substring(4, 6));
        final hour = int.parse(str.substring(6, 8));
        final minute = int.parse(str.substring(8, 10));
        final second = int.parse(str.substring(10, 12));
        times.add(DateTime.utc(fullYear, month, day, hour, minute, second));
      }
    }
  }
  return times.length >= 2 ? times[1] : null;
}

void main() {
  // Auditoria 2026-08 (V2): o pin embutido é a ANCORA do SecurityContext —
  // se o PEM for corrompido (ou alguém o trocar sem atualizar o teste), o
  // fingerprint não bate e a suite falha. Fingerprint SHA-256 do WE1:
  //   openssl x509 -in we1.pem -noout -fingerprint -sha256
  //   → 1D:FC:16:05:FB:AD:35:8D:8B:C8:44:F7:6D:15:20:3F:AC:9C:A5:C1:A7:9F:D4:85:7F:FA:F2:86:4F:BE:BF:96
  test('PEM do WE1 embutido tem o fingerprint SHA-256 esperado', () async {
    final der = _pemToDer(we1IntermediatePem);
    final digest = await Sha256().hash(der);
    final hex = digest.bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(':');

    expect(
      hex,
      '1D:FC:16:05:FB:AD:35:8D:8B:C8:44:F7:6D:15:20:3F:'
      'AC:9C:A5:C1:A7:9F:D4:85:7F:FA:F2:86:4F:BE:BF:96',
    );
  });

  test('buildPinnedHttpClient cria um cliente com pin (não nulo)', () {
    // A função constrói o SecurityContext com o PEM embutido — se o PEM
    // fosse inválido, lançaria aqui (setTrustedCertificatesBytes valida).
    final client = buildPinnedHttpClient();
    expect(client, isNotNull);
    client.close();
  });

  test(
    'WE1 expira no futuro com folga mínima de 180 dias (health check local)',
    () {
      final der = _pemToDer(we1IntermediatePem);
      final notAfter = _extractNotAfter(der);
      expect(
        notAfter,
        isNotNull,
        reason: 'Não foi possível extrair a data de expiração do DER',
      );

      // Validação estrita da data de expiração (2029-02-20)
      expect(notAfter!.year, 2029);
      expect(notAfter.month, 2);
      expect(notAfter.day, 20);

      final daysRemaining = notAfter.difference(DateTime.now()).inDays;
      expect(
        daysRemaining,
        greaterThan(180),
        reason:
            'Certificado pinado expira em $daysRemaining dias (< 180 dias)! Necessário rotacionar.',
      );
    },
  );
}
