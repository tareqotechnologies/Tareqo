import 'package:flutter/material.dart';

import '../../core/i18n/l10n_ext.dart';
import '../../core/i18n/payment_method_l10n.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/quantity.dart';
import '../../domain/entities/purchase.dart';
import 'app_card.dart';
import 'method_badge.dart';
import 'smart_amount.dart';
import 'payment_filter.dart' show PaymentMethodAccent, PaymentMethodIcon;
import 'status_chip.dart';

/// Card de compra premium — compartilhado entre a lista de compras e as
/// compras recentes do dashboard: forma de pagamento com selo colorido por
/// método, fornecedor, número sequencial, itens, unidades adicionadas ao
/// estoque, dia/hora inteligente e valor em destaque. Mesma linguagem
/// visual do [SalesCard] (linha única compacta, design system 2026) — mas
/// estático: a compra não tem tela de detalhes, então sem hover/ripple.
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
    // Total de UNIDADES adicionadas ao estoque (W11: quantidades em
    // MILÉSIMOS — converte para unidades inteiras na exibição).
    final units = Quantity.toUnits(
      purchase.items.fold<int>(0, (sum, item) => sum + item.quantity),
    ).round();

    // AppCard (design system ultra-clean): radius 12, borda 0.5px, flat —
    // mesma linguagem do SalesCard (linha única compacta), sem hover/ripple
    // (a compra não tem tela de detalhes).
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
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
                  // Nome do fornecedor COMPLETO — quebra em linhas quando
                  // necessário (nada de truncar).
                  Text(
                    purchase.supplierName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${Formatters.purchaseLabel(purchase.number)} · '
                    '$itemsLabel · '
                    '${purchase.paymentMethod.labelFor(l10n)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    // Data inteligente: 'Hoje/Ontem/04/08' + hora.
                    '${Formatters.day(purchase.dateTime)} • '
                    '${Formatters.time(purchase.dateTime)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Coluna direita: unidades adicionadas + valor, ancoradas.
            Flexible(
              child: Align(
                alignment: Alignment.centerRight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // SmartAmount (design system ultra-clean): auto-size
                    // do valor — encolhe em vez de estourar/truncar.
                    SmartAmount(
                      cents: purchase.totalAmountCents,
                      alignment: Alignment.centerRight,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    StatusChip(
                      label: l10n.purchasesStockAdded(units, l10n.commonUnits),
                      color: theme.colorScheme.primary,
                      icon: Icons.inventory_2_outlined,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
