import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/core/network/deep_link_handler.dart';

/// Validação da URIs de callback de autenticação (auditoria V12): só o
/// scheme legado `tareqo://callback` e o App Link `https://tareqo.app/callback`
/// são legítimos — qualquer outra origem é rejeitada (defesa contra hijack
/// de deep link que trocaria o code PKCE por um código do atacante).
void main() {
  group('DeepLinkHandler.isAuthCallbackUri — URIs legítimas', () {
    test('aceita tareqo://callback simples', () {
      expect(
        DeepLinkHandler.isAuthCallbackUri(Uri.parse('tareqo://callback')),
        isTrue,
      );
    });

    test('aceita tareqo://callback com code PKCE', () {
      expect(
        DeepLinkHandler.isAuthCallbackUri(
          Uri.parse('tareqo://callback?code=pkce-code-123'),
        ),
        isTrue,
      );
    });

    test('aceita https://tareqo.app/callback (App Links)', () {
      expect(
        DeepLinkHandler.isAuthCallbackUri(
          Uri.parse('https://tareqo.app/callback?code=abc'),
        ),
        isTrue,
      );
    });
  });

  group('DeepLinkHandler.isAuthCallbackUri — hijack e origens estranhas', () {
    test('rejeita scheme parecido (tareqoe://callback)', () {
      expect(
        DeepLinkHandler.isAuthCallbackUri(Uri.parse('tareqoe://callback')),
        isFalse,
      );
    });

    test('rejeita host errado no scheme do app', () {
      expect(
        DeepLinkHandler.isAuthCallbackUri(Uri.parse('tareqo://evil?code=abc')),
        isFalse,
      );
    });

    test('rejeita host https errado com path de callback', () {
      expect(
        DeepLinkHandler.isAuthCallbackUri(
          Uri.parse('https://evil.example.com/callback?code=abc'),
        ),
        isFalse,
      );
    });

    test('rejeita path errado no domínio web', () {
      expect(
        DeepLinkHandler.isAuthCallbackUri(
          Uri.parse('https://tareqo.app/callbackx?code=abc'),
        ),
        isFalse,
      );
    });

    test('rejeita http (sem TLS) no domínio web', () {
      expect(
        DeepLinkHandler.isAuthCallbackUri(
          Uri.parse('http://tareqo.app/callback?code=abc'),
        ),
        isFalse,
      );
    });

    test('rejeita URLs da web arbitrárias e URLs sem origem', () {
      expect(
        DeepLinkHandler.isAuthCallbackUri(
          Uri.parse('https://supabase.co/auth/v1/callback'),
        ),
        isFalse,
      );
      expect(
        DeepLinkHandler.isAuthCallbackUri(Uri.parse('mailto:test@tareqo.app')),
        isFalse,
      );
    });
  });
}
