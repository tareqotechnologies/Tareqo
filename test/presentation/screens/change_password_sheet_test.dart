import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

import 'package:dumbhanengue/domain/entities/app_user.dart';
import 'package:dumbhanengue/domain/entities/auth_event.dart';
import 'package:dumbhanengue/domain/repositories/i_auth_repository.dart';
import 'package:dumbhanengue/presentation/controllers/auth_providers.dart';
import 'package:dumbhanengue/presentation/screens/auth/change_password_sheet.dart';
import 'package:dumbhanengue/presentation/widgets/app_sheet.dart';

class _FakeAuthRepository implements IAuthRepository {
 final _controller = StreamController<AppUser?>.broadcast();

 String? lastCurrent;
 String? lastNew;
 Exception? errorToThrow;

 @override
 Future<AppUser> signUp({
 required String email,
 required String password,
 String? fullName,
 }) async => throw UnimplementedError();

 @override
 Future<AppUser> signIn({
 required String email,
 required String password,
 }) async => throw UnimplementedError();

 @override
 Future<void> signOut() async {}

 @override
 Future<void> resetPassword({required String email}) async {}

 @override
 Future<void> changePassword({
 required String currentPassword,
 required String newPassword,
 }) async {
 if (errorToThrow != null) throw errorToThrow!;
 lastCurrent = currentPassword;
 lastNew = newPassword;
 }

 @override
 Future<void> setNewPassword({required String newPassword}) async {}

 @override
 Stream<AppUser?> get authStateChanges => _controller.stream;

 @override
 Stream<AuthEvent> get authEvents => const Stream.empty();
}

Widget _buildApp(IAuthRepository repository) {
 return ProviderScope(
 overrides: [authRepositoryProvider.overrideWithValue(repository)],
 child: testApp(
 home: Builder(
 builder: (context) => Scaffold(
 body: Center(
 child: ElevatedButton(
 onPressed: () => showAppSheet<void>(
 context,
 builder: (_) => const ChangePasswordSheet(),
 ),
 child: const Text('abrir'),
 ),
 ),
 ),
 ),
 ),
 );
}

void main() {
 testWidgets('troca a senha validando a atual e a nova (política forte)', (
 tester,
 ) async {
 final repository = _FakeAuthRepository();
 await tester.pumpWidget(_buildApp(repository));

 await tester.tap(find.text('abrir'));
 await tester.pumpAndSettle();
 expect(find.text('Trocar senha'), findsOneWidget);

 await tester.enterText(find.byType(TextFormField).at(0), 'SenhaAtual1!');
 await tester.enterText(find.byType(TextFormField).at(1), 'NovaSenha2@');
 await tester.enterText(find.byType(TextFormField).at(2), 'NovaSenha2@');

 await tester.ensureVisible(find.text('Alterar senha'));
 await tester.tap(find.text('Alterar senha'));
 await tester.pumpAndSettle();

 expect(repository.lastCurrent, 'SenhaAtual1!');
 expect(repository.lastNew, 'NovaSenha2@');
 expect(find.text('Senha alterada com sucesso!'), findsOneWidget);
 });

 testWidgets('senha nova fraca bloqueia o envio (4 classes exigidas)', (
 tester,
 ) async {
 final repository = _FakeAuthRepository();
 await tester.pumpWidget(_buildApp(repository));

 await tester.tap(find.text('abrir'));
 await tester.pumpAndSettle();

 await tester.enterText(find.byType(TextFormField).at(0), 'SenhaAtual1!');
 await tester.enterText(find.byType(TextFormField).at(1), 'fraca123');
 await tester.enterText(find.byType(TextFormField).at(2), 'fraca123');

 await tester.ensureVisible(find.text('Alterar senha'));
 await tester.tap(find.text('Alterar senha'));
 await tester.pumpAndSettle();

 expect(
 find.text(
 'A senha deve conter letras minúsculas, maiúsculas, números e símbolos.',
 ),
 findsOneWidget,
 );
 expect(repository.lastNew, isNull);
 });

 testWidgets('confirmação diferente da nova senha bloqueia o envio', (
 tester,
 ) async {
 final repository = _FakeAuthRepository();
 await tester.pumpWidget(_buildApp(repository));

 await tester.tap(find.text('abrir'));
 await tester.pumpAndSettle();

 await tester.enterText(find.byType(TextFormField).at(0), 'SenhaAtual1!');
 await tester.enterText(find.byType(TextFormField).at(1), 'NovaSenha2@');
 await tester.enterText(find.byType(TextFormField).at(2), 'OutraSenha3#');

 await tester.ensureVisible(find.text('Alterar senha'));
 await tester.tap(find.text('Alterar senha'));
 await tester.pumpAndSettle();

 expect(find.text('As senhas não coincidem.'), findsOneWidget);
 expect(repository.lastNew, isNull);
 });
}
