import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import 'app_card.dart';

/// Card de módulo V4 — ícone em badge + rótulo (até 2 linhas).
class ModuleCard extends StatelessWidget {
 const ModuleCard({
 super.key,
 required this.icon,
 required this.label,
 required this.onTap,
 this.width = 152,
 });

 final IconData icon;
 final String label;
 final VoidCallback onTap;
 final double width;

 @override
 Widget build(BuildContext context) {
 final theme = Theme.of(context);
 final scheme = theme.colorScheme;

 return SizedBox(
 width: width,
 child: AppCard(
 onTap: onTap,
 elevated: true,
 borderRadius: const BorderRadius.all(Radius.circular(18)),
 padding: const EdgeInsets.all(AppSpacing.md),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Container(
 width: AppSizes.avatarMd,
 height: AppSizes.avatarMd,
 alignment: Alignment.center,
 decoration: BoxDecoration(
 color: theme.accent.withValues(alpha: 0.12),
 borderRadius: AppRadius.mdAll,
 border: Border.all(
 color: theme.accent.withValues(alpha: 0.35),
 ),
 ),
 child: Icon(icon, size: 20, color: theme.accent),
 ),
 const SizedBox(height: AppSpacing.sm),
 Text(
 label,
 maxLines: 2,
 overflow: TextOverflow.ellipsis,
 style: theme.textTheme.labelLarge?.copyWith(
 color: scheme.onSurface,
 fontWeight: FontWeight.w500,
 letterSpacing: -0.1,
 ),
 ),
 ],
 ),
 ),
 );
 }
}
