import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/supabase_config.dart';
import '../../core/di/service_locator.dart';
import '../../core/security/secure_storage_service.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/auth_event.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../../domain/usecases/change_password_use_case.dart';
import '../../domain/usecases/reset_password_use_case.dart';
import '../../domain/usecases/set_new_password_use_case.dart';
import '../../core/security/biometric_service.dart';
import '../../core/security/mfa_service.dart';
import '../../data/datasources/auth/supabase_mfa_server_port.dart';
import '../../domain/repositories/i_mfa_server_port.dart';
import '../../domain/usecases/biometric_auth_use_case.dart';
import '../../domain/usecases/mfa_auth_use_case.dart';
import '../../domain/usecases/sign_in_use_case.dart';
import '../../domain/usecases/sign_out_use_case.dart';
import '../../domain/usecases/sign_up_use_case.dart';

/// Ponte com o ServiceLocator (GetIt): expõe o repositório de auth como
/// provider. Os use cases são **compostos** a partir dele (e não lidos do
/// GetIt), para que um único override nos testes cubra toda a cadeia.
final authRepositoryProvider = Provider<IAuthRepository>(
  (ref) => ServiceLocator.instance<IAuthRepository>(),
);

final signInUseCaseProvider = Provider<SignInUseCase>(
  (ref) => SignInUseCase(ref.watch(authRepositoryProvider)),
);

final signUpUseCaseProvider = Provider<SignUpUseCase>(
  (ref) => SignUpUseCase(ref.watch(authRepositoryProvider)),
);

final signOutUseCaseProvider = Provider<SignOutUseCase>(
  (ref) => SignOutUseCase(ref.watch(authRepositoryProvider)),
);

final resetPasswordUseCaseProvider = Provider<ResetPasswordUseCase>(
  (ref) => ResetPasswordUseCase(ref.watch(authRepositoryProvider)),
);

final changePasswordUseCaseProvider = Provider<ChangePasswordUseCase>(
  (ref) => ChangePasswordUseCase(ref.watch(authRepositoryProvider)),
);

final setNewPasswordUseCaseProvider = Provider<SetNewPasswordUseCase>(
  (ref) => SetNewPasswordUseCase(ref.watch(authRepositoryProvider)),
);

/// Eventos de autenticação em bruto — o [AuthGate] usa para detectar o
/// fluxo de RECUPERAÇÃO de senha vindo do link do e-mail.
final authEventsProvider = StreamProvider<AuthEvent>(
  (ref) => SupabaseConfig.isConfigured
      ? ref.watch(authRepositoryProvider).authEvents
      : Stream.value(AuthEvent.other),
);

/// Sinaliza que a sessão veio de um link de recuperação de senha: o
/// [AuthGate] mostra a tela de definir nova senha antes de entrar. É
/// limpo ao concluir a troca ou ao sair da conta.
///
/// B2: migrado de StateProvider (legacy) para Notifier (Riverpod 3).
final passwordRecoveryPendingProvider =
    NotifierProvider<PasswordRecoveryPendingNotifier, bool>(
      PasswordRecoveryPendingNotifier.new,
    );

final class PasswordRecoveryPendingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

/// Estado da sessão: `null` = deslogado; [AppUser] = logado.
///
/// O stream reemite a sessão **persistida** ao abrir o app (ver README),
/// permitindo que o [AuthGate] restaure a navegação sem novo login.
///
/// Sem credenciais do Supabase, o stream emite `null` (deslogado) em vez
/// de acessar `Supabase.instance` (que lançaria [StateError] se o cliente
/// não fosse inicializado) — o app abre e o login falha com mensagem
/// amigável em vez de quebrar.
final authStateProvider = StreamProvider<AppUser?>(
  (ref) => SupabaseConfig.isConfigured
      ? ref.watch(authRepositoryProvider).authStateChanges
      : Stream.value(null),
);

/// Porta MFA do servidor: GoTrue real quando o Supabase está configurado;
/// fallback local (sem GoTrue) em dev/testes.
final mfaServerPortProvider = Provider<IMfaServerPort>(
  (ref) => SupabaseConfig.isConfigured
      ? const SupabaseMfaServerPort()
      : LocalOnlyMfaServerPort(MFAService()),
);

/// Caso de uso MFA (Multi-Factor Authentication / TOTP).
/// Requer SecureStorageService já registrado no ServiceLocator.
///
/// P1: agora ORQUESTRA o servidor (GoTrue) — a matrícula cria o fator no
/// servidor e a verificação no login sobe a sessão para aal2, o que as
/// guardas `mfa_ok()` do RLS consultam quando o tenant exige MFA.
final mfaAuthUseCaseProvider = Provider<MFAAuthUseCase>(
  (ref) => MFAAuthUseCase(
    MFAService(),
    ServiceLocator.instance<SecureStorageService>(),
    ref.watch(mfaServerPortProvider),
  ),
);

/// Caso de uso de autenticação biométrica (fingerprint, face ID).
final biometricAuthUseCaseProvider = Provider<BiometricAuthUseCase>(
  (ref) => BiometricAuthUseCase(
    BiometricService(),
    ServiceLocator.instance<SecureStorageService>(),
  ),
);
