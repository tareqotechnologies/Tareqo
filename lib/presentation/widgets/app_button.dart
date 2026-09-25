import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// Botão padrão V4 — variantes primary, secondary e danger.
class AppButton extends StatelessWidget {
  const AppButton.primary({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.style,
    this.expanded = false,
  }) : _variant = _AppButtonVariant.primary;

  const AppButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.style,
    this.expanded = false,
  }) : _variant = _AppButtonVariant.secondary;

  const AppButton.danger({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.style,
    this.expanded = false,
  }) : _variant = _AppButtonVariant.danger;

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final ButtonStyle? style;
  final bool expanded;
  final _AppButtonVariant _variant;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final Widget content;
    if (icon != null) {
      // Flexible no rótulo: numa Row, filho sem flex recebe largura
      // ilimitada no eixo principal e estoura com texto longo (fr a 360dp
      // ou escala de texto 2.0). Com Flexible o rótulo quebra em 2 linhas
      // em vez de vazar do botão.
      content = Row(
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon!,
          const SizedBox(width: AppSpacing.xs),
          Flexible(child: Text(label, textAlign: TextAlign.center)),
        ],
      );
    } else {
      content = Text(label);
    }

    final button = switch (_variant) {
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

    if (!expanded) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}

enum _AppButtonVariant { primary, secondary, danger }
