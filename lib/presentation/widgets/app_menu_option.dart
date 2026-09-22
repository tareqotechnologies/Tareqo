import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Pílula de seleção minimalista ("Hoje ▾") — UM único padrão para todos
/// os menus de opção do app (período, exportação, ações, troca de loja).
///
/// O gatilho é só texto + chevron fino (sem caixa, estilo iOS); o menu
/// segue o `popupMenuTheme` global (raio 12, overlay chapado, itens de
/// 44px com texto `bodySmall`) e marca a opção ativa com um check leve.
class AppMenuOption<T> extends StatelessWidget {
  const AppMenuOption({
    super.key,
    required this.label,
    required this.options,
    required this.onSelected,
    this.showCheck = true,
    this.leading,
    this.tooltip,
  });

  /// Texto da pílula (opção ativa).
  final String label;

  final List<AppMenuOptionItem<T>> options;
  final ValueChanged<T> onSelected;

  /// Mostra o check circular na opção ativa (desligue para menus de ação
  /// sem estado, ex.: exportar).
  final bool showCheck;

  /// Ícone opcional antes do texto (calendário, pagamentos…).
  final IconData? leading;

  /// Tooltip da pílula (acessibilidade/desktop).
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopupMenuButton<T>(
      onSelected: onSelected,
      tooltip: tooltip,
      position: PopupMenuPosition.under,
      constraints: const BoxConstraints(minWidth: 160),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[
              Icon(
                leading,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        for (final option in options)
          PopupMenuItem<T>(
            value: option.value,
            height: 44,
            child: Row(
              children: [
                if (showCheck) ...[
                  Icon(
                    option.checked
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    size: 16,
                    color: option.checked
                        ? theme.accent
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10),
                ],
                Flexible(
                  child: Text(
                    option.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Opção de [AppMenuOption].
class AppMenuOptionItem<T> {
  const AppMenuOptionItem({
    required this.value,
    required this.label,
    this.checked = false,
  });

  final T value;
  final String label;
  final bool checked;
}
