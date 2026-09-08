import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// Card padrão V4 — superfície elevada, borda sutil, ripple opcional.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.onTap,
    this.borderColor,
    this.color,
    this.elevated = false,
    this.borderRadius = const BorderRadius.all(Radius.circular(AppRadius.md)),
    required this.child,
  });

  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? borderColor;
  final Color? color;
  final bool elevated;

  /// Cantos do card — telas "premium" passam raios maiores (ex.: 20) para
  /// o visual Apple; o default segue o design system (12).
  final BorderRadius borderRadius;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final border = scheme.outlineVariant;
    final bg =
        color ?? (elevated ? scheme.surfaceContainerHighest : scheme.surface);

    return Material(
      color: bg,
      elevation: elevated ? 1 : 0,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: BorderSide(color: borderColor ?? border, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
