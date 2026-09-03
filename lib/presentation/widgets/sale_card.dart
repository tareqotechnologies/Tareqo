import 'package:flutter/material.dart';

import '../../core/i18n/l10n_ext.dart';
import '../../core/i18n/payment_method_l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/sale.dart';
import '../screens/sales/sale_detail_screen.dart';
import 'payment_filter.dart' show PaymentMethodAccent, PaymentMethodIcon;
import 'status_chip.dart';

/// Card de venda minimalista — Google Apps style.
///
/// Layout em duas linhas:
/// - Linha 1: payment icon (sutil) + method name à esquerda, valor à direita
/// - Linha 2: sale number · items · date à esquerda, status à direita
class SalesCard extends StatefulWidget {
  const SalesCard({super.key, required this.sale, this.onTap});

  final Sale sale;
  final VoidCallback? onTap;

  @override
  State<SalesCard> createState() => _SalesCardState();
}

class _SalesCardState extends State<SalesCard> {
  bool _hovered = false;

  Sale get _sale => widget.sale;
  VoidCallback? get _onTap => widget.onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final accent = _sale.paymentMethod.accent(theme);
    final itemsLabel = l10n.dashboardSaleItems(_sale.items.length);
    final isCancelled = _sale.status == SaleStatus.cancelled;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: _hovered
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.6)
            : scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        child: InkWell(
          onTap: _onTap ?? () => _openDetails(context),
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            child: Row(
              children: [
                // ── Left: payment icon (dark solid bg + light fg) ──
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: IconTone.darkBackground(accent),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _sale.paymentMethod.icon,
                    size: 18,
                    color: IconTone.lightForeground(accent),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Primary line: payment method + amount
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _sale.paymentMethod.labelFor(l10n),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              Formatters.currency(_sale.totalAmountCents),
                              maxLines: 1,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      // Secondary line: sale number · items (date visible in details)
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${Formatters.saleLabel(_sale.number)}'
                              '  ·  $itemsLabel',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 12,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusChip(
                            label: isCancelled
                                ? l10n.salesStatusCancelled
                                : l10n.salesStatusPaid,
                            color: isCancelled
                                ? theme.expense
                                : theme.income,
                            icon: isCancelled
                                ? Icons.block
                                : Icons.check_circle_outline,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openDetails(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => SaleDetailScreen(sale: _sale)),
    );
  }
}
