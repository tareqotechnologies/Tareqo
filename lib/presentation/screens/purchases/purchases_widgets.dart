import 'package:flutter/material.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/purchase.dart';
import '../../widgets/daily_summary_header.dart';

/// Cabeçalho-resumo da tela de compras: gasto de HOJE + delta opcional vs
/// ontem — mesmo visual de Vendas ([DailySummaryHeader] compartilhado).
///
/// Para COMPRAS (despesa), gastar MAIS que ontem é negativo (vermelho) e
/// gastar menos é positivo (verde) — cores invertidas em relação a Vendas.
///
/// O card de compra vive em `widgets/purchase_card.dart` (compartilhado com
/// o dashboard).
class PurchasesSummaryHeader extends StatelessWidget {
  const PurchasesSummaryHeader({super.key, required this.purchases});

  final List<Purchase> purchases;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    var todayCents = 0;
    var todayCount = 0;
    var yesterdayCents = 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    for (final purchase in purchases) {
      final day = DateTime(
        purchase.dateTime.year,
        purchase.dateTime.month,
        purchase.dateTime.day,
      );
      if (day == today) {
        todayCents += purchase.totalAmountCents;
        todayCount++;
      } else if (day == yesterday) {
        yesterdayCents += purchase.totalAmountCents;
      }
    }

    final deltaPercent = yesterdayCents > 0
        ? ((todayCents - yesterdayCents) / yesterdayCents * 100).round()
        : null;

    return DailySummaryHeader(
      icon: Icons.local_shipping_outlined,
      iconBackground: theme.colorScheme.secondaryContainer,
      iconColor: theme.colorScheme.onSecondaryContainer,
      label: l10n.periodToday,
      value: Formatters.currency(todayCents),
      subtitle: l10n.purchasesHeaderCount(todayCount),
      deltaPercent: deltaPercent,
      deltaLabel: l10n.purchasesHeaderVsYesterday,
      // Em COMPRAS (despesa), subir é ruim (vermelho) e cair é bom (verde).
      deltaUpColor: theme.expense,
      deltaDownColor: theme.income,
    );
  }
}
