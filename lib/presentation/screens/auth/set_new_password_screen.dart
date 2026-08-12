import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/utils/password_policy.dart';
import '../../controllers/auth_providers.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_text_field.dart';

/// Tela de DEFINIR NOVA SENHA — mostrada pelo [AuthGate] quando a sessão
/// veio de um link de RECUPERAÇÃO de senha (o e-mail já foi confirmado e o
/// usuário ainda não tem uma senha nova). Ao concluir, o evento `userUpdated`
/// limpa o sinal de recovery e o [AuthGate] segue para a área de gestão.
class SetNewPasswordScreen extends ConsumerStatefulWidget {
  const SetNewPasswordScreen({super.key});

  @override
  ConsumerState<SetNewPasswordScreen> createState() =>
      _SetNewPasswordScreenState();
}

class _SetNewPasswordScreenState extends ConsumerState<SetNewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    setState(() => _isSubmitting = true);

    var updated = false;
    try {
      await ref
          .read(setNewPasswordUseCaseProvider)
          .call(newPassword: _newController.text);
      updated = true;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.setNewPasswordSuccess)),
      );
    } on AuthWeakPasswordException {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.loginWeakPasswordError)),
      );
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.setNewPasswordError)));
    } finally {
      // Limpa o sinal de recovery APENAS no sucesso — e mesmo que a tela
      // seja desmontada durante o await (o `mounted` guard), o flag nunca
      // fica preso indevidamente: sem um NOVO link de recuperação, o
      // AuthGate não volta a mostrar esta tela.
      if (mounted) {
        if (updated) {
          ref.read(passwordRecoveryPendingProvider.notifier).state = false;
        }
        setState(() => _isSubmitting = false);
      }
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
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
                        Icons.lock_reset,
                        size: 38,
                        color: scheme.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.setNewPasswordTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.setNewPasswordHint,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),
                  AppCard(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppTextField(
                            controller: _newController,
                            obscureText: _obscureNew,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.newPassword],
                            label: l10n.changePasswordNewLabel,
                            prefixIcon: Icons.lock_reset_outlined,
                            suffixIcon: IconButton(
                              tooltip: _obscureNew
                                  ? l10n.loginShowPassword
                                  : l10n.loginHidePassword,
                              icon: Icon(
                                _obscureNew
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () =>
                                  setState(() => _obscureNew = !_obscureNew),
                            ),
                            validator: (value) {
                              final issue = passwordIssue(
                                value ?? '',
                                requireStrong: true,
                              );
                              return switch (issue) {
                                PasswordIssue.tooShort =>
                                  l10n.loginPasswordError,
                                PasswordIssue.weak =>
                                  l10n.loginWeakPasswordError,
                                null => null,
                              };
                            },
                          ),
                          const SizedBox(height: 14),
                          AppTextField(
                            controller: _confirmController,
                            obscureText: _obscureConfirm,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _submit(),
                            autofillHints: const [AutofillHints.newPassword],
                            label: l10n.changePasswordConfirmLabel,
                            prefixIcon: Icons.lock_outline,
                            suffixIcon: IconButton(
                              tooltip: _obscureConfirm
                                  ? l10n.loginShowPassword
                                  : l10n.loginHidePassword,
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () => setState(
                                () => _obscureConfirm = !_obscureConfirm,
                              ),
                            ),
                            validator: (value) {
                              if (value != _newController.text) {
                                return l10n.loginConfirmError;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          AppButton.primary(
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
                            label: l10n.setNewPasswordSubmit,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Sair: o usuário pode desistir do fluxo de recuperação
                  // (ex.: clicou no link sem querer).
                  Center(
                    child: TextButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => ref.read(signOutUseCaseProvider).call(),
                      child: Text(l10n.setNewPasswordSignOut),
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
