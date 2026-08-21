import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import 'app_card.dart';

/// Card de módulo V5 Apple-clean — ícone circular tingido + rótulo.
///
/// Ícones seguem o padrão do dashboard: container circular, sem borda,
/// cor de fundo com opacidade baixa + ícone colorido.
class ModuleCard extends StatelessWidget {
  const ModuleCard({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.width = 152,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final double width;

  /// Cor do ícone — se nulo, usa [ThemeData.accent].
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = iconColor ?? theme.accent;

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
            // Ícone circular — padrão do dashboard (sem borda).
            Container(
              width: AppSizes.avatarSm,
              height: AppSizes.avatarSm,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: color),
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
