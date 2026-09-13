import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../domain/repositories/i_mfa_server_port.dart';
import '../../controllers/auth_providers.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

/// Sheet para verificação de código MFA durante login
class MFAVerificationSheet extends ConsumerStatefulWidget {
  const MFAVerificationSheet({super.key});

  @override
  ConsumerState<MFAVerificationSheet> createState() =>
      _MFAVerificationSheetState();
}

class _MFAVerificationSheetState extends ConsumerState<MFAVerificationSheet> {
  final _codeController = TextEditingController();
  bool _isVerifying = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.mfaCodeLengthError)));
      return;
    }

    setState(() => _isVerifying = true);

    try {
      // P1: a verificação é feita NO SERVIDOR (GoTrue) — o código correto
      // renova a sessão com claim aal2, o que as guardas de RLS consultam.
      // A flag local antiga (`verifyCode` TOTP offline) NÃO eleva a sessão.
      final result = await ref
          .read(mfaAuthUseCaseProvider)
          .verifyAndElevate(code);

      if (result == MfaElevationResult.success) {
        setState(() => _isVerifying = false);
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        setState(() => _isVerifying = false);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(context.l10n.mfaInvalidCode)));
        }
      }
    } catch (e) {
      setState(() => _isVerifying = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.mfaVerifyError('$e'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.l10n.securityTwoFactorTitle,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                context.l10n.mfaCodeHint,
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _verifyCode(),
                label: context.l10n.mfaCodeFieldLabel,
                prefixIcon: Icons.security,
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton.primary(
                expanded: true,
                onPressed: _isVerifying ? null : _verifyCode,
                icon: _isVerifying
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: scheme.onPrimary,
                        ),
                      )
                    : null,
                label: context.l10n.mfaVerify,
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton.secondary(
                expanded: true,
                onPressed: () => Navigator.of(context).pop(false),
                label: context.l10n.commonCancel,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
