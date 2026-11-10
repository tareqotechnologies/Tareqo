import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// Skeleton loading — envolve o conteúdo (blocos do mesmo shape dos
/// elementos reais) com um pulso suave de opacidade. Sem shimmer, evitando
/// dependência nova. Respeita "reduzir movimento" (acessibilidade).
class Skeleton extends StatefulWidget {
  const Skeleton({super.key, required this.child});

  final Widget child;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return FadeTransition(
      opacity: Tween<double>(
        begin: 0.45,
        end: 1,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: widget.child,
    );
  }
}

/// Bloco de skeleton — retângulo arredondado num véu neutro de tinta
/// (`onSurface` com baixa opacidade), visível sobre o canvas nos dois temas.
class SkeletonBlock extends StatelessWidget {
  const SkeletonBlock({
    super.key,
    required this.height,
    this.width,
    this.radius = AppRadius.md,
  });

  final double height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // O fundo da app já é `canvas`/`surfaceContainerHighest` nos dois temas:
    // usar essa cor tornaria o bloco invisível. O véu de tinta é o único
    // neutro da paleta que contrasta com o fundo em light e dark.
    final veil = theme.brightness == Brightness.dark ? 0.10 : 0.06;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: veil),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
