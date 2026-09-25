import 'package:flutter/material.dart';

/// SnackBar de sucesso com UNDO — o padrão "aço dissipável" do plano
/// UI/UX (Fase 1.3): ações destrutivas REVERSÍVEIS confirmam com esta
/// barra (4s, duração acima do padrão 3s de leitura), deixando o
/// desfazer a um toque. Para ações irreversíveis, continuar usando o
/// `showConfirmDialog` antes de executar — o undo nunca substitui a
/// confirmação explícita, apenas dá uma segunda chance honesta quando a
/// reversão é possível e barata.
///
/// As cores vêm do `snackBarTheme` global (inversão por brilho auditada
/// em `theme_contrast_test.dart`) — este helper só padroniza DURAÇÃO,
/// ação e o controle de duplicidade via `SnackBarAction`.
void showUndoSnackBar(
  BuildContext context, {
  required String message,
  required String undoLabel,
  required VoidCallback onUndo,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;

  // Remover a barra anterior: dois undos consecutivos (ex.: apagar dois
  // clientes em sequência) empilham barras — a nova sempre substitui a
  // antiga, e o undo pendente não confirmado simplesmente não roda.
  messenger
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(label: undoLabel, onPressed: onUndo),
      ),
    );
}
