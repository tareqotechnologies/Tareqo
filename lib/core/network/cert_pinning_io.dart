import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// Certificate pinning (auditoria 2026-08 — V2).
///
/// PEM do intermediário **WE1** (Google Trust Services) — o mesmo que assina
/// o leaf de `dotklbpqmlnhcdifiukd.supabase.co` (cadeia: leaf → WE1 → GTS
/// Root R4). O `SecurityContext` é criado com `withTrustedRoots: false` e
/// esta âncora: a app só aceita cadeias que terminam no WE1. Um MITM com CA
/// user-installed (proxy, malware, rede hostil) é rejeitado porque o trust
/// store do SO é ignorado — a validação usa APENAS este pin.
///
/// Por que o INTERMEDIÁRIO (e não o leaf)? O leaf do Supabase rotaciona
/// (o atual expira em set/2026) — pinar o leaf quebraria o app a cada
/// rotação. O WE1 é estável até 2028: a rotação normal do leaf continua
/// funcionando, e só uma troca de CA (rara) exigiria atualização do app.
///
/// Verificação da âncora: `openssl s_client -showcerts` (cert #2) +
/// `openssl x509 -fingerprint -sha256` → WE1, emitido por GTS Root R4.
const String we1IntermediatePem = '''
-----BEGIN CERTIFICATE-----
MIICnzCCAiWgAwIBAgIQf/MZd5csIkp2FV0TttaF4zAKBggqhkjOPQQDAzBHMQsw
CQYDVQQGEwJVUzEiMCAGA1UEChMZR29vZ2xlIFRydXN0IFNlcnZpY2VzIExMQzEU
MBIGA1UEAxMLR1RTIFJvb3QgUjQwHhcNMjMxMjEzMDkwMDAwWhcNMjkwMjIwMTQw
MDAwWjA7MQswCQYDVQQGEwJVUzEeMBwGA1UEChMVR29vZ2xlIFRydXN0IFNlcnZp
Y2VzMQwwCgYDVQQDEwNXRTEwWTATBgcqhkjOPQIBBggqhkjOPQMBBwNCAARvzTr+
Z1dHTCEDhUDCR127WEcPQMFcF4XGGTfn1XzthkubgdnXGhOlCgP4mMTG6J7/EFmP
LCaY9eYmJbsPAvpWo4H+MIH7MA4GA1UdDwEB/wQEAwIBhjAdBgNVHSUEFjAUBggr
BgEFBQcDAQYIKwYBBQUHAwIwEgYDVR0TAQH/BAgwBgEB/wIBADAdBgNVHQ4EFgQU
kHeSNWfE/6jMqeZ72YB5e8yT+TgwHwYDVR0jBBgwFoAUgEzW63T/STaj1dj8tT7F
avCUHYwwNAYIKwYBBQUHAQEEKDAmMCQGCCsGAQUFBzAChhhodHRwOi8vaS5wa2ku
Z29vZy9yNC5jcnQwKwYDVR0fBCQwIjAgoB6gHIYaaHR0cDovL2MucGtpLmdvb2cv
ci9yNC5jcmwwEwYDVR0gBAwwCjAIBgZngQwBAgEwCgYIKoZIzj0EAwMDaAAwZQIx
AOcCq1HW90OVznX+0RGU1cxAQXomvtgM8zItPZCuFQ8jSBJSjz5keROv9aYsAm5V
sQIwJonMaAFi54mrfhfoFNZEfuNMSQ6/bIBiNLiyoX46FohQvKeIoJ99cx7sUkFN
7uJW
-----END CERTIFICATE-----
''';

