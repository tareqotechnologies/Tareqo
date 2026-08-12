import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'app_card.dart';

/// Cabeçalho-resumo diário compartilhado (Vendas/Compras): ícone, rótulo,
/// valor em destaque, subtítulo (ex.: contagem) e comparativo OPCIONAL vs
/// ontem (pílula com percentual, seta e rótulo como "vs ontem").
///
/// Os valores chegam já formatados — o widget não conhece o domínio. As cores
/// do comparativo são passadas pelo chamador: em Vendas "subir" é positivo
/// (verde); em Compras (despesa) "subir" é negativo (vermelho).
class DailySummaryHeader extends StatelessWidget {
  const DailySummaryHeader({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    this.iconBackground,
    this.iconColor,
    this.deltaPercent,
    this.deltaLabel,
    this.deltaUpColor,
    this.deltaDownColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final Color? iconBackground;
  final Color? iconColor;

  /// Percentual de variação vs ontem; `null` esconde o comparativo.
  final int? deltaPercent;

  /// Rótulo do comparativo (ex.: "vs ontem" / "vs yesterday").
  final String? deltaLabel;
  final Color? deltaUpColor;
  final Color? deltaDownColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // AppCard (design system ultra-clean): radius 12, borda 0.5px, flat —
    // o resumo do dia compartilhado (Vendas/Compras) segue o padrão.
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: iconBackground ?? theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                size: 22,
                color: iconColor ?? theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // FittedBox: valores longos (ou escala de texto alta)
                  // encolhem em vez de estourar o card.
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      maxLines: 1,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (deltaPercent != null) ...[
              const SizedBox(width: 12),
              // Flexible + ellipsis: o comparativo nunca estoura o card em
              // telas estreitas com escala de texto alta.
              Flexible(
                child: _DeltaPill(
                  percent: deltaPercent!,
                  label: deltaLabel ?? '',
                  upColor: deltaUpColor,
                  downColor: deltaDownColor,
                ),
              ),
            ],
        ],
      ),
    );
  }
}

/// Pílula de comparação com ontem (`▲ +25% vs ontem` / `▼ -10% vs ontem`).
class _DeltaPill extends StatelessWidget {
  const _DeltaPill({
    required this.percent,
    required this.label,
    this.upColor,
    this.downColor,
  });

  final int percent;
  final String label;
  final Color? upColor;
  final Color? downColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final up = percent > 0;
    final color = up
        ? (upColor ?? theme.colorScheme.primary)
        : percent < 0
        ? (downColor ?? theme.expense)
        : theme.colorScheme.onSurfaceVariant;
    final icon = up
        ? Icons.trending_up
        : percent < 0
        ? Icons.trending_down
        : Icons.trending_flat;
    final sign = up ? '+' : '';
    final text = label.isEmpty ? '$sign$percent%' : '$sign$percent% $label';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              // Quebra em até 2 linhas em telas estreitas em vez de
              // truncar ("-100% vs ontem" precisa ser legível completo).
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
                // Percentuais (+25% / -10%) alinhados dígito a dígito.
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
