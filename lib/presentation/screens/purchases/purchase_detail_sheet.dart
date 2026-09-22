import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/i18n/payment_method_l10n.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/quantity.dart';
import '../../../domain/entities/purchase.dart';
import '../../controllers/products_providers.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/detail_row.dart';
import '../../widgets/payment_filter.dart'
    show PaymentMethodAccent, PaymentMethodIcon;
import '../../widgets/product_image.dart';
import '../../widgets/section_header.dart';
import '../../widgets/smart_amount.dart';
import '../../widgets/status_chip.dart';

/// Detalhes de uma COMPRA — aberta ao tocar no card da lista de Compras.
///
/// Espelha o detalhe da venda: cabeçalho com número sequencial (C-00001) +
/// data, chip da forma de pagamento, total em destaque, lista de itens
/// (produto, quantidade × preço unitário, subtotal e VALIDADE do lote
/// FIFO criado) e nota de snapshot — "fotografia" dos preços de compra no
/// momento da entrada. A compra não tem ações (nada a anular/partilhar):
/// a sheet é só de LEITURA.
Future<void> showPurchaseDetailSheet(
  BuildContext context, {
  required Purchase purchase,
}) {
  return showAppSheet<void>(
    context,
    builder: (_) => _PurchaseDetailSheet(purchase: purchase),
  );
}

class _PurchaseDetailSheet extends ConsumerWidget {
  const _PurchaseDetailSheet({required this.purchase});

  final Purchase purchase;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final accent = purchase.paymentMethod.accent(theme);
    final itemsLabel = l10n.dashboardSaleItems(purchase.items.length);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabeçalho padrão das sheets (fechar à esquerda, título).
          SheetHeader(title: l10n.purchaseDetailTitle),
          // ── Cabeçalho: número sequencial + data + chip do pagamento ──
          Text(
            Formatters.purchaseLabel(purchase.number),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${Formatters.dateTime(purchase.dateTime)}  ·  $itemsLabel',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          StatusChip(
            label: purchase.paymentMethod.labelFor(l10n),
            color: accent,
            icon: purchase.paymentMethod.icon,
          ),
          const SizedBox(height: 20),

          // ── Dados da compra ──
          Container(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 6,
            ),
            child: Column(
              children: [
                DetailRow(
                  icon: Icons.local_shipping_outlined,
                  label: l10n.purchaseDetailSupplier,
                  value: purchase.supplierName,
                ),
                DetailRow(
                  icon: Icons.event_outlined,
                  label: l10n.purchaseDetailDate,
                  value: Formatters.dateTime(purchase.dateTime),
                ),
                DetailRow(
                  icon: Icons.payment_outlined,
                  label: l10n.purchaseDetailPayment,
                  value: purchase.paymentMethod.labelFor(l10n),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Total ──
          Text(
            l10n.saleDetailTotalLabel,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          SmartAmount(
            cents: purchase.totalAmountCents,
            alignment: Alignment.centerLeft,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),

          // ── Itens (com validade do lote FIFO de cada item) ──
          SectionHeader(title: l10n.saleDetailItems),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < purchase.items.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      indent: 14,
                      endIndent: 14,
                      color: scheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  _PurchaseItemRow(
                    item: purchase.items[i],
                    productsAsync: ref.watch(productsProvider),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Notas: FIFO + snapshot ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 14,
                color: scheme.outline,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '${l10n.purchaseDetailStockNote} ${l10n.saleDetailSnapshot}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.outline,
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

/// Linha de item da compra — mesmo shape da linha de item do detalhe da
/// venda (imagem, nome, quantidade × preço unitário, subtotal) com a
/// VALIDADE do lote criado por este item (FIFO) quando o produto perece.
class _PurchaseItemRow extends StatelessWidget {
  const _PurchaseItemRow({required this.item, required this.productsAsync});

  final PurchaseItem item;
  final AsyncValue<List<dynamic>> productsAsync;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final subtotal = Quantity.lineTotal(item.quantity, item.unitPriceCents);
    final imagePath = productsAsync.value
        ?.where((p) => p.id == item.productId)
        .map((p) => p.imagePath as String?)
        .firstOrNull;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          ProductImage(imagePath: imagePath ?? '', size: 40, radius: 10),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '${Quantity.format(item.quantity, language: Formatters.currentLanguage)} × '
                  '${Formatters.currency(item.unitPriceCents)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${l10n.purchaseDetailExpiry}: '
                  '${item.expiryDate != null ? Formatters.date(item.expiryDate!) : l10n.purchaseDetailNoExpiry}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: scheme.outline,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            Formatters.currency(subtotal),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
