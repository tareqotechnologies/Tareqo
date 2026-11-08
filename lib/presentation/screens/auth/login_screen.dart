import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/password_policy.dart';
import '../../controllers/auth_providers.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/premium_decor.dart';
import '../../../core/observability/crash_reporting.dart';
import '../../../core/theme/app_typography.dart';
import 'forgot_password_sheet.dart';

/// Paleta da tela de login — variante clara e escura.
///
/// Decisão de produto: o login acompanha o brilho do tema do app
/// (`ThemeMode.system`), como as demais telas — no modo claro usa
/// superfícies claras/texto escuro e no escuro mantém o dark premium
/// (antes, a auth era SEMPRE escura mesmo no light mode).
///
/// Os neutros vêm dos tokens do design system: no escuro,
/// `AppColors.darkBackground`/`surfaceDark`/`borderDark`; no claro, os
/// valores espelham os do `AppTheme.light` (scaffold #FAFAFA, superfície
/// branca, texto #18181B/#6E6E77, borda #E4E4E7). A cor de acento/links
/// segue a regra AA do design system: laranja #F28C00 no claro, laranja
/// #FF9800 no escuro — usadas somente em links de ação e estado
/// de foco.
@immutable
class _LoginPalette {
  const _LoginPalette({
    required this.background,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
    required this.accentDark,
    required this.onCta,
  });

  /// Fundo da página (atrás dos campos).
  final Color background;

  /// Texto principal (título, rótulos, input).
  final Color textPrimary;

  /// Texto secundário (subtítulo, dicas, rodapé).
  final Color textSecondary;

  /// Acento: links, cursor e ícone dos campos com foco.
  final Color accent;

  /// Fundo do botão principal (CTA).
  final Color accentDark;

  /// Conteúdo sobre o CTA: tinta escura sobre o laranja do botão —
  /// branco sobre #FF9800 dá só 2.06:1 (reprovava o AA de 4.5:1); a tinta
  /// escura sobe para ~7.9:1.
  final Color onCta;

  /// Modo escuro — preto oficial com texto gelo.
  static final _LoginPalette dark = _LoginPalette(
    background: AppColors.darkBackground,
    textPrimary: AppColors.ice,
    textSecondary: AppColors.darkTextSecondary,
    // Acento laranja (links, cursor, ícone em foco) sobre o fundo neutro.
    // #F28C00 no claro, #FF9800 no escuro — usadas somente em links
    // de ação e estado de foco, ≥ 4.5:1 AA sobre as respectivas
    // superfícies.
    accent: AppColors.accentOrange,
    accentDark: AppColors.darkAccentOrange,
    onCta: AppColors.lightTextPrimary,
  );

