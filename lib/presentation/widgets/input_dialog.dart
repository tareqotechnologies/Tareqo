import 'package:flutter/material.dart';

import '../../core/i18n/l10n_ext.dart';
import 'app_button.dart';
import 'app_text_field.dart';

/// Dialog de INPUT unificado do design system — um campo de texto com
/// cancelar (`TextButton`) + confirmar (`AppButton.primary`), seguindo o
/// mesmo contrato do [showConfirmDialog] do barrel `dialogs.dart`.
///
/// Retorna o texto preenchido (com trim quando [trimResult]) ao confirmar e
/// `null` ao cancelar ou fechar — o mesmo contrato dos `showDialog<String>`
/// de motivo de rejeição de tenant e de quantidade que substitui.
Future<String?> showInputDialog(
  BuildContext context, {
  required String title,
  required String label,
  String? hintText,
  String? suffixText,
  String? initialValue,
  TextInputType? keyboardType,
  int maxLines = 1,
  required String confirmLabel,
  String? cancelLabel,
  bool trimResult = true,
}) {
  final l10n = context.l10n;
  final controller = TextEditingController(text: initialValue ?? '');

  void submit() {
    final value = controller.text;
    Navigator.of(context).pop(trimResult ? value.trim() : value);
  }

  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: AppTextField(
        controller: controller,
        maxLines: maxLines,
        autofocus: true,
        label: label,
        hintText: hintText,
        suffixText: suffixText,
        keyboardType: keyboardType,
        onSubmitted: (_) => submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(cancelLabel ?? l10n.commonCancel),
        ),
        AppButton.primary(
          label: confirmLabel,
          onPressed: submit,
        ),
      ],
    ),
  );
}