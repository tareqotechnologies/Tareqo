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
        'Atenção: Supabase não configurado. Defina SUPABASE_URL e SUPABASE_ANON_KEY '
        'via --dart-define.',
      );
      return;
    }

    // Fail-fast (auditoria S2 + A1): um build RELEASE NUNCA pode apontar
    // para os defaults embutidos — independentemente do flavor. O flavor é
    // a porta de entrada (o main.dart já bloqueia release sem `--flavor
    // prod`); aqui a guarda é redundância defensiva em camada por VALOR:
    // release + credenciais embutidas = erro de configuração.
    //
    // Antes (deploy Aug 2026) o projeto Supabase era ÚNICO e compartilhado
    // entre dev e prod, então um release prod com os defaults era aceite de
    // propósito. Desde a auditoria A1 todo release EXIGE as credenciais
    // EXPLÍCITAS (--dart-define-from-file=env/prod.env ou --dart-define),
    // mesmo que hoje o env/prod.env ainda aponte para o projeto único — o
    // passo de infra pendente é criar o projeto de PRODUÇÃO separado e
    // atualizar env/prod.env (ver docs/13-build-e-publicacao e o checklist
    // de produção).
    if (kReleaseMode && SupabaseConfig.usesEmbeddedDefaults) {
      throw StateError(
        'Build de release com as credenciais EMBUTIDAS (defaults de '
        'desenvolvimento): o APK falaria contra o projeto errado. Passe '
        'SUPABASE_URL/SUPABASE_ANON_KEY explícitos + o marcador '
        'SUPABASE_CREDENTIALS_EXPLICIT=true via --dart-define-from-file=env/'
        'prod.env ou --dart-define (ver docs/13-build-e-publicacao).',
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
      // Atenção: Na web (flutter_secure_storage 10.x não a suporta), o default do
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
