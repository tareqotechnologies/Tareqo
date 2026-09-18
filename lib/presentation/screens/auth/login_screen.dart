import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/password_policy.dart';
import '../../controllers/auth_providers.dart';
import '../../widgets/app_sheet.dart';
import '../../../core/observability/crash_reporting.dart';
import 'forgot_password_sheet.dart';

/// Paleta da tela de login — variante clara e escura.
///
/// Decisão de produto: o login acompanha o brilho do tema do app
/// (`ThemeMode.system`), como as demais telas — no modo claro usa
/// superfícies claras/texto escuro e no escuro mantém o dark premium
/// (antes, a auth era SEMPRE escura mesmo no light mode).
///
/// Os neutros vêm dos tokens do design system: no escuro,
/// `AppColors.backgroundDark`/`surfaceDark`/`borderDark`; no claro, os
/// valores espelham os do `AppTheme.light` (scaffold #FAFAFA, superfície
/// branca, texto #18181B/#6E6E77, borda #E4E4E7). O verde de link/texto
/// segue a regra AA do design system: no claro é o `brandMuted` (#15803D,
/// ≥ 4.5:1 sobre branco) — o vivo #16A34A fica só para a borda de foco
/// (não-texto) no escuro.
@immutable
class _LoginPalette {
  const _LoginPalette({
    required this.background,
    required this.surface,
    required this.border,
    required this.borderFocus,
    required this.textPrimary,
    required this.textSecondary,
    required this.green,
    required this.greenDark,
  });

  /// Fundo da página (atrás dos campos).
  final Color background;

  /// Preenchimento dos campos.
  final Color surface;

  /// Borda dos campos em repouso.
  final Color border;

  /// Borda dos campos com foco.
  final Color borderFocus;

  /// Texto principal (título, rótulos, input).
  final Color textPrimary;

  /// Texto secundário (subtítulo, dicas, rodapé).
  final Color textSecondary;

  /// Acento: links, cursor e ícone dos campos com foco.
  final Color green;

  /// Fundo do botão principal (CTA).
  final Color greenDark;

  /// Modo escuro — dark premium (mesma paleta da v2.0.0).
  static const _LoginPalette dark = _LoginPalette(
    background: AppColors.backgroundDark,
    surface: AppColors.surfaceDark,
    border: AppColors.borderDark,
    borderFocus: AppColors.brand,
    // Branco puro e verde vivo #22C55E são exclusivos da identidade
    // premium do login (não são papéis do tema).
    textPrimary: Colors.white,
    textSecondary: AppColors.onSurfaceVariantDark,
    green: Color(0xFF22C55E),
    greenDark: AppColors.brand,
  );

  /// Modo claro — espelha os neutros do `AppTheme.light` via tokens.
  static const _LoginPalette light = _LoginPalette(
    background: AppColors.scaffoldLight,
    surface: Colors.white,
    border: AppColors.borderLight,
    borderFocus: AppColors.brandMuted,
    textPrimary: AppColors.onSurfaceLight,
    textSecondary: AppColors.onSurfaceVariantLight,
    green: AppColors.brandMuted,
    greenDark: AppColors.brandMuted,
  );
}

