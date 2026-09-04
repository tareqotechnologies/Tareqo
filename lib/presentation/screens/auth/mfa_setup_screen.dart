import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_tokens.dart';
import '../../controllers/auth_providers.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_text_field.dart';

/// Tela de configuração de MFA (Multi-Factor Authentication)
class MFASetupScreen extends ConsumerStatefulWidget {
  const MFASetupScreen({super.key});

  @override
  ConsumerState<MFASetupScreen> createState() => _MFASetupScreenState();
}

class _MFASetupScreenState extends ConsumerState<MFASetupScreen> {
  final _codeController = TextEditingController();
  bool _isVerifying = false;
  String? _secret;
  String? _qrCodeData;
  Timer? _timer;
  int _timeRemaining = 30;

  @override
  void initState() {
    super.initState();
    _initializeMFA();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _initializeMFA() async {
    try {
      final secret = await ref.read(mfaAuthUseCaseProvider).generateSecret();
      final user = ref.read(authStateProvider).value;
      final qrData = await ref.read(mfaAuthUseCaseProvider).generateQRCodeData(
        issuer: 'TAREQO',
        account: user?.email ?? 'user',
      );

      setState(() {
        _secret = secret;
        _qrCodeData = qrData;
      });
      
      _startTimer();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.mfaInitError('$e'))),
        );
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      final remaining = ref.read(mfaAuthUseCaseProvider).getTimeRemaining();
      setState(() {
        _timeRemaining = remaining;
      });
    });
  }

  Future<void> _verifySetup() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.mfaCodeLengthError)),
      );
      return;
    }

    setState(() => _isVerifying = true);

    try {
      final isValid = await ref.read(mfaAuthUseCaseProvider).verifyCode(code);
      
      if (isValid) {
        // Confirmar ativação — só agora gravamos mfa_enabled.
        await ref.read(mfaAuthUseCaseProvider).confirmEnable();
        setState(() => _isVerifying = false);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.mfaSetupSuccess)),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        setState(() => _isVerifying = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.mfaInvalidCode)),
          );
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
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.mfaSetupTitle),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_qrCodeData != null) ...[
                Text(
                  l10n.mfaQrScanTitle,
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.mfaQrScanHelp,
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                Center(
                  child: AppCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: QrImageView(
                      data: _qrCodeData!,
                      version: QrVersions.auto,
                      size: 200.0,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.mfaManualEntryTitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                if (_secret != null)
                  SelectableText(
                    _secret!,
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'monospace',
                      color: scheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  l10n.mfaConfirmPrompt,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textInputAction: TextInputAction.done,
                  label: l10n.mfaDigitsFieldLabel,
                  prefixIcon: Icons.security,
                ),
                const SizedBox(height: AppSpacing.sm),
                Center(
                  child: Text(
                    l10n.mfaExpiresIn(_timeRemaining),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppButton.primary(
                  expanded: true,
                  onPressed: _isVerifying ? null : _verifySetup,
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
                  label: l10n.mfaVerifyAndEnable,
                ),
              ] else
                const Center(
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
