import 'package:flutter/material.dart';

/// Card de indicador (KPI) — minimalista: ícone, valor em destaque e rótulo.
class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.iconBackground,
    this.iconColor,
    this.caption,
    this.loading = false,
  });

  final String label;

  /// Valor já formatado (ex.: `R$ 1.234,56`).
  final String value;
  final IconData icon;
  final Color? iconBackground;
  final Color? iconColor;
  final String? caption;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background =
        iconBackground ?? theme.colorScheme.primaryContainer;
    final foreground = iconColor ?? theme.colorScheme.onPrimaryContainer;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: foreground),
            ),
            const SizedBox(height: 12),
            // FittedBox evita overflow em telas estreitas com valores longos.
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                loading ? '—' : value,
                maxLines: 1,
                style: theme.textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (caption != null) ...[
              const SizedBox(height: 6),
              Text(
                caption!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
