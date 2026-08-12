import 'package:flutter/material.dart';

/// Botão padrão do design system ultra-clean: altura 48, cantos 12, cores
/// SÓLIDAS e texto `w400` (herdado do tema — o [FilledButtonTheme] global
/// já aplica 48/12/w400; este componente padroniza as variantes).
///
/// - [AppButton.primary] — FilledButton no acento (ação principal);
/// - [AppButton.secondary] — OutlinedButton na superfície (ação neutra);
/// - [AppButton.danger] — FilledButton em vermelho sóbrio (ação destrutiva
///   de confirmação — ex.: anular venda no diálogo).
///
/// Um [style] opcional permite sobrepor cores/estados específicos (ex.:
/// botão secundário em laranja) sem abrir mão das medidas do design system
/// (altura 48, cantos 12, w400 — herdados dos temas globais).
class AppButton extends StatelessWidget {
  const AppButton.primary({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.style,
  }) : _variant = _AppButtonVariant.primary;

  const AppButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.style,
  }) : _variant = _AppButtonVariant.secondary;

  const AppButton.danger({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.style,
  }) : _variant = _AppButtonVariant.danger;

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;

  /// Sobreposição de estilo — merge sobre o estilo da variante/tema.
  final ButtonStyle? style;
  final _AppButtonVariant _variant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final Widget content;
    if (icon != null) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [icon!, const SizedBox(width: 8), Text(label)],
      );
    } else {
      content = Text(label);
    }

    return switch (_variant) {
      _AppButtonVariant.primary => FilledButton(
          onPressed: onPressed,
          style: style,
          child: content,
        ),
      _AppButtonVariant.secondary => OutlinedButton(
          onPressed: onPressed,
          style: style,
          child: content,
        ),
      _AppButtonVariant.danger => FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ).merge(style),
          child: content,
        ),
    };
  }
}

enum _AppButtonVariant { primary, secondary, danger }
