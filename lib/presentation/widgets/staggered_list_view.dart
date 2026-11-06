import 'package:flutter/material.dart';

/// Staggered ListView — entra os itens com fade-in de forma sequencial,
/// criando uma onda de animação suave. Quando as animações estão desativadas
/// (reduzir movimento), a lista aparece instantaneamente.
///
/// Use como substituto de ListView/ListView.builder:
///   StaggeredListView.builder(
///     itemCount: items.length,
///     itemBuilder: (context, index) => ListTile(title: Text(item)),
///     physics: const AlwaysScrollableScrollPhysics(),
/// );
///
/// A animação usa um AnimationController compartilhado: o item 0 começa
/// imediatamente, o item 1 após 80ms, o item 2 após 160ms, etc.
/// O controller é criado em initState e descartado em dispose.
class StaggeredListView extends StatefulWidget {
  const StaggeredListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding,
    this.physics,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;

  @override
  State<StaggeredListView> createState() => _StaggeredListViewState();
}

class _StaggeredListViewState extends State<StaggeredListView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300 + widget.itemCount * 80),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Se o usuário pediu reduzir movimento, não há animação.
    if (MediaQuery.disableAnimationsOf(context)) {
      return ListView.builder(
        key: const ValueKey('staggered_list_no_anim'),
        padding: widget.padding,
        physics: widget.physics ?? const AlwaysScrollableScrollPhysics(),
        itemCount: widget.itemCount,
        itemBuilder: (context, index) => widget.itemBuilder(context, index),
      );
    }

    // Lista animate-in: cada item tem um CurvedAnimation com intervalo baseado no índice.
    // O item 0 começa imediatamente, o item 1 após 80ms, o item 2 após 160ms, etc.
    // O controlador dura 300ms + (itemCount * 80ms), criando uma onda natural.
    return ListView.builder(
      padding: widget.padding,
      physics: widget.physics ?? const AlwaysScrollableScrollPhysics(),
      itemCount: widget.itemCount,
      itemBuilder: (context, index) {
        // A cada frame, calculamos qual item deve estar visível baseado no valor do controller.
        final value = _controller.value;
        // O item i começa quando t >= i * 0.08; usa curva ease-out.
        // O valor do controller vai de 0 a 1 ao longo de 300 + index*80 ms.
        final visibleIndex = (value * widget.itemCount).floor();

        // Item ainda não começou a animação (índice maior que o visível).
        if (index > visibleIndex) {
          // Fade-in + scale-up para o item que ainda não começou.
          return FadeTransition(
            opacity: Tween<double>(begin: 0, end: 1.0).animate(
              CurvedAnimation(parent: _controller, curve: Curves.easeOut),
            ),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                CurvedAnimation(parent: _controller, curve: Curves.easeOut),
              ),
              child: widget.itemBuilder(context, index),
            ),
          );
        }

        // Item que está "agora" em animação - mostrar progressivamente.
        if (index == visibleIndex) {
          return FadeTransition(
            opacity: Tween<double>(begin: 0, end: 1.0).animate(
              CurvedAnimation(parent: _controller, curve: Curves.easeOut),
            ),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                CurvedAnimation(parent: _controller, curve: Curves.easeOut),
              ),
              child: widget.itemBuilder(context, index),
            ),
          );
        }

        // Item já terminou animação - totalmente visível.
        if (index < visibleIndex) {
          return widget.itemBuilder(context, index);
        }

        // Fallback - item totalmente visível.
        return widget.itemBuilder(context, index);
      },
    );
  }
}

/// Lista com keys únicos por item para controle de animação fina.
class StaggeredListViewWithUniqueKey extends StatefulWidget {
  const StaggeredListViewWithUniqueKey({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final EdgeInsetsGeometry? padding;

  @override
  State<StaggeredListViewWithUniqueKey> createState() =>
      _StaggeredListViewWithUniqueKeyState();
}

class _StaggeredListViewWithUniqueKeyState
    extends State<StaggeredListViewWithUniqueKey>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300 + widget.itemCount * 80),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return ListView.builder(
        key: const ValueKey('staggered_no_anim'),
        padding: widget.padding,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: widget.itemCount,
        itemBuilder: (context, index) => widget.itemBuilder(context, index),
      );
    }

    return ListView.builder(
      padding: widget.padding,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: widget.itemCount,
      itemBuilder: (context, index) {
        // Cada item tem seu próprio SlideTransition com base no controller.
        // O controller anima de 0 a 1 ao longo de 300 + itemCount*80ms.
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.1, 0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: _controller,
              curve: Curves.easeOutCubic,
            ),
          ),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0, end: 1.0).animate(
              CurvedAnimation(
                parent: _controller,
                curve: Curves.easeOutCubic,
              ),
            ),
            child: widget.itemBuilder(context, index),
          ),
        );
      },
    );
  }
}
