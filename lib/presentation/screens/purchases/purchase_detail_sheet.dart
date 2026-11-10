import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/i18n/payment_method_l10n.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/quantity.dart';
import '../../../domain/entities/purchase.dart';
import '../../controllers/products_providers.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/detail_row.dart';
import '../../widgets/payment_filter.dart'
    show PaymentMethodAccent, PaymentMethodIcon;
import '../../widgets/premium_decor.dart';
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
      padding: AppSpacing.sheetPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabeçalho padrão das sheets (fechar à esquerda, título).
          SheetHeader(title: l10n.purchaseDetailTitle),
          // ── Cabeçalho: número sequencial + data + chip do pagamento ──
          Text(
            Formatters.purchaseLabel(purchase.number),
            style: AppTypography.titleLarge.copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${Formatters.dateTime(purchase.dateTime)}  ·  $itemsLabel',
            style: AppTypography.bodySmall.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          StatusChip(
            label: purchase.paymentMethod.labelFor(l10n),
            color: accent,
            icon: purchase.paymentMethod.icon,
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Dados da compra ──
          Container(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: PremiumDecor.hairline(scheme)),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
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
          const SizedBox(height: AppSpacing.lg),

          // ── Total ──
          Text(
            l10n.saleDetailTotalLabel,
            style: AppTypography.bodySmall.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          SmartAmount(
            cents: purchase.totalAmountCents,
            alignment: Alignment.centerLeft,
            style: AppTypography.headline.copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Itens (com validade do lote FIFO de cada item) ──
          SectionHeader(title: l10n.saleDetailItems),
          const SizedBox(height: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: PremiumDecor.hairline(scheme)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < purchase.items.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      indent: AppSpacing.md,
                      endIndent: AppSpacing.md,
                      color: PremiumDecor.hairline(scheme),
                    ),
                  _PurchaseItemRow(
                    item: purchase.items[i],
                    productsAsync: ref.watch(productsProvider),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Notas: FIFO + snapshot ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: AppSizes.iconSm,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  '${l10n.purchaseDetailStockNote} ${l10n.saleDetailSnapshot}',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    color: scheme.onSurfaceVariant,
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          ProductImage(
            imagePath: imagePath ?? '',
            size: AppSizes.avatarMd,
            radius: AppRadius.sm,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  // Nome do produto = 12/w500 (labelMedium).
                  style: AppTypography.labelMedium.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.micro),
                Text(
                  '${Quantity.format(item.quantity, language: Formatters.currentLanguage)} × '
                  '${Formatters.currency(item.unitPriceCents)}',
                  style: AppTypography.bodySmall.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.micro),
                Text(
                  '${l10n.purchaseDetailExpiry}: '
                  '${item.expiryDate != null ? Formatters.date(item.expiryDate!) : l10n.purchaseDetailNoExpiry}',
                  // Metadado (validade) = 12 — nunca 11: é informação
                  // operacional, não decoração.
                  style: AppTypography.bodySmall.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            Formatters.currency(subtotal),
            style: AppTypography.amountInRow(scheme.onSurface),
          ),
        ],
      ),
    );
  }
}
