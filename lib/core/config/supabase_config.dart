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

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: _defaultUrl,
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: _defaultAnonKey,
  );

  /// Se as credenciais estão preenchidas para inicializar o cliente.
  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;

  /// O build forneceu as credenciais do Supabase EXPLICITAMENTE?
  ///
  /// O Dart não consegue distinguir "define passado com o mesmo valor do
  /// default" de "default usado" comparando apenas valores — os defaults
  /// embutidos apontam para DEV, então um build de dev tem valores
  /// idênticos e não é distinguível só pela comparação; por isso o marcador
  /// `SUPABASE_CREDENTIALS_EXPLICIT=true` acompanha os defines de
  /// SUPABASE_URL/SUPABASE_ANON_KEY em env/*.env, fastlane e CI (auditoria
  /// A1). Dev e produção são projetos SEPARADOS desde Set/2026
  /// (`dotklbpqmlnhcdifiukd` / `bcyolmheltzlddfwgqcq`), logo um release de
  /// produção tem valores diferentes do default.
  static const bool credentialsExplicit = bool.fromEnvironment(
    'SUPABASE_CREDENTIALS_EXPLICIT',
    defaultValue: false,
  );

  /// O build está a usar os DEFAULTS embutidos (projeto de desenvolvimento)
  /// porque as credenciais NÃO foram fornecidas explicitamente. Em release
  /// isso é SEMPRE um erro de configuração, em qualquer flavor (auditoria
  /// H5/S2 + A1): um APK publicado com os defaults falaria silenciosamente
  /// contra o projeto errado — o `SupabaseBootstrap` rejeita em
  /// kReleaseMode quando `usesEmbeddedDefaults` é verdadeiro.
  static bool get usesEmbeddedDefaults => !credentialsExplicit;
}
