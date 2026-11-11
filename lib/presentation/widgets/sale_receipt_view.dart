import 'package:flutter/material.dart';

import '../../core/i18n/l10n_ext.dart';
import '../../core/i18n/payment_method_l10n.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/quantity.dart';
import '../../domain/entities/sale.dart';
import '../../domain/entities/sale_item.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';

/// Recibo de venda VISUAL — a cara de um recibo térmico impresso.
///
/// Exceção de documento (U-13): cores de papel/tinta fixas, mas a
/// **família tipográfica é a Outfit do app** (antes caía na fonte da
/// plataforma — recibo diferente por Android/iOS).
/// Cores fixas (papel branco + tinta escura), independentes do tema do app:
/// é este widget que vira a IMAGEM partilhada (capturada via
/// `RepaintBoundary`), então precisa parecer um recibo de verdade em
/// qualquer contexto. Conteúdo espelha o [ReceiptText] (partilha por
/// WhatsApp) — cabeçalho do estabelecimento, título, itens com
/// `quantidade × unitário = subtotal`, total, pagamento e agradecimento.
class SaleReceiptView extends StatelessWidget {
  const SaleReceiptView({
    super.key,
    required this.sale,
    this.storeName,
    this.storeAddress,
  });

  final Sale sale;

  /// Nome do estabelecimento (loja) exibido no cabeçalho — opcional: sem
  /// ele o recibo começa direto no título.
  final String? storeName;

  /// Endereço do estabelecimento (opcional, abaixo do nome).
  final String? storeAddress;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cancelled = sale.status == SaleStatus.cancelled;

    return Container(
      // "Papel" do recibo: gelo oficial (sem branco puro).
      color: AppColors.softWhite,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabeçalho do estabelecimento.
          if (storeName != null && storeName!.trim().isNotEmpty) ...[
            Text(
              storeName!.toUpperCase(),
              textAlign: TextAlign.center,
              style: _headerStyle.copyWith(fontSize: 16),
            ),
            if (storeAddress != null && storeAddress!.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.micro),
              Text(
                storeAddress!,
                textAlign: TextAlign.center,
                style: _mutedStyle,
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            const _DashedDivider(),
          ],
          const SizedBox(height: AppSpacing.sm),
          // Título do recibo + identificação da venda.
          Text(
            cancelled
                ? l10n.saleDetailReceiptTitleCancelled
                : l10n.saleDetailReceiptTitle,
            textAlign: TextAlign.center,
            style: _headerStyle,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            '${l10n.saleDetailId(Formatters.saleLabel(sale.number))} · '
            '${Formatters.dateTime(sale.dateTime)}',
            textAlign: TextAlign.center,
            style: _mutedStyle,
          ),
          const SizedBox(height: AppSpacing.sm),
          const _DashedDivider(),
          const SizedBox(height: AppSpacing.xs),
          // Itens: nome + `qtd × unitário = subtotal`.
          for (final item in sale.items) _ReceiptItemRow(item: item),
          const SizedBox(height: AppSpacing.xs),
          const _DashedDivider(),
          const SizedBox(height: AppSpacing.sm),
          // Total.
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.saleDetailTotal.toUpperCase(),
                  style: _bodyStyle.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                Formatters.currency(sale.totalAmountCents),
                style: _bodyStyle.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          // Forma de pagamento.
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.saleDetailReceiptPayment.toUpperCase(),
                  style: _bodyStyle,
                ),
              ),
              Text(sale.paymentMethod.labelFor(l10n), style: _bodyStyle),
            ],
          ),
          if (cancelled && sale.cancelledAt != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${l10n.saleDetailCancelledAt} '
              '${Formatters.dateTime(sale.cancelledAt!)}',
              textAlign: TextAlign.center,
              style: _mutedStyle,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          const _DashedDivider(),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.saleDetailReceiptThanks,
            textAlign: TextAlign.center,
            style: _mutedStyle,
          ),
        ],
      ),
    );
  }
}

/// Título do cabeçalho (estabelecimento / título do recibo).
final TextStyle _headerStyle = const TextStyle(
  fontFamily: AppTypography.family,
  fontFamilyFallback: AppTypography.familyFallback,
  color: AppColors.brandInk,
  fontSize: 12,
  fontWeight: FontWeight.w600,
  letterSpacing: 1.2,
  height: 1.4,
);

/// Corpo do recibo (total, pagamento, itens) — fonte proporcional com
/// algarismos tabulares, como uma impressora térmica.
final TextStyle _bodyStyle = const TextStyle(
  fontFamily: AppTypography.family,
  fontFamilyFallback: AppTypography.familyFallback,
  color: AppColors.brandInk,
  fontSize: 12,
  height: 1.5,
  fontFeatures: [FontFeature.tabularFigures()],
);

/// Texto secundário (endereço, data, agradecimento) — cinza de superfície.
final TextStyle _mutedStyle = const TextStyle(
  fontFamily: AppTypography.family,
  fontFamilyFallback: AppTypography.familyFallback,
  color: AppColors.brandInk,
  fontSize: 12,
  height: 1.5,
);

/// Linha de item do recibo: nome em cima, `quantidade × unitário` e o
/// subtotal à direita — layout do cupom térmico.
class _ReceiptItemRow extends StatelessWidget {
  const _ReceiptItemRow({required this.item});

  final SaleItem item;

  @override
  Widget build(BuildContext context) {
    final subtotal = Quantity.lineTotal(item.quantity, item.unitPriceCents);
    final qty = Quantity.format(
      item.quantity,
      language: Formatters.currentLanguage,
    );
    final unit = Formatters.currency(item.unitPriceCents);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.micro),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.productName, style: _bodyStyle),
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.xs),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '$qty × $unit',
                    style: _mutedStyle,
                    // Quebra em até 2 linhas — a quantidade nunca é cortada.
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  Formatters.currency(subtotal),
                  style: _bodyStyle.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Separador pontilhado — o traço característico do cupom térmico.
class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      size: Size(double.infinity, 1),
      painter: _DashedLinePainter(color: AppColors.surfaceGray),
    );
  }
}

/// Traço LINEAR do cupom térmico — geometria de linha (dash 5 / gap 4),
/// distinta da borda tracejada circular [DashedCirclePainter] usada em
/// ícones: papel do recibo impresso, cores fixas de tinta.
class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const dash = 5.0;
    const gap = 4.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dash, 0), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}
