/// Configuração do Supabase.
///
/// Os valores padrão apontam para o projeto de desenvolvimento. A anon key
/// é **pública por design** no modelo Supabase (fica embutida no app do
/// cliente — a segurança real vem do Row Level Security). **Nunca** coloque
/// a service role key aqui: ela é exclusiva do servidor.
///
/// Para apontar para outro projeto (produção), sobrescreva no build:
/// `flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
abstract final class SupabaseConfig {
 static const String _defaultUrl = 'https://dotklbpqmlnhcdifiukd.supabase.co';

 static const String _defaultAnonKey =
 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
 'eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRvdGtsYnBxbWxuaGNkaWZpdWtkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODU1ODk2NTcsImV4cCI6MjEwMTE2NTY1N30.'
 'ssUUe7G2U5LDKP1-b8FO8ngTwq6_RODxE58NuGw2Zfs';

 static const String url =
 String.fromEnvironment('SUPABASE_URL', defaultValue: _defaultUrl);

 static const String anonKey = String.fromEnvironment(
 'SUPABASE_ANON_KEY',
 defaultValue: _defaultAnonKey,
 );

 /// Se as credenciais estão preenchidas para inicializar o cliente.
 static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;

 /// O build está a usar os DEFAULTS embutidos (projeto de desenvolvimento)
 /// em vez de `--dart-define`? Em release isso é um erro de configuração:
 /// um APK publicado falaria silenciosamente contra o projeto errado
 /// (auditoria H5/S2).
 static bool get usesEmbeddedDefaults =>
 url == _defaultUrl && anonKey == _defaultAnonKey;
}
