import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// Badge animado com efeito de pulso para notificações.
///
/// Exibe um círculo com contagem que pulsa suavemente quando há
/// notificações novas. O pulso para automaticamente após некоторое
/// tempo para não ser distraínte.
///
/// Uso:
/// ```dart
/// PulseBadge(
///   count: 3,
///   child: Icon(Icons.notifications_outlined),
/// )
/// ```
class PulseBadge extends StatefulWidget {
  const PulseBadge({
    super.key,
    required this.count,
    required this.child,
    this.color,
    this.showPulse = true,
    this.pulseDuration = const Duration(seconds: 2),
    this.maxCount = 99,
  });

  /// Quantidade a exibir no badge (0 = sem badge).
  final int count;

  /// Widget filho (normalmente um ícone).
  final Widget child;

  /// Cor de fundo do badge. Se nulo, usa [ColorScheme.tertiary].
  final Color? color;

  /// Se deve animar o pulso.
  final bool showPulse;

  /// Duração de cada ciclo de pulso.
  final Duration pulseDuration;

  /// Contagem máxima exibida (ex.: 99 → "99+").
  final int maxCount;

  @override
  State<PulseBadge> createState() => _PulseBadgeState();
}

class _PulseBadgeState extends State<PulseBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: widget.pulseDuration,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.showPulse && widget.count > 0) {
      _startPulse();
    }
  }

  @override
  void didUpdateWidget(PulseBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.count > 0 && widget.showPulse) {
      _startPulse();
    } else {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  void _startPulse() {
    if (_pulseController.isAnimating) return;
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.count <= 0) return widget.child;

    final scheme = Theme.of(context).colorScheme;
    final badgeColor = widget.color ?? scheme.tertiary;
    final displayText = widget.count > widget.maxCount
        ? '${widget.maxCount}+'
        : '${widget.count}';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        Positioned(
          right: -2,
          top: -2,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: child,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(AppRadius.full),
                boxShadow: [
                  BoxShadow(
                    color: badgeColor.withValues(alpha: 0.4),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                displayText,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
