import 'dart:io' show Platform;

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
  /// Flavor detectado via variável de ambiente no runtime (padrão `dev`).
  /// No Windows o Flutter não injeta `FLUTTER_APP_FLAVOR` via --flavor, então
  /// a detecção em runtime usa FLUTTER_APP_FLAVOR do ambiente — definida em
  /// dev/test pelo ciadores e em prod via script de lançamento antes de rodar
  /// o .exe. Em builds sem a variável o app é considerado dev/sandbox.
  static AppFlavor get current {
    final fromEnv = Platform.environment['FLUTTER_APP_FLAVOR'];
    if (fromEnv == 'prod') return AppFlavor.prod;
    const raw = String.fromEnvironment(
      'FLUTTER_APP_FLAVOR',
      defaultValue: String.fromEnvironment('APP_FLAVOR', defaultValue: 'dev'),
    );
    return raw == 'prod' ? AppFlavor.prod : AppFlavor.dev;
  }

  /// O build é de produção?
  static bool get isProd => current == AppFlavor.prod;

  /// Rótulo curto do flavor (`dev` / `prod`) para logs e relatórios.
  static String get label => current.name;
}
