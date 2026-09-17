import 'package:flutter/material.dart';

/// Ponte mínima entre os widgets de dialog do design system e a
/// tipografia **Thin** do painel do super admin.
///
/// Os dialogs/sheets do painel são abertos por rotas modais
/// (`showDialog`/`showModalBottomSheet`), que NÃO herdam o [Theme] local
/// aplicado pelo `AdminThin` no shell — o builder recebe o tema raiz.
/// Estes helpers permitem que qualquer diálogo do app adote o padrão thin
/// sem acoplar `widgets/` às telas de admin (evita import circular):
/// o estilo vive aqui como função pura sobre o [ThemeData] recebido.
///
/// `AdminThin` (telas) continua sendo a fonte da verdade da escala; os
/// valores abaixo espelham os pesos usados lá (títulos w300, corpo w400).

/// Envolve [child] no tema thin quando [thinStyle] — caso contrário
/// devolve o child intacto.
Widget adminThinIfNeeded(
  BuildContext context, {
  required bool thinStyle,
  required Widget child,
}) {
  if (!thinStyle) return child;
  return Theme(
    data: adminThinTheme(Theme.of(context)),
    child: child,
  );
}

/// ThemeData derivado com a escala thin (espelha `AdminThin`).
ThemeData adminThinTheme(ThemeData theme) {
  TextStyle fn(TextStyle? style, {FontWeight? weight}) {
    if (style == null) return const TextStyle();
    return style.copyWith(fontWeight: weight ?? FontWeight.w400);
  }

  final base = theme.textTheme;
  return theme.copyWith(
    textTheme: base.copyWith(
      titleLarge: fn(base.titleLarge, weight: FontWeight.w300),
      titleMedium: fn(base.titleMedium, weight: FontWeight.w300),
      titleSmall: fn(base.titleSmall, weight: FontWeight.w400),
      labelLarge: fn(base.labelLarge, weight: FontWeight.w400),
      labelMedium: fn(base.labelMedium, weight: FontWeight.w400),
    ),
    // Título do AlertDialog: 19/w300 — hierarquia por tamanho, sem peso.
    dialogTheme: theme.dialogTheme.copyWith(
      titleTextStyle: TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w300,
        letterSpacing: -0.2,
        height: 1.25,
        color: theme.colorScheme.onSurface,
      ),
    ),
    inputDecorationTheme: theme.inputDecorationTheme.copyWith(
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      floatingLabelStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    ),
  );
}

/// Estilo explícito do título do dialog — usado quando o caller quer
/// aplicar o peso thin mesmo sem envolver a subtree (respeita o tema
/// raiz quando `thinStyle` é falso).
TextStyle? adminDialogTitleStyle(BuildContext context, {bool thinStyle = false}) {
  final theme = Theme.of(context);
  if (!thinStyle) return null; // null = usa o dialogTheme global (22/w600).
  return TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w300,
    letterSpacing: -0.2,
    height: 1.25,
    color: theme.colorScheme.onSurface,
  );
}
