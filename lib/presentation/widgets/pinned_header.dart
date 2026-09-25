import 'package:flutter/material.dart';
import '../../../core/theme/app_tokens.dart';

/// Barra FIXA no topo de uma lista (`SliverPersistentHeader` `pinned`): o
/// restante do conteúdo rola por baixo enquanto a barra permanece visível.
/// Usada por Vendas e Compras (busca + chips de filtro).
///
/// A altura é medida em runtime — o [child] pode quebrar linha (chips de
/// filtro) em telas estreitas / escala de texto alta, então o extent não
/// pode ser fixo. A medição acontece no primeiro frame (a aba já nasce
/// montada no IndexedStack, fora da tela) e a cada mudança de [MediaQuery]
/// (escala de texto, orientação, redimensionamento web) — o usuário nunca
/// vê o frame intermediário.
class PinnedHeader extends StatefulWidget {
  const PinnedHeader({super.key, required this.child});

  /// Conteúdo da barra (ex.: busca + filtros). O espaçamento vertical
  /// interno desejado deve vir no [child]; o padding lateral (20) é
  /// aplicado aqui, igual nas duas telas.
  final Widget child;

  @override
  State<PinnedHeader> createState() => _PinnedHeaderState();
}

class _PinnedHeaderState extends State<PinnedHeader> {
  /// Chave no conteúdo REAL da barra: mede a altura natural, que vira o
  /// extent do header. Fica dentro de um `UnconstrainedBox` (ver delegate)
  /// para ser disposta à altura natural mesmo quando o extent ainda é 0 no
  /// primeiro frame — evita o ciclo extent→layout→extent.
  final GlobalKey _contentKey = GlobalKey();
  double _extent = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscrição explícita a MediaQuery: mudanças de escala de texto,
    // orientação ou redimensionamento (web) alteram a altura do conteúdo
    // (os chips quebram linha) — registra a dependência para que este
    // método dispare e a altura seja re-medida.
    MediaQuery.maybeOf(context);
    _scheduleMeasure();
  }

  @override
  void didUpdateWidget(covariant PinnedHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleMeasure();
  }

  void _scheduleMeasure() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  void _measure() {
    if (!mounted) return;
    final render = _contentKey.currentContext?.findRenderObject();
    if (render is RenderBox && render.hasSize) {
      final height = render.size.height;
      if (height != _extent) {
        setState(() => _extent = height);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _PinnedHeaderDelegate(
        extent: _extent,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        child: Padding(
          key: _contentKey,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xxs,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Delegate do header fixo (sem colapso: `minExtent == maxExtent`).
///
/// O conteúdo é disposto por um [UnconstrainedBox] para que a medição veja a
/// altura NATURAL (mesmo com extent 0 no primeiro frame); a largura é travada
/// na do viewport. Uma divisória sutil aparece quando a lista rola por baixo
/// (`overlapsContent`).
class _PinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  _PinnedHeaderDelegate({
    required this.extent,
    required this.backgroundColor,
    required this.child,
  });

  final double extent;
  final Color backgroundColor;
  final Widget child;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final divider = Theme.of(context).dividerColor;
    return LayoutBuilder(
      builder: (context, constraints) {
        return ColoredBox(
          color: backgroundColor,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: UnconstrainedBox(
                  alignment: Alignment.topCenter,
                  child: SizedBox(width: constraints.maxWidth, child: child),
                ),
              ),
              // Divisória sutil quando a lista passa por baixo da barra.
              if (overlapsContent)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(height: 1, color: divider),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedHeaderDelegate oldDelegate) =>
      oldDelegate.extent != extent ||
      oldDelegate.backgroundColor != backgroundColor ||
      oldDelegate.child != child;
}
