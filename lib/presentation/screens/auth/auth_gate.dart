import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/network/deep_link_handler.dart';
import '../../../core/observability/crash_reporting.dart';
import '../../../domain/entities/app_user.dart';
import '../../../domain/entities/auth_event.dart';
import '../../../domain/entities/tenant.dart';
import '../../controllers/account_providers.dart';
import '../../controllers/admin_providers.dart';
import '../../controllers/auth_providers.dart';
import '../account/tenant_onboarding_screen.dart';
import '../account/tenant_pending_screen.dart';
import '../account/tenant_rejected_screen.dart';
import '../admin/admin_shell.dart';
import '../shell/app_shell.dart';
import 'login_screen.dart';
import 'set_new_password_screen.dart';

/// Portão de autenticação e de **acesso**: decide a tela raiz com base na
/// sessão e no papel do usuário logado.
///
/// - `loading` (restaurando sessão persistida) → splash;
/// - deslogado → [LoginScreen];
/// - **super admin** (papel baseado em banco — `public.super_admins` via
///   RPC `is_super_admin`) → [AdminShell];
/// - logado sem tenant → [TenantOnboardingScreen] (escolher plano + negócio);
/// - tenant `pending` → [TenantPendingScreen] (aguardando aprovação ≤ 24h);
/// - tenant `rejected` → [TenantRejectedScreen] (motivo da rejeição);
/// - tenant `approved` → [AppShell] (área de gestão do dono).
///
/// **Bloqueio REATIVO de funcionários desativados:** o polling CENTRAL
/// ([employeesPollingProvider]) re-busca os vínculos no Realtime (Supabase
/// — bloqueio INSTANTÂNEO quando o dono desativa em outro dispositivo) e
/// num timer de fallback de 30s ([employeePollIntervalProvider], modo
/// local/websocket fora do ar). O servidor segue sendo a autoridade:
/// RLS/RPCs negam as operações imediatamente.
class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  bool _authTimedOut = false;
  Timer? _authTimer;

  @override
  void initState() {
    super.initState();
    DeepLinkHandler.init();
    _startAuthTimeout();
  }

  /// Timer de segurança GLOBAL: cobre TODA a cadeia auth → admin → tenant.
  /// Só é cancelado quando saímos definitivamente do splash (mostramos
  /// LoginScreen, AppShell, AdminShell, etc.).
  void _startAuthTimeout() {
    _authTimer?.cancel();
    _authTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && !_authTimedOut) {
        setState(() => _authTimedOut = true);
      }
    });
  }

  @override
  void dispose() {
    _authTimer?.cancel();
    super.dispose();
  }

  /// Cancela o timer de segurança — chamado apenas quando o build retorna
  /// uma tela REAL (não splash), garantindo que o timer cobre toda a
  /// cadeia de loading (auth + super_admin + tenant + employees).
  /// Cancela o timer de segurança quando saímos do splash.
  void _cancelTimerIfResolved() {
    if (_authTimer != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_authTimedOut) {
          _authTimer?.cancel();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ── Tela de timeout global ──────────────────────────────────────
    if (_authTimedOut) {
      return _AuthErrorScreen(
        onRetry: () {
          setState(() => _authTimedOut = false);
          // Invalidar TODOS os providers da cadeia.
          ref.invalidate(authStateProvider);
          _startAuthTimeout();
        },
      );
    }

    final authState = ref.watch(authStateProvider);
    // Sessão veio de um link de RECUPERAÇÃO de senha? O gotrue emite o
    // evento `passwordRecovery` ao trocar o token do e-mail — o AuthGate
    // então exige definir a nova senha antes de entrar.
    final recoveryPending = ref.watch(passwordRecoveryPendingProvider);
    ref.listen(authEventsProvider, (previous, next) {
      if (next.value == AuthEvent.passwordRecovery) {
        // Escrita ADIADA para o próximo microtask: o listener pode rodar
        // DURANTE a construção da árvore (ex.: evento de recovery chegando
        // junto com o primeiro frame após o deep link) e o Riverpod 3
        // proíbe modificar um provider nessa fase.
        Future.microtask(() {
          if (mounted) {
            ref.read(passwordRecoveryPendingProvider.notifier).state = true;
          }
        });
      }
    });
    // POLLING CENTRAL: mantém o provider vivo APENAS com usuário logado —
    // o refresh dos vínculos acontece dentro do provider a cada sinal
    // (timer + Realtime). No sign-out (usuário null) o autoDispose
    // descarta o provider e CANCELA o timer de fallback e o canal
    // Realtime — nada roda em segundo plano durante a sessão inteira.
    if (authState.value != null) {
      ref.watch(employeesPollingProvider);
    }

    return authState.when(
      loading: () => const _SplashScreen(),
      // Erro no stream de sessão: mostra um estado explícito com retry em
      // vez de voltar silenciosamente para o login (evita confundir uma
      // falha transitória com "sessão encerrada").
      error: (error, stackTrace) {
        CrashReporting.capture(
          error,
          stackTrace,
          hint: 'AuthGate: erro no stream de sessão',
        );
        _cancelTimerIfResolved();
        return _AuthErrorScreen(
          onRetry: () => ref.invalidate(authStateProvider),
        );
      },
      data: (user) {
        if (user == null) {
          // Sessão encerrada: o sinal de recuperação não faz mais sentido.
          if (ref.read(passwordRecoveryPendingProvider)) {
            Future.microtask(() {
              if (mounted) {
                ref.read(passwordRecoveryPendingProvider.notifier).state =
                    false;
              }
            });
          }
          _cancelTimerIfResolved();
          return const LoginScreen();
        }
        // Recovery: sessão veio do link do e-mail — definir a nova senha
        // ANTES de entrar na área de gestão.
        if (recoveryPending) {
          _cancelTimerIfResolved();
          return const SetNewPasswordScreen();
        }

        // Super admin: papel baseado em BANCO (tabela `public.super_admins`
        // no Supabase via RPC `is_super_admin`) — não mais e-mail
        // hardcoded. Enquanto o papel carrega, mostra o splash; numa falha
        // transitória, segue para o fluxo do tenant (o banco permanece
        // autoritativo e negará ações de admin sem o papel).
        return Consumer(
          builder: (context, ref, _) {
            final adminAsync = ref.watch(isSuperAdminProvider(user.id));
            return adminAsync.when(
              loading: () => const _SplashScreen(),
              error: (error, stackTrace) {
                CrashReporting.capture(
                  error,
                  stackTrace,
                  hint: 'AuthGate: erro ao verificar papel de super admin',
                );
                return _tenantGate(ref, user);
              },
              data: (isAdmin) => isAdmin
                  ?              const AdminShell()
                  : _tenantGate(ref, user),
            );
          },
        );
      },
    );
  }

  /// Portão do tenant (dono/funcionário): resolve o tenant do usuário e
  /// decide entre onboarding, pendente, rejeitado ou área de gestão.
  Widget _tenantGate(WidgetRef ref, AppUser user) {
    final tenantAsync = ref.watch(myTenantProvider(user.id));
    return tenantAsync.when(
      loading: () => const _SplashScreen(),
      error: (error, stackTrace) {
        CrashReporting.capture(
          error,
          stackTrace,
          hint: 'AuthGate: erro ao resolver tenant',
        );
        // Não voltar para o login (usuário já logado): mostra um estado de
        // erro com tentar novamente.
        return _TenantErrorScreen(
          onRetry: () => ref.invalidate(myTenantProvider(user.id)),
          onSignOut: () => ref.read(signOutUseCaseProvider).call(),
        );
      },
      data: (tenant) {
        if (tenant == null) {
          _cancelTimerIfResolved();
          return TenantOnboardingScreen(user: user);
        }
        // Funcionário DESATIVADO pelo dono: bloqueio total — o app mostra
        // a tela de acesso suspenso (o servidor também nega as operações,
        // via is_my_store exigindo vínculo ativo). O dono nunca passa aqui.
        if (tenant.status == TenantStatus.approved &&
            tenant.ownerUserId != user.id) {
          final employeesAsync = ref.watch(employeesProvider(tenant.id));
          if (employeesAsync.isLoading && employeesAsync.value == null) {
            return const _SplashScreen();
          }
          final employees = employeesAsync.value;
          if (employees != null) {
            final myLinks = employees
                .where((employee) => employee.userId == user.id)
                .toList();
            if (myLinks.isEmpty || myLinks.every((link) => !link.isActive)) {
              _cancelTimerIfResolved();
              return _BlockedEmployeeScreen(
                onSignOut: () => ref.read(signOutUseCaseProvider).call(),
              );
            }
          } else if (employeesAsync.hasError) {
            final error = employeesAsync.error;
            final stackTrace = employeesAsync.stackTrace;
            if (error != null && stackTrace != null) {
              CrashReporting.capture(
                error,
                stackTrace,
                hint: 'AuthGate: erro ao buscar vínculos do funcionário',
              );
            }
          }
        }
        final screen = switch (tenant.status) {
          TenantStatus.pending => TenantPendingScreen(tenant: tenant),
          TenantStatus.rejected => TenantRejectedScreen(tenant: tenant),
          TenantStatus.approved => const AppShell(),
        };
        _cancelTimerIfResolved();
        return screen;
      },
    );
  }
}

