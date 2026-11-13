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
import '../../widgets/app_button.dart';
import '../../widgets/app_sheet.dart';
import 'login_screen.dart';
import 'mfa_verification_sheet.dart';
import 'set_new_password_screen.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';

/// Portão de autenticação e de **acesso**: decide a tela raiz com base na
/// sessão e no papel do usuário logado.
class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  bool _timeoutReached = false;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    DeepLinkHandler.init();
    // Se o auth state não resolver em 3 segundos, mostrar login em vez de
    // ficar preso no splash (problema comum em release quando o Supabase
    // demora ou falha silenciosamente).
    _timeoutTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && !_timeoutReached) {
        setState(() => _timeoutReached = true);
      }
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final recoveryPending = ref.watch(passwordRecoveryPendingProvider);
    ref.listen(authEventsProvider, (previous, next) {
      if (next.value == AuthEvent.passwordRecovery) {
        Future.microtask(() {
          if (mounted) {
            ref.read(passwordRecoveryPendingProvider.notifier).set(true);
          }
        });
      }
    });

    return authState.when(
      loading: () =>
          _timeoutReached ? const LoginScreen() : const TareqoSplashScreen(),
      error: (error, stackTrace) {
        CrashReporting.capture(
          error,
          stackTrace,
          hint: 'AuthGate: erro no stream de sessão',
        );
        Future.microtask(() {
          if (mounted) ref.invalidate(authStateProvider);
        });
        return const LoginScreen();
      },
      data: (user) {
        if (user == null) {
          if (ref.read(passwordRecoveryPendingProvider)) {
            Future.microtask(() {
              if (mounted) {
                ref.read(passwordRecoveryPendingProvider.notifier).set(false);
              }
            });
          }
          return const LoginScreen();
        }
        if (recoveryPending) return const SetNewPasswordScreen();

        // Auth OK → MFA gate → admin/tenant.
        return _MFAGate(user: user);
      },
    );
  }
}

// ─── MFA Gate ─────────────────────────────────────────────────────────

class _MFAGate extends ConsumerStatefulWidget {
  const _MFAGate({required this.user});
  final AppUser user;

  @override
  ConsumerState<_MFAGate> createState() => _MFAGateState();
}

class _MFAGateState extends ConsumerState<_MFAGate> {
  bool _mfaChecked = false;
  bool _mfaEnabled = false;
  bool _timedOut = false;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    _checkMFA();
    // Timeout de 3 segundos — se MFA check não resolver, assumir desabilitado.
    _timeoutTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && !_mfaChecked) {
        setState(() {
          _mfaChecked = true;
          _mfaEnabled = false;
          _timedOut = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkMFA() async {
    final enabled = await ref.read(mfaAuthUseCaseProvider).isEnabled();
    if (mounted) {
      setState(() {
        _mfaEnabled = enabled;
        _mfaChecked = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_mfaChecked && !_timedOut) return const TareqoSplashScreen();

    if (_mfaEnabled) {
      return _MFAVerificationGate(user: widget.user);
    }

    return _AdminTenantGate(user: widget.user);
  }
}

// ─── MFA Verification Gate ──────────────────────────────────────────────

class _MFAVerificationGate extends ConsumerStatefulWidget {
  const _MFAVerificationGate({required this.user});
  final AppUser user;

  @override
  ConsumerState<_MFAVerificationGate> createState() =>
      _MFAVerificationGateState();
}

class _MFAVerificationGateState extends ConsumerState<_MFAVerificationGate> {
  bool _verified = false;
  bool _showing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showMFA());
  }

  Future<void> _showMFA() async {
    if (_showing || !mounted) return;
    _showing = true;

    final result = await showAppSheet<bool>(
      context,
      isDismissible: false,
      builder: (_) => const MFAVerificationSheet(),
    );

    if (!mounted) return;

    if (result == true) {
      setState(() => _verified = true);
    } else {
      ref.read(signOutUseCaseProvider).call();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_verified) return _AdminTenantGate(user: widget.user);
    return const TareqoSplashScreen();
  }
}

// ─── Admin / Tenant Gate ────────────────────────────────────────────────

class _AdminTenantGate extends ConsumerStatefulWidget {
  const _AdminTenantGate({required this.user});
  final AppUser user;

  @override
  ConsumerState<_AdminTenantGate> createState() => _AdminTenantGateState();
}

class _AdminTenantGateState extends ConsumerState<_AdminTenantGate> {
  bool _timedOut = false;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    // Timeout de 3 segundos para este gate também.
    _timeoutTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && !_timedOut) setState(() => _timedOut = true);
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminAsync = ref.watch(isSuperAdminProvider(widget.user.id));
    if (_timedOut && adminAsync.isLoading) {
      return _TenantGate(user: widget.user);
    }
    return adminAsync.when(
      loading: () => const TareqoSplashScreen(),
      error: (error, stackTrace) {
        CrashReporting.capture(
          error,
          stackTrace,
          hint: 'AuthGate: erro ao verificar papel de super admin',
        );
        return _TenantGate(user: widget.user);
      },
      data: (isAdmin) {
        if (isAdmin) return const AdminShell();
        return _TenantGate(user: widget.user);
      },
    );
  }
}

