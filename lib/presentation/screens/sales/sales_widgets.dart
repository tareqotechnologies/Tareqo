import 'package:flutter/material.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/sale.dart';
import '../../widgets/daily_summary_header.dart';
import '../../widgets/payment_filter.dart';
import '../../widgets/period_filter.dart';

/// Cabeçalho-resumo da tela de vendas: valor e transações de HOJE + delta
/// opcional vs ontem (inspirado no dashboard do Square/Stripe).
///
/// Agrega a lista já carregada pelo provider (pura apresentação, em centavos
/// inteiros — W4); quando não há vendas ontem, o comparativo é omitido. O
/// visual é o [DailySummaryHeader] compartilhado com Compras.
class SalesSummaryHeader extends StatelessWidget {
  const SalesSummaryHeader({super.key, required this.sales});

  final List<Sale> sales;

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
    for (final sale in sales) {
      final day =
          DateTime(sale.dateTime.year, sale.dateTime.month, sale.dateTime.day);
      if (day == today) {
        todayCents += sale.totalAmountCents;
        todayCount++;
      } else if (day == yesterday) {
        yesterdayCents += sale.totalAmountCents;
      }
    }

    final deltaPercent = yesterdayCents > 0
        ? ((todayCents - yesterdayCents) / yesterdayCents * 100).round()
        : null;

    return DailySummaryHeader(
      icon: Icons.point_of_sale,
      label: l10n.periodToday,
      value: Formatters.currency(todayCents),
      subtitle: l10n.salesHeaderTransactions(todayCount),
      deltaPercent: deltaPercent,
      deltaLabel: l10n.salesHeaderVsYesterday,
      // Em VENDAS, faturar mais que ontem é positivo (verde).
      deltaUpColor: theme.income,
      deltaDownColor: theme.expense,
    );
  }
}

/// Barra de filtros rápidos da lista de vendas (período + pagamento),
/// Material 3.
///
/// Período e pagamento usam os widgets compartilhados com Compras
/// ([PeriodFilterBar] e [PaymentFilterBar]) — `Wrap` interno em ambos: os
/// chips fluem para a próxima linha em telas estreitas / escala alta.
class SalesFilterBar extends StatelessWidget {
  const SalesFilterBar({
    super.key,
    required this.period,
    required this.payment,
    required this.onPeriodChanged,
    required this.onPaymentChanged,
  });

  final PeriodFilter period;
  final PaymentFilter payment;
  final ValueChanged<PeriodFilter> onPeriodChanged;
  final ValueChanged<PaymentFilter> onPaymentChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PeriodFilterBar(value: period, onChanged: onPeriodChanged),
        const SizedBox(height: 8),
        PaymentFilterBar(value: payment, onChanged: onPaymentChanged),
      ],
    );
  }
}
