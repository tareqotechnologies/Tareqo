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
        if (user == null) {
          // Sessão encerrada: o sinal de recuperação não faz mais sentido.
          // (Escrita adiada — o branch roda durante o build.)
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
        // Recovery: sessão veio do link do e-mail — definir a nova senha
        // ANTES de entrar na área de gestão.
        if (recoveryPending) return const SetNewPasswordScreen();

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
          return TenantOnboardingScreen(user: user);
        }
        // Funcionário DESATIVADO pelo dono: bloqueio total — o app mostra
        // a tela de acesso suspenso (o servidor também nega as operações,
        // via is_my_store exigindo vínculo ativo). O dono nunca passa aqui.
        if (tenant.status == TenantStatus.approved &&
            tenant.ownerUserId != user.id) {
          final employeesAsync = ref.watch(employeesProvider(tenant.id));
          // Enquanto a PRIMEIRA busca dos vínculos não termina, `value` é
          // null — NÃO decidir bloqueio (senão todo funcionário válido veria
          // "Acesso suspenso" por um instante até a lista chegar). Mantém o
          // splash; a decisão só acontece com dados reais. Num REFRESH
          // (poll de 30s) o Riverpod mantém o valor anterior, então
          // `value != null` e não há flash a cada poll.
          if (employeesAsync.isLoading && employeesAsync.value == null) {
            return const _SplashScreen();
          }
          final employees = employeesAsync.value;
          if (employees != null) {
            final myLinks = employees
                .where((employee) => employee.userId == user.id)
                .toList();
            // Sem vínculo OU todos os vínculos desativados → conta suspensa.
            if (myLinks.isEmpty || myLinks.every((link) => !link.isActive)) {
              return _BlockedEmployeeScreen(
                onSignOut: () => ref.read(signOutUseCaseProvider).call(),
              );
            }
          } else if (employeesAsync.hasError) {
            // Falha transitória (ex.: rede) ao buscar os vínculos: fail-open
            // — deixa seguir para o fluxo normal abaixo. O servidor
            // permanece autoritativo (RLS/RPCs negam quem está realmente
            // suspenso) e o polling central reavalia em breve. Sem dados de
            // vínculo, nunca decidir um bloqueio: seria um falso positivo.
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
/// V5: fundo BRANCO da identidade oficial (o mesmo do .ico) com o logotipo
/// azul em brilho suave, o nome da marca no mesmo corte do login (Large
/// Title) e um status discreto sob o spinner. A entrada é um fade-in
/// sutil que respeita "reduzir movimento" do sistema — abertura sem
/// "flash" (o splash sistêmico do Android também é branco).
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

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
          // Fade-in + leve subida (400ms) — profissional sem ser chamativo.
          // Com "reduzir movimento", a entrada é instantânea.
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 10 * (1 - value)),
                child: child,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logotipo OFICIAL (azul/branco, v4) — empacotado como
                // asset do app (assets/branding/splash_logo.png). O brilho
                // circular suave dá profundidade sem sombra pesada.
                Container(
                  width: 132,
                  height: 132,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0076F6).withValues(alpha: 0.12),
                        blurRadius: 40,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/branding/splash_logo.png',
                    width: 116,
                    height: 116,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 20),
                // Marca no MESMO corte do login (Large Title — displaySmall)
                // para a identidade conversar entre abertura e login.
                // FittedBox scaleDown: como no login, a palavra única nunca
                // trunca em escala de texto alta.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Dumbhanengue',
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: const Color(0xFF202023),
                    ),
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
                const SizedBox(height: 14),
                // Status discreto: informa o que está acontecendo sem
                // parecer carregamento técnico (i18n pt/en). Cor FIXA
                // cinza-escura: o splash é sempre branco (identidade
                // oficial) — o onSurfaceVariant do tema escuro seria
                // cinza-claro e sumiria sobre o fundo branco.
                Text(
                  l10n.splashLoading,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF5F6B64),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
