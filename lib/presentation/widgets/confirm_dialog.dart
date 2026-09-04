import 'package:flutter/material.dart';

import '../../core/i18n/l10n_ext.dart';
import 'app_button.dart';

/// Dialog de confirmação unificado do design system.
///
/// Padrão fixo: cancelamento como `TextButton` (peso baixo) e a acção
/// principal como `AppButton` — `.primary` para confirmações comuns e
/// `.danger` para acções destrutivas (excluir, cancelar venda, sair).
///
/// Retorna `true` quando o utilizador confirma e `false`/`null` caso
/// contrário — o mesmo contrato dos `showDialog<bool>` que substitui.
Future<bool?> showConfirmDialog(
  BuildContext context, {
  required String title,
  String? message,
  required String confirmLabel,
  String? cancelLabel,
  bool destructive = false,
}) {
  final l10n = context.l10n;
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: message == null ? null : Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel ?? l10n.commonCancel),
        ),
        if (destructive)
          AppButton.danger(
            label: confirmLabel,
            onPressed: () => Navigator.of(context).pop(true),
          )
        else
          AppButton.primary(
            label: confirmLabel,
            onPressed: () => Navigator.of(context).pop(true),
          ),
      ],
    ),
  );
}