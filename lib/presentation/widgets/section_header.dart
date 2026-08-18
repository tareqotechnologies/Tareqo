import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// Cabeçalho de seção V4 — título + ação opcional à direita.
class SectionHeader extends StatelessWidget {
 const SectionHeader({
 super.key,
 required this.title,
 this.subtitle,
 this.actionLabel,
 this.onAction,
 });

 final String title;
 final String? subtitle;
 final String? actionLabel;
 final VoidCallback? onAction;

 @override
 Widget build(BuildContext context) {
 final theme = Theme.of(context);

 return Row(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 title,
 style: theme.textTheme.titleLarge?.copyWith(
 fontWeight: FontWeight.w700,
 letterSpacing: -0.3,
 ),
 ),
 if (subtitle != null) ...[
 const SizedBox(height: 2),
 Text(subtitle!, style: theme.textTheme.bodySmall),
 ],
 ],
 ),
 ),
 if (actionLabel != null && onAction != null)
 TextButton(
 onPressed: onAction,
 style: TextButton.styleFrom(
 visualDensity: VisualDensity.compact,
 padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
 ),
 child: Text(actionLabel!),
 ),
 ],
 );
 }
}
