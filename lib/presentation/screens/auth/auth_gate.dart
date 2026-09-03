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
import '../../widgets/app_sheet.dart';
import 'login_screen.dart';
import 'mfa_verification_sheet.dart';
import 'set_new_password_screen.dart';

/// Portão de autenticação e de **acesso**: decide a tela raiz com base na
/// sessão e no papel do usuário logado.
class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  bool _timeoutReached = false;
  int _splashStartMs = 0;

  @override
  void initState() {
    super.initState();
    DeepLinkHandler.init();
    _splashStartMs = DateTime.now().millisecondsSinceEpoch;
    // Se o auth state não resolver em 5 segundos, mostrar login em vez de
    // ficar preso no splash (problema comum em release quando o Supabase
    // demora ou falha silenciosamente).
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && !_timeoutReached) {
        setState(() => _timeoutReached = true);
      }
    });
  }

  /// Verifica se já passou do tempo máximo no splash.
  bool get _splashTimedOut {
    return DateTime.now().millisecondsSinceEpoch - _splashStartMs > 5000;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
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

    // Se o auth state resolveu, resetar o flag.
    authState.whenData((_) => _timeoutReached = false);

    return authState.when(
      loading: () => _timeoutReached
          ? const LoginScreen()
          : const _SplashScreen(),
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
                ref.read(passwordRecoveryPendingProvider.notifier).state =
                    false;
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

  @override
  void initState() {
    super.initState();
    _checkMFA();
    // Timeout de 5 segundos — se MFA check não resolver, assumir desabilitado.
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && !_mfaChecked) {
        setState(() {
          _mfaChecked = true;
          _mfaEnabled = false;
          _timedOut = true;
        });
      }
    });
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
    if (!_mfaChecked && !_timedOut) return const _SplashScreen();

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
    return const _SplashScreen();
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

  @override
  void initState() {
    super.initState();
    // Timeout de 5 segundos para este gate também.
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && !_timedOut) setState(() => _timedOut = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminAsync = ref.watch(isSuperAdminProvider(widget.user.id));
    if (_timedOut && adminAsync.isLoading) {
      return _TenantGate(user: widget.user);
    }
    return adminAsync.when(
      loading: () => const _SplashScreen(),
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

  @override
  void initState() {
    super.initState();
    // Timeout de 5 segundos — mostrar tela de erro em vez de ficar preso.
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && !_timedOut) setState(() => _timedOut = true);
    });
  }

  @override
  Widget build(BuildContext context) {
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
      loading: () => const _SplashScreen(),
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
            return const _SplashScreen();
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

// ─── Splash ─────────────────────────────────────────────────────────────

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  // Mesma paleta da tela de login.
  static const _bg = Color(0xFF101112);
  static const _surface = Color(0xFF1D1E22);
  static const _border = Color(0xFF303238);
  static const _textPrimary = Color(0xFFFFFFFF);
  static const _textSecondary = Color(0xFFA1A1AA);
  static const _green = Color(0xFF16A34A);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: _bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo direto (TQ monograma branco sobre fundo preto).
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                'assets/branding/icon_official.png',
                width: 88,
                height: 88,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 28),
            // Título.
            const Text(
              'TAREQO',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            // Subtítulo.
            Text(
              'Gestão simples para o seu negócio',
              style: TextStyle(
                fontSize: 14,
                color: _textSecondary.withValues(alpha: 0.7),
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 48),
            // Spinner verde.
            const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: _green,
                backgroundColor: Color(0x2016A34A),
              ),
            ),
            const SizedBox(height: 20),
            // Texto de loading.
            Text(
              l10n.splashLoading,
              style: const TextStyle(
                fontSize: 14,
                color: _textSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
