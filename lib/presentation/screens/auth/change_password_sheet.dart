import '../../../core/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/observability/crash_reporting.dart';
import '../../../core/ui/haptics.dart';
import '../../../core/utils/password_policy.dart';
import '../../controllers/auth_providers.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/app_text_field.dart';

/// Sheet de "Trocar senha" (usuário logado): valida a senha atual com o
/// provedor e grava a nova. Reutiliza a política de senha do cadastro.
class ChangePasswordSheet extends ConsumerStatefulWidget {
  const ChangePasswordSheet({super.key});

  @override
  ConsumerState<ChangePasswordSheet> createState() =>
      _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends ConsumerState<ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    setState(() => _isSubmitting = true);

    try {
      await ref
          .read(changePasswordUseCaseProvider)
          .call(
            currentPassword: _currentController.text,
            newPassword: _newController.text,
          );
      if (!mounted) return;
      // Confirmação tátil da troca (antes do pop: imediato, sem atraso) —
      // mesmo padrão das sheets de Vendas/Compras/Fiado.
      Haptics.success();
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.changePasswordSuccess)),
      );
    } on AuthApiException catch (error) {
      // Erros de NEGÓCIO do GoTrue (fetch.dart mapeia `error_code`):
      //   * invalid_credentials — a reautenticação com a senha ATUAL foi
      //     rejeitada (senha errada) — vem do POST /token;
      //   * current_password_invalid / current_password_required — o PUT
      //     /user rejeitou o `current_password` (senha errada);
      //   * same_password — nova igual à atual;
      //   * 401/insufficient_aal — conta com MFA: a troca exige aal2
      //     (reautenticar por senha não eleva o AAL) — genérico + Sentry.
      final code = error.code;
      final wrongCurrent =
          code == 'invalid_credentials' ||
          code == 'current_password_invalid' ||
          code == 'current_password_required' ||
          (code == null &&
              error.message.toLowerCase().contains(
                'invalid login credentials',
              ));
      final String message;
      if (wrongCurrent) {
        message = l10n.changePasswordWrongCurrent;
      } else if (code == 'same_password') {
        message = l10n.passwordSameAsCurrent;
      } else {
        CrashReporting.capture(
          error,
          StackTrace.current,
          hint: 'change-password: ${error.statusCode} ${error.code}',
        );
        message = l10n.changePasswordError;
      }
      if (!mounted) return;
      Haptics.error();
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } on AuthWeakPasswordException {
      Haptics.error();
      // Política de senha do provedor (GoTrue).
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.loginWeakPasswordError)),
      );
    } catch (error) {
      Haptics.error();
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.changePasswordError)));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SingleChildScrollView(
      padding: AppSpacing.sheetPadding,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeader(title: l10n.changePasswordTitle),
            AppTextField(
              controller: _currentController,
              obscureText: _obscureCurrent,
              textInputAction: TextInputAction.next,
              label: l10n.changePasswordCurrentLabel,
              prefixIcon: Icons.lock_outline,
              autofillHints: const [AutofillHints.password],
              suffixIcon: IconButton(
                tooltip: _obscureCurrent
                    ? l10n.loginShowPassword
                    : l10n.loginHidePassword,
                icon: Icon(
                  _obscureCurrent
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () =>
                    setState(() => _obscureCurrent = !_obscureCurrent),
              ),
              validator: (value) => (value == null || value.isEmpty)
                  ? l10n.loginPasswordError
                  : null,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _newController,
              obscureText: _obscureNew,
              textInputAction: TextInputAction.next,
              label: l10n.changePasswordNewLabel,
              prefixIcon: Icons.lock_reset_outlined,
              autofillHints: const [AutofillHints.newPassword],
              suffixIcon: IconButton(
                tooltip: _obscureNew
                    ? l10n.loginShowPassword
                    : l10n.loginHidePassword,
                icon: Icon(
                  _obscureNew
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () => setState(() => _obscureNew = !_obscureNew),
              ),
              validator: (value) {
                final issue = passwordIssue(value ?? '', requireStrong: true);
                return switch (issue) {
                  PasswordIssue.tooShort => l10n.loginPasswordError,
                  PasswordIssue.weak => l10n.loginWeakPasswordError,
                  null => null,
                };
              },
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _confirmController,
              obscureText: _obscureConfirm,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              label: l10n.changePasswordConfirmLabel,
              prefixIcon: Icons.lock_outline,
              autofillHints: const [AutofillHints.newPassword],
              suffixIcon: IconButton(
                tooltip: _obscureConfirm
                    ? l10n.loginShowPassword
                    : l10n.loginHidePassword,
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              validator: (value) {
                if (value != _newController.text) {
                  return l10n.loginConfirmError;
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            AppButton.primary(
              onPressed: _isSubmitting ? null : _submit,
              label: l10n.changePasswordSubmit,
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