  /// Modo claro — espelha os neutros do `AppTheme.light` via tokens.
  static final _LoginPalette light = _LoginPalette(
    background: AppColors.lightBackground,
    textPrimary: AppColors.lightTextPrimary,
    textSecondary: AppColors.lightTextSecondary,
    // Acento laranja: usado somente em links de ação e estado de foco.
    // #F28C00 no claro, #FF9800 no escuro — ≥ 4.5:1 AA sobre as
    // superfícies respectivas.
    accent: AppColors.accentOrange,
    accentDark: AppColors.darkAccentOrange,
    onCta: AppColors.lightTextPrimary,
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

  /// Parallax do Large Title (item 4.5 do plano UI/UX, docs/pt/21): o
  /// header (logo + TAREQO + tagline) desliza a MEIA velocidade do
  /// conteúdo durante o scroll — profundidade iOS. O [Transform.translate]
  /// não participa do layout: em repouso (offset 0) a página é
  /// pixel-idêntica à v4; rolando, o formulário sobe por cima do header
  /// (pintado depois na coluna).
  final _scrollController = ScrollController();
  double _headerParallax = 0;

  bool _isSignUpMode = false;
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  /// Progresso do parallax (4.5): o header acompanha o scroll a 0.5×.
  /// Com `disableAnimations` (acessibilidade) o movimento é desligado —
  /// o header rola à velocidade normal e nada se move "sozinho".
  void _onScroll() {
    final parallax = MediaQuery.disableAnimationsOf(context)
        ? 0.0
        : _scrollController.offset * 0.5;
    if (parallax != _headerParallax) {
      setState(() => _headerParallax = parallax);
    }
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
        // Fundo premium: dois halos de luz da cor da marca (canto superior
        // direito e inferior esquerdo) por trás do formulário — puramente
        // decorativos, sem toque nem semântica.
        body: Stack(
          children: [
            Positioned(
              top: -140,
              right: -120,
              child: PremiumGlow(
                color: palette.accent,
                size: 380,
                opacity: isDark ? 0.16 : 0.12,
              ),
            ),
            Positioned(
              bottom: -160,
              left: -140,
              child: PremiumGlow(
                color: palette.accentDark,
                size: 420,
                opacity: isDark ? 0.12 : 0.08,
              ),
            ),
            Positioned.fill(child: _buildBody(context, palette)),
          ],
        ),
      ),
    );
  }

  /// Conteúdo do login (logo, campos, CTA e links) — o mesmo de antes,
  /// agora pintado por cima dos halos do fundo.
  Widget _buildBody(BuildContext context, _LoginPalette palette) {
    final l10n = context.l10n;
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.xl,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header com parallax (4.5): Large Title da escala
                // (`displaySmall` 34/w300, tracking negativo) — a
                // "primeira impressão" do plano. O bloco desliza a
                // meia velocidade do conteúdo; o formulário sobe por
                // cima (pintado depois). Em repouso, translate 0 —
                // layout/pixels idênticos ao login anterior.
                Transform.translate(
                  offset: Offset(0, _headerParallax),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Logo ──
                      // Logo com brilho da marca por baixo e aro de
                      // cabelo — "joia" de abertura do app.
                      Center(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                            boxShadow: PremiumDecor.glow(
                              palette.accent,
                              strength: 1.2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                            child: Image.asset(
                              'assets/branding/icon_official.png',
                              width: 100,
                              height: 100,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // ── Título + subtítulo ──
                      Text(
                        'TAREQO',
                        textAlign: TextAlign.center,
                        // Large Title da escala — cor do tema (mesmos
                        // pares auditados: branco no escuro, #161616
                        // no claro).
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _isSignUpMode
                            ? l10n.loginSubtitleSignUp
                            : l10n.loginTagline,
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium.copyWith(
                          color: palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // ── Nome (modo cadastro) ──
                if (_isSignUpMode) ...[
                  _buildLabel(palette, l10n.loginNameLabel),
                  const SizedBox(height: AppSpacing.sm),
                  _buildTextField(
                    palette,
                    controller: _nameController,
                    hint: l10n.loginNameHint,
                    icon: Icons.person_outline_rounded,
                    textInputAction: TextInputAction.next,
                    obscure: false,
                  ),
                  const SizedBox(height: AppSpacing.xl),
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
                // CTA com brilho da marca quando habilitado (o brilho
                // apaga-se durante o envio — feedback de estado).
                AnimatedContainer(
                  duration: AppDurations.fast,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    boxShadow: _isSubmitting
                        ? null
                        : PremiumDecor.glow(palette.accentDark),
                  ),
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: palette.accentDark,
                      foregroundColor: palette.onCta,
                      disabledBackgroundColor: palette.accentDark.withValues(
                        alpha: 0.5,
                      ),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        // Design system V4: mesmo raio dos controles
                        // (botões/campos) — o 14 ad-hoc divergia.
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      // CTA = labelLarge (14/w500), o mesmo degrau dos
                      // demais botões primários do app.
                      textStyle: AppTypography.labelLarge.copyWith(
                        letterSpacing: 0.3,
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.ice,
                            ),
                          )
                        : Text(
                            _isSignUpMode ? l10n.loginSignUp : l10n.loginSignIn,
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
                        style: AppTypography.labelLarge.copyWith(
                          color: palette.accent,
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
                        style: AppTypography.bodyMedium.copyWith(
                          color: palette.textSecondary,
                        ),
                        children: [
                          TextSpan(
                            text: _isSignUpMode
                                ? l10n.loginSignIn
                                : l10n.loginSignUp,
                            style: AppTypography.labelLarge.copyWith(
                              color: palette.accent,
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
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        l10n.loginSecurityFooter,
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall.copyWith(
                          color: palette.textSecondary.withValues(alpha: 0.6),
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
    );
  }

  // ── Helpers ──

  Widget _buildLabel(_LoginPalette palette, String text) {
    return Text(
      text,
      // Rótulo visível do campo = labelLarge (14/w500).
      style: AppTypography.labelLarge.copyWith(color: palette.textPrimary),
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
    Widget? suffixIcon,
  }) {
    // Campos alinhados ao design system: usa o InputDecorationTheme do app
    // (fill, borda em repouso, foco 1.5 com primary, raio md) — o mesmo
    // tratamento de todos os formulários. O foco é gerido pelo Flutter; a
    // identidade do login fica na paleta (fundo e acento), não numa
    // decoração de campo divergente.
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      // Texto digitado = bodyLarge (16) — o mesmo do corpo dos formulários.
      style: AppTypography.bodyLarge.copyWith(color: palette.textPrimary),
      cursorColor: palette.accent,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: suffixIcon,
        // Alinhado ao design system: erro aparecendo abaixo do campo
        errorMaxLines: 2,
        errorStyle: Theme.of(context).textTheme.bodySmall?.copyWith(),
      ),
    );
  }
}
