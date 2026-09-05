import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import 'app_card.dart';
import 'smart_amount.dart';

/// Card de indicador (KPI) V4 — ícone em badge + valor + rótulo.
class KpiCard extends StatelessWidget {
 const KpiCard({
 super.key,
 required this.label,
 this.value,
 this.amountCents,
 required this.icon,
 this.iconBackground,
 this.iconColor,
 this.caption,
 this.valueColor,
 this.loading = false,
 this.borderRadius,
 }) : assert(
 value != null || amountCents != null,
 'KpiCard requer value ou amountCents',
 );

 final String label;
 final String? value;
 final int? amountCents;
 final IconData icon;
 final Color? iconBackground;
 final Color? iconColor;
 final Color? valueColor;
 final String? caption;
 final bool loading;

 /// Cantos do card — telas premium passam raios maiores (ex.: 18).
 final BorderRadius? borderRadius;

 @override
 Widget build(BuildContext context) {
 final theme = Theme.of(context);
 final background = iconBackground ?? theme.accent.withValues(alpha: 0.1);
 final foreground = iconColor ?? theme.accent;

 return AppCard(
 borderRadius: borderRadius ?? const BorderRadius.all(Radius.circular(AppRadius.md)),
 child: Column(
 mainAxisSize: MainAxisSize.min,
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Container(
 width: AppSizes.avatarMd,
 height: AppSizes.avatarMd,
 alignment: Alignment.center,
 decoration: BoxDecoration(
 color: background,
 borderRadius: AppRadius.mdAll,
 border: Border.all(
 color: foreground.withValues(alpha: 0.4),
 ),
 ),
 child: Icon(icon, size: 20, color: foreground),
 ),
 const SizedBox(height: AppSpacing.md),
 _Value(
 loading: loading,
 value: value,
 amountCents: amountCents,
 color: valueColor,
 ),
 const SizedBox(height: AppSpacing.xxs),  Text(
   label,
   maxLines: 2,
   overflow: TextOverflow.ellipsis,
   // Rótulo do indicador ligeiramente menor que a nota padrão (13 → 12)
   // para o rótulo não competir com o valor do card (pedido de UI).
   style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
  ),
 if (caption != null) ...[
 const SizedBox(height: AppSpacing.xs),
 Text(
 caption!,
 maxLines: 2,
 overflow: TextOverflow.ellipsis,
 style: theme.textTheme.labelSmall,
 ),
 ],
 ],
 ),
 );
 }
}

class _Value extends StatelessWidget {
 const _Value({
 required this.loading,
 required this.value,
 required this.amountCents,
 this.color,
 });

 final bool loading;
 final String? value;
 final int? amountCents;
 final Color? color;

 @override
 Widget build(BuildContext context) {
 final theme = Theme.of(context);
 final style = theme.textTheme.headlineSmall?.copyWith(color: color);

 if (loading) {
 return FittedBox(
 fit: BoxFit.scaleDown,
 alignment: Alignment.centerLeft,
 child: Text('—', maxLines: 1, style: style),
 );
 }
 if (amountCents != null) {
 return SmartAmount(cents: amountCents!, style: style);
 }
 return FittedBox(
 fit: BoxFit.scaleDown,
 alignment: Alignment.centerLeft,
 child: Text(value ?? '', maxLines: 1, style: style),
 );
 }
}
