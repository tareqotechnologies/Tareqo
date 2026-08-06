import 'dart:async';

import 'package:http/http.dart' as http;

/// Cliente HTTP com timeout global e retry para leituras idempotentes.
///
/// Injetado no [Supabase.initialize] (`httpClient:`) — cobre de forma
/// central TODAS as chamadas REST do app (PostgREST, GoTrue, Storage):
/// se o servidor não responder em [timeout], o pedido falha de forma
/// controlada (em vez de pendurar a UI) e leituras idempotentes
/// (GET/HEAD) são repetidas com backoff curto em timeout, 5xx e 429.
///
/// ⚠️ Escritas (POST/PATCH/PUT/DELETE) NUNCA são repetidas: repetir uma
/// escrita pode duplicar efeitos no servidor (as RPCs do schema têm
/// idempotência própria, mas as chamadas genéricas não).
final class TimeoutRetryHttpClient extends http.BaseClient {
  TimeoutRetryHttpClient({
    http.Client? inner,
    this.timeout = const Duration(seconds: 20),
    this.maxRetries = 2,
  }) : _inner = inner ?? http.Client();

  final http.Client _inner;

  /// Tempo máximo por tentativa (conexão + resposta).
  final Duration timeout;

  /// Repetições adicionais (para além da tentativa inicial) em leituras.
  final int maxRetries;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Só repetimos pedidos idempotentes SEM corpo (GET/HEAD): reenviar um
    // pedido com corpo poderia reutilizar um stream já consumido e
    // duplicar o efeito no servidor.
    final retriable = (request.method == 'GET' || request.method == 'HEAD') &&
        request is! http.StreamedRequest;

    var attempt = 0;
    while (true) {
      attempt++;
      // Clona o pedido a cada tentativa: o `http.Client` FINALIZA o request
      // na primeira chamada (`BaseRequest.finalize`) — reutilizar o mesmo
      // objecto nas retries lança "Can't finalize a finalized Request".
      final candidate = retriable ? _clone(request) : request;
      try {
        final response = await _inner.send(candidate).timeout(timeout);
        final recoverable =
            response.statusCode == 429 || response.statusCode >= 500;
        if (retriable && recoverable && attempt <= maxRetries) {
          await Future<void>.delayed(Duration(milliseconds: 300 * attempt));
          continue;
        }
        return response;
      } on TimeoutException {
        if (retriable && attempt <= maxRetries) {
          await Future<void>.delayed(Duration(milliseconds: 300 * attempt));
          continue;
        }
        rethrow;
      }
    }
  }

  /// Cópia fresca de um pedido idempotente (GET/HEAD) para poder ser
  /// reenviado. O `http.Request` só pode ser finalizado uma vez.
  static http.BaseRequest _clone(http.BaseRequest request) {
    if (request is http.Request) {
      return http.Request(request.method, request.url)
        ..headers.addAll(request.headers)
        ..followRedirects = request.followRedirects
        ..persistentConnection = request.persistentConnection
        ..bodyBytes = request.bodyBytes;
    }
    // GET/HEAD nunca chega aqui com StreamedRequest (guardado no `send`);
    // fallback defensivo — sem corpo, apenas copia o essencial.
    return http.Request(request.method, request.url)
      ..headers.addAll(request.headers);
  }
}
