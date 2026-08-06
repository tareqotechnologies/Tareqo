import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:dumbhanengue/core/network/timeout_retry_http_client.dart';

void main() {
  group('TimeoutRetryHttpClient', () {
    test('repete GET em 503 e devolve a resposta final', () async {
      var calls = 0;
      final inner = MockClient((request) async {
        calls++;
        if (calls == 1) return http.Response('erro', 503);
        return http.Response('ok', 200);
      });
      final client = TimeoutRetryHttpClient(inner: inner, maxRetries: 2);
      final response = await client.get(Uri.parse('https://exemplo.pt/x'));
      expect(response.statusCode, 200);
      expect(calls, 2);
    });

    test('repete GET em timeout e devolve a resposta final', () async {
      var calls = 0;
      final inner = MockClient((request) async {
        calls++;
        if (calls == 1) {
          await Future<void>.delayed(const Duration(milliseconds: 200));
        }
        return http.Response('ok', 200);
      });
      final client = TimeoutRetryHttpClient(
        inner: inner,
        timeout: const Duration(milliseconds: 50),
        maxRetries: 2,
      );
      final response = await client.get(Uri.parse('https://exemplo.pt/x'));
      expect(response.statusCode, 200);
      expect(calls, 2);
    });

    test('esgota as tentativas e propaga a última resposta (5xx)', () async {
      var calls = 0;
      final inner = MockClient((request) async {
        calls++;
        return http.Response('erro', 500);
      });
      final client = TimeoutRetryHttpClient(inner: inner, maxRetries: 2);
      final response = await client.get(Uri.parse('https://exemplo.pt/x'));
      expect(response.statusCode, 500);
      expect(calls, 3); // 1 inicial + 2 retries
    });

    test('NÃO repete POST em 503 (escritas nunca são repetidas)', () async {
      var calls = 0;
      final inner = MockClient((request) async {
        calls++;
        return http.Response('erro', 503);
      });
      final client = TimeoutRetryHttpClient(inner: inner, maxRetries: 2);
      final response = await client.post(Uri.parse('https://exemplo.pt/x'));
      expect(response.statusCode, 503);
      expect(calls, 1);
    });

    test('NÃO repete GET em 4xx (erro de cliente não é recuperável)', () async {
      var calls = 0;
      final inner = MockClient((request) async {
        calls++;
        return http.Response('nao autorizado', 401);
      });
      final client = TimeoutRetryHttpClient(inner: inner, maxRetries: 2);
      final response = await client.get(Uri.parse('https://exemplo.pt/x'));
      expect(response.statusCode, 401);
      expect(calls, 1);
    });
  });
}
