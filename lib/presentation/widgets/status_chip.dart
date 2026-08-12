import 'package:flutter/material.dart';

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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        // Ícone verticalmente CENTRALIZADO mesmo quando o rótulo quebra em
        // 2+ linhas (âncoras com valores longos).
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          // Flexible SEM ellipsis: rótulos longos (ex.: 'Fiado
          // R\$ 1.234.567,89') quebram em linhas quando o espaço aperta —
          // o texto da âncora fica SEMPRE completo, nunca truncado.
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: scheme.brightness == Brightness.dark
                    ? color.withValues(alpha: 0.9)
                    : color,
                // Chips carregam quantidades/valores/datas — dígitos
                // alinhados em colunas de chips.
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
