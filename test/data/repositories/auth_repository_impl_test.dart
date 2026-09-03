import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/data/datasources/auth/auth_remote_data_source.dart';
import 'package:tareqo/data/repositories/auth_repository_impl.dart';
import 'package:tareqo/domain/entities/app_user.dart';
import 'package:tareqo/domain/entities/auth_event.dart';

class _FakeAuthRemoteDataSource implements AuthRemoteDataSource {
 final _controller = StreamController<AppUser?>.broadcast();

 bool signOutCalled = false;
 String? lastSignInEmail;
 String? lastSignInPassword;
 String? lastResetEmail;
 String? lastChangedTo;
 String? lastSetNew;

 @override
 Future<AppUser> signUp({
 required String email,
 required String password,
 String? fullName,
 }) async {
 return AppUser(id: 'novo', email: email, fullName: fullName ?? '');
 }

 @override
 Future<AppUser> signIn({
 required String email,
 required String password,
 }) async {
 lastSignInEmail = email;
 lastSignInPassword = password;
 return const AppUser(id: '1', email: 'dono@loja.com');
 }

 @override
 Future<void> signOut() async {
 signOutCalled = true;
 }

 @override
 Future<void> resetPassword({required String email}) async {
 lastResetEmail = email;
 }

 @override
 Future<void> changePassword({
 required String currentPassword,
 required String newPassword,
 }) async {
 lastChangedTo = newPassword;
 }

 @override
 Future<void> setNewPassword({required String newPassword}) async {
 lastSetNew = newPassword;
 }

 @override
 Stream<AppUser?> get authStateChanges => _controller.stream;

 @override
 Stream<AuthEvent> get authEvents => const Stream.empty();

 void emit(AppUser? user) => _controller.add(user);

 Future<void> close() => _controller.close();
}

void main() {
 late _FakeAuthRemoteDataSource dataSource;
 late AuthRepositoryImpl repository;

 setUp(() {
 dataSource = _FakeAuthRemoteDataSource();
 repository = AuthRepositoryImpl(dataSource);
 });

 tearDown(() => dataSource.close());

 test(
 'signIn repassa credenciais e retorna o AppUser personalizado',
 () async {
 final user = await repository.signIn(
 email: 'dono@loja.com',
 password: 'segredo123',
 );

 expect(dataSource.lastSignInEmail, 'dono@loja.com');
 expect(dataSource.lastSignInPassword, 'segredo123');
 // Retorna o objeto de domínio, não o User do provedor.
 expect(user, isA<AppUser>());
 expect(user.email, 'dono@loja.com');
 },
 );

 test('signUp repassa nome e retorna AppUser', () async {
 final user = await repository.signUp(
 email: 'novo@loja.com',
 password: 'segredo123',
 fullName: 'Maria',
 );

 expect(user.fullName, 'Maria');
 });

 test('signOut delega ao datasource', () async {
 await repository.signOut();

 expect(dataSource.signOutCalled, isTrue);
 });

 test(
 'resetPassword/changePassword/setNewPassword delegam ao datasource',
 () async {
 await repository.resetPassword(email: 'dono@loja.com');
 expect(dataSource.lastResetEmail, 'dono@loja.com');

 await repository.changePassword(
 currentPassword: 'atual1!',
 newPassword: 'nova2@',
 );
 expect(dataSource.lastChangedTo, 'nova2@');

 await repository.setNewPassword(newPassword: 'nova2@');
 expect(dataSource.lastSetNew, 'nova2@');
 },
 );

 test('authStateChanges repassa o fluxo de sessão', () async {
 final events = <AppUser?>[];
 final subscription = repository.authStateChanges.listen(events.add);

 dataSource.emit(const AppUser(id: '1', email: 'dono@loja.com'));
 dataSource.emit(null);

 await Future<void>.delayed(Duration.zero);

 expect(events, hasLength(2));
 expect(events.first?.email, 'dono@loja.com');
 expect(events.last, isNull);

 await subscription.cancel();
 });
}
