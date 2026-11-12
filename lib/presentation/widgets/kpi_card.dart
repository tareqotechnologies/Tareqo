import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import 'app_card.dart';
import 'premium_decor.dart';
import 'smart_amount.dart';

/// Card de indicador (KPI) V4 — ícone em badge + valor + rótulo.
class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.label,
    this.value,
    this.amountCents,
    required this.icon,
    this.iconBackground,
    this.iconColor,
    this.caption,
    this.valueColor,
    this.loading = false,
    this.borderRadius,
  }) : assert(
         value != null || amountCents != null,
         'KpiCard requer value ou amountCents',
       );

  final String label;
  final String? value;
  final int? amountCents;
  final IconData icon;
  final Color? iconBackground;
  final Color? iconColor;
  final Color? valueColor;
  final String? caption;
  final bool loading;

  /// Cantos do card — telas premium passam raios maiores (ex.: 18).
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    // Ícone do indicador em tinta (neutro): o acento fica reservado a
    // CTA, foco e selecção — KPIs são informação, não acção.
    final foreground = iconColor ?? theme.colorScheme.onSurface;

    return AppCard(
      borderRadius:
          borderRadius ?? const BorderRadius.all(Radius.circular(AppRadius.md)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge do ícone: gradiente subtil da própria cor + aro fino —
          // lê-se como "joia" do card sem competir com o valor.
          Container(
            width: AppSizes.avatarMd,
            height: AppSizes.avatarMd,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: iconBackground,
              gradient: iconBackground == null
                  ? PremiumDecor.iconTint(foreground, dark: dark)
                  : null,
              borderRadius: AppRadius.mdAll,
              border: Border.all(color: foreground.withValues(alpha: 0.22)),
            ),
            child: Icon(icon, size: 20, color: foreground),
          ),
          const SizedBox(height: AppSpacing.md),
          _Value(
            loading: loading,
            value: value,
            amountCents: amountCents,
            color: valueColor,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            // Rótulo do indicador ligeiramente menor que a nota padrão (13 → 12)
            // para o rótulo não competir com o valor do card (pedido de UI).
            style: AppTypography.labelSmall,
          ),
          if (caption != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              caption!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelSmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _Value extends StatelessWidget {
  const _Value({
    required this.loading,
    required this.value,
    required this.amountCents,
    this.color,
  });

  final bool loading;
  final String? value;
  final int? amountCents;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    // Valor do KPI em 600 com tracking negativo: números "desenhados",
    // sem mudar o degrau da escala (o FittedBox absorve a largura extra).
    final style = AppTypography.titleMedium.copyWith(
      color: color,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.3,
    );

    if (loading) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text('—', maxLines: 1, style: style),
      );
    }
    if (amountCents != null) {
      return SmartAmount(cents: amountCents!, style: style);
    }
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(value ?? '', maxLines: 1, style: style),
    );
  }
}
