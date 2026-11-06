import 'package:flutter/material.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';

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
  }) : inline = false;

  /// Variante INLINE (rótulo na frente do valor, ex.: `Origem: Loja A`) —
  /// usada nos bottom sheets do dashboard (feed de transferências).
  /// Consolida a última cópia privada `_DetailRow` (dashboard_screen).
  const DetailRow.inline({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.labelWidth = 100,
    this.gap = 8,
    this.valueColor,
    this.maxLines,
  }) : padding = EdgeInsets.zero,
       inline = true;

  final String label;
  final String value;
  final double labelWidth;
  final IconData? icon;
  final double gap;
  final EdgeInsetsGeometry padding;
  final Color? valueColor;
  final int? maxLines;

  /// Variante inline: rótulo `Label:` junto ao valor (font/tamanho
  /// compressos) em vez da coluna fixa de rótulo.
  final bool inline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (inline) {
      return Row(
        children: [
          Icon(icon, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: AppTypography.bodySmall.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: AppTypography.labelMedium.copyWith(
                color: scheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

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
              // Rótulo = metadado (12) — nunca 11, que corta em nomes de
              // campo longos ("Método de pagamento").
              style: AppTypography.bodySmall.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: maxLines,
              overflow: maxLines == null ? null : TextOverflow.ellipsis,
              // Valor = 14/w500: enfatiza sem o w600 reservado a títulos.
              style: AppTypography.labelLarge.copyWith(
                color: valueColor ?? scheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
