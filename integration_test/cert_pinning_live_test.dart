import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:dumbhanengue/core/network/cert_pinning_io.dart';

/// E2E do certificate pinning (auditoria 2026-08 — V2) CONTRA O SUPABASE
/// REAL. Não precisa de credenciais: usa apenas o endpoint público de saúde
/// do GoTrue (`/auth/v1/health` → 200 JSON) e o endpoint REST (`/rest/v1/`
/// → 401 sem token — o handshake TLS JÁ aconteceu antes do 401).
///
///   flutter drive --driver=test_driver/integration_test.dart \
///     --target=integration_test/cert_pinning_live_test.dart \
///     -d DEVICE --dart-define-from-file=env/dev.env
///
/// O teste prova:
/// 1. **Positivo:** o cliente PINADO (SecurityContext ancorado no WE1,
///    `withTrustedRoots: false`) conecta ao Supabase real — o handshake
///    TLS valida a cadeia até o WE1 e a chamada HTTP chega ao servidor;
/// 2. **Negativo (fail-closed):** um cliente ancorado num certificado
///    DIFERENTE (âncora falsa) é REJEITADO no handshake (HandshakeException)
///    — é exatamente o que um MITM com CA própria sofreria.
const _baseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://dotklbpqmlnhcdifiukd.supabase.co',
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'cliente pinado conecta ao Supabase real; âncora errada é rejeitada',
    (tester) async {
      // ── 1) POSITIVO: o pin real NÃO quebra a conexão legítima ──
      final pinned = buildPinnedHttpClient();
      final health = await pinned.get(Uri.parse('$_baseUrl/auth/v1/health'));
      // O endpoint de saúde pode exigir apikey (401 sem token) — o que
      // IMPORTA aqui é que a chamada RETORNOU um status HTTP: o handshake
      // TLS (validado contra o WE1) concluiu e o request chegou ao servidor.
      // Se o pin falhasse, teríamos HandshakeException, não um status code.
      expect(health.statusCode, anyOf(200, 401));
      pinned.close();

      // ── 2) NEGATIVO: âncora errada = handshake recusado (fail-closed) ──
      // O MITM com CA própria sofre exatamente isto: o cliente NÃO confia
      // na CA do atacante e a conexão falha ANTES de qualquer HTTP.
      final bogus = buildBogusPinnedHttpClient();
      await expectLater(
        bogus.get(Uri.parse('$_baseUrl/auth/v1/health')),
        throwsA(isA<Exception>()),
      );
      bogus.close();
    },
  );
}
