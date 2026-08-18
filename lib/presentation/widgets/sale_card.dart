import 'package:flutter/material.dart';

import '../../core/i18n/l10n_ext.dart';
import '../../core/i18n/payment_method_l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/sale.dart';
import '../screens/sales/sale_detail_screen.dart';
import 'method_badge.dart';
import 'smart_amount.dart';
import 'payment_filter.dart' show PaymentMethodAccent, PaymentMethodIcon;
import 'status_chip.dart';

/// Card de venda premium — compartilhado entre a lista de vendas e as
/// vendas recentes do dashboard: forma de pagamento com selo colorido por
/// método (cash/cartão/M-Pesa/E-Mola/transferência), número sequencial,
/// itens, dia/hora inteligente, status "Pago" e valor em destaque.
///
/// Layout COMPACTO em linha única (design system 2026, igual ao app de
/// referência): selo do método à esquerda, identificação no meio e o par
/// (valor + status) ancorado à direita. No desktop/web o hover realça a
/// borda e muda o cursor.
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

 // Linha do feed (estilo Home): transparente dentro da [FeedCard] — o
 // hover (web/desktop) realça o FUNDO com uma tinta do acento; o ripple
 // cobre a linha toda.
 return MouseRegion(
 cursor: SystemMouseCursors.click,
 onEnter: (_) => setState(() => _hovered = true),
 onExit: (_) => setState(() => _hovered = false),
 child: Material(
 color: _hovered
 ? scheme.primary.withValues(alpha: 0.06)
 : Colors.transparent,
 child: InkWell(
 onTap: _onTap ?? () => _openDetails(context),
 child: Padding(
 padding: const EdgeInsets.symmetric(
 horizontal: AppSpacing.md,
 vertical: AppSpacing.sm + 2,
 ),
 child: Row(
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
 // Nome da forma de pagamento COMPLETO — quebra em
 // linhas quando necessário (nada de truncar).
 Text(
 _sale.paymentMethod.labelFor(l10n),
 style: theme.textTheme.titleSmall?.copyWith(
 fontWeight: FontWeight.w600,
 ),
 ),
 const SizedBox(height: 2),
 Text(
 '${Formatters.saleLabel(_sale.number)} · '
 '$itemsLabel',
 style: theme.textTheme.labelSmall?.copyWith(
 color: scheme.onSurfaceVariant,
 ),
 ),
 const SizedBox(height: 2),
 Text(
 // Data inteligente: 'Hoje/Ontem/04/08' + hora.
 '${Formatters.day(_sale.dateTime)} • '
 '${Formatters.time(_sale.dateTime)}',
 style: theme.textTheme.labelSmall?.copyWith(
 color: scheme.outline,
 ),
 ),
 ],
 ),
 ),
 const SizedBox(width: 8),
 // Coluna direita: valor + status, ANCORADA à borda.
 // Align + Flexible: encolhe (ellipsis interno) em telas
 // estreitas com escala alta — nunca estoura o Row.
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
 cents: _sale.totalAmountCents,
 alignment: Alignment.centerRight,
 style: theme.textTheme.bodyMedium?.copyWith(
 fontWeight: FontWeight.w600,
 fontFeatures: const [FontFeature.tabularFigures()],
 ),
 ),
 const SizedBox(height: 4),
 StatusChip(
 label: _sale.status == SaleStatus.cancelled
 ? l10n.salesStatusCancelled
 : l10n.salesStatusPaid,
 color: _sale.status == SaleStatus.cancelled
 ? theme.expense
 : theme.income,
 icon: _sale.status == SaleStatus.cancelled
 ? Icons.block
 : Icons.check_circle_outline,
 ),
 ],
 ),
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
