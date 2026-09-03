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
  @override
  void initState() {
    super.initState();
    DeepLinkHandler.init();
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

    return authState.when(
      loading: () => const _SplashScreen(),
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

  @override
  void initState() {
    super.initState();
    _checkMFA();
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
    if (!_mfaChecked) return const _SplashScreen();

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

class _AdminTenantGate extends ConsumerWidget {
  const _AdminTenantGate({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminAsync = ref.watch(isSuperAdminProvider(user.id));
    return adminAsync.when(
      loading: () => const _SplashScreen(),
      error: (error, stackTrace) {
        CrashReporting.capture(
          error,
          stackTrace,
          hint: 'AuthGate: erro ao verificar papel de super admin',
        );
        return _TenantGate(user: user);
      },
      data: (isAdmin) {
        if (isAdmin) return const AdminShell();
        return _TenantGate(user: user);
      },
    );
  }
}

class _TenantGate extends ConsumerWidget {
  const _TenantGate({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        if (tenant == null) {
          return TenantOnboardingScreen(user: user);
        }
        if (tenant.status == TenantStatus.approved &&
            tenant.ownerUserId != user.id) {
          final employeesAsync = ref.watch(employeesProvider(tenant.id));
          if (employeesAsync.isLoading && employeesAsync.value == null) {
            return const _SplashScreen();
          }
          final employees = employeesAsync.value;
          if (employees != null) {
            final myLinks = employees
                .where((e) => e.userId == user.id)
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
            // Logo em container com borda (mesmo padrão do login).
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: _border, width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.asset(
                  'assets/branding/icon_official.png',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
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
