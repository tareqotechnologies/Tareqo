import '../repositories/i_auth_repository.dart';

/// Caso de uso: definir uma nova senha a partir da sessão de RECUPERAÇÃO
/// (link do e-mail já trocado — o usuário está autenticado em modo
/// recovery e ainda não tem senha nova).
class SetNewPasswordUseCase {
  const SetNewPasswordUseCase(this._repository);

  final IAuthRepository _repository;

  Future<void> call({required String newPassword}) =>
      _repository.setNewPassword(newPassword: newPassword);
}
