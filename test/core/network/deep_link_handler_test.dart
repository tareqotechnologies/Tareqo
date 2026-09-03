import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/core/network/deep_link_handler.dart';

void main() {
  group('DeepLinkHandler.isAuthCallbackUri (auditoria 2026-08 — V8/V12)', () {
    test('aceita tareqo://callback com query PKCE (code)', () {
      expect(
        DeepLinkHandler.isAuthCallbackUri(
          Uri.parse('tareqo://callback?code=abc123&state=xyz'),
        ),
        isTrue,
      );
    });

    test('aceita tareqo://callback com error (fluxo rejeitado)', () {
      expect(
        DeepLinkHandler.isAuthCallbackUri(
          Uri.parse('tareqo://callback?error=access_denied'),
        ),
        isTrue,
      );
    });

    test('rejeita outro HOST no mesmo scheme (hijack de scheme)', () {
      expect(
        DeepLinkHandler.isAuthCallbackUri(
          Uri.parse('tareqo://outra-coisa?code=abc'),
        ),
        isFalse,
      );
      expect(
        DeepLinkHandler.isAuthCallbackUri(
          Uri.parse('tareqo://evil?code=abc'),
        ),
        isFalse,
      );
    });

    test('rejeita outro SCHEME com host callback', () {
      expect(
        DeepLinkHandler.isAuthCallbackUri(
          Uri.parse('https://callback?code=abc'),
        ),
        isFalse,
      );
      expect(
        DeepLinkHandler.isAuthCallbackUri(
          Uri.parse('evil://callback?code=abc'),
        ),
        isFalse,
      );
      // Nota: Uri NORMALIZA o scheme para minúsculas — 'tareqoE' seria
      // aceito (vira 'tareqo'); a validação compara o scheme
      // normalizado, comportamento correto.
    });

    test('rejeita URI sem host/scheme (malformada)', () {
      expect(
        DeepLinkHandler.isAuthCallbackUri(Uri.parse('tareqo:callback')),
        isFalse,
      );
      expect(DeepLinkHandler.isAuthCallbackUri(Uri.parse('callback')), isFalse);
    });

    test('rejeita scheme vazio ou host vazio', () {
      expect(
        DeepLinkHandler.isAuthCallbackUri(Uri.parse('//callback')),
        isFalse,
      );
    });
  });
}
