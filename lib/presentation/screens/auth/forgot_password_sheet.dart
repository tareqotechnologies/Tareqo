import '../../../core/theme/app_tokens.dart';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/observability/crash_reporting.dart';
import '../../../core/utils/password_policy.dart';
import '../../controllers/auth_providers.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/app_text_field.dart';

/// Sheet "Esqueceu a senha?": informa o e-mail e o app envia o link de
/// redefinição do provedor (fluxo padrão GoTrue — a resposta não revela
/// se a conta existe, anti-enumeração).
class ForgotPasswordSheet extends ConsumerStatefulWidget {
  const ForgotPasswordSheet({super.key});

  @override
  ConsumerState<ForgotPasswordSheet> createState() =>
      _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends ConsumerState<ForgotPasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    setState(() => _isSubmitting = true);

    try {
      // Chama diretamente o repository (sem use case intermediário) para
      // minimizar pontos de captura de exceção.
      final repository = ref.read(authRepositoryProvider);
      final email = _emailController.text.trim();

      // M7: NUNCA logar o e-mail do usuário (PII) — apenas o fluxo, sem
      // identificar a conta.
      developer.log(
        'resetPassword: enviando link (fluxo iniciado)',
        name: 'ForgotPassword',
      );

      await repository.resetPassword(email: email);

      developer.log(
        'resetPassword: link enviado com sucesso',
        name: 'ForgotPassword',
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text(l10n.forgotPasswordSent)));
    } on AuthApiException catch (error) {
      if (!mounted) return;
      developer.log(
        'AuthApiException: ${error.statusCode} - ${error.message}',
        name: 'ForgotPassword',
      );
      CrashReporting.capture(
        error,
        StackTrace.current,
        hint: 'Erro API ao enviar link de redefinição',
      );
      if (error.statusCode == '429') {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.loginRateLimitError)),
        );
      } else {
        final detail = error.message.isNotEmpty ? error.message : '';
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              detail.isNotEmpty
                  ? '${l10n.forgotPasswordError}\n($detail)'
                  : l10n.forgotPasswordError,
            ),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } catch (error, stackTrace) {
      if (!mounted) return;
      // Log COMPLETO no console (visível no DevTools/terminal) — M7: sem
      // e-mail (a exceção do SDK não carrega PII da conta).
      developer.log(
        'ERRO resetPassword: ${error.runtimeType}',
        name: 'ForgotPassword',
        error: error,
        stackTrace: stackTrace,
      );
      CrashReporting.capture(
        error,
        stackTrace,
        hint: 'Erro ao enviar link de redefinição de senha',
      );
      messenger.showSnackBar(SnackBar(content: Text(l10n.forgotPasswordError)));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return SingleChildScrollView(
      padding: AppSpacing.sheetPadding,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeader(title: l10n.forgotPasswordTitle),
            Text(
              l10n.forgotPasswordHint,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              autofillHints: const [AutofillHints.email],
              label: l10n.loginEmailLabel,
              prefixIcon: Icons.mail_outline,
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty || !emailRegExp.hasMatch(email)) {
                  return l10n.loginEmailError;
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            AppButton.primary(
              onPressed: _isSubmitting ? null : _submit,
              label: l10n.forgotPasswordSubmit,
              icon: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
