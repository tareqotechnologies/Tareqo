import '../entities/app_user.dart';
import '../repositories/i_auth_repository.dart';

/// Caso de uso: criar uma nova conta.
class SignUpUseCase {
  const SignUpUseCase(this._repository);

  final IAuthRepository _repository;

  Future<AppUser> call({
    required String email,
    required String password,
    String? fullName,
  }) =>
      _repository.signUp(email: email, password: password, fullName: fullName);
}
