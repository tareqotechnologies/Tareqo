import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/network/deep_link_handler.dart';
import '../../../core/theme/app_theme.dart';
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
import '../../../core/theme/app_tokens.dart';

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

    // Se o auth state resolveu, resetar o flag.
    authState.whenData((_) => _timeoutReached = false);

    return authState.when(
      loading: () =>
          _timeoutReached ? const LoginScreen() : const _SplashScreen(),
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
          padding: const EdgeInsets.all(AppSpacing.xl),
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
          padding: const EdgeInsets.all(AppSpacing.xl),
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

  // Mesma paleta da tela de login: segue o brilho do tema do app
  // (light/dark) — no escuro os tokens AppColors.*Dark; no claro os
  // neutros do AppTheme.light (ver `login_screen.dart`).
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.backgroundDark : AppColors.scaffoldLight;
    final textPrimary = isDark ? Colors.white : AppColors.onSurfaceLight;
    final textSecondary = isDark
        ? AppColors.onSurfaceVariantDark
        : AppColors.onSurfaceVariantLight;
    // Acento da marca: bege no escuro (primário do tema escuro) e slate
    // no claro — o logo/pulse ganha a identidade petróleo sem verde.
    final accent = isDark ? AppColors.warmBeige : AppColors.brandMuted;

    return Scaffold(
      backgroundColor: bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo direto (TQ monograma branco sobre fundo preto).
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xxl),
              child: Image.asset(
                'assets/branding/icon_official.png',
                width: 120,
                height: 120,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            // Título.
            Text(
              'TAREQO',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            // Subtítulo (localizado).
            Text(
              l10n.loginTagline,
              style: TextStyle(
                fontSize: 14,
                color: textSecondary.withValues(alpha: 0.7),
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 48),
            // Spinner no acento da marca (bege/slate — sem verde).
            SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: accent,
                backgroundColor: accent.withValues(alpha: 0.125),
              ),
            ),
            const SizedBox(height: 20),
            // Texto de loading.
            Text(
              l10n.splashLoading,
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
