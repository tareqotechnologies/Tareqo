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

  /// Timer de segurança GLOBAL: 10s para toda a cadeia auth → admin → tenant.
  /// Só é cancelado quando saímos definitivamente do splash.
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
  /// uma tela REAL (LoginScreen, AppShell, AdminShell, etc.), nunca quando
  /// volta ao splash.
  void _cancelTimer() {
    _authTimer?.cancel();
    _authTimer = null;
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
          ref.invalidate(isSuperAdminProvider);
          _startAuthTimeout();
        },
      );
    }

    final authState = ref.watch(authStateProvider);
    // Sessão veio de um link de RECUPERAÇÃO de senha?
    final recoveryPending = ref.watch(passwordRecoveryPendingProvider);
    ref.listen(authEventsProvider, (previous, next) {
      if (next.value == AuthEvent.passwordRecovery) {
        Future.microtask(() {
          if (mounted) {
            ref.read(passwordRecoveryPendingProvider.notifier).state = true;
          }
        });
      }
    });

    return authState.when(
      loading: () => const _SplashScreen(),
      error: (error, stackTrace) {
        CrashReporting.capture(
          error,
          stackTrace,
          hint: 'AuthGate: erro no stream de sessão',
        );
        // NÃO cancelar o timer aqui — o timeout continua como safety net.
        return _AuthErrorScreen(
          onRetry: () {
            ref.invalidate(authStateProvider);
            _startAuthTimeout();
          },
        );
      },
      data: (user) {
        if (user == null) {
          // Sessão encerrada.
          if (ref.read(passwordRecoveryPendingProvider)) {
            Future.microtask(() {
              if (mounted) {
                ref.read(passwordRecoveryPendingProvider.notifier).state =
                    false;
              }
            });
          }
          // NÃO cancelar o timer — pode ser que o Supabase ainda vá
          // emitir a sessão restaurada via onAuthStateChange.
          return const LoginScreen();
        }
        // Recovery: sessão veio do link do e-mail.
        if (recoveryPending) {
          return const SetNewPasswordScreen();
        }

        // Super admin check.
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
                  ? const AdminShell()
                  : _tenantGate(ref, user),
            );
          },
        );
      },
    );
  }

  /// Portão do tenant (dono/funcionário).
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
        return _TenantErrorScreen(
          onRetry: () => ref.invalidate(myTenantProvider(user.id)),
          onSignOut: () => ref.read(signOutUseCaseProvider).call(),
        );
      },
      data: (tenant) {
        // Chegámos a um ecrã real — cancelar o timer.
        _cancelTimer();

        if (tenant == null) {
          return TenantOnboardingScreen(user: user);
        }
        // Funcionário DESATIVADO pelo dono.
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
        return switch (tenant.status) {
          TenantStatus.pending => TenantPendingScreen(tenant: tenant),
          TenantStatus.rejected => TenantRejectedScreen(tenant: tenant),
          TenantStatus.approved => const AppShell(),
        };
      },
    );
  }
}

/// Funcionário com acesso suspenso pelo dono.
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

/// Estado de erro no stream de autenticação.
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

/// Estado de erro na resolução do tenant.
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

/// Splash screen — visual estático. Timer é gerido pelo [AuthGate].
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

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
            Container(
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
            const SizedBox(height: 24),
            Text(
              'Dumbhanengue',
              style: theme.textTheme.displaySmall?.copyWith(
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 40),
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
    );
  }
}
