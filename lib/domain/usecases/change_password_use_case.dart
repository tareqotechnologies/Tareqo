import '../repositories/i_auth_repository.dart';

/// Caso de uso: trocar a senha do usuário logado, validando a senha atual.
class ChangePasswordUseCase {
  const ChangePasswordUseCase(this._repository);

  final IAuthRepository _repository;

  Future<void> call({
    required String currentPassword,
    required String newPassword,
  }) => _repository.changePassword(
    currentPassword: currentPassword,
    newPassword: newPassword,
  );
}
