import 'package:flutter/material.dart';

import '../../core/theme/app_typography.dart';

/// Associação contagem → rótulo (ex.: "12 Ativas", "3 Pendentes") —
/// padrão único do painel admin.
///
/// Consolida as variantes privadas `_Pill` eliminadas de
/// `admin_addons_screen`, `admin_audit_log_screen` e `admin_plans_screen`
/// (idênticas por hash de 12 linhas). A pílula INTERATIVA de filtro
/// (notificações/checklist, com seleção e badge) é um componente diferente
/// e permanece local à sua tela.
class MetricPill extends StatelessWidget {
  const MetricPill({
    super.key,
    required this.count,
    required this.label,
    required this.color,
  });

  final int count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$count',
          style: AppTypography.labelMedium.copyWith(color: color),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
