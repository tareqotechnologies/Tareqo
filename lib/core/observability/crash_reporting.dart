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
 Sentry.captureException(
 details.exception,
 stackTrace: details.stack,
 );
 };
 },
 );
 }

 /// Registra um erro de aplicação (catch de telas/providers) no canal
 /// ativo: console em debug, Sentry em release.
 static void capture(Object error, StackTrace stackTrace, {String? hint}) {
 if (isEnabled) {
 Sentry.captureException(error, stackTrace: stackTrace);
 }
 // `debugPrint` mantém a legibilidade do desenvolvimento; no release o
 // Sentry já tem o evento (evita imprimir dados sensíveis no console).
 if (kDebugMode) {
 debugPrint('[erro]${hint == null ? '' : ' $hint'} $error\n$stackTrace');
 }
 }
}
