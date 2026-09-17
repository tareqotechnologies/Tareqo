import 'package:flutter/material.dart';

import '../../core/i18n/l10n_ext.dart';
import '../../core/ui/haptics.dart';
import 'app_button.dart';

import 'admin_thin_bridge.dart';

/// Dialog de confirmação unificado do design system.
///
/// Padrão fixo: cancelamento como `TextButton` (peso baixo) e a acção
/// principal como `AppButton` — `.primary` para confirmações comuns e
/// `.danger` para acções destrutivas (excluir, cancelar venda, sair).
///
/// [thinStyle] aplica a tipografia Thin do painel do super admin
/// (títulos w300) — rotas modais não herdam o Theme local do shell,
/// então o painel pede explicitamente.
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
  bool thinStyle = false,
}) {
  final l10n = context.l10n;
  return showDialog<bool>(
    context: context,
    builder: (context) => adminThinIfNeeded(
      context,
      thinStyle: thinStyle,
      child: AlertDialog(
        title: Text(title),
        titleTextStyle: adminDialogTitleStyle(context, thinStyle: thinStyle),
        content: message == null ? null : Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelLabel ?? l10n.commonCancel),
          ),
          if (destructive)
            AppButton.danger(
              label: confirmLabel,
              onPressed: () {
                // Confirmação tátil do risco aceito — um único ponto
                // centraliza o feedback de TODAS as destrutivas do app.
                Haptics.warning();
                Navigator.of(context).pop(true);
              },
            )
          else
            AppButton.primary(
              label: confirmLabel,
              onPressed: () => Navigator.of(context).pop(true),
            ),
        ],
      ),
    ),
  );
}
