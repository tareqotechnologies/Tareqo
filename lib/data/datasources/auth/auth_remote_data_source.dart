import '../../../domain/entities/app_user.dart';

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

  Future<AppUser> signIn({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Stream<AppUser?> get authStateChanges;
}
