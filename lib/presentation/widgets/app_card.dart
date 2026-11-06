import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import 'focus_ring.dart';
import 'premium_decor.dart';

/// Card padrão V4 (acabamento premium) — superfície com borda de cabelo,
/// sombra neutra em camadas, ripple opcional e microinteração de toque.
///
/// * Repouso: [PremiumDecor.softShadow] (contacto + ambiente).
/// * Hover (desktop/web) em card clicável: sobe para
///   [PremiumDecor.liftShadow].
/// * Press em card clicável: escala 0.985 (respeita
///   `MediaQuery.disableAnimationsOf`).
/// * Cards com fundo translúcido (ex.: `Colors.transparent`) não projectam
///   sombra — a sombra apareceria através da superfície.
class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.onTap,
    this.borderColor,
    this.color,
    this.gradient,
    this.elevated = false,
    this.borderRadius = const BorderRadius.all(Radius.circular(AppRadius.md)),
    required this.child,
  });

  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? borderColor;
  final Color? color;

  /// Fundo em gradiente (heroes). Quando presente, substitui [color].
  final Gradient? gradient;

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
  bool _hovered = false;
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final border = widget.borderColor ?? PremiumDecor.hairline(scheme);
    final bg =
        widget.color ??
        (widget.elevated ? scheme.surfaceContainerHighest : scheme.surface);

    // A11y (plano UI/UX — Fase 3.3): teclado físico/Bluetooth (scanner +
    // teclado nas lojas) precisa de foco VISÍVEL — o fill sutil do InkWell
    // não basta. O anel de 2px primário só existe com [onTap] (card
    // clicável) e pinta POR CIMA dentro dos limites (não soma layout).
    final interactive = widget.onTap != null;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final opaque = widget.gradient != null || bg.a >= 1.0;
    final List<BoxShadow>? shadows = !opaque
        ? null
        : (interactive && _hovered) || widget.elevated
        ? PremiumDecor.liftShadow(scheme)
        : PremiumDecor.softShadow(scheme);

    Widget card = AnimatedContainer(
      duration: AppDurations.fast,
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius,
        gradient: widget.gradient,
        color: widget.gradient == null ? null : bg,
        boxShadow: shadows,
      ),
      child: Material(
        color: widget.gradient != null ? Colors.transparent : bg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: widget.borderRadius,
          side: BorderSide(color: border, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            InkWell(
              onTap: widget.onTap,
              onFocusChange: interactive
                  ? (f) => setState(() => _focused = f)
                  : null,
              onHover: interactive ? (h) => setState(() => _hovered = h) : null,
              onHighlightChanged: interactive && !reduceMotion
                  ? _setPressed
                  : null,
              child: Padding(padding: widget.padding, child: widget.child),
            ),
            if (interactive)
              FocusRing(visible: _focused, borderRadius: widget.borderRadius),
          ],
        ),
      ),
    );

    if (interactive && !reduceMotion) {
      card = AnimatedScale(
        scale: _pressed ? 0.985 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: card,
      );
    }
    return card;
  }
}
