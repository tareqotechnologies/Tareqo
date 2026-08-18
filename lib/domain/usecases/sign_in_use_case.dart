import '../entities/app_user.dart';
import '../repositories/i_auth_repository.dart';

/// Caso de uso: autenticar o usuário com e-mail e senha.
class SignInUseCase {
 const SignInUseCase(this._repository);

 final IAuthRepository _repository;

 Future<AppUser> call({required String email, required String password}) =>
 _repository.signIn(email: email, password: password);
}
