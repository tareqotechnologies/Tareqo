import 'package:integration_test/integration_test.dart';

import '../../../integration_test/cert_pinning_live_test.dart' as cert;

/// Executa o E2E de certificate pinning na VM do host (`flutter test`),
/// sem device. O corpo do teste é EXATAMENTE o de
/// `integration_test/cert_pinning_live_test.dart` (importado, não copiado):
///
/// - handshake TLS REAL contra o Supabase de dev (endpoint `/auth/v1/health`);
/// - âncora WE1 real (positivo) e âncora falsa (negativo fail-closed).
///
/// Por que este wrapper existe: `cert_pinning_io.dart` usa `dart:io`
/// (SecurityContext) e NÃO compila para web — o `flutter drive -d chrome`
/// original do E2E nunca termina (o doc do módulo documenta o stub web
/// exatamente por isso). A VM do host executa o mesmo `dart:io` e o MESMO
/// handshake TLS, então a validação é equivalente.
///
///   flutter test test/core/network/cert_pinning_live_host_test.dart \
///     --dart-define-from-file=env/dev.env
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // Guarda de hermeticidade: SUPABASE_URL lido SEM default — só é não-vazio
  // quando passado EXPLICITAMENTE via --dart-define(-from-file). NÃO dá
  // para usar SupabaseConfig.isConfigured: os defaults embutidos de dev o
  // tornam sempre verdadeiro e o teste falaria com a rede no CI.
  const explicitUrl = String.fromEnvironment('SUPABASE_URL');
  if (explicitUrl.isEmpty) {
    // ignore: avoid_print
    print(
      'SKIPPED (sem credenciais): passe --dart-define-from-file=env/dev.env '
      'para validar o pin contra o Supabase real.',
    );
    return;
  }
  cert.main();
}
