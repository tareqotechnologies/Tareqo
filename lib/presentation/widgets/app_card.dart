import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import 'focus_ring.dart';

/// Card padrão V4 — superfície elevada, borda sutil, ripple opcional.
class AppCard extends StatefulWidget {
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
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final border = scheme.outlineVariant;
    final bg =
        widget.color ??
        (widget.elevated ? scheme.surfaceContainerHighest : scheme.surface);

    // A11y (plano UI/UX — Fase 3.3): teclado físico/Bluetooth (scanner +
    // teclado nas lojas) precisa de foco VISÍVEL — o fill sutil do InkWell
    // não basta. O anel de 2px primário só existe com [onTap] (card
    // clicável) e pinta POR CIMA dentro dos limites (não soma layout).
    final ring = widget.onTap != null;

    return Material(
      color: bg,
      elevation: widget.elevated ? 1 : 0,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: widget.borderRadius,
        side: BorderSide(color: widget.borderColor ?? border, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          InkWell(
            onTap: widget.onTap,
            onFocusChange: ring ? (f) => setState(() => _focused = f) : null,
            child: Padding(padding: widget.padding, child: widget.child),
          ),
          if (ring)
            FocusRing(visible: _focused, borderRadius: widget.borderRadius),
        ],
      ),
    );
  }
}
