import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart' show SentryLevel;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/observability/crash_reporting.dart';
import '../../../core/utils/password_policy.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../controllers/auth_providers.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/app_text_field.dart';
import 'mfa_verification_sheet.dart';

/// Tela de DEFINIR NOVA SENHA — mostrada pelo [AuthGate] quando a sessão
/// veio de um link de RECUPERAÇÃO de senha (o e-mail já foi confirmado e o
/// usuário ainda não tem uma senha nova). Ao concluir, o evento `userUpdated`
/// limpa o sinal de recovery e o [AuthGate] segue para a área de gestão.
class SetNewPasswordScreen extends ConsumerStatefulWidget {
  const SetNewPasswordScreen({super.key});

  @override
  ConsumerState<SetNewPasswordScreen> createState() =>
      _SetNewPasswordScreenState();
}

class _SetNewPasswordScreenState extends ConsumerState<SetNewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    setState(() => _isSubmitting = true);

    var updated = false;
    var awaitingMfa = false;
    try {
      await ref
          .read(setNewPasswordUseCaseProvider)
          .call(newPassword: _newController.text);
      updated = true;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.setNewPasswordSuccess)),
      );
    } on AuthApiException catch (error) {
      // Erros de NEGÓCIO do GoTrue têm código próprio (fetch.dart mapeia
      // `error_code` da resposta) — cada um vira uma mensagem acionável em
      // vez do genérico "Could not update the password".
      final code = error.code;
      if (code == 'same_password') {
        // 422: a nova senha é IGUAL à atual — o usuário provavelmente
        // reabriu um link antigo ou digitou a senha de sempre.
        CrashReporting.log(
          'Recovery: nova senha rejeitada (same_password)',
          SentryLevel.info,
          hint: 'set-new-password:same_password',
        );
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.setNewPasswordSamePassword)),
        );
      } else if (code == 'insufficient_aal' ||
          code == 'reauthentication_needed') {
        // Conta com MFA: a sessão de recovery é aal1 e o servidor exige
        // aal2 para gravar a senha. Pede o código TOTP (a verificação sobe
        // a sessão para aal2) e tenta de novo na sequência.
        awaitingMfa = true;
        if (mounted) await _elevateAndRetry(messenger, l10n);
      } else if (error.statusCode == '401' || code == 'session_missing') {
        // Sessão de recovery expirada/revogada (link antigo, token já
        // usado, refresh falhou) — a recuperação tem de recomeçar.
        CrashReporting.log(
          'Recovery: sessão de recuperação expirada/ausente',
          SentryLevel.warning,
          hint: 'set-new-password:session_expired',
        );
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.setNewPasswordSessionExpired)),
        );
      } else if (error.statusCode == '429' ||
          code == 'over_request_rate_limit') {
        CrashReporting.log(
          'Recovery: rate limit no update de senha',
          SentryLevel.warning,
          hint: 'set-new-password:rate_limited',
        );
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.setNewPasswordRateLimited)),
        );
      } else {
        // Erro não mapeado — reporta com o código para diagnóstico e
        // mostra o genérico (não engolir mais a causa real).
        CrashReporting.capture(
          error,
          StackTrace.current,
          hint: 'set-new-password: ${error.statusCode} ${error.code}',
        );
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.setNewPasswordError)),
        );
      }
    } on AuthRetryableFetchException {
      // Sem rede — mensagem acionável (mesma do login offline).
      messenger.showSnackBar(SnackBar(content: Text(l10n.loginNoConnection)));
    } on AuthWeakPasswordException {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.loginWeakPasswordError)),
      );
    } catch (error, stackTrace) {
      CrashReporting.capture(
        error,
        stackTrace,
        hint: 'set-new-password: erro inesperado',
      );
      messenger.showSnackBar(SnackBar(content: Text(l10n.setNewPasswordError)));
    } finally {
      // Limpa o sinal de recovery APENAS no sucesso — e mesmo que a tela
      // seja desmontada durante o await (o `mounted` guard), o flag nunca
      // fica preso indevidamente: sem um NOVO link de recuperação, o
      // AuthGate não volta a mostrar esta tela.
      if (mounted) {
        if (updated && !awaitingMfa) {
          ref.read(passwordRecoveryPendingProvider.notifier).set(false);
        }
        if (!awaitingMfa) {
          setState(() => _isSubmitting = false);
        }
      }
    }
  }

  /// Eleva a sessão para aal2 (sheet de MFA) e tenta gravar a senha de
  /// novo. Falha mantém a tela ativa com mensagem (o usuário pode tentar
  /// novamente); cancelamento volta ao formulário sem alterar nada.
  Future<void> _elevateAndRetry(
    ScaffoldMessengerState messenger,
    AppLocalizations l10n,
  ) async {
    final elevated = await showAppSheet<bool>(
      context,
      isDismissible: false,
      builder: (_) => const MFAVerificationSheet(),
    );
    if (elevated != true || !mounted) {
      if (mounted) setState(() => _isSubmitting = false);
      return;
    }
    try {
      await ref
          .read(setNewPasswordUseCaseProvider)
          .call(newPassword: _newController.text);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.setNewPasswordSuccess)),
      );
      ref.read(passwordRecoveryPendingProvider.notifier).set(false);
      if (mounted) {
        // O evento userUpdated + flag limpo movem o AuthGate para a área
        // de gestão; esta tela sai da árvore.
        setState(() => _isSubmitting = false);
      }
    } on AuthException catch (error, stackTrace) {
      CrashReporting.capture(
        error,
        stackTrace,
        hint: 'set-new-password: falhou após elevação aal2',
      );
      messenger.showSnackBar(SnackBar(content: Text(l10n.setNewPasswordError)));
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final l10n = context.l10n;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF16211E),
                    scheme.surface,
                    const Color(0xFF131916),
                  ]
                : [
                    const Color(0xFFE4F2EC),
                    scheme.surface,
                    const Color(0xFFF0F7F4),
                  ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
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
                        Icons.lock_reset,
                        size: 38,
                        color: scheme.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.setNewPasswordTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.setNewPasswordHint,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Card premium (estilo Apple): cantos 20 + superfície
                  // elevada — mesmo padrão do login e do onboarding.
                  AppCard(
                    elevated: true,
                    borderRadius: const BorderRadius.all(Radius.circular(20)),
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppTextField(
                            controller: _newController,
                            obscureText: _obscureNew,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.newPassword],
                            label: l10n.changePasswordNewLabel,
                            prefixIcon: Icons.lock_reset_outlined,
                            suffixIcon: IconButton(
                              tooltip: _obscureNew
                                  ? l10n.loginShowPassword
                                  : l10n.loginHidePassword,
                              icon: Icon(
                                _obscureNew
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () =>
                                  setState(() => _obscureNew = !_obscureNew),
                            ),
                            validator: (value) {
                              final issue = passwordIssue(
                                value ?? '',
                                requireStrong: true,
                              );
                              return switch (issue) {
                                PasswordIssue.tooShort =>
                                  l10n.loginPasswordError,
                                PasswordIssue.weak =>
                                  l10n.loginWeakPasswordError,
                                null => null,
                              };
                            },
                          ),
                          const SizedBox(height: 14),
                          AppTextField(
                            controller: _confirmController,
                            obscureText: _obscureConfirm,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _submit(),
                            autofillHints: const [AutofillHints.newPassword],
                            label: l10n.changePasswordConfirmLabel,
                            prefixIcon: Icons.lock_outline,
                            suffixIcon: IconButton(
                              tooltip: _obscureConfirm
                                  ? l10n.loginShowPassword
                                  : l10n.loginHidePassword,
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () => setState(
                                () => _obscureConfirm = !_obscureConfirm,
                              ),
                            ),
                            validator: (value) {
                              if (value != _newController.text) {
                                return l10n.loginConfirmError;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          AppButton.primary(
                            onPressed: _isSubmitting ? null : _submit,
                            icon: _isSubmitting
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: scheme.onPrimary,
                                    ),
                                  )
                                : null,
                            label: l10n.setNewPasswordSubmit,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Sair: o usuário pode desistir do fluxo de recuperação
                  // (ex.: clicou no link sem querer).
                  Center(
                    child: TextButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => ref.read(signOutUseCaseProvider).call(),
                      child: Text(l10n.setNewPasswordSignOut),
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