/// Constrói o cliente HTTP com pinning do WE1.
///
/// - `withTrustedRoots: false` → ignora o trust store do SO (o MITM com CA
///   user-installed deixa de validar);
/// - `setTrustedCertificatesBytes` → a única âncora é o WE1;
/// - `badCertificateCallback` → retorna `false` SEMPRE (fail-closed): mesmo
///   que algo valide por fora do pin, a conexão é recusada. Um callback que
///   devolvesse `true` abriria uma porta de escape para o MITM.
http.Client buildPinnedHttpClient() {
  final context = SecurityContext(withTrustedRoots: false)
    ..setTrustedCertificatesBytes(utf8.encode(we1IntermediatePem));
  final inner = HttpClient(context: context)
    ..badCertificateCallback = (cert, host, port) => false;
  return IOClient(inner);
}

/// Cliente com pin ERRADO (usado apenas no teste E2E de pinning): ancorado
/// num certificado que NÃO está na cadeia do Supabase, o handshake TLS é
/// rejeitado — prova que o pin NÃO valida por acaso e que um MITM com CA
/// própria (cadeia diferente) é bloqueado da MESMA forma.
@visibleForTesting
http.Client buildBogusPinnedHttpClient() {
  // Um certificado auto-assinado arbitrário (chave EC falsa) como âncora:
  // a cadeia real do Supabase (leaf → WE1 → R4) nunca termina nele.
  const bogusPem = '''
-----BEGIN CERTIFICATE-----
MIIDBzCCAe+gAwIBAgIUT8v4uQNw3GqdCBcEGLxHXh0TEngwDQYJKoZIhvcNAQEL
BQAwEzERMA8GA1UEAwwIYm9ndXMtY2EwHhcNMjYwODE4MDgzNzU0WhcNMjcwODE4
MDgzNzU0WjATMREwDwYDVQQDDAhib2d1cy1jYTCCASIwDQYJKoZIhvcNAQEBBQAD
ggEPADCCAQoCggEBAN2Nj2dLtXZ9ZC99e4oayehTtFNHor+80FSIfBlTX/iLlipc
RkIo5M1BEk7SmduWtJ10PQGSUbwzm3uzlY//SK0ccsRrcK9bxb21ClRnuF7HqaFa
y/qYopC/mwP+8TWmxWvp8ijV/POppChuFuN1e+L81y1cTgVoecdvXEOw9OCN5y01
ieWgrKHcWSDEOovQNVyCE1ZACeQ/+ajKfAttzWpZqbV+BExP1V1AZKLVdMxPXJ6L
JROg0rkly2YVbPBY2BhRlgwa3Jx8az9b5yUzroVjy6FGplkHJNzWShtRj7wOnNMF
XT86FhP7tcEPd083tCel+iK7Ep0FiD/c9HhoWHcCAwEAAaNTMFEwHQYDVR0OBBYE
FHPEE+WzrjzDrJ/IMNa7CRfoIRQ0MB8GA1UdIwQYMBaAFHPEE+WzrjzDrJ/IMNa7
CRfoIRQ0MA8GA1UdEwEB/wQFMAMBAf8wDQYJKoZIhvcNAQELBQADggEBAB8A2GE+
giFMuH+KBOp3goAlfphiSqqMB3mKAu01j4OBYAY6oyEVQZqROrwUyxfmT6D/C0nu
BFQay/W5AMduy4JS7EO9vT+iYPA5Cpu0qR8OfCiAO0edoufkegfIb6ZG5ccX6ixV
UyIJYoDK6nFyXg+VTkWx9Hy84yehbREH7iRogL9drKqu6sQXZHoRfM4R1nnQ9Py/
6z7eTqvjgZGhnomCsBNSiRUhmHeDDl2aV/o2/IbeE+6p10gZnkebAy849loYARwX
jz8f1eyw35cKRgDYXFsq8yGtZMiCzS0x6kuYJxl7Knq3EFruhnVc0Nds/pXydN4o
t/OmO3UjomKtOvk=
-----END CERTIFICATE-----
''';
  final context = SecurityContext(withTrustedRoots: false)
    ..setTrustedCertificatesBytes(utf8.encode(bogusPem));
  final inner = HttpClient(context: context)
    ..badCertificateCallback = (cert, host, port) => false;
  return IOClient(inner);
}
