/// Evento de autenticação em bruto — espelho dos eventos do provedor
/// (gotrue) sem vazar o tipo do Supabase para o domínio.
enum AuthEvent {
  /// A sessão foi criada a partir de um link de RECUPERAÇÃO de senha — o
  /// [AuthGate] mostra a tela de definir nova senha antes de entrar.
  passwordRecovery,

  /// Qualquer outro evento (sessão inicial, login, logout, refresh...).
  other,
}
