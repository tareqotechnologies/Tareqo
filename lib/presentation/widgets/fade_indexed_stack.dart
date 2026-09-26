import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// Transição entre abas do shell (plano UI/UX — F4.4): **fade-through M3** —
/// o padrão Material/iOS para conteúdo NÃO-hierárquico. Em vez do fade puro
/// de entrada (o conteúdo novo "acendia" sobre o antigo), a troca tem duas
/// fases com direção:
///
/// 1. **fade out** (90ms) do conteúdo atual;
/// 2. troca do índice + **fade in** com slide de 24px (easeOutCubic).
///
/// O [IndexedStack] permanece: o estado de cada aba é preservado entre
/// trocas (scroll, campo de busca, carrinho do PDV aberto). Movimento
/// reduzido (`MediaQuery.disableAnimationsOf`): troca direta, sem animação.
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
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppDurations.normal, // fase de entrada (out = metade do ciclo)
    value: 1,
  );

  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  /// Índice EXIBIDO durante a fase de saída: continua o antigo (o fade out
  /// é do conteúdo que está a sair); troca junto com o fade in.
  int _displayed = 0;

  @override
  void initState() {
    super.initState();
    _displayed = widget.index;
  }

  @override
  void didUpdateWidget(FadeIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    // O controller nasce em 1 (opaco) — o primeiro build NÃO anima; aqui
    // só chegam mudanças reais de aba.
    if (oldWidget.index != widget.index) {
      _transitionTo(widget.index);
    }
  }

  Future<void> _transitionTo(int next) async {
    // Fase 1 — fade out rápido do conteúdo atual (90ms, easeIn).
    await _controller.animateTo(
      0,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeIn,
    );
    if (!mounted) return;
    setState(() => _displayed = next);
    // Fase 2 — fade in + slide de 24px do conteúdo novo (220ms, easeOut).
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Movimento reduzido (acessibilidade): a troca de aba é direta, sem
    // animação — mesmo conteúdo, mesmo estado preservado.
    if (MediaQuery.disableAnimationsOf(context)) {
      return IndexedStack(index: widget.index, children: widget.children);
    }
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 24 / 800), // ~24px lógicos de subida
          end: Offset.zero,
        ).animate(_curve),
        child: IndexedStack(index: _displayed, children: widget.children),
      ),
    );
  }
}
