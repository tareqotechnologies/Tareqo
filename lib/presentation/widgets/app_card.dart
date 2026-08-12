import 'package:flutter/material.dart';

/// Card padrão do design system ultra-clean: fundo `#161D22`, borda externa
/// de 0.5px em `#222E35`, cantos de 12px e SEM sombras (flat — o
/// [CardTheme] global já carrega shape/cores; este componente padroniza o
/// uso: padding consistente e `onTap` com ripple dentro do card).
///
/// [borderColor] sobrepõe a cor da borda — útil para estados de hover
/// (web/desktop) ou seleção, mantendo a espessura e o raio do design system.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.borderColor,
    this.color,
    required this.child,
  });

  /// Espaçamento interno padrão do card (16 em todos os lados).
  final EdgeInsetsGeometry padding;

  /// Opcional: transforma o card em botão (InkWell com ripple).
  final VoidCallback? onTap;

  /// Opcional: cor da borda (0.5px) — hover/seleção. `null` usa a borda
  /// padrão do tema (`#222E35` no escuro).
  final Color? borderColor;

  /// Opcional: cor do fundo — estados especiais (ex.: produto esgotado no
  /// carrinho). `null` usa a superfície padrão do tema.
  final Color? color;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = theme.colorScheme.outlineVariant;
    final radius = theme.cardTheme.shape is RoundedRectangleBorder
        ? (theme.cardTheme.shape as RoundedRectangleBorder).borderRadius
        : BorderRadius.circular(12);
    return Card(
      color: color,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: borderColor ?? border, width: 0.5),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
