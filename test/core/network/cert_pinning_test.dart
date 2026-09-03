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
}
