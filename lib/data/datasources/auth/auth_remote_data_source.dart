import '../../../domain/entities/app_user.dart';
import '../../../domain/entities/auth_event.dart';

/// Contrato de autenticação remota (camada de dados).
///
/// Implementação concreta: [SupabaseAuthRemoteDataSourceImpl] (Supabase).
/// O domínio nunca conhece este contrato — apenas o repositório.
abstract interface class AuthRemoteDataSource {
  Future<AppUser> signUp({
    required String email,
    required String password,
    String? fullName,
  });

  Future<AppUser> signIn({required String email, required String password});

  Future<void> signOut();

  /// Envia o link de redefinição de senha (fluxo "Esqueceu a senha?").
  Future<void> resetPassword({required String email});

  /// Troca a senha do usuário logado, validando a senha atual.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Define uma nova senha na sessão de recuperação.
  Future<void> setNewPassword({required String newPassword});

  Stream<AppUser?> get authStateChanges;

  /// Eventos de autenticação em bruto (recovery etc.).
  Stream<AuthEvent> get authEvents;
}