/// Tela de login — premium, com variantes clara e escura (segue o brilho do
/// tema do sistema, como o resto do app).
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
        await ref
            .read(signUpUseCaseProvider)
            .call(
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
    } on AuthRetryableFetchException {
      // DNS/rede fora (errno 7 "No address associated with hostname" etc.):
      // mensagem ACIONÁVEL em vez do genérico "verifique e-mail e senha".
      messenger.showSnackBar(SnackBar(content: Text(l10n.loginNoConnection)));
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? _LoginPalette.dark : _LoginPalette.light;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: palette.background,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: palette.background,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
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
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isSignUpMode
                          ? l10n.loginSubtitleSignUp
                          : l10n.loginTagline,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: palette.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // ── Nome (modo cadastro) ──
                    if (_isSignUpMode) ...[
                      _buildLabel(palette, l10n.loginNameLabel),
                      const SizedBox(height: 8),
                      _buildTextField(
                        palette,
                        controller: _nameController,
                        hint: l10n.loginNameHint,
                        icon: Icons.person_outline_rounded,
                        textInputAction: TextInputAction.next,
                        obscure: false,
                        focusNode: null,
                        focused: false,
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ── Email ──
                    _buildLabel(palette, l10n.loginEmailLabel),
                    const SizedBox(height: 8),
                    _buildTextField(
                      palette,
                      controller: _emailController,
                      hint: l10n.loginEmailHint,
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      obscure: false,
                      focusNode: _emailFocus,
                      focused: _emailFocused,
                    ),
                    const SizedBox(height: 20),

                    // ── Senha ──
                    _buildLabel(palette, l10n.loginPasswordLabel),
                    const SizedBox(height: 8),
                    _buildTextField(
                      palette,
                      controller: _passwordController,
                      hint: l10n.loginPasswordHint,
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
                          color: palette.textSecondary,
                        ),
                        // A11y: leitor de ecrã anuncia a ação (e o estado
                        // futuro — o tooltip descreve o que o toque FAZ).
                        tooltip: _obscurePassword
                            ? l10n.loginShowPassword
                            : l10n.loginHidePassword,
                        onPressed: () => setState(() {
                          _obscurePassword = !_obscurePassword;
                        }),
                      ),
                    ),

                    // ── Confirmar senha (modo cadastro) ──
                    if (_isSignUpMode) ...[
                      const SizedBox(height: 20),
                      _buildLabel(palette, l10n.loginConfirmPasswordLabel),
                      const SizedBox(height: 8),
                      _buildTextField(
                        palette,
                        controller: _confirmController,
                        hint: l10n.loginConfirmPasswordHint,
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
                            color: palette.textSecondary,
                          ),
                          tooltip: _obscureConfirm
                              ? l10n.loginShowPassword
                              : l10n.loginHidePassword,
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
                          backgroundColor: palette.greenDark,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: palette.greenDark.withValues(
                            alpha: 0.5,
                          ),
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
                                    : l10n.loginSignIn,
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Links ──
                    if (!_isSignUpMode)
                      Center(
                        child: GestureDetector(
                          onTap: _isSubmitting ? null : _openForgotPassword,
                          child: Text(
                            l10n.loginForgotPassword,
                            style: TextStyle(
                              fontSize: 14,
                              color: palette.green,
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
                                ? '${l10n.loginPromptHaveAccount} '
                                : '${l10n.loginPromptNoAccount} ',
                            style: TextStyle(
                              fontSize: 14,
                              color: palette.textSecondary,
                              fontWeight: FontWeight.w400,
                            ),
                            children: [
                              TextSpan(
                                text: _isSignUpMode
                                    ? l10n.loginSignIn
                                    : l10n.loginSignUp,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: palette.green,
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
                    // Quebra linha em telas estreitas/escala de texto alta
                    // (o texto NUNCA estoura o container — acessibilidade).
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.lock_outline_rounded,
                            size: 14,
                            color: palette.textSecondary.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            l10n.loginSecurityFooter,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: palette.textSecondary.withValues(
                                alpha: 0.6,
                              ),
                              fontWeight: FontWeight.w400,
                            ),
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

  Widget _buildLabel(_LoginPalette palette, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: palette.textPrimary,
      ),
    );
  }

  Widget _buildTextField(
    _LoginPalette palette, {
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
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: focused ? palette.borderFocus : palette.border,
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
        style: TextStyle(
          fontSize: 15,
          color: palette.textPrimary,
          fontWeight: FontWeight.w400,
        ),
        cursorColor: palette.green,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontSize: 15,
            color: palette.textSecondary.withValues(alpha: 0.5),
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(
            icon,
            size: 20,
            color: focused
                ? palette.green
                : palette.textSecondary.withValues(alpha: 0.7),
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
