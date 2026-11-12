import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import 'premium_decor.dart';

/// Hero de resumo — o cabeçalho que abre Vendas, Compras e Crédito.
///
/// Uma única superfície (cartão do tema, borda de cabelo, raio 20) com
/// hierarquia fixa:
/// 1. [label] — contexto em caixa alta (o chamador decide o texto);
/// 2. [value] — o número que domina o ecrã (`AppTypography.heroAmount`,
///    tabular, encolhe em vez de estourar);
/// 3. [subtitle] — nota discreta (contagens);
/// 4. [deltaPercent] ou [trailing] — comparação vs. período anterior ou uma
///    estatística secundária.
///
/// O hero nunca tinge o fundo com a cor de estado: a cor aparece apenas nos
/// indicadores (pílula de variação, número secundário). É a mesma regra do
/// resto do sistema — cor representa função, não decoração.
class SummaryHero extends StatelessWidget {
  const SummaryHero({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    this.valueColor,
    this.deltaPercent,
    this.deltaLabel,
    this.deltaUpColor,
    this.deltaDownColor,
    this.trailing,
  });

  /// Rótulo de contexto já formatado (ex.: "HOJE", "Total a receber").
  final String label;

  /// Valor principal já formatado (moeda do tenant, contagem, etc.).
  final String value;

  /// Nota sob o valor (ex.: "3 transações").
  final String? subtitle;

  /// Cor do valor (default: `onSurface`). Use só para semântica real
  /// (saldo negativo, por exemplo).
  final Color? valueColor;

  /// Percentual de variação vs. o período anterior; `null` esconde a pílula.
  final int? deltaPercent;
  final String? deltaLabel;
  final Color? deltaUpColor;
  final Color? deltaDownColor;

  /// Bloco secundário ancorado à direita do valor (ex.: "Atrasados 3").
  /// Mutuamente exclusivo com [deltaPercent] na prática — o chamador decide.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Acabamento premium: superfície com véu neutro quase imperceptível,
    // halo de luz no canto superior direito e sombra neutra em camadas. O
    // conteúdo continua sobre `surface` — a cor de estado só nos
    // indicadores; a tinta fica no traço de marca e nos CTAs.
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: PremiumDecor.heroSurface(scheme, tint: scheme.onSurface),
        borderRadius: AppRadius.xlAll,
        border: Border.all(color: PremiumDecor.hairline(scheme)),
        boxShadow: PremiumDecor.softShadow(scheme),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -90,
            right: -70,
            child: PremiumGlow(
              color: scheme.onSurface,
              size: 240,
              opacity: 0.06,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: _content(theme, scheme),
          ),
        ],
      ),
    );
  }

  Widget _content(ThemeData theme, ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Marcador de marca: um traço curto em gradiente antes do
            // rótulo — assinatura visual dos heroes.
            Container(
              width: 14,
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.accent, theme.accent.withValues(alpha: 0.35)],
                ),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.eyebrow(scheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              // FittedBox scaleDown: com Dynamic Type extremo o valor
              // encolhe em vez de estourar a linha — nunca é truncado.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  maxLines: 1,
                  style: AppTypography.heroAmount(
                    valueColor ?? scheme.onSurface,
                  ),
                ),
              ),
            ),
            if (deltaPercent != null) ...[
              const SizedBox(width: AppSpacing.sm),
              DeltaPill(
                percent: deltaPercent!,
                label: deltaLabel ?? '',
                upColor: deltaUpColor,
                downColor: deltaDownColor,
              ),
            ],
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.md),
              trailing!,
            ],
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

/// Variação vs. período anterior — pílula semântica discreta.
///
/// A seta e o sinal dizem a direção; a cor reforça o significado (o chamador
/// inverte as cores quando "subir" é mau, como em Compras). Nunca é o foco
/// do hero: fundo a 10%, texto 11/w500.
class DeltaPill extends StatelessWidget {
  const DeltaPill({
    super.key,
    required this.percent,
    this.label = '',
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
        ? Icons.arrow_upward_rounded
        : percent < 0
        ? Icons.arrow_downward_rounded
        : Icons.remove_rounded;
    final sign = up ? '+' : '';
    final text = label.isEmpty ? '$sign$percent%' : '$sign$percent% $label';

    return Semantics(
      label: text,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs + 2,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: color.withValues(alpha: 0.20), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.eyebrow(color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
