import 'package:flutter/material.dart';

import '../../core/i18n/l10n_ext.dart';
import '../../core/i18n/payment_method_l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/sale.dart';
import '../screens/sales/sale_detail_screen.dart';
import 'method_badge.dart';
import 'payment_filter.dart' show PaymentMethodAccent, PaymentMethodIcon;
import 'status_chip.dart';

/// Card de venda premium — compartilhado entre a lista de vendas e as
/// vendas recentes do dashboard: forma de pagamento com selo colorido por
/// método (cash/cartão/M-Pesa/E-Mola/transferência), número sequencial,
/// itens, dia/hora inteligente, status "Pago" e valor em destaque.
///
/// Estrutura em duas faixas separadas por um filete fino: a faixa de cima
/// identifica a venda (método + número + status) e a de baixo traz o tempo
/// e o valor. No desktop/web o hover realça a borda e muda o cursor.
class SalesCard extends StatefulWidget {
  const SalesCard({super.key, required this.sale, this.onTap});

  final Sale sale;

  /// Ação ao tocar; quando nula, abre os detalhes da venda (padrão).
  final VoidCallback? onTap;

  @override
  State<SalesCard> createState() => _SalesCardState();
}

class _SalesCardState extends State<SalesCard> {
  /// Hover (web/desktop): realça a borda para sinalizar que o card é tocável.
  bool _hovered = false;

  Sale get _sale => widget.sale;
  VoidCallback? get _onTap => widget.onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    // Cor de destaque da forma de pagamento — identidade visual por método.
    final accent = _sale.paymentMethod.accent(theme);
    final itemsLabel = l10n.dashboardSaleItems(_sale.items.length);

    // Mesmo raio do card do tema (cards compartilhados: Vendas, dashboard).
    final baseShape = theme.cardTheme.shape;
    final radius = baseShape is RoundedRectangleBorder
        ? baseShape.borderRadius
        : BorderRadius.circular(20);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: _hovered
                ? scheme.primary.withValues(alpha: 0.55)
                : (theme.dividerTheme.color ?? scheme.outlineVariant),
          ),
        ),
        child: InkWell(
          onTap: _onTap ?? () => _openDetails(context),
          hoverColor: scheme.primary.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    PaymentMethodBadge(
                      accent: accent,
                      icon: _sale.paymentMethod.icon,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _sale.paymentMethod.labelFor(l10n),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${Formatters.saleLabel(_sale.number)} · '
                            '$itemsLabel',
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
                    // Status "Pago": toda venda é registrada paga (não há
                    // devoluções no ERP) — rótulo derivado, sem modelo novo.
                    // Align + Flexible: o chip fica ANCORADO à direita do
                    // card (não flutuando colado ao texto) e encolhe
                    // (ellipsis interno) em telas estreitas com escala alta.
                    Flexible(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: StatusChip(
                          label: l10n.salesStatusPaid,
                          color: theme.income,
                          icon: Icons.check_circle_outline,
                        ),
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
                    Icon(
                      Icons.schedule,
                      size: 14,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        // Data inteligente: 'Hoje/Ontem/04/08' + hora, sem
                        // repetir a data completa ao lado.
                        '${Formatters.day(_sale.dateTime)} • '
                        '${Formatters.time(_sale.dateTime)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Valor MINIMALISTA (15px Medium, sem bold — regra de
                    // ouro da escala: valores em colunas com peso médio).
                    // FittedBox: valores altos ENCOLHEM para caber — nunca
                    // truncam; o valor completo fica sempre visível.
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          Formatters.currency(_sale.totalAmountCents),
                          maxLines: 1,
                          textAlign: TextAlign.end,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
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
      MaterialPageRoute<void>(
        builder: (_) => SaleDetailScreen(sale: _sale),
      ),
    );
  }
}
