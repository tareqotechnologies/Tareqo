import '../repositories/i_auth_repository.dart';

/// Caso de uso: enviar o link de redefinição de senha ("Esqueceu a
/// senha?"). Não revela se a conta existe (anti-enumeração).
class ResetPasswordUseCase {
  const ResetPasswordUseCase(this._repository);

  final IAuthRepository _repository;

  Future<void> call({required String email}) =>
      _repository.resetPassword(email: email);
}
