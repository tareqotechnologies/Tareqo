import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/network/deep_link_handler.dart';
import '../../../core/observability/crash_reporting.dart';
import '../../../domain/entities/app_user.dart';
import '../../../domain/entities/store_employee.dart';
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
  @override
  void initState() {
    super.initState();
    // Deep links de autenticação: o link de confirmação de e-mail
    // (dumbhanengue://callback) reabre o app e conclui o fluxo no gotrue.
    // Idempotente e à prova de falhas (no-op sem Supabase / em testes).
    DeepLinkHandler.init();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    // POLLING CENTRAL: mantém o provider vivo APENAS com usuário logado —
    // o refresh dos vínculos acontece dentro do provider a cada sinal
    // (timer + Realtime). No sign-out (usuário null) o autoDispose
    // descarta o provider e CANCELA o timer de fallback e o canal
    // Realtime — nada roda em segundo plano durante a sessão inteira.
    // (Dono/super admin/pendente continuam com o timer vivo, mas o guard
    // de [refreshEmployeeLinksIfNeeded] torna cada tick um no-op barato.)
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
                CrashReporting.capture(
                  error,
                  stackTrace,
                  hint: 'AuthGate: erro ao verificar papel de super admin',
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
  }/// Portão do tenant (dono/funcionário): resolve o tenant do usuário e
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
          return TenantOnboardingScreen(user: user);
        }
        // Funcionário DESATIVADO pelo dono: bloqueio total — o app mostra
        // a tela de acesso suspenso (o servidor também nega as operações,
        // via is_my_store exigindo vínculo ativo). O dono nunca passa aqui.
        if (tenant.status == TenantStatus.approved &&
            tenant.ownerUserId != user.id) {
          final employees =
              ref.watch(employeesProvider(tenant.id)).value ??
              const <StoreEmployee>[];
          final myLinks = employees
              .where((employee) => employee.userId == user.id)
              .toList();
          // Sem vínculo OU todos os vínculos desativados → conta suspensa.
          if (myLinks.isEmpty || myLinks.every((link) => !link.isActive)) {
            return _BlockedEmployeeScreen(
              onSignOut: () => ref.read(signOutUseCaseProvider).call(),
            );
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

/// Tela de abertura (restaurando sessão / resolvendo papel e tenant).
///
/// V4 (Aug 8): fundo BRANCO da identidade oficial (o mesmo do .ico) com o
/// logotipo azul (`assets/branding/splash_logo.png`), o nome da marca em
/// cinza-escuro e o spinner na cor do logotipo. Espelha o ícone oficial
/// (tool/generate_icons_test.dart) — abertura sem "flash" (o splash
/// sistêmico do Android também é branco).
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFF6F7F8)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logotipo OFICIAL (azul/branco, v4) — empacotado como asset
              // do app (assets/branding/splash_logo.png).
              Image.asset(
                'assets/branding/splash_logo.png',
                width: 116,
                height: 116,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 18),
              Text(
                'Dumbhanengue',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: const Color(0xFF202023),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 30),
              const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFF0076F6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
