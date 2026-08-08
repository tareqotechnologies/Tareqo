import 'package:flutter/material.dart';

/// Card de indicador (KPI) — minimalista: ícone, valor em destaque e rótulo.
///
/// Layout por altura intrínseca (`mainAxisSize: min`): o conteúdo nunca
/// estoura o card, mesmo com escala de texto alta, valores longos ou
/// caption presente — a altura é decidida pelo próprio conteúdo quando o
/// card é usado numa grade adaptativa (ver grade de KPIs do dashboard).
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

  /// Rótulo auxiliar opcional (ex.: período do indicador).
  final String? caption;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = iconBackground ?? theme.colorScheme.primaryContainer;
    final foreground = iconColor ?? theme.colorScheme.onPrimaryContainer;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chip do ícone — área fixa 40×40, alinhamento central garante
            // consistência visual entre cards.
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: foreground),
            ),
            const SizedBox(height: 14),
            // FittedBox evita overflow horizontal em telas estreitas com
            // valores longos (o texto encolhe, nunca transborda).
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                loading ? '—' : value,
                maxLines: 1,
                style: theme.textTheme.headlineSmall?.copyWith(
                  letterSpacing: -0.4,
                ),
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
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: foreground.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      caption!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
