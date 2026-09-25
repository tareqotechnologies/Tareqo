import 'package:flutter/material.dart';
import '../../../core/theme/app_tokens.dart';

/// Linha chave → valor de listas de detalhe — padrão único das sheets de
/// detalhe (transação financeira, loja e log de auditoria).
///
/// Consolida as variantes privadas `_DetailRow` que estavam copiadas
/// nesses arquivos. O rótulo fica em coluna fixa ([labelWidth]) para os
/// valores alinharem em lista; o valor quebra em quantas linhas precisar
/// ([maxLines] null = sem truncamento — dados de contato/endereço nunca
/// são escondidos). [valueColor] colore o valor (ex.: verde de entrada,
/// vermelho de saída); [icon] opcional à esquerda.
class DetailRow extends StatelessWidget {
  const DetailRow({
    super.key,
    required this.label,
    required this.value,
    this.labelWidth = 100,
    this.icon,
    this.gap = 8,
    this.padding = const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    this.valueColor,
    this.maxLines,
  });

  final String label;
  final String value;
  final double labelWidth;
  final IconData? icon;
  final double gap;
  final EdgeInsetsGeometry padding;
  final Color? valueColor;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: scheme.onSurfaceVariant),
            SizedBox(width: gap),
          ],
          SizedBox(
            width: labelWidth,
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: maxLines,
              overflow: maxLines == null ? null : TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: valueColor ?? scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
