import '../entities/app_user.dart';
import '../entities/auth_event.dart';

/// Contrato de autenticação (camada de domínio).
///
/// Retorna sempre o [AppUser] personalizado — o domínio nunca enxerga o
/// `User` do Supabase. A implementação concreta vive na camada `data`.
abstract interface class IAuthRepository {
  /// Cria uma nova conta e retorna o usuário.
  Future<AppUser> signUp({
    required String email,
    required String password,
    String? fullName,
  });

  /// Autentica com e-mail e senha e retorna o usuário.
  Future<AppUser> signIn({required String email, required String password});

  /// Encerra a sessão atual.
  Future<void> signOut();

  /// Envia o link de redefinição de senha para o e-mail (fluxo "Esqueceu a
  /// senha?"). Não revela se a conta existe (anti-enumeração).
  Future<void> resetPassword({required String email});

  /// Troca a senha do usuário logado, validando a senha atual (a sessão é
  /// renovada para atender à exigência de reautenticação do provedor).
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Define uma nova senha a partir da sessão de RECUPERAÇÃO (o link do
  /// e-mail já foi trocado — o usuário está autenticado em modo recovery).
  Future<void> setNewPassword({required String newPassword});

  /// Fluxo de sessão: emite o usuário atual (ou `null` quando deslogado)
  /// e reage a login/logout — usado para persistência e navegação.
  Stream<AppUser?> get authStateChanges;

  /// Eventos de autenticação em bruto — permite ao [AuthGate] detectar o
  /// fluxo de recuperação de senha vindo do link do e-mail.
  Stream<AuthEvent> get authEvents;
}
