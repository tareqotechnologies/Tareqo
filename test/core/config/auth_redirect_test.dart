import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/core/config/auth_redirect.dart';

/// O link enviado pelo Supabase tem de voltar para o app certo: deep link
/// nativo no Android/iOS e a própria origem no web (o browser não abre
/// `tareqo://`). Sem isso a confirmação de e-mail e a recuperação de
/// palavra-passe ficavam presas no `site_url` do projeto.
void main() {
  group('authRedirectUrl — nativo', () {
    test('usa o scheme registado no Android/iOS', () {
      expect(authRedirectUrl(isWeb: false), 'tareqo://callback');
    });
  });

  group('authRedirectUrl — web', () {
    test('usa a origem do app publicado no GitHub Pages', () {
      expect(
        authRedirectUrl(
          isWeb: true,
          baseUri: Uri.parse('https://tareqotechnologies.github.io/Tareqo/app/'),
        ),
        'https://tareqotechnologies.github.io/Tareqo/app/',
      );
    });

    test('descarta query e fragment da página atual', () {
      expect(
        authRedirectUrl(
          isWeb: true,
          baseUri: Uri.parse('https://tareqo.app/?code=abc#/login'),
        ),
        'https://tareqo.app/',
      );
    });

    test('preserva host com porta (dev local)', () {
      expect(
        authRedirectUrl(
          isWeb: true,
          baseUri: Uri.parse('http://localhost:8080/#/'),
        ),
        'http://localhost:8080/',
      );
    });

    test('acrescenta a barra final em /app sem barra', () {
      expect(
        authRedirectUrl(
          isWeb: true,
          baseUri: Uri.parse('https://tareqotechnologies.github.io/Tareqo/app'),
        ),
        'https://tareqotechnologies.github.io/Tareqo/app/',
      );
    });

    test('normaliza path vazio para a raiz', () {
      expect(
        authRedirectUrl(isWeb: true, baseUri: Uri.parse('https://tareqo.app')),
        'https://tareqo.app/',
      );
    });
  });
}