class _TenantGate extends ConsumerStatefulWidget {
  const _TenantGate({required this.user});
  final AppUser user;

  @override
  ConsumerState<_TenantGate> createState() => _TenantGateState();
}

class _TenantGateState extends ConsumerState<_TenantGate> {
  bool _timedOut = false;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    // Timeout de 3 segundos — mostrar tela de erro em vez de ficar preso.
    _timeoutTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && !_timedOut) setState(() => _timedOut = true);
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Mantém vivo o polling CENTRAL do bloqueio reativo de funcionários
    // (Realtime + timer de fallback): enquanto este gate existe (usuário
    // logado no fluxo do tenant), os vínculos são reavaliados. autoDispose
    // cancela tudo no sign-out.
    ref.watch(employeesPollingProvider);
    final tenantAsync = ref.watch(myTenantProvider(widget.user.id));
    // Se excedeu o timeout e ainda está loading, mostrar erro com retry.
    if (_timedOut && tenantAsync.isLoading) {
      return _TenantErrorScreen(
        onRetry: () {
          setState(() => _timedOut = false);
          ref.invalidate(myTenantProvider(widget.user.id));
        },
        onSignOut: () => ref.read(signOutUseCaseProvider).call(),
      );
    }
    return tenantAsync.when(
      loading: () => const TareqoSplashScreen(),
      error: (error, stackTrace) {
        CrashReporting.capture(
          error,
          stackTrace,
          hint: 'AuthGate: erro ao resolver tenant',
        );
        return _TenantErrorScreen(
          onRetry: () => ref.invalidate(myTenantProvider(widget.user.id)),
          onSignOut: () => ref.read(signOutUseCaseProvider).call(),
        );
      },
      data: (tenant) {
        if (tenant == null) {
          return TenantOnboardingScreen(user: widget.user);
        }
        if (tenant.status == TenantStatus.approved &&
            tenant.ownerUserId != widget.user.id) {
          final employeesAsync = ref.watch(employeesProvider(tenant.id));
          if (employeesAsync.isLoading && employeesAsync.value == null) {
            return const TareqoSplashScreen();
          }
          final employees = employeesAsync.value;
          if (employees != null) {
            final myLinks = employees
                .where((e) => e.userId == widget.user.id)
                .toList();
            if (myLinks.isEmpty || myLinks.every((l) => !l.isActive)) {
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

// ─── Error / Blocked screens ────────────────────────────────────────────

/// Layout comum das telas de estado da autenticação (bloqueio e erro) —
/// ícone em superfície suave, título, mensagem e ações no padrão do
/// design system.
class _AuthStateScreen extends StatelessWidget {
  const _AuthStateScreen({
    required this.icon,
    required this.title,
    required this.message,
    required this.actions,
  });

  final IconData icon;
  final String title;
  final String message;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: scheme.error.withValues(alpha: 0.10),
                      borderRadius: AppRadius.lgAll,
                    ),
                    child: Icon(icon, size: 32, color: scheme.error),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: AppTypography.headline,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ...actions,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BlockedEmployeeScreen extends StatelessWidget {
  const _BlockedEmployeeScreen({required this.onSignOut});
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return _AuthStateScreen(
      icon: Icons.block,
      title: l10n.authBlockedTitle,
      message: l10n.authBlockedMessage,
      actions: [
        AppButton.primary(
          onPressed: onSignOut,
          icon: const Icon(Icons.logout, size: 18),
          label: l10n.authBlockedSignOut,
        ),
      ],
    );
  }
}

class _TenantErrorScreen extends StatelessWidget {
  const _TenantErrorScreen({required this.onRetry, required this.onSignOut});
  final VoidCallback onRetry;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return _AuthStateScreen(
      icon: Icons.cloud_off,
      title: l10n.authErrorLoadAccount,
      message: l10n.authErrorCheckConnection,
      actions: [
        AppButton.primary(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh, size: 18),
          label: l10n.commonRetry,
        ),
        const SizedBox(height: AppSpacing.xs),
        AppButton.secondary(
          onPressed: onSignOut,
          icon: const Icon(Icons.logout, size: 18),
          label: l10n.commonSignOut,
        ),
      ],
    );
  }
}

// ─── Splash ─────────────────────────────────────────────────────────────

/// Abertura visual da marca; não controla sessão, rotas ou duração de carga.
class TareqoSplashScreen extends StatelessWidget {
  const TareqoSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          // Mantém a composição acessível em paisagem e com texto ampliado.
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    isDark
                        ? 'assets/branding/splash_logo.png'
                        : 'assets/branding/splash_logo_ink.png',
                    width: 144,
                    height: 144,
                    fit: BoxFit.contain,
                    excludeFromSemantics: true,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'TAREQO',
                      textAlign: TextAlign.center,
                      // Wordmark de marca: mantém uma linha em ecrãs estreitos.
                      style: AppTypography.display.copyWith(
                        fontWeight: FontWeight.w400,
                        letterSpacing: 5,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.loginTagline,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.huge),
                  SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: scheme.onSurfaceVariant,
                      backgroundColor: scheme.outlineVariant,
                      semanticsLabel: l10n.splashLoading,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.splashLoading,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
