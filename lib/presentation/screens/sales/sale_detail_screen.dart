import 'package:flutter/material.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/i18n/payment_method_l10n.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/sale.dart';
import '../../../domain/entities/sale_item.dart';
import '../../widgets/section_header.dart';
import '../../widgets/status_chip.dart';

/// Tela de detalhes de uma venda — itens expandidos com quantidade,
/// preço unitário e subtotal, além do total e da forma de pagamento.
class SaleDetailScreen extends StatelessWidget {
  const SaleDetailScreen({super.key, required this.sale});

  final Sale sale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final itemsLabel = l10n.dashboardSaleItems(sale.items.length);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.saleDetailTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          // ---------------------------------------------------------
          // Resumo: identificação, pagamento, data e total
          // ---------------------------------------------------------
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.receipt_long_outlined,
                          size: 20,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.saleDetailId(sale.id),
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$itemsLabel · '
                              '${Formatters.dateTime(sale.dateTime)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // O chip fica em linha própria: rótulos longos
                  // ('Cartão de crédito') não causam overflow em telas
                  // estreitas.
                  StatusChip(
                    label: sale.paymentMethod.labelFor(context.l10n),
                    color: theme.colorScheme.primary,
                    icon: Icons.payments_outlined,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.saleDetailTotalLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Formatters.currency(sale.totalAmountCents),
                    style: theme.textTheme.headlineMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SectionHeader(title: l10n.saleDetailItems),
          const SizedBox(height: 8),
          // ---------------------------------------------------------
          // Itens: quantidade × preço unitário e subtotal
          // ---------------------------------------------------------
          Card(
            child: Column(
              children: [
                for (var i = 0; i < sale.items.length; i++) ...[
                  if (i > 0)
                    const Divider(height: 1, indent: 14, endIndent: 14),
                  _ItemRow(item: sale.items[i]),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Text(l10n.saleDetailTotal, style: theme.textTheme.titleMedium),
                const Spacer(),
                Text(
                  Formatters.currency(sale.totalAmountCents),
                  style: theme.textTheme.headlineSmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // ---------------------------------------------------------
          // Snapshot: preços congelados no momento da venda
          // ---------------------------------------------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_clock_outlined,
                size: 14,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  l10n.saleDetailSnapshot,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Linha de item: nome, `quantidade × preço unitário` e subtotal.
class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final SaleItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtotal = item.quantity * item.unitPriceCents;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.quantity} × '
                  '${Formatters.currency(item.unitPriceCents)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            Formatters.currency(subtotal),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
