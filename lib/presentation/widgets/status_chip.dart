import 'package:flutter/material.dart';

import 'num_text.dart';
import '../../../core/theme/app_tokens.dart';

/// Pílula de status — rótulo com fundo colorido translúcido.
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 3),
          ],
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              // NumText: chips carregam quantidades/valores/datas — dígitos
              // alinhados em colunas de chips (tabular embutido).
              child: NumText(
                label,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: scheme.brightness == Brightness.dark
                      ? color.withValues(alpha: 0.9)
                      : color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
