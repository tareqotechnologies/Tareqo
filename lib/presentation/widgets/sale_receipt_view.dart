import 'package:flutter/material.dart';

import '../../core/i18n/l10n_ext.dart';
import '../../core/i18n/payment_method_l10n.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/quantity.dart';
import '../../domain/entities/sale.dart';
import '../../domain/entities/sale_item.dart';
import '../../../core/theme/app_tokens.dart';

/// Recibo de venda VISUAL — a cara de um recibo térmico impresso.
///
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
      // "Papel" do recibo: branco com leve viés quente, como um cupom.
      color: const Color(0xFFFFFEFA),
      padding: const EdgeInsets.fromLTRB(20, AppSpacing.xl, 20, 20),
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
              const SizedBox(height: 2),
              Text(
                storeAddress!,
                textAlign: TextAlign.center,
                style: _mutedStyle,
              ),
            ],
            const SizedBox(height: 12),
            const _DashedDivider(),
          ],
          const SizedBox(height: 12),
          // Título do recibo + identificação da venda.
          Text(
            cancelled
                ? l10n.saleDetailReceiptTitleCancelled
                : l10n.saleDetailReceiptTitle,
            textAlign: TextAlign.center,
            style: _headerStyle,
          ),
          const SizedBox(height: 4),
          Text(
            '${l10n.saleDetailId(Formatters.saleLabel(sale.number))} · '
            '${Formatters.dateTime(sale.dateTime)}',
            textAlign: TextAlign.center,
            style: _mutedStyle,
          ),
          const SizedBox(height: 12),
          const _DashedDivider(),
          const SizedBox(height: 8),
          // Itens: nome + `qtd × unitário = subtotal`.
          for (final item in sale.items) _ReceiptItemRow(item: item),
          const SizedBox(height: 8),
          const _DashedDivider(),
          const SizedBox(height: 12),
          // Total.
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.saleDetailTotal.toUpperCase(),
                  style: _bodyStyle.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                Formatters.currency(sale.totalAmountCents),
                style: _bodyStyle.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
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
            const SizedBox(height: 8),
            Text(
              '${l10n.saleDetailCancelledAt} '
              '${Formatters.dateTime(sale.cancelledAt!)}',
              textAlign: TextAlign.center,
              style: _mutedStyle,
            ),
          ],
          const SizedBox(height: 12),
          const _DashedDivider(),
          const SizedBox(height: 12),
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
  color: Color(0xFF1B1B1B),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  letterSpacing: 1.2,
  height: 1.4,
);

/// Corpo do recibo (total, pagamento, itens) — fonte proporcional com
/// algarismos tabulares, como uma impressora térmica.
final TextStyle _bodyStyle = const TextStyle(
  color: Color(0xFF1B1B1B),
  fontSize: 12,
  height: 1.5,
  fontFeatures: [FontFeature.tabularFigures()],
);

/// Texto secundário (endereço, data, agradecimento).
final TextStyle _mutedStyle = const TextStyle(
  color: Color(0xFF6B6B6B),
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
      padding: const EdgeInsets.symmetric(vertical: 3),
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
                const SizedBox(width: 8),
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
    return CustomPaint(
      size: const Size(double.infinity, 1),
      painter: _DashedLinePainter(color: const Color(0xFF9A9A9A)),
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
