import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';

/// Layout padrão de página — AppBar opcional, padding responsivo e
/// suporte a FAB/RefreshIndicator via [body].
class AppPage extends StatelessWidget {
 const AppPage({
 super.key,
 this.title,
 this.actions,
 this.leading,
 this.floatingActionButton,
 this.bottom,
 this.padding,
 this.useSafeArea = true,
 required this.body,
 });

 final String? title;
 final List<Widget>? actions;
 final Widget? leading;
 final Widget? floatingActionButton;
 final PreferredSizeWidget? bottom;
 final EdgeInsetsGeometry? padding;
 final bool useSafeArea;
 final Widget body;

 @override
 Widget build(BuildContext context) {
 return Scaffold(
 appBar: title != null
 ? AppBar(
 title: Text(title!),
 actions: actions,
 leading: leading,
 bottom: bottom,
 )
 : null,
 floatingActionButton: floatingActionButton,
 body: useSafeArea
 ? SafeArea(
 child: Padding(
 padding: padding ?? EdgeInsets.zero,
 child: body,
 ),
 )
 : Padding(
 padding: padding ?? EdgeInsets.zero,
 child: body,
 ),
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
 final bg = backgroundColor ?? fg.withValues(alpha: 0.12);
 final radius = borderRadius ??
 const BorderRadius.all(Radius.circular(AppRadius.full));

 return Container(
 width: size,
 height: size,
 decoration: BoxDecoration(
 color: bg,
 borderRadius: radius,
 ),
 child: CustomPaint(
 painter: dashedBorder ? _DashedBorderPainter(color: fg) : null,
 child: Icon(icon, size: iconSize, color: fg),
 ),
 );
 }
}

class _DashedBorderPainter extends CustomPainter {
 const _DashedBorderPainter({required this.color});

 final Color color;

 @override
 void paint(Canvas canvas, Size size) {
 final paint = Paint()
 ..color = color
 ..style = PaintingStyle.stroke
 ..strokeWidth = 1.4;
 final center = size.center(Offset.zero);
 final radius = size.width / 2 - 2;
 const dashCount = 12;
 const totalAngle = 2 * 3.141592653589793;
 final dashAngle = totalAngle / dashCount;
 for (var i = 0; i < dashCount; i++) {
 canvas.drawArc(
 Rect.fromCircle(center: center, radius: radius),
 i * dashAngle,
 dashAngle * 0.55,
 false,
 paint,
 );
 }
 }

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
 padding: padding ??
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
 fontWeight: FontWeight.w500,
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
 const SizedBox(width: 6),
 ],
 Text(
 label,
 style: theme.textTheme.labelMedium?.copyWith(color: fg),
 ),
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
