import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/password_policy.dart';
import '../../controllers/auth_providers.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/app_text_field.dart';
import '../../../core/observability/crash_reporting.dart';
import 'forgot_password_sheet.dart';

/// Tela de autenticação V4 — login e cadastro num único formulário.
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

 @override
 void dispose() {
 _emailController.dispose();
 _passwordController.dispose();
 _confirmController.dispose();
 _nameController.dispose();
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
 final theme = Theme.of(context);
 final scheme = theme.colorScheme;
 final l10n = context.l10n;

 return Scaffold(
 body: SafeArea(
 child: Center(
 child: SingleChildScrollView(
 padding: const EdgeInsets.symmetric(
 horizontal: AppSpacing.xl,
 vertical: AppSpacing.xxl,
 ),
 child: ConstrainedBox(
 constraints: const BoxConstraints(maxWidth: 420),
 child: Column(
 mainAxisSize: MainAxisSize.min,
 crossAxisAlignment: CrossAxisAlignment.stretch,
 children: [
 const _LoginHero(),
 const SizedBox(height: AppSpacing.xxl),
 Text(
 _isSignUpMode
 ? l10n.loginSubtitleSignUp
 : l10n.loginSubtitleSignIn,
 textAlign: TextAlign.center,
 style: theme.textTheme.bodyMedium?.copyWith(
 color: scheme.onSurfaceVariant,
 ),
 ),
 const SizedBox(height: AppSpacing.lg),
 // Card premium (estilo Apple): cantos 20 + superfície
 // elevada — o formulário flutua sobre o fundo contínuo.
 AppCard(
 elevated: true,
 borderRadius: AppRadius.xlAll,
 padding: const EdgeInsets.all(AppSpacing.lg),
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
 prefixIcon: Icons.person_outline_rounded,
 ),
 const SizedBox(height: AppSpacing.md),
 ],
 AppTextField(
 controller: _emailController,
 keyboardType: TextInputType.emailAddress,
 textInputAction: TextInputAction.next,
 autofillHints: const [AutofillHints.email],
 label: l10n.loginEmailLabel,
 prefixIcon: Icons.mail_outline_rounded,
 ),
 const SizedBox(height: AppSpacing.md),
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
 prefixIcon: Icons.lock_outline_rounded,
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
 const SizedBox(height: AppSpacing.md),
 AppTextField(
 controller: _confirmController,
 obscureText: _obscureConfirm,
 textInputAction: TextInputAction.done,
 onSubmitted: (_) => _submit(),
 autofillHints: const [AutofillHints.newPassword],
 label: l10n.loginConfirmLabel,
 prefixIcon: Icons.lock_outline_rounded,
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
 const SizedBox(height: AppSpacing.xl),
 AppButton.primary(
 expanded: true,
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
 label: _isSignUpMode
 ? l10n.loginSignUp
 : l10n.loginSignIn,
 ),
 if (!_isSignUpMode) ...[
 const SizedBox(height: AppSpacing.xxs),
 Center(
 child: TextButton(
 onPressed: _isSubmitting
 ? null
 : _openForgotPassword,
 child: Text(l10n.loginForgotPassword),
 ),
 ),
 ],
 const SizedBox(height: AppSpacing.xs),
 Center(
 child: TextButton(
 onPressed: _isSubmitting
 ? null
 : () => setState(() {
 _isSignUpMode = !_isSignUpMode;
 _confirmController.clear();
 }),
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
 const SizedBox(height: AppSpacing.lg),
 Text(
 l10n.loginSecurityNote,
 textAlign: TextAlign.center,
 style: theme.textTheme.bodySmall,
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

class _LoginHero extends StatelessWidget {
 const _LoginHero();

 @override
 Widget build(BuildContext context) {
 final theme = Theme.of(context);

 return Column(
 children: [
    Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.35),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.asset(
          'assets/branding/icon_official.png',
          width: 72,
          height: 72,
          fit: BoxFit.cover,
        ),
      ),
    ),
    const SizedBox(height: AppSpacing.lg),
    FittedBox(
 fit: BoxFit.scaleDown,
 child: Text(
 'Dumbhanengue',
 textAlign: TextAlign.center,
 // Tipografia apertada (estilo Apple): peso pesado + tracking
 // negativo — a marca tem presença de wordmark.
 style: theme.textTheme.displaySmall?.copyWith(
 fontWeight: FontWeight.w500,
 letterSpacing: -1.0,
 ),
 ),
 ),
 ],
 );
 }
}
