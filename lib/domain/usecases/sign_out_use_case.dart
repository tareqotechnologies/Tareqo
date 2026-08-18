import '../repositories/i_auth_repository.dart';

/// Caso de uso: encerrar a sessão do usuário.
class SignOutUseCase {
 const SignOutUseCase(this._repository);

 final IAuthRepository _repository;

 Future<void> call() => _repository.signOut();
}
