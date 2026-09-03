import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/utils/password_policy.dart';
import '../../controllers/auth_providers.dart';
import '../../widgets/app_sheet.dart';
import '../../../core/observability/crash_reporting.dart';
import 'forgot_password_sheet.dart';

/// Paleta de cores da tela de login — dark premium.
class _LoginColors {
  static const background = Color(0xFF101112);
  static const surface = Color(0xFF1D1E22);
  static const border = Color(0xFF303238);
  static const borderFocus = Color(0xFF16A34A);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFA1A1AA);
  static const green = Color(0xFF22C55E);
  static const greenDark = Color(0xFF16A34A);
}

/// Tela de login — design dark premium, minimalista e profissional.
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
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _emailFocused = false;
  bool _passwordFocused = false;

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(() {
      setState(() => _emailFocused = _emailFocus.hasFocus);
    });
    _passwordFocus.addListener(() {
      setState(() => _passwordFocused = _passwordFocus.hasFocus);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _nameController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _openForgotPassword() async {
    await showAppSheet<void>(
      context,
      builder: (_) => const ForgotPasswordSheet(),
    );
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;

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
        await ref.read(signUpUseCaseProvider).call(
          email: email,
          password: password,
          fullName: _nameController.text.trim(),
        );
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.loginSignUpSuccess)),
        );
      } else {
        await ref
            .read(signInUseCaseProvider)
            .call(email: email, password: password);
      }
    } on AuthWeakPasswordException {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.loginWeakPasswordError)),
      );
    } on AuthApiException catch (error) {
      if (error.statusCode == '429') {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.loginRateLimitError)),
        );
      } else {
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
    final l10n = context.l10n;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: _LoginColors.background,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _LoginColors.background,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 28,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Logo ──
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset(
                          'assets/branding/icon_official.png',
                          width: 100,
                          height: 100,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Título + subtítulo ──
                    Text(
                      'TAREQO',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        color: _LoginColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isSignUpMode
                          ? l10n.loginSubtitleSignUp
                          : 'Gestão simples para o seu negócio',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: _LoginColors.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // ── Nome (modo cadastro) ──
                    if (_isSignUpMode) ...[
                      _buildLabel('Nome'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _nameController,
                        hint: 'Digite seu nome',
                        icon: Icons.person_outline_rounded,
                        textInputAction: TextInputAction.next,
                        obscure: false,
                        focusNode: null,
                        focused: false,
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ── Email ──
                    _buildLabel('Email'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _emailController,
                      hint: 'Digite seu email',
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      obscure: false,
                      focusNode: _emailFocus,
                      focused: _emailFocused,
                    ),
                    const SizedBox(height: 20),

                    // ── Senha ──
                    _buildLabel('Senha'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _passwordController,
                      hint: 'Digite sua senha',
                      icon: Icons.lock_outline_rounded,
                      obscure: _obscurePassword,
                      textInputAction: _isSignUpMode
                          ? TextInputAction.next
                          : TextInputAction.done,
                      onSubmitted: (_) {
                        if (!_isSignUpMode) _submit();
                      },
                      focusNode: _passwordFocus,
                      focused: _passwordFocused,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                          color: _LoginColors.textSecondary,
                        ),
                        onPressed: () => setState(() {
                          _obscurePassword = !_obscurePassword;
                        }),
                      ),
                    ),

                    // ── Confirmar senha (modo cadastro) ──
                    if (_isSignUpMode) ...[
                      const SizedBox(height: 20),
                      _buildLabel('Confirmar senha'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _confirmController,
                        hint: 'Repita a senha',
                        icon: Icons.lock_outline_rounded,
                        obscure: _obscureConfirm,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        focusNode: null,
                        focused: false,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 20,
                            color: _LoginColors.textSecondary,
                          ),
                          onPressed: () => setState(() {
                            _obscureConfirm = !_obscureConfirm;
                          }),
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // ── Botão Entrar ──
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _LoginColors.greenDark,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              _LoginColors.greenDark.withValues(alpha: 0.5),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _isSignUpMode
                                    ? l10n.loginSignUp
                                    : 'Entrar',
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Links ──
                    if (!_isSignUpMode)
                      Center(
                        child: GestureDetector(
                          onTap: _isSubmitting ? null : _openForgotPassword,
                          child: const Text(
                            'Esqueceu sua senha?',
                            style: TextStyle(
                              fontSize: 14,
                              color: _LoginColors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Center(
                      child: GestureDetector(
                        onTap: _isSubmitting
                            ? null
                            : () => setState(() {
                                  _isSignUpMode = !_isSignUpMode;
                                  _confirmController.clear();
                                }),
                        child: RichText(
                          text: TextSpan(
                            text: _isSignUpMode
                                ? 'Já tem uma conta? '
                                : 'Ainda não tem uma conta? ',
                            style: const TextStyle(
                              fontSize: 14,
                              color: _LoginColors.textSecondary,
                              fontWeight: FontWeight.w400,
                            ),
                            children: [
                              TextSpan(
                                text: _isSignUpMode ? 'Entrar' : 'Criar conta',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: _LoginColors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 48),

                    // ── Rodapé de segurança ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 14,
                          color: _LoginColors.textSecondary
                              .withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Seus dados são protegidos com criptografia.',
                          style: TextStyle(
                            fontSize: 12,
                            color: _LoginColors.textSecondary
                                .withValues(alpha: 0.6),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ──

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: _LoginColors.textPrimary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
    FocusNode? focusNode,
    bool focused = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _LoginColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: focused ? _LoginColors.borderFocus : _LoginColors.border,
          width: focused ? 1.5 : 1,
        ),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscure,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        style: const TextStyle(
          fontSize: 15,
          color: _LoginColors.textPrimary,
          fontWeight: FontWeight.w400,
        ),
        cursorColor: _LoginColors.green,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontSize: 15,
            color: _LoginColors.textSecondary.withValues(alpha: 0.5),
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(
            icon,
            size: 20,
            color: focused
                ? _LoginColors.green
                : _LoginColors.textSecondary.withValues(alpha: 0.7),
          ),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
