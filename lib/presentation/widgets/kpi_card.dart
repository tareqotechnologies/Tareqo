import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'app_card.dart';
import 'smart_amount.dart';

/// Card de indicador (KPI) — design system 2026: ícone em QUADRADO
/// arredondado com BORDA verde (acento) e ícone verde, valor em destaque
/// e rótulo esmaecido. Espelha o card de métrica do app de referência.
///
/// Layout por altura intrínseca (`mainAxisSize: min`): o conteúdo nunca
/// estoura o card, mesmo com escala de texto alta, valores longos ou
/// caption presente — a altura é decidida pelo próprio conteúdo quando o
/// card é usado numa grade adaptativa (ver grade de KPIs do dashboard).
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
    this.loading = false,
  }) : assert(
          value != null || amountCents != null,
          'KpiCard requer value ou amountCents',
        );

  final String label;

  /// Valor já formatado — usado para indicadores NÃO monetários
  /// (ex.: `12 un`, `12,5%`) ou quando o valor não vem em centavos.
  /// Ignorado quando [amountCents] é fornecido.
  final String? value;

  /// Valor monetário em CENTAVOS (W4): renderizado com [SmartAmount]
  /// (auto-size) — o texto ENCOLHE para nunca estourar nem truncar,
  /// mesmo com valores grandes ou escala de texto alta.
  final int? amountCents;
  final IconData icon;

  /// Quando nulas, o card usa o ACENTO verde do design system (padrão).
  final Color? iconBackground;
  final Color? iconColor;

  /// Rótulo auxiliar opcional (ex.: período do indicador).
  final String? caption;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background =
        iconBackground ?? theme.accent.withValues(alpha: 0.08);
    final foreground = iconColor ?? theme.accent;

    // AppCard (design system ultra-clean): radius 12, borda 0.5px #222E35,
    // flat — o componente em uso real em todos os KPIs do app.
    return AppCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            // Chip do ícone — QUADRADO arredondado com borda verde (acento)
            // e ícone verde, como no app de referência. Área fixa 42×42.
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: foreground.withValues(alpha: 0.55),
                  width: 1.2,
                ),
              ),
              child: Icon(icon, size: 21, color: foreground),
            ),
            const SizedBox(height: 14),
            _Value(loading: loading, value: value, amountCents: amountCents),
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
      );
  }
}

/// Valor do KPI — auto-size para MOEDA ([SmartAmount]), FittedBox para os
/// demais formatos; o placeholder "—" cobre o estado de carregamento.
class _Value extends StatelessWidget {
  const _Value({
    required this.loading,
    required this.value,
    required this.amountCents,
  });

  final bool loading;
  final String? value;
  final int? amountCents;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.headlineSmall?.copyWith(
      letterSpacing: -0.4,
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
    // FittedBox evita overflow horizontal em telas estreitas com valores
    // longos (o texto encolhe, nunca transborda).
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(value ?? '', maxLines: 1, style: style),
    );
  }
}
