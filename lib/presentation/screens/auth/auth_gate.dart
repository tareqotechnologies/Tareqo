import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../domain/entities/app_user.dart';
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
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () => const _SplashScreen(),
      // Erro no stream de sessão: mostra um estado explícito com retry em
      // vez de voltar silenciosamente para o login (evita confundir uma
      // falha transitória com "sessão encerrada").
      error: (error, stackTrace) {
        debugPrint('AuthGate: erro no stream de sessão: $error\n$stackTrace');
        return _AuthErrorScreen(
          onRetry: () => ref.invalidate(authStateProvider),
        );
      },
      data: (user) {
        if (user == null) return const LoginScreen();

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
                debugPrint(
                  'AuthGate: erro ao verificar papel de super admin: '
                  '$error\n$stackTrace',
                );
                return _tenantGate(ref, user);
              },
              data: (isAdmin) =>
                  isAdmin ? const AdminShell() : _tenantGate(ref, user),
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
        debugPrint(
          'AuthGate: erro ao resolver tenant: $error\n$stackTrace',
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
          return TenantOnboardingScreen(user: user);
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
  const _TenantErrorScreen({
    required this.onRetry,
    required this.onSignOut,
  });

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

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF16211E), scheme.surface]
                : [const Color(0xFFE4F2EC), scheme.surface],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.storefront,
                  size: 38,
                  color: scheme.onPrimary,
                ),
              ),
              const SizedBox(height: 20),
              Text('Dumbhanengue', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 28),
              const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
