import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/utils/password_policy.dart';
import '../../controllers/auth_providers.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/app_text_field.dart';
import '../../../core/observability/crash_reporting.dart';
import 'forgot_password_sheet.dart';

/// Tela de autenticação: login e cadastro em um único formulário.
///
/// Após o sucesso, o [AuthGate] troca para o dashboard automaticamente
/// (reage ao stream de sessão) — esta tela não navega manualmente.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isSignUpMode = false;
  bool _isSubmitting = false;

  /// Alterna visibilidade das senhas (UX — senha longa no celular).
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  /// Abre a sheet "Esqueceu a senha?" (envia o link de redefinição).
  Future<void> _openForgotPassword() async {
    await showAppSheet<void>(
      context,
      builder: (_) => const ForgotPasswordSheet(),
    );
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;

    // Validação manual ANTES do envio: a primeira regra violada bloqueia o
    // submit e aparece como NOTIFICAÇÃO (SnackBar) — sem texto fixo sob os
    // campos (o aviso de senha antes ficava sempre visível e truncado em
    // telas estreitas).
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    String? validationError;
    if (email.isEmpty || !emailRegExp.hasMatch(email)) {
      validationError = l10n.loginEmailError;
    } else {
      validationError = switch (passwordIssue(
        password,
        requireStrong: _isSignUpMode,
      )) {
        PasswordIssue.tooShort => l10n.loginPasswordError,
        PasswordIssue.weak => l10n.loginWeakPasswordError,
        null => null,
      };
    }
    if (validationError == null &&
        _isSignUpMode &&
        _confirmController.text != password) {
      validationError = l10n.loginConfirmError;
    }

    if (validationError != null) {
      messenger.showSnackBar(SnackBar(content: Text(validationError)));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      if (_isSignUpMode) {
        await ref
            .read(signUpUseCaseProvider)
            .call(
              email: email,
              password: password,
              fullName: _nameController.text.trim(),
            );
        // Com confirmação de e-mail ativa (padrão no Supabase), a conta é
        // criada mas a sessão só vem após confirmar — oriente o usuário.
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.loginSignUpSuccess)),
        );
      } else {
        await ref
            .read(signInUseCaseProvider)
            .call(email: email, password: password);
        // Sucesso: o authStateProvider emite o usuário e o AuthGate navega.
      }
    } on AuthWeakPasswordException {
      // Política de senha do provedor (GoTrue): mostra o requisito exato em
      // vez do erro genérico — é validação de entrada, não falha do app.
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.loginWeakPasswordError)),
      );
    } on AuthApiException catch (error) {
      // 429 — limite de requisições do provedor (ex.: envio de e-mails de
      // confirmação). É transiente: orienta a aguardar em vez de mostrar a
      // falha genérica — e não vale logar como erro inesperado do app.
      if (error.statusCode == '429') {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.loginRateLimitError)),
        );
      } else {
        // Outros erros do provedor (ex.: credenciais inválidas): mantém o
        // comportamento anterior — loga para diagnóstico e mostra o erro
        // genérico.
        CrashReporting.capture(
          error,
          StackTrace.current,
          hint: 'Erro de autenticação (API)',
        );
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              _isSignUpMode ? l10n.loginSignUpError : l10n.loginSignInError,
            ),
          ),
        );
      }
    } catch (error, stackTrace) {
      // Log detalhado para diagnóstico; a UI mostra apenas mensagem genérica
      // (não expõe detalhes internos do provedor ao usuário).
      CrashReporting.capture(error, stackTrace, hint: 'Erro de autenticação');
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _isSignUpMode ? l10n.loginSignUpError : l10n.loginSignInError,
          ),
        ),
      );
    } finally {
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
                        Icons.storefront,
                        size: 38,
                        color: scheme.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // FittedBox scaleDown: 'Dumbhanengue' é uma única palavra e
                  // não pode quebrar — em telas estreitas ou escala de texto
                  // alta ela encolhe para SEMPRE caber (nunca trunca).
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Dumbhanengue',
                      textAlign: TextAlign.center,
                      // Large Title (34) — identidade no ecrã de login.
                      style: theme.textTheme.displaySmall,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isSignUpMode
                        ? l10n.loginSubtitleSignUp
                        : l10n.loginSubtitleSignIn,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 28),
                  AppCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_isSignUpMode) ...[
                          AppTextField(
                            controller: _nameController,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.name],
                            label: l10n.loginNameLabel,
                            prefixIcon: Icons.person_outline,
                          ),
                          const SizedBox(height: 16),
                        ],
                        AppTextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          label: l10n.loginEmailLabel,
                          prefixIcon: Icons.mail_outline,
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: _isSignUpMode
                              ? TextInputAction.next
                              : TextInputAction.done,
                          onSubmitted: (_) {
                            if (!_isSignUpMode) _submit();
                          },
                          autofillHints: [
                            _isSignUpMode
                                ? AutofillHints.newPassword
                                : AutofillHints.password,
                          ],
                          label: l10n.loginPasswordLabel,
                          prefixIcon: Icons.lock_outline,
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword
                                ? l10n.loginShowPassword
                                : l10n.loginHidePassword,
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () => setState(() {
                              _obscurePassword = !_obscurePassword;
                            }),
                          ),
                        ),
                        if (_isSignUpMode) ...[
                          const SizedBox(height: 16),
                          AppTextField(
                            controller: _confirmController,
                            obscureText: _obscureConfirm,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _submit(),
                            autofillHints: const [AutofillHints.newPassword],
                            label: l10n.loginConfirmLabel,
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
                              onPressed: () => setState(() {
                                _obscureConfirm = !_obscureConfirm;
                              }),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        AppButton.primary(
                          onPressed: _isSubmitting ? null : _submit,
                          icon: _isSubmitting
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    // Sem cor explícita o spinner usaria o
                                    // primary (verde) sobre o botão verde —
                                    // invisível durante o envio.
                                    color: scheme.onPrimary,
                                  ),
                                )
                              : null,
                          label: _isSignUpMode
                              ? l10n.loginSignUp
                              : l10n.loginSignIn,
                        ),
                        // "Esqueceu a senha?" — só no login (o link chega
                        // por e-mail; o fluxo continua no app pelo deep
                        // link de recuperação).
                        if (!_isSignUpMode) ...[
                          const SizedBox(height: 4),
                          Center(
                            child: TextButton(
                              onPressed: _isSubmitting
                                  ? null
                                  : _openForgotPassword,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                              ),
                              child: Text(l10n.loginForgotPassword),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        // Link de troca de modo CENTRALIZADO (antes esticava
                        // a largura toda do card) — parece um link, não um
                        // botão de tela cheia. Altura de toque generosa.
                        Center(
                          child: TextButton(
                            onPressed: _isSubmitting
                                ? null
                                : () => setState(() {
                                    _isSignUpMode = !_isSignUpMode;
                                    // Limpa o campo de confirmação ao
                                    // trocar de modo.
                                    _confirmController.clear();
                                  }),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                            ),
                            child: Text(
                              _isSignUpMode
                                  ? l10n.loginSwitchToSignIn
                                  : l10n.loginSwitchToSignUp,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Nota de segurança: bodySmall (13) em onSurfaceVariant —
                  // legível, sem competir com o conteúdo (antes: labelSmall
                  // 11 em outline, pequeno e pálido).
                  Text(
                    l10n.loginSecurityNote,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
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
