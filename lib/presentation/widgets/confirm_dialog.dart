import 'package:flutter/material.dart';

import '../../core/i18n/l10n_ext.dart';
import '../../core/ui/haptics.dart';
import 'app_button.dart';
import 'admin_thin_bridge.dart';

import '../../core/theme/app_typography.dart';

/// Dialog de confirmação unificado do design system.
///
/// Padrão fixo: cancelamento como `TextButton` (peso baixo) e a acção
/// principal como `AppButton` — `.primary` para confirmações comuns e
/// `.danger` para acções destrutivas (excluir, cancelar venda, sair).
///
/// Adição F4.3: [animated] controla se a confirmação tem animação visual
/// (scale do botão no press + feedback haptico). Quando [thinStyle] está
/// ativo (painéis de admin), a animação é contida ao mínimo para não
/// atrapalhar a densidade de informações.
///
/// Retorna `true` quando o utilizador confirma e `false`/`null` caso
/// contrário — o mesmo contrato dos `showDialog<bool>` que substitui.
Future<bool?> showConfirmDialog({
  required BuildContext context,
  required String title,
  String? message,
  required String confirmLabel,
  String? cancelLabel,
  bool destructive = false,
  bool thinStyle = false,
  bool animated = true,
}) {
  final l10n = context.l10n;
  final theme = Theme.of(context);
  return showDialog<bool>(
    context: context,
    builder: (context) => adminThinIfNeeded(
      context,
      thinStyle: thinStyle,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        transitionBuilder: (Widget child, Animation<double> animation) =>
            FadeTransition(opacity: animation, child: child),
        child: AlertDialog(
          title: Text(title, style: AppTypography.titleMedium),
          titleTextStyle: AppTypography.titleMedium.copyWith(
            color: theme.colorScheme.onSurface,
          ),
          content: message == null ? null : Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelLabel ?? l10n.commonCancel),
            ),
            if (destructive)
              AppButton.danger(
                label: confirmLabel,
                onPressed: animated
                    ? () {
                        // Confirmação tátil do risco aceito — um único ponto
                        // centraliza o feedback de TODAS as destrutivas do app.
                        Haptics.warning();
                        Navigator.of(context).pop(true);
                      }
                    : () => Navigator.of(context).pop(true),
              )
            else
              AppButton.primary(
                label: confirmLabel,
                onPressed: animated
                    ? () => Navigator.of(context).pop(true)
                    : () => Navigator.of(context).pop(true),
              ),
          ],
        ),
      ),
    ),
  );
}
