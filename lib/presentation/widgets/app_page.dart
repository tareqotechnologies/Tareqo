import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/ui/dashed_circle_painter.dart';

/// Layout padrão de página — AppBar opcional, padding responsivo e
/// suporte a FAB/RefreshIndicator via [body].
class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    this.title,
    this.subtitle,
    this.badge,
    this.titleStyle,
    this.actions,
    this.leading,
    this.floatingActionButton,
    this.bottom,
    this.padding,
    this.backgroundColor,
    this.useSafeArea = true,
    required this.body,
  });

  /// Título do AppBar (escala do tema — `titleLarge` 22/w600).
  final String? title;

  /// Estilo do título do AppBar (default: `titleLarge`). Telas com
  /// rótulos longos (ex.: add-ons 'Factura Personalizada') usam
  /// `titleMedium` (20/w600) para não truncar em idiomas verbosos.
  final TextStyle? titleStyle;

  /// Subtítulo discreto abaixo do título (ex.: contagem de itens) —
  /// renderizado quando presente com o cabeçalho de duas linhas (altura 72)
  /// que as telas de módulo usavam inline.
  final String? subtitle;

  /// Contador exibido como pílula de erro ao lado do título (ex.: não
  /// lidas). Só se aplica ao título de linha única (sem [subtitle]).
  final int? badge;

  final List<Widget>? actions;
  final Widget? leading;
  final Widget? floatingActionButton;
  final PreferredSizeWidget? bottom;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final bool useSafeArea;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: title != null
          ? AppBar(
              toolbarHeight: subtitle != null ? 72 : null,
              title: _titleContent(theme, scheme),
              actions: actions,
              leading: leading,
              bottom: bottom,
            )
          : null,
      floatingActionButton: floatingActionButton,
      body: useSafeArea
          ? SafeArea(
              child: Padding(padding: padding ?? EdgeInsets.zero, child: body),
            )
          : Padding(padding: padding ?? EdgeInsets.zero, child: body),
    );
  }

  /// Conteúdo do título: texto simples, texto + badge ou coluna com
  /// subtítulo — nunca combinado com [badge] (linha única apenas).
  Widget _titleContent(ThemeData theme, ColorScheme scheme) {
    final Widget titleWidget = Text(
      title!,
      style: titleStyle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    if (subtitle != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          titleWidget,
          Text(
            subtitle!,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }
    if (badge == null || badge == 0) return titleWidget;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        titleWidget,
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
          decoration: BoxDecoration(
            color: scheme.error,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Text(
            '$badge',
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onError,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  /// Padding horizontal padrão para conteúdo scrollável.
  static EdgeInsets horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return EdgeInsets.symmetric(
      horizontal: AppSpacing.pagePaddingForWidth(width),
    );
  }
}

/// Container de ícone com fundo tingido — padrão V4 para listas e cards.
class AppIconBadge extends StatelessWidget {
  const AppIconBadge({
    super.key,
    required this.icon,
    this.color,
    this.backgroundColor,
    this.size = AppSizes.avatarSm,
    this.iconSize = AppSizes.iconSm,
    this.borderRadius,
    this.dashedBorder = false,
  });

  final IconData icon;
  final Color? color;
  final Color? backgroundColor;
  final double size;
  final double iconSize;
  final BorderRadius? borderRadius;
  final bool dashedBorder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = color ?? theme.accent;
    final bg = backgroundColor ?? IconTone.darkBackground(fg);
    final iconFg = IconTone.lightForeground(fg);
    final radius =
        borderRadius ?? const BorderRadius.all(Radius.circular(AppRadius.full));

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, borderRadius: radius),
      child: CustomPaint(
        painter: dashedBorder ? _DashedBorderPainter(color: fg) : null,
        child: Icon(icon, size: iconSize, color: iconFg),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) => DashedCirclePainter.paintDashes(
    canvas,
    size,
    color: color,
    strokeWidth: DashedBorders.strokeWidth,
  );

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Linha de lista reutilizável — ícone + título/subtítulo + trailing.
class AppListTile extends StatelessWidget {
  const AppListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.padding,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final content = Padding(
      padding:
          padding ??
          const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.xs),
            trailing!,
          ],
        ],
      ),
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mdAll,
        child: content,
      ),
    );
  }
}

/// Pílula de filtro/seleção reutilizável.
class AppPill extends StatelessWidget {
  const AppPill({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.selected = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bg = selected ? scheme.primaryContainer : scheme.surface;
    final fg = selected ? scheme.onPrimaryContainer : scheme.onSurface;
    final border = selected
        ? scheme.primary.withValues(alpha: 0.4)
        : scheme.outlineVariant;

    final child = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 14,
              color: selected ? theme.accent : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
          ],
          Text(label, style: theme.textTheme.labelMedium?.copyWith(color: fg)),
          if (onTap != null) ...[
            const SizedBox(width: 2),
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return child;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: child,
    );
  }
}

/// Feedback de hover único para tiles/listas — o mesmo em todo o app.
///
/// Em telas de toque não faz nada (hover não existe); em desktop/web
/// escurece a superfície do tile quando o cursor passa por cima.
/// [enabled] = false desativa (ex.: tile sem ação).
class HoverableTile extends StatefulWidget {
  const HoverableTile({super.key, required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  @override
  State<HoverableTile> createState() => _HoverableTileState();
}

class _HoverableTileState extends State<HoverableTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        type: MaterialType.transparency,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          decoration: BoxDecoration(
            color: _hovered
                ? Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
                : null,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
