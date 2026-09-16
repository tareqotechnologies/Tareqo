import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Observabilidade (auditoria H4): crash reporting via Sentry.
///
/// Ativado quando `SENTRY_DSN` é passado no build:
/// flutter run --dart-define=SENTRY_DSN=https://chave@sentry.io/projeto
///
/// Sem DSN (dev/CI) o serviço é um no-op silencioso — o app não depende do
/// Sentry para funcionar. O DSN é **público por design** (cliente mobile/web
/// precisa embuti-lo); a segurança do Sentry vem das permissões do projeto.
///
/// Também centraliza o log de erros de UI: em vez de `debugPrint` solto,
/// as telas chamam [CrashReporting.capture] — no debug imprime no console,
/// em release envia ao Sentry (auditoria M2: log estruturado em um lugar só).
abstract final class CrashReporting {
  static const String _dsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue: '',
  );

  static bool get isEnabled => _dsn.isNotEmpty;

  /// Inicializa o Sentry (se DSN configurado) e os handlers globais de
  /// erros não capturados (Flutter + Dart).
  static Future<void> initialize() async {
    if (!isEnabled) return;

    await SentryFlutter.init(
      (options) {
        options.dsn = _dsn;
        // Erros não capturados de widgets/flutter.
        options.environment = kReleaseMode ? 'production' : 'development';
        // Logs estruturados (Sentry Logs, SDK >= 9.0): `Sentry.logger.*`
        // envia entradas de log ao projeto — visíveis em Logs Explorer.
        // A captura por INTEGRAÇÃO (console/dart:loggin) fica OFF para não
        // duplicar eventos; o que enviamos explicitamente via [log] é
        // sempre capturado.
        options.enableLogs = true;
        // Não enviar eventos esperados de negócio (ex.: StateError de
        // entidade inválida já tratado pela UI) — reduz ruído no Sentry.
        options.beforeSend = (event, _) {
          final throwable = event.throwable;
          if (throwable is StateError) return null;
          return event;
        };
      },
      appRunner: () {
        FlutterError.onError = (details) {
          FlutterError.presentError(details);
          Sentry.captureException(details.exception, stackTrace: details.stack);
        };
      },
    );
  }

  /// Log estruturado no Sentry (novo API de Logs do SDK 9.x). No-op sem
  /// DSN — o app nunca depende do Sentry para funcionar. Níveis:
  /// trace/debug/info/warn/error/fatal via [SentryLevel].
  static void log(
    String message,
    SentryLevel level, {
    String? hint,
    Map<String, String>? attributes,
  }) {
    if (!isEnabled) return;
    final attrs = {
      if (hint != null) 'hint': SentryAttribute.string(hint),
      ...?attributes?.map((k, v) => MapEntry(k, SentryAttribute.string(v))),
    };
    switch (level) {
      case SentryLevel.fatal:
        Sentry.logger.fatal(message, attributes: attrs);
      case SentryLevel.error:
        Sentry.logger.error(message, attributes: attrs);
      case SentryLevel.warning:
        Sentry.logger.warn(message, attributes: attrs);
      case SentryLevel.info:
        Sentry.logger.info(message, attributes: attrs);
      case SentryLevel.debug:
        Sentry.logger.debug(message, attributes: attrs);
      default:
        Sentry.logger.trace(message, attributes: attrs);
    }
    if (kDebugMode) {
      debugPrint('[log ${level.name}]${hint == null ? '' : ' $hint'} $message');
    }
  }

  /// Registra um erro de aplicação (catch de telas/providers) no canal
  /// ativo: console em debug, Sentry em release.
  static void capture(Object error, StackTrace stackTrace, {String? hint}) {
    if (isEnabled) {
      // B3: o `hint` agora acompanha o evento no Sentry como TAG (antes era
      // ignorado — só aparecia no console em debug), dando contexto de
      // negócio para filtrar/agrupar no dashboard.
      Sentry.captureException(
        error,
        stackTrace: stackTrace,
        withScope: (scope) {
          if (hint != null) scope.setTag('hint', hint);
        },
      );
    }
    // `debugPrint` mantém a legibilidade do desenvolvimento; no release o
    // Sentry já tem o evento (evita imprimir dados sensíveis no console).
    if (kDebugMode) {
      debugPrint('[erro]${hint == null ? '' : ' $hint'} $error\n$stackTrace');
    }
  }
}
