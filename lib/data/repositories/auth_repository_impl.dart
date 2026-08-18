import '../../domain/entities/app_user.dart';
import '../../domain/entities/auth_event.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../datasources/auth/auth_remote_data_source.dart';

/// Implementação de [IAuthRepository] sobre [AuthRemoteDataSource].
///
/// O repositório não sabe se a autenticação vem do Supabase, Firebase ou
/// outro provedor — apenas delega ao datasource injetado.
final class AuthRepositoryImpl implements IAuthRepository {
 const AuthRepositoryImpl(this._remoteDataSource);

 final AuthRemoteDataSource _remoteDataSource;

 @override
 Future<AppUser> signUp({
 required String email,
 required String password,
 String? fullName,
 }) => _remoteDataSource.signUp(
 email: email,
 password: password,
 fullName: fullName,
 );

 @override
 Future<AppUser> signIn({required String email, required String password}) =>
 _remoteDataSource.signIn(email: email, password: password);

 @override
 Future<void> signOut() => _remoteDataSource.signOut();

 @override
 Future<void> resetPassword({required String email}) =>
 _remoteDataSource.resetPassword(email: email);

 @override
 Future<void> changePassword({
 required String currentPassword,
 required String newPassword,
 }) => _remoteDataSource.changePassword(
 currentPassword: currentPassword,
 newPassword: newPassword,
 );

 @override
 Future<void> setNewPassword({required String newPassword}) =>
 _remoteDataSource.setNewPassword(newPassword: newPassword);

 @override
 Stream<AppUser?> get authStateChanges => _remoteDataSource.authStateChanges;

 @override
 Stream<AuthEvent> get authEvents => _remoteDataSource.authEvents;
}
