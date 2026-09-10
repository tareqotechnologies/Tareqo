import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Sessão de auth em memória (evita SharedPreferences no teste).
class MemAuthStorage extends LocalStorage {
  String? _data;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async => _data != null;

  @override
  Future<String?> accessToken() async => _data;

  @override
  Future<void> removePersistedSession() async => _data = null;

  @override
  Future<void> persistSession(String value) async => _data = value;
}

/// Storage PKCE em memória (evita o plugin shared_preferences no teste).
class MemAsyncStorage extends GotrueAsyncStorage {
  final Map<String, String> _items = {};

  @override
  Future<String?> getItem({required String key}) async => _items[key];

  @override
  Future<void> setItem({required String key, required String value}) async {
    _items[key] = value;
  }

  @override
  Future<void> removeItem({required String key}) async => _items.remove(key);
}

/// Resposta programável do servidor REST falso.
class FakeResponse {
  FakeResponse(this.body, {this.status = 200, this.errorCode});

  /// Corpo JSON (Map, List ou texto puro).
  final Object? body;
  final int status;

  /// Código de erro do PostgREST (`error.code`) em respostas 4xx/5xx.
  final String? errorCode;
}

/// Um `http.Client` programável que responde por rota e grava as requisições
/// — a única superfície que os datasources remotos tocam.
///
/// - `handler(path, request) → FakeResponse` decide o corpo/status por rota.
/// - Se nenhum handler for fornecido, responde `[]` (listagem vazia).
/// - Se [failNext] estiver definido, a próxima requisição lança
///   [http.SocketException] (simula ausência de rede / timeout).
class StubSupabaseHttp extends http.BaseClient {
  /// Handler mutável: como `Supabase.initialize` só roda uma vez por
  /// processo de teste, cada teste troca o comportamento de resposta
  /// AQUI (em vez de criar um novo stub).
  FakeResponse Function(String path, http.BaseRequest request)? handler;

  StubSupabaseHttp({this.handler});

  /// Requisições recebidas, em ordem (método + caminho + corpo).
  final List<http.BaseRequest> requests = [];
  int? failNext;

  String _pathOf(http.BaseRequest request) =>
      request.url.path.replaceFirst(RegExp(r'^/'), '');

  static http.Response _toResponse(FakeResponse fake) {
    final body = switch (fake.body) {
      final String s => s,
      null => '',
      final Object other => jsonEncode(other),
    };
    return http.Response(
      body,
      fake.status,
      headers: const {'content-type': 'application/json'},
    );
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests.add(request);

    if (failNext != null && failNext! > 0) {
      failNext = failNext! - 1;
      throw http.ClientException('Sem conexão com o servidor.');
    }

    // Auth (GoTrue): endpoint de token → sessão com usuário fixo `u1`.
    if (_pathOf(request).endsWith('/token')) {
      return _stream(
        jsonEncode({
          'access_token': 'test-token',
          'token_type': 'bearer',
          'expires_in': 3600,
          'expires_at': 4102444800,
          'refresh_token': 'refresh-1',
          'user': {
            'id': 'u1',
            'aud': 'authenticated',
            'email': 'dono@test.local',
            'app_metadata': <String, dynamic>{},
            'user_metadata': <String, dynamic>{},
            'created_at': '2026-01-01T00:00:00Z',
          },
        }),
        request,
      );
    }

    final handler = this.handler;
    final fake = handler != null
        ? handler(_pathOf(request), request)
        : FakeResponse(<dynamic>[]);
    final response = _toResponse(fake);
    // POST/PUT retornam a mesma carga (o PostgREST ecoa a linha criada
    // quando `.select()` é aplicado; sem `.select()`, o corpo é ignorado).
    return _stream(response.body, request, fake);
  }

  http.StreamedResponse _stream(
    String body,
    http.BaseRequest request, [
    FakeResponse? fake,
  ]) {
    return http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      fake?.status ?? 200,
      request: request,
      headers: const {'content-type': 'application/json'},
    );
  }
}

/// Inicializa o Supabase UMA VEZ por processo de teste sobre o stub.
///
/// Em arquivo único (rodado sozinho), o `initialize` real acontece; em
/// `flutter test` em lote os arquivos rodam isolados por processo, então
/// cada arquivo de teste chama isto no próprio `setUpAll`.
Future<StubSupabaseHttp> initStubbedSupabase({
  FakeResponse Function(String path, http.BaseRequest request)? handler,
}) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final stub = StubSupabaseHttp(handler: handler);
  try {
    await Supabase.initialize(
      url: 'https://fake.supabase.co',
      publishableKey: 'test-anon-key',
      httpClient: stub,
      authOptions: FlutterAuthClientOptions(
        localStorage: MemAuthStorage(),
        pkceAsyncStorage: MemAsyncStorage(),
        detectSessionInUri: false,
        autoRefreshToken: false,
      ),
    );
  } on StateError {
    // Já inicializado (re-execução no mesmo processo): segue com o atual.
  }
  return stub;
}

/// Faz login no stub (define `auth.currentUser = u1`).
Future<void> signInStubUser() async {
  await Supabase.instance.client.auth.signInWithPassword(
    email: 'dono@test.local',
    password: 'irrelevante-o-stub-responde-ok',
  );
}

/// Corpo JSON de uma requisição POST/PUT/PATCH gravada pelo stub.
dynamic jsonBodyOf(http.BaseRequest request) {
  final base = request as http.Request;
  return base.body.isEmpty ? null : jsonDecode(base.body);
}
