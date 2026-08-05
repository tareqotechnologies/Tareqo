import '../entities/app_user.dart';

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
  Future<AppUser> signIn({
    required String email,
    required String password,
  });

  /// Encerra a sessão atual.
  Future<void> signOut();

  /// Fluxo de sessão: emite o usuário atual (ou `null` quando deslogado)
  /// e reage a login/logout — usado para persistência e navegação.
  Stream<AppUser?> get authStateChanges;
}
