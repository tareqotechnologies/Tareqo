import 'package:flutter/material.dart';

/// Anel de foco visível (plano UI/UX — Fase 3.3): borda primária de 2px no
/// widget focado por teclado físico/Bluetooth — lojas operam com scanner +
/// teclado, e o highlight padrão do [InkWell] (fill sutil) não é perceptível
/// o suficiente para navegação por Tab.
///
/// USO: colocado como filho DIRETO de um [Stack] que envolve o conteúdo
/// clicável (o [Positioned.fill] precisa do Stack como pai):
///
/// ```dart
/// Stack(children: [
///   InkWell(onFocusChange: ..., child: ...),
///   FocusRing(visible: _focused, borderRadius: ...),
/// ])
/// ```
///
/// Pinta POR CIMA do conteúdo ([IgnorePointer] — nunca rouba o toque) e
/// DENTRO dos limites do card (sem somar 2px de layout — borda interna,
/// o card não "cresce" ao receber foco). Some quando o foco sai.
class FocusRing extends StatelessWidget {
  const FocusRing({
    super.key,
    required this.visible,
    this.borderRadius,
    this.width = 2,
  });

  final bool visible;
  final BorderRadius? borderRadius;
  final double width;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            border: Border.fromBorderSide(
              BorderSide(color: scheme.primary, width: width),
            ),
          ),
        ),
      ),
    );
  }
}
