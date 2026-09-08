import 'package:tareqo/core/config/supabase_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SupabaseConfig', () {
    test('sem dart-define, usa os defaults de desenvolvimento (S2)', () {
      // Em testes (sem --dart-define) as credenciais embutidas de
      // desenvolvimento estão ativas — exatamente o cenário que a guarda
      // de release (SupabaseBootstrap) rejeita com StateError em kReleaseMode.
      expect(SupabaseConfig.isConfigured, isTrue);
      expect(SupabaseConfig.usesEmbeddedDefaults, isTrue);
      expect(SupabaseConfig.url, isNotEmpty);
      expect(SupabaseConfig.anonKey, isNotEmpty);
    });
  });
}
