import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../controllers/auth_providers.dart';
import '../../../core/observability/crash_reporting.dart';

/// Tela de autenticação: login e cadastro em um único formulário.
///
/// Após o sucesso, o [AuthGate] troca para o dashboard automaticamente
/// (reage ao stream de sessão) — esta tela não navega manualmente.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

/// Validação de e-mail mais rigorosa (exige domínio e TLD) — evita
/// aceitar 'a@b' como endereço válido.
final RegExp _emailRegExp = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Classes de caracteres exigidas pela política de senha do provedor
/// (GoTrue/Supabase): pelo menos uma minúscula, uma maiúscula, um número
/// e um símbolo — espelha a regra do servidor para validar ANTES do envio.
final RegExp _lowercaseRegExp = RegExp(r'[a-z]');
final RegExp _uppercaseRegExp = RegExp(r'[A-Z]');
final RegExp _digitRegExp = RegExp(r'[0-9]');
final RegExp _symbolRegExp = RegExp(
  "[!@#\$%^&*()_+\\-=\\[\\]{};:'\",.?`~<>/\\\\|]",
);

bool _isStrongPassword(String value) =>
    _lowercaseRegExp.hasMatch(value) &&
    _uppercaseRegExp.hasMatch(value) &&
    _digitRegExp.hasMatch(value) &&
    _symbolRegExp.hasMatch(value);

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

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
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
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
                  Text(
                    'Dumbhanengue',
                    textAlign: TextAlign.center,
                    // Large Title (34) — identidade no ecrã de login.
                    style: theme.textTheme.displaySmall,
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
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_isSignUpMode) ...[
                              TextFormField(
                                controller: _nameController,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.name],
                                decoration: InputDecoration(
                                  labelText: l10n.loginNameLabel,
                                  prefixIcon: const Icon(Icons.person_outline),
                                ),
                              ),
                              const SizedBox(height: 14),
                            ],
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                              decoration: InputDecoration(
                                labelText: l10n.loginEmailLabel,
                                prefixIcon: const Icon(Icons.mail_outline),
                              ),
                              validator: (value) {
                                final email = value?.trim() ?? '';
                                if (email.isEmpty ||
                                    !_emailRegExp.hasMatch(email)) {
                                  return l10n.loginEmailError;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: _isSignUpMode
                                  ? TextInputAction.next
                                  : TextInputAction.done,
                              onFieldSubmitted: (_) {
                                if (!_isSignUpMode) _submit();
                              },
                              autofillHints: [
                                _isSignUpMode
                                    ? AutofillHints.newPassword
                                    : AutofillHints.password,
                              ],
                              decoration: InputDecoration(
                                labelText: l10n.loginPasswordLabel,
                                prefixIcon: const Icon(Icons.lock_outline),
                                helperText: _isSignUpMode
                                    ? l10n.loginPasswordHint
                                    : null,
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
                              validator: (value) {
                                final password = value ?? '';
                                if (password.length < 8) {
                                  return l10n.loginPasswordError;
                                }
                                if (_isSignUpMode &&
                                    !_isStrongPassword(password)) {
                                  return l10n.loginWeakPasswordError;
                                }
                                return null;
                              },
                            ),
                            if (_isSignUpMode) ...[
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _confirmController,
                                obscureText: _obscureConfirm,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _submit(),
                                autofillHints: const [
                                  AutofillHints.newPassword,
                                ],
                                decoration: InputDecoration(
                                  labelText: l10n.loginConfirmLabel,
                                  prefixIcon: const Icon(Icons.lock_outline),
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
                                validator: (value) {
                                  if (value != _passwordController.text) {
                                    return l10n.loginConfirmError;
                                  }
                                  return null;
                                },
                              ),
                            ],
                            const SizedBox(height: 20),
                            FilledButton(
                              onPressed: _isSubmitting ? null : _submit,
                              child: _isSubmitting
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      _isSignUpMode
                                          ? l10n.loginSignUp
                                          : l10n.loginSignIn,
                                    ),
                            ),
                            const SizedBox(height: 4),
                            TextButton(
                              onPressed: _isSubmitting
                                  ? null
                                  : () => setState(() {
                                      _isSignUpMode = !_isSignUpMode;
                                      // Limpa o campo de confirmação ao
                                      // trocar de modo.
                                      _confirmController.clear();
                                    }),
                              child: Text(
                                _isSignUpMode
                                    ? l10n.loginSwitchToSignIn
                                    : l10n.loginSwitchToSignUp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.loginSecurityNote,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.outline,
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