/// Funcionário com acesso suspenso pelo dono (conta desativada).
///
/// Mostra um estado explícito com sair da conta — espelha o bloqueio do
/// servidor (vínculo `is_active = false` nega toda operação nas lojas).
class _BlockedEmployeeScreen extends StatelessWidget {
  const _BlockedEmployeeScreen({required this.onSignOut});

  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.block, size: 48, color: scheme.error),
                const SizedBox(height: 16),
                Text(
                  l10n.authBlockedTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.authBlockedMessage,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onSignOut,
                  icon: const Icon(Icons.logout),
                  label: Text(l10n.authBlockedSignOut),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Estado de erro no stream de autenticação: oferece "tentar novamente"
/// (recarrega o provider) — sem usuário logado, não há sessão para sair.
class _AuthErrorScreen extends StatelessWidget {
  const _AuthErrorScreen({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off, size: 48, color: scheme.error),
                const SizedBox(height: 16),
                Text(
                  l10n.authErrorRestoreSession,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.authErrorCheckConnection,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.commonRetry),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Estado de erro na resolução do tenant: mantém o usuário logado e
/// oferece "tentar novamente" e "sair da conta".
class _TenantErrorScreen extends StatelessWidget {
  const _TenantErrorScreen({required this.onRetry, required this.onSignOut});

  final VoidCallback onRetry;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off, size: 48, color: scheme.error),
                const SizedBox(height: 16),
                Text(
                  l10n.authErrorLoadAccount,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.authErrorCheckConnection,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.commonRetry),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: onSignOut,
                  icon: const Icon(Icons.logout),
                  label: Text(l10n.commonSignOut),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tela de abertura animada (restaurando sessão / resolvendo papel e tenant).
///
/// Splash animado profissional com fundo azul, logo que escala e fade-in
/// suave, nome da marca com slide-up, e spinner. O timer de segurança é
/// gerido pelo [AuthGate] (não por este widget) — este é apenas visual.
class _SplashScreen extends StatefulWidget {
  const _SplashScreen();

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _spinnerFade;
  bool _animInitialized = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Logo: escala de 0.7 → 1.0 + fade-in (0 → 1) nos primeiros 500ms.
    _logoScale = Tween<double>(begin: 0.7, end: 1).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0, 0.42, curve: Curves.easeOutBack),
      ),
    );
    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0, 0.35, curve: Curves.easeOut),
      ),
    );

    // Marca: fade-in + slide-up (20px) entre 300ms e 700ms.
    _textFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.25, 0.58, curve: Curves.easeOut),
      ),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.25, 0.58, curve: Curves.easeOutCubic),
      ),
    );

    // Spinner + status: fade-in suave entre 500ms e 800ms.
    _spinnerFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.42, 0.68, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_animInitialized) {
      _animInitialized = true;
      final reduceMotion = MediaQuery.disableAnimationsOf(context);
      if (reduceMotion) {
        _ctrl.value = 1;
      } else {
        _ctrl.forward();
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: const Color(0xFF0076F6),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _ctrl,
              builder: (context, child) => Opacity(
                opacity: _logoFade.value,
                child: Transform.scale(
                  scale: _logoScale.value,
                  child: child,
                ),
              ),
              child: Container(
                width: 101,
                height: 101,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.white24,
                      blurRadius: 48,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Image.asset(
                    'assets/branding/splash_logo.png',
                    width: 81,
                    height: 81,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Marca: fade + slide-up animado.
            AnimatedBuilder(
              animation: _ctrl,
              builder: (context, child) => Opacity(
                opacity: _textFade.value,
                child: FractionalTranslation(
                  translation: _textSlide.value,
                  child: child,
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Dumbhanengue',
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            // Spinner + status: fade-in suave.
            AnimatedBuilder(
              animation: _ctrl,
              builder: (context, child) => Opacity(
                opacity: _spinnerFade.value,
                child: child,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                      backgroundColor: Colors.white24,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.splashLoading,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
