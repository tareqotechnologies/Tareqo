import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';

/// Badge de contagem de notificações.
///
/// Exibe um círculo com contagem sobre o widget filho (normalmente um
/// ícone). O número já comunica a informação — o badge é ESTÁTICO por
/// padrão: animação em loop num ecrã consultado dezenas de vezes por dia
/// vira ruído (Fase 3: cada animação deve explicar uma mudança).
///
/// O pulso continua disponível como OPT-IN explícito via [showPulse]
/// (ex.: um momento pontual de "há algo novo") e respeita
/// `MediaQuery.disableAnimationsOf` (movimento reduzido).
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
    this.showPulse = false,
    this.pulseDuration = const Duration(seconds: 2),
    this.maxCount = 99,
  });

  /// Quantidade a exibir no badge (0 = sem badge).
  final int count;

  /// Widget filho (normalmente um ícone).
  final Widget child;

  /// Cor de fundo do badge. Se nulo, usa [ColorScheme.tertiary].
  final Color? color;

  /// Se deve animar o pulso — OPT-IN: o default é o badge estático,
  /// porque o pulso em loop não acrescenta informação à contagem e
  /// distrai no uso diário.
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

    // Movimento reduzido (acessibilidade, Fase 7): o pulso é uma animação
    // INFINITA — no pior caso rodaria para sempre com a preferência de
    // movimento reduzido ativa. O badge continua visível (a informação
    // importa; o movimento não) e a escala fica estável em 1.0.
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulseController.stop();
    } else if (widget.showPulse &&
        _pulseController.isAnimating == false &&
        _pulseController.isCompleted == false) {
      _pulseController.repeat(reverse: true);
    }

    final scheme = Theme.of(context).colorScheme;
    final badgeColor = widget.color ?? scheme.tertiary;
    // Rótulo legível sobre o fundo por omissão (tertiary); cor custom do
    // chamador mantém o branco original.
    final onBadgeColor = widget.color == null ? scheme.onTertiary : Colors.white;
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
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: 1,
              ),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                displayText,
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: onBadgeColor,
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
