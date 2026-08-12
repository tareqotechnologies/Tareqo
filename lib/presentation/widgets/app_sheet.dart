import 'package:flutter/material.dart';

import '../../core/i18n/l10n_ext.dart';

/// Abre uma modal bottom sheet com a identidade visual do app:
/// cantos superiores grandes e arredondados, sem sombra pesada, e
/// padding automático para o teclado.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isDismissible = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: isDismissible,
    backgroundColor: Colors.transparent,
    builder: (context) => SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: builder(context),
      ),
    ),
  );
}

/// Cabeçalho padrão das sheets: título + botão de fechar.
class AppSheetHeader extends StatelessWidget {
  const AppSheetHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 12, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: theme.textTheme.titleLarge),
          ),
          // Botão de fechar CIRCULAR (design system 2026): fundo escuro com
          // o X em verde — igual ao app de referência.
          IconButton(
            tooltip: context.l10n.appSheetClose,
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              foregroundColor: theme.colorScheme.primary,
            ),
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
