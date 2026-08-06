/// Flavor de ambiente compilado no app (auditoria 2.4).
///
/// O valor vem do dart-define obrigatório `FLUTTER_APP_FLAVOR`, fornecido
/// pelo `--dart-define-from-file` do build (ver `env/dev.env` e
/// `env/prod.env.example`). O padrão é `dev`, para que builds sem o define
/// (CI, testes, `flutter run` simples) nunca sejam confundidos com produção.
enum AppFlavor { dev, prod }

abstract final class AppFlavorConfig {
  /// Valor cru do dart-define (`dev` ou `prod`).
  static const String rawFlavor =
      String.fromEnvironment('FLUTTER_APP_FLAVOR', defaultValue: 'dev');

  /// Flavor atual, derivado de [rawFlavor].
  static AppFlavor get current =>
      rawFlavor == 'prod' ? AppFlavor.prod : AppFlavor.dev;

  /// O build é de produção?
  static bool get isProd => current == AppFlavor.prod;

  /// Rótulo curto do flavor (`dev` / `prod`) para logs e relatórios.
  static String get label => current.name;
}
