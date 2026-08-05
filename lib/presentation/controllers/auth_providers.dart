import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/supabase_config.dart';
import '../../core/di/service_locator.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/i_auth_repository.dart';
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
