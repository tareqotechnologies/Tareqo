import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Borda TRACEJADA circular — mesma geometria do traço do cupom térmico
/// (recibo), reaproveitada como linguagem visual única do design system:
/// no recibo separa blocos de texto; nos ícones marca valores que fogem do
/// padrão (ajuste manual, diferença de troco no fiado).
class DashedCirclePainter extends CustomPainter {
  const DashedCirclePainter({required this.color});

  final Color color;

  /// Desenha os tracejos a partir de um painter externo (uso em widgets
  /// que já têm um [CustomPaint] dedicado e não precisam de um objeto).
  static void paintDashes(
    Canvas canvas,
    Size size, {
    required Color color,
    double strokeWidth = DashedBorders.strokeWidth,
  }) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - DashedBorders.inset;
    final dashCount = DashedBorders.dashCount;
    final totalAngle = 2 * 3.141592653589793;
    final dashAngle = totalAngle / dashCount;
    for (var i = 0; i < dashCount; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * dashAngle,
        dashAngle * DashedBorders.dashFraction,
        false,
        paint,
      );
    }
  }

  @override
  void paint(Canvas canvas, Size size) => paintDashes(
    canvas,
    size,
    color: color,
    strokeWidth: DashedBorders.strokeWidth,
  );

  @override
  bool shouldRepaint(covariant DashedCirclePainter oldDelegate) =>
      oldDelegate.color != color;
}
