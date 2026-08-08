import 'package:flutter/material.dart';

import '../../core/i18n/l10n_ext.dart';
import '../../core/i18n/payment_method_l10n.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/purchase.dart';
import 'method_badge.dart';
import 'payment_filter.dart' show PaymentMethodAccent, PaymentMethodIcon;
import 'status_chip.dart';

/// Card de compra premium — compartilhado entre a lista de compras e as
/// compras recentes do dashboard: forma de pagamento com selo colorido por
/// método, fornecedor, número sequencial, itens, unidades adicionadas ao
/// estoque, dia/hora inteligente e valor em destaque. Mesma linguagem
/// visual do [SalesCard] (duas faixas + filete) — mas estático: a compra
/// não tem tela de detalhes, então sem hover/ripple (a borda não muda para
/// não sugerir um toque que não existe).
class PurchaseCard extends StatelessWidget {
  const PurchaseCard({super.key, required this.purchase});

  final Purchase purchase;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    // Cor de destaque da forma de pagamento — identidade visual por método.
    final accent = purchase.paymentMethod.accent(theme);
    final itemsLabel = l10n.dashboardSaleItems(purchase.items.length);
    // Total de UNIDADES adicionadas ao estoque (soma das quantidades).
    final units = purchase.items.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PaymentMethodBadge(
                  accent: accent,
                  icon: purchase.paymentMethod.icon,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        purchase.supplierName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${Formatters.purchaseLabel(purchase.number)} · '
                        '$itemsLabel · '
                        '${purchase.paymentMethod.labelFor(l10n)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Chip: unidades adicionadas ao estoque (informação
                // derivada das quantidades dos itens — sem modelo novo).
                // Flexible: encolhe (ellipsis interno) em telas estreitas.
                Flexible(
                  child: StatusChip(
                    label: l10n.purchasesStockAdded(units, l10n.commonUnits),
                    color: theme.colorScheme.primary,
                    icon: Icons.inventory_2_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Filete fino: estrutura o card em "identidade + valor".
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.schedule, size: 14, color: scheme.onSurfaceVariant),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    // Data inteligente: 'Hoje/Ontem/04/08' + hora.
                    '${Formatters.day(purchase.dateTime)} • '
                    '${Formatters.time(purchase.dateTime)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Flexible: valores altos (ou escala de texto alta)
                // encolhem com ellipsis em vez de estourar o card.
                Flexible(
                  child: Text(
                    Formatters.currency(purchase.totalAmountCents),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
