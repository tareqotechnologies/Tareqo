import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../controllers/auth_providers.dart';

/// [AppLockOverlay] — bloqueio biométrico do app.
///
/// Vive no `builder` do [MaterialApp] (acima do [Navigator], por isso cobre
/// também sheets e diálogos abertos). Com a biometria ACTIVA nas
/// Configurações → Segurança, o app pede a digital/rosto:
///
///  1. no **arranque a frio** quando a sessão é restaurada (sem voltar a
///     digitar a senha); e
///  2. ao **voltar** ao app depois de ir para o fundo (home / troca de app).
///
/// Se a autenticação falhar (ou o utilizador cancelar), permanece no ecrã de
/// bloqueio com opção de tentar de novo ou terminar a sessão — nunca entra
/// na área de gestão sem a biometria.
class AppLockOverlay extends ConsumerStatefulWidget {
  const AppLockOverlay({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppLockOverlay> createState() => _AppLockOverlayState();
}

class _AppLockOverlayState extends ConsumerState<AppLockOverlay>
    with WidgetsBindingObserver {
  /// Estado biométrico (disponibilidade/flag) já carregado.
  bool _ready = false;

  /// Biometria ACTIVA e disponível no aparelho.
  bool _enabled = false;

  /// O app deve pedir a biometria (arranque com sessão restaurada ou
  /// regresso do fundo). Só é desarmado após desbloquear com sucesso ou
  /// quando o utilizador sai da conta em primeiro plano.
  bool _armed = true;

  /// O ecrã de bloqueio está visível.
  bool _locked = false;

  /// Uma autenticação está em curso (evita prompts duplicados).
  bool _authenticating = false;

  /// A última tentativa falhou/cancelou — mostra a mensagem de erro.
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Arranque a frio: se houver sessão restaurada com biometria ativa, o
    // app inicia bloqueado (auditoria V3 — desbloquear sem redigitar senha).
    _armed = true;
    _refreshBiometricState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ─── Ciclo de vida ──────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        // Foi para o fundo (home, troca de app, ecrã bloqueado): arma o
        // bloqueio para o regresso. `inactive` (sombra de notificações,
        // chamada, multitasking momentâneo) NÃO arma — evita pedir a
        // biometria a cada interrupção transitória.
        _onBackgrounded();
        break;
      case AppLifecycleState.resumed:
        _onResumed();
        break;
      default:
        break;
    }
  }

  void _onBackgrounded() {
    if (_locked) return;
    final user = ref.read(authStateProvider).value;
    if (user == null || !_ready || !_enabled) return;
    _armed = true;
  }

  Future<void> _onResumed() async {
    // Relê a flag no regresso: se o dono acabou de a ativar/desativar em
    // Configurações → Segurança, o novo estado já vale no próximo bloqueio.
    await _refreshBiometricState();
  }

  // ─── Estado da biometria ────────────────────────────────────────────

  Future<void> _refreshBiometricState() async {
    final useCase = ref.read(biometricAuthUseCaseProvider);
    final available = await useCase.isAvailable();
    final enabled = available && await useCase.isEnabled();
    if (!mounted) return;
    setState(() {
      _ready = true;
      _enabled = enabled;
      if (!_enabled) _armed = false;
    });
    // Reavalia depois de carregar: no arranque a frio a sessão restaurada
    // pode chegar ANTES do estado biométrico — o bloqueio só dispara aqui.
    _evaluateLock();
  }

  // ─── Bloqueio ───────────────────────────────────────────────────────

  void _evaluateLock() {
    if (_locked || _authenticating || !mounted) return;
    if (!_ready || !_enabled || !_armed) return;
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    setState(() {
      _locked = true;
      _failed = false;
    });
    // Espera o ecrã de bloqueio estar na árvore antes de pedir a biometria.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _prompt();
    });
  }

  Future<void> _prompt() async {
    if (!_locked || _authenticating || !mounted) return;
    setState(() {
      _authenticating = true;
      _failed = false;
    });
    // M3: prompt de biometria no idioma ativo do app.
    final l10n = context.l10n;
    final ok = await ref
        .read(biometricAuthUseCaseProvider)
        .authenticate(
          localizedReason: l10n.appLockMessage,
          signInTitle: l10n.biometricSignInTitle,
          biometricHint: l10n.biometricHint,
          cancelButton: l10n.biometricCancel,
          fallbackTitle: l10n.biometricFallbackTitle,
          goToSettingsButton: l10n.biometricGoToSettingsButton,
          goToSettingsDescription: l10n.biometricGoToSettingsDescription,
          lockOut: l10n.biometricLockOut,
        );
    if (!mounted) return;
    setState(() {
      _authenticating = false;
      if (ok) {
        _locked = false;
        _armed = false;
      } else {
        _failed = true;
      }
    });
  }

  void _onSignedOut() {
    if (!mounted) return;
    setState(() {
      _locked = false;
      _armed = false;
      _authenticating = false;
    });
  }

  void _signOut() {
    ref.read(signOutUseCaseProvider).call();
  }

  // ─── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Reage à sessão: utilizador entra com sessão restaurada (bloqueia se
    // armado) e sai da conta (desarma e remove o ecrã de bloqueio — o
    // LoginScreen fica visível em baixo).
    ref.listen(authStateProvider, (previous, next) {
      if (next.hasValue && next.value == null) {
        _onSignedOut();
      } else if (next.value != null) {
        _evaluateLock();
      }
    });

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (_locked)
          _BiometricLockScreen(
            failed: _failed,
            authenticating: _authenticating,
            onUnlock: _prompt,
            onSignOut: _signOut,
          ),
      ],
    );
  }
}

/// Ecrã de bloqueio — minimalista, segue o mesmo visual do splash/login.
class _BiometricLockScreen extends StatelessWidget {
  const _BiometricLockScreen({
    required this.failed,
    required this.authenticating,
    required this.onUnlock,
    required this.onSignOut,
  });

  final bool failed;
  final bool authenticating;
  final VoidCallback onUnlock;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            // Rola em viewports baixas/escala de texto grande — o conteúdo
            // nunca fica truncado nem estoura.
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.fingerprint_rounded,
                      size: 30,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.appLockTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.appLockMessage,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  if (failed) ...[
                    const SizedBox(height: 12),
                    Text(
                      l10n.appLockError,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: authenticating ? null : onUnlock,
                    icon: const Icon(Icons.fingerprint_rounded, size: 18),
                    label: Text(l10n.appLockUnlock),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: authenticating ? null : onSignOut,
                    child: Text(l10n.commonSignOut),
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
