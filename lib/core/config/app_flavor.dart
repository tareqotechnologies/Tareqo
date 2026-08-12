/// Flavor de ambiente compilado no app (auditoria 2.4).
///
/// Em Android/iOS/macOS o valor vem do define reservado `FLUTTER_APP_FLAVOR`,
/// injetado pelo framework a partir do `--flavor` do build (ver
/// `env/dev.env` e `env/prod.env.example`) — não pode ser passado à mão.
///
/// No desktop Windows (sem suporte a `--flavor` neste Flutter) usa-se o
/// define livre `APP_FLAVOR` como fallback, para que um release EXE de
/// produção seja realmente `prod` (a guarda do main.dart exige isso).
///
/// O padrão é `dev`, para que builds sem o define (CI, testes, `flutter run`
/// simples) nunca sejam confundidos com produção.
enum AppFlavor { dev, prod }

abstract final class AppFlavorConfig {
  /// Valor cru do dart-define (`dev` ou `prod`).
  static const String rawFlavor = String.fromEnvironment(
    'FLUTTER_APP_FLAVOR',
    defaultValue: String.fromEnvironment('APP_FLAVOR', defaultValue: 'dev'),
  );

  /// Flavor atual, derivado de [rawFlavor].
  static AppFlavor get current =>
      rawFlavor == 'prod' ? AppFlavor.prod : AppFlavor.dev;

  /// O build é de produção?
  static bool get isProd => current == AppFlavor.prod;

  /// Rótulo curto do flavor (`dev` / `prod`) para logs e relatórios.
  static String get label => current.name;
}
