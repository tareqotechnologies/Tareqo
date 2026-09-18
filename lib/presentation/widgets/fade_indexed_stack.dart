import 'package:flutter/material.dart';

/// [IndexedStack] com transição suave (fade-through) ao trocar de aba.
///
/// A navegação híbrida (Fase 3) mantém as seções num [IndexedStack] para
/// preservar o estado de cada aba (busca, scroll, formulários abertos).
/// Este wrapper adiciona um fade curto (220ms, easeOut) sempre que o
/// [index] muda — a transição é APENAS visual: os filhos continuam
/// montados e o estado nunca é perdido (a troca de aba não desmonta nada).
class FadeIndexedStack extends StatefulWidget {
  const FadeIndexedStack({
    super.key,
    required this.index,
    required this.children,
  });

  final int index;
  final List<Widget> children;

  @override
  State<FadeIndexedStack> createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<FadeIndexedStack>
    with SingleTickerProviderStateMixin {
  // Opaco no primeiro build — o fade só roda em trocas subsequentes.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    value: 1,
  );

  @override
  void didUpdateWidget(FadeIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      // Reinicia o fade a cada troca de aba (rapidamente re-tapadas também
      // só reexecutam a animação — nunca deixam o conteúdo invisível).
      // `forward(from: 0)` já reinicia do início (o stop é redundante).
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Movimento reduzido (acessibilidade, Fase 7): a troca de aba é direta,
    // sem fade — mesmo conteúdo, mesmo estado preservado.
    if (MediaQuery.disableAnimationsOf(context)) {
      return IndexedStack(index: widget.index, children: widget.children);
    }
    return FadeTransition(
      opacity: CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      child: IndexedStack(index: widget.index, children: widget.children),
    );
  }
}
