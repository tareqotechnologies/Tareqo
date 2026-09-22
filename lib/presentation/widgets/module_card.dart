import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import 'app_card.dart';

/// Card de módulo — ícone circular com fundo sólido escuro + rótulo.
///
/// Padrão replicado do feed de atividade da Home: container circular
/// com background escuro (mesma família de cor do ícone) e ícone
/// CLARO que contrasta sobre o fundo.
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
    final bg = IconTone.darkBackground(color);
    final fg = IconTone.lightForeground(color);

    return SizedBox(
      width: width,
      child: AppCard(
        onTap: onTap,
        elevated: true,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.lg)),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ícone circular — fundo sólido escuro, ícone claro.
            Container(
              width: AppSizes.avatarSm,
              height: AppSizes.avatarSm,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: Icon(icon, size: 20, color: fg),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
