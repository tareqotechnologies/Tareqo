import 'package:flutter_test/flutter_test.dart';

import 'package:dumbhanengue/core/network/deep_link_handler.dart';

void main() {
  group('DeepLinkHandler.isAuthCallbackUri (auditoria 2026-08 — V8/V12)', () {
    test('aceita dumbhanengue://callback com query PKCE (code)', () {
      expect(
        DeepLinkHandler.isAuthCallbackUri(
          Uri.parse('dumbhanengue://callback?code=abc123&state=xyz'),
        ),
        isTrue,
      );
    });

    test('aceita dumbhanengue://callback com error (fluxo rejeitado)', () {
      expect(
        DeepLinkHandler.isAuthCallbackUri(
          Uri.parse('dumbhanengue://callback?error=access_denied'),
        ),
        isTrue,
      );
    });

    test('rejeita outro HOST no mesmo scheme (hijack de scheme)', () {
      expect(
        DeepLinkHandler.isAuthCallbackUri(
          Uri.parse('dumbhanengue://outra-coisa?code=abc'),
        ),
        isFalse,
      );
      expect(
        DeepLinkHandler.isAuthCallbackUri(
          Uri.parse('dumbhanengue://evil?code=abc'),
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
      // Nota: Uri NORMALIZA o scheme para minúsculas — 'dumbhanenguE' seria
      // aceito (vira 'dumbhanengue'); a validação compara o scheme
      // normalizado, comportamento correto.
    });

    test('rejeita URI sem host/scheme (malformada)', () {
      expect(
        DeepLinkHandler.isAuthCallbackUri(Uri.parse('dumbhanengue:callback')),
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
