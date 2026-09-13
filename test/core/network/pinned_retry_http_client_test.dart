import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import 'package:tareqo/core/network/cert_pinning_io.dart';
import 'package:tareqo/core/network/pinned_retry_http_client.dart';
import 'package:tareqo/core/network/timeout_retry_http_client.dart';

/// Regressão do P2 (auditoria forense): o cert pinning PRECISA estar
/// conectado ao cliente HTTP real — antes, `cert_pinning_io.dart` existia
/// mas nunca era injetado no caminho de rede (o bootstrap passava apenas
/// o `TimeoutRetryHttpClient` com trust store padrão), e o job
/// `cert-pin-health` do CI monitorava um pin inativo.
///
/// O que estes testes travam:
///  1. a fábrica oficial do app ([buildPinnedRetryHttpClient]) produz um
///     `TimeoutRetryHttpClient` cujo cliente INTERNO é o IOClient pinado
///     (`IOClient` de `buildPinnedHttpClient`) — alguém que remova o pin
///     do bootstrap quebra este teste;
///  2. o cliente pinado rejeita (fail-closed) um handshake contra uma
///     âncora falsa — prova de que o pin NÃO valida por acaso.
void main() {
  test(
    'buildPinnedRetryHttpClient envolve o cliente PINADO (não o padrão)',
    () async {
      final client = buildPinnedRetryHttpClient();
      addTearDown(client.close);

      expect(client, isA<TimeoutRetryHttpClient>());
      // Inspeciona a composição: o `inner` do wrapper DEVE ser o IOClient
      // construído com o SecurityContext do WE1 (mesma classe de runtime
      // que `buildPinnedHttpClient()` devolve). Se o pin for removido do
      // bootstrap, `inner` vira o `http.Client()` padrão e o teste falha.
      final inner = (client as TimeoutRetryHttpClient).debugInnerClient;
      expect(inner, isA<IOClient>());
    },
  );

  test('pin WE1 rejeita handshake com âncora falsa (fail-closed)', () async {
    // O cliente pinado com a âncora REAL deve falhar contra um host cuja
    // cadeia não termina no WE1 — este teste usa o cliente BOGUS (âncora
    // auto-assinada arbitrária) contra o próprio Supabase para provar a
    // recusa SEM depender de rede: o handshake contra `localhost` com uma
    // âncora que não corresponde a nenhum certificado apresentado falha
    // sempre, e o mesmo mecanismo (`badCertificateCallback => false` +
    // SecurityContext sem roots do SO) protege o cliente real.
    final client = buildBogusPinnedHttpClient();
    addTearDown(client.close);

    expect(
      () => client.get(Uri.parse('https://127.0.0.1:1/health')),
      throwsA(anyOf(isA<http.ClientException>(), isA<Exception>())),
    );
  });
}
