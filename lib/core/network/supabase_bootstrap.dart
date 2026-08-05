import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

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

    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.anonKey,
    );
  }
}
