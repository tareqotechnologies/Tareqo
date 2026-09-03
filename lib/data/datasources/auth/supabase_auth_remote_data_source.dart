import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/entities/app_user.dart';
import '../../../domain/entities/auth_event.dart';
import 'auth_remote_data_source.dart';

/// Implementação [AuthRemoteDataSource] sobre o Supabase (gotrue).
///
/// Toda a conversão do `User` do Supabase para o [AppUser] do domínio
/// acontece aqui — as camadas acima nunca enxergam gotrue.
final class SupabaseAuthRemoteDataSourceImpl implements AuthRemoteDataSource {
 GoTrueClient get _auth => Supabase.instance.client.auth;

 @override
 Future<AppUser> signUp({
 required String email,
 required String password,
 String? fullName,
 }) async {
 final response = await _auth.signUp(
 email: email,
 password: password,
 data: fullName == null ? null : {'full_name': fullName},
 );
 // Se a confirmação por e-mail estiver ativa, o `user` pode ser null
 // (a conta é criada, mas a sessão só vem após confirmar).
 return _toAppUser(
 response.user,
 fallbackEmail: email,
 fallbackName: fullName,
 );
 }

 @override
 Future<AppUser> signIn({
 required String email,
 required String password,
 }) async {
 final response = await _auth.signInWithPassword(
 email: email,
 password: password,
 );
 final user = response.user;
 if (user == null) {
 throw AuthException('Falha ao autenticar: nenhum usuário retornado.');
 }
 return _toAppUser(user);
 }

 @override
 Future<void> signOut() => _auth.signOut();  @override
  Future<void> resetPassword({required String email}) =>
      _auth.resetPasswordForEmail(
        email,
        redirectTo: 'tareqo://callback',
      );

 @override
 Future<void> changePassword({
 required String currentPassword,
 required String newPassword,
 }) async {
 final email = _auth.currentUser?.email;
 if (email == null) {
 throw AuthException('Sessão expirada — entre novamente.');
 }
 // O GoTrue exige sessão RECENTE para `updateUser`: reautentica com a
 // senha atual (valida a senha E renova a sessão) antes de gravar a nova.
 await _auth.signInWithPassword(email: email, password: currentPassword);
 await _auth.updateUser(UserAttributes(password: newPassword));
 }

 @override
 Future<void> setNewPassword({required String newPassword}) =>
 _auth.updateUser(UserAttributes(password: newPassword));  @override
  Stream<AppUser?> get authStateChanges {
    final controller = StreamController<AppUser?>.broadcast();
    StreamSubscription<AuthState>? sub;

    // Emit the current session when the FIRST listener subscribes.
    // A broadcast stream silently drops values emitted before any
    // listener exists — so adding the value eagerly in the getter body
    // meant the StreamProvider (Riverpod) never saw it and stayed stuck
    // in `loading`, causing an infinite splash → timeout loop.
    controller.onListen = () {
      try {
        final current = _auth.currentSession?.user;
        controller.add(current == null ? null : _toAppUser(current));
      } catch (e) {
        // Session restore failed — emit null (logged out) instead of
        // crashing the stream (which would show the error screen).
        controller.add(null);
      }

      // Forward future changes from onAuthStateChange.
      // Wrapped in try-catch: if Supabase isn't fully ready yet,
      // the stream gracefully falls back to null (login screen).
      try {
        sub = _auth.onAuthStateChange.listen(
          (state) {
            try {
              final user = state.session?.user;
              controller.add(user == null ? null : _toAppUser(user));
            } catch (e) {
              // Ignore malformed user data — keep previous state.
            }
          },
          onError: (Object error) {
            // Auth stream error (e.g. network timeout during token refresh).
            // Emit null instead of propagating the error — the user will see
            // the login screen rather than the error screen.
            if (!controller.isClosed) {
              controller.add(null);
            }
          },
        );
      } catch (e) {
        // Supabase not ready — stream will just emit the initial null/current.
      }
    };
    controller.onCancel = () {
      sub?.cancel();
      sub = null;
    };
    return controller.stream;
  }

  @override
  Stream<AuthEvent> get authEvents {
    final controller = StreamController<AuthEvent>.broadcast();
    // Emit the initial event when the FIRST listener subscribes.
    // Same reasoning as authStateChanges: eagerly adding to a broadcast
    // stream before any listener exists silently drops the value.
    controller.onListen = () {
      controller.add(AuthEvent.other);
    };
    final sub = _auth.onAuthStateChange.listen(
      (state) {
        final event = state.event == AuthChangeEvent.passwordRecovery
            ? AuthEvent.passwordRecovery
            : AuthEvent.other;
        controller.add(event);
      },
      onError: (Object error) {
        // Auth stream error — emit default event instead of crashing.
        if (!controller.isClosed) {
          controller.add(AuthEvent.other);
        }
      },
    );
    controller.onCancel = () => sub.cancel();
    return controller.stream;
  }

 AppUser _toAppUser(
 User? user, {
 String? fallbackEmail,
 String? fallbackName,
 }) {
 if (user == null) {
 // Confirmação de e-mail pendente: ainda não existe um uid real do
 // Supabase. O id é um PLACEHOLDER (não canônico) — nenhum dado deve
 // ser associado a ele; a sessão real só chega após a confirmação.
 return AppUser(
 id: fallbackEmail ?? '',
 email: fallbackEmail ?? '',
 fullName: fallbackName ?? '',
 );
 }
 return AppUser(
 id: user.id,
 email: user.email ?? fallbackEmail ?? '',
 fullName:
 (user.userMetadata?['full_name'] as String?) ?? fallbackName ?? '',
 );
 }
}
