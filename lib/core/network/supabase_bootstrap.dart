import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../security/secure_supabase_local_storage.dart';
import 'timeout_retry_http_client.dart';

/// Inicialização do cliente Supabase (chamada no `main()` antes do runApp).
abstract final class SupabaseBootstrap {
  /// Inicializa o Supabase se [SupabaseConfig] estiver preenchido.
  ///
  /// Sem credenciais, apenas registra um aviso (útil em desenvolvimento);
  /// as chamadas de autenticação só funcionarão após configurar.
  static Future<void> initialize() async {
    if (!SupabaseConfig.isConfigured) {
      debugPrint(
        '⚠ Supabase não configurado. Defina SUPABASE_URL e SUPABASE_ANON_KEY '
        'via --dart-define.',
      );
      return;
    }

    // Fail-fast (auditoria S2): um build RELEASE nunca pode apontar para o
    // projeto de desenvolvimento embutido nos defaults. Em debug o default
    // é útil (desenvolvimento); em release é erro de configuração.
    if (kReleaseMode && SupabaseConfig.usesEmbeddedDefaults) {
      throw StateError(
        'Build de release sem SUPABASE_URL/SUPABASE_ANON_KEY: o APK falaria '
        'silenciosamente contra o projeto de desenvolvimento. Passe os '
        'dart-defines do ambiente de produção (ver docs/13-build-e-publicacao).',
      );
    }

    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.anonKey,
      // W6: timeout global + retry de leituras idempotentes (GET/HEAD) em
      // timeout/5xx/429 — cobre todas as chamadas REST de forma central.
      httpClient: TimeoutRetryHttpClient(),
      // Auditoria S1 (Aug 6): a sessão do Supabase é persistida no
      // Keychain/Keystore via [SecureSupabaseLocalStorage] em plataformas
      // nativas — o default do SDK usa `shared_preferences` (texto claro).
      // O code verifier do PKCE também vai para o armazenamento seguro
      // ([SecureGotrueAsyncStorage]) — nenhum material de autenticação fica
      // em texto claro no dispositivo.
      // ⚠️ Na web (flutter_secure_storage 10.x não a suporta), o default do
      // SDK é mantido (localStorage do navegador — limitação documentada).
      authOptions: kIsWeb
          ? const FlutterAuthClientOptions()
          : FlutterAuthClientOptions(
              localStorage: SecureSupabaseLocalStorage(),
              pkceAsyncStorage: SecureGotrueAsyncStorage(),
            ),
    );
  }
}
