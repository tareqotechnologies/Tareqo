import 'package:flutter/material.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/sale.dart';

/// Cabeçalho-resumo da tela de vendas.
///
/// Usa a MESMA linguagem visual do feed de eventos da Home ("Atividade de
/// hoje"): um painel único com cantos de sheet, borda hairline e as linhas
/// separadas por réguas finas — em vez do cartão compacto anterior, cujo chip
/// de variação truncava o texto ("12 % vs. on…").
///
/// Linhas: total do dia (com a contagem de transações) e a variação vs. ontem.
/// Os valores ficam à direita num [FittedBox] `scaleDown`: em ecrãs estreitos
/// ou com Dynamic Type o número ENCOLHE — nunca é cortado com reticências.
class SalesSummaryHeader extends StatelessWidget {
  const SalesSummaryHeader({super.key, required this.sales});

  final List<Sale> sales;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    var todayCents = 0;
    var todayCount = 0;
    var yesterdayCents = 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    for (final sale in sales) {
      if (sale.status == SaleStatus.cancelled) continue;
      final day = DateTime(
        sale.dateTime.year,
        sale.dateTime.month,
        sale.dateTime.day,
      );
      if (day == today) {
        todayCents += sale.totalAmountCents;
        todayCount++;
      } else if (day == yesterday) {
        yesterdayCents += sale.totalAmountCents;
      }
    }

    // Sem vendas ontem não há base de comparação: a linha de variação é
    // OMITIDA (antes aparecia um chip com o texto "Cancelar").
    final deltaPercent = yesterdayCents > 0
        ? ((todayCents - yesterdayCents) / yesterdayCents * 100).round()
        : null;

    final rows = <Widget>[
      Semantics(
        container: true,
        excludeSemantics: true,
        label:
            '${l10n.periodToday}: ${Formatters.currency(todayCents)}, '
            '${l10n.salesHeaderTransactions(todayCount)}',
        child: _SummaryRow(
          icon: Icons.receipt_long_outlined,
          // U-22: antes IconTone.accentOrange (#F28C00, terceiro laranja)
          // + Colors.white. Agora deriva do acento do tema.
          iconBackground: IconTone.darkBackground(theme.accent),
          iconColor: IconTone.lightForeground(theme.accent),
          title: l10n.periodToday,
          details: l10n.salesHeaderTransactions(todayCount),
          trailing: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              Formatters.currency(todayCents),
              maxLines: 1,
              style: AppTypography.summaryAmount(scheme.onSurface),
            ),
          ),
        ),
      ),
      if (deltaPercent != null)
        Semantics(
          container: true,
          excludeSemantics: true,
          label:
              '${l10n.salesHeaderVsYesterday}: '
              '${_deltaLabel(deltaPercent)}',
          child: _SummaryRow(
            icon: deltaPercent >= 0
                ? Icons.trending_up_rounded
                : Icons.trending_down_rounded,
            iconBackground: _deltaColor(
              deltaPercent,
              theme,
            ).withValues(alpha: 0.18),
            iconColor: _deltaColor(deltaPercent, theme),
            title: l10n.salesHeaderVsYesterday,
            details: Formatters.currency(yesterdayCents),
            trailing: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: _deltaColor(deltaPercent, theme).withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _deltaLabel(deltaPercent),
                  maxLines: 1,
                  style: AppTypography.labelMedium.copyWith(
                    color: _deltaColor(deltaPercent, theme),
                  ),
                ),
              ),
            ),
          ),
        ),
    ];

    return Material(
      color: scheme.surfaceContainerHighest,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: 60,
                endIndent: AppSpacing.md,
                color: scheme.outlineVariant,
              ),
            rows[i],
          ],
        ],
      ),
    );
  }

  /// "+12 %" / "-8 %" / "0 %" — sem o rótulo "vs ontem" (que é o título da
  /// linha), para caber sem truncar.
  String _deltaLabel(int percent) => '${percent > 0 ? '+' : ''}$percent %';

  Color _deltaColor(int percent, ThemeData theme) {
    if (percent > 0) return theme.income;
    if (percent < 0) return theme.expense;
    return theme.colorScheme.onSurfaceVariant;
  }
}

/// Linha do painel-resumo — mesma anatomia das linhas do feed de atividade
/// da Home: ícone em círculo de 40 px, título + detalhe à esquerda e a
/// âncora (valor/badge) à direita.
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.details,
    this.trailing,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String details;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: iconBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.micro),
                Text(
                  details,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Align(alignment: Alignment.centerRight, child: trailing),
            ),
          ],
        ],
      ),
    );
  }
}
