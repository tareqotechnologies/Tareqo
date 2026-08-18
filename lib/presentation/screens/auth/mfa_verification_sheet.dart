import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../../controllers/auth_providers.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

/// Sheet para verificação de código MFA durante login
class MFAVerificationSheet extends ConsumerStatefulWidget {
  const MFAVerificationSheet({super.key});

  @override
  ConsumerState<MFAVerificationSheet> createState() => _MFAVerificationSheetState();
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite o código de 6 dígitos')),
      );
      return;
    }

    setState(() => _isVerifying = true);

    try {
      final isValid = await ref.read(mfaAuthUseCaseProvider).verifyCode(code);
      
      if (isValid) {
        setState(() => _isVerifying = false);
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        setState(() => _isVerifying = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Código inválido. Tente novamente.')),
          );
        }
      }
    } catch (e) {
      setState(() => _isVerifying = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao verificar código: $e')),
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
                'Autenticação em Dois Fatores',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Digite o código de 6 dígitos do seu aplicativo autenticador:',
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _verifyCode(),
                label: 'Código MFA',
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
                label: 'Verificar',
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton.secondary(
                expanded: true,
                onPressed: () => Navigator.of(context).pop(false),
                label: 'Cancelar',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
