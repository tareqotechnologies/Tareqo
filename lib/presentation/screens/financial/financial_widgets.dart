import 'package:flutter/material.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/financial_transaction.dart';
import '../../widgets/smart_amount.dart';
import '../../widgets/status_chip.dart';

/// Ícone inteligente por direção do movimento: entrada (north_east) em
/// verde e saída (south_west) em vermelho — mesma direção do feed da
/// Home (dinheiro que entra sobe, que sai desce).
extension TransactionDirectionIcon on TransactionType {
 IconData get icon => switch (this) {
 TransactionType.income => Icons.north_east,
 TransactionType.expense => Icons.south_west,
 };
}

/// Card de movimentação premium — direção com ícone semântico, descrição,
/// número amigável + categoria, dia/hora inteligente, status e valor em
/// destaque com sinal e cor. Pendências ganham a ação logo abaixo:
/// "Receber" para entradas (fiado) e "Pagar" para saídas (contas a pagar).
class TransactionCard extends StatelessWidget {
 const TransactionCard({
 super.key,
 required this.transaction,
 this.onReceive,
 this.onPay,
 });

 final FinancialTransaction transaction;

 /// Ação de recebimento para entradas pendentes (null quando não aplicável).
 final VoidCallback? onReceive;

 /// Ação de pagamento para saídas pendentes (null quando não aplicável).
 final VoidCallback? onPay;

 @override
 Widget build(BuildContext context) {
 final theme = Theme.of(context);
 final isIncome = transaction.type == TransactionType.income;
 final color = isIncome ? theme.income : theme.expense;
 final sign = isIncome ? '+' : '-';
 final pending = transaction.status == TransactionStatus.pending;

 // Linha do feed (estilo Home): transparente dentro da [FeedCard] —
 // sem chrome próprio; a folha única entrega o card e as divisórias.
 return Padding(
 padding: const EdgeInsets.symmetric(
 horizontal: AppSpacing.md,
 vertical: AppSpacing.sm + 2,
 ),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Row(
 children: [
 // Ícone circular tintado (estilo feed da Home) — círculo
 // pleno com fundo translúcido na cor da direção.
 Container(
 width: 42,
 height: 42,
 alignment: Alignment.center,
 decoration: BoxDecoration(
 shape: BoxShape.circle,
 color: color.withValues(alpha: 0.14),
 ),
 child: Icon(transaction.type.icon, size: 20, color: color),
 ),
 const SizedBox(width: 12),
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 // Descrição COMPLETA — quebra em linhas quando
 // necessário (nada de truncar textos nos cards).
 Text(
 transaction.description,
 style: theme.textTheme.titleSmall?.copyWith(
 fontWeight: FontWeight.w600,
 ),
 ),
 const SizedBox(height: 2),
 Text(
 // Número amigável (derivado do id) + categoria.
 '${Formatters.entityNumber(transaction.id)} · '
 '${transaction.category}',
 style: theme.textTheme.labelSmall?.copyWith(
 color: theme.colorScheme.onSurfaceVariant,
 ),
 ),
 ],
 ),
 ),
 const SizedBox(width: 8),
 // Coluna direita (estilo Home): valor ANCORADO ao canto,
 // com o chip de status logo abaixo — mesmo padrão do
 // SalesCard. Align + Flexible: encolhe (ellipsis interno)
 // em telas estreitas com escala alta, nunca estoura o Row.
 Flexible(
 child: Align(
 alignment: Alignment.centerRight,
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.end,
 mainAxisSize: MainAxisSize.min,
 children: [
 SmartAmount(
 cents: transaction.amountCents,
 prefix: '$sign ',
 alignment: Alignment.centerRight,
 style: theme.textTheme.bodyMedium?.copyWith(
 fontWeight: FontWeight.w600,
 color: color,
 fontFeatures: const [FontFeature.tabularFigures()],
 ),
 ),
 if (pending) ...[
 const SizedBox(height: 4),
 StatusChip(
 label: context.l10n.statusPending,
 color: theme.warning,
 icon: Icons.schedule,
 ),
 ],
 ],
 ),
 ),
 ),
 ],
 ),
 const SizedBox(height: 12),
 Text(
 // Data inteligente: 'Hoje/Ontem/04/08' + hora, sem repetir a
 // data completa ao lado.
 '${Formatters.day(transaction.date)} • '
 '${Formatters.time(transaction.date)}',
 style: theme.textTheme.bodySmall?.copyWith(
 color: theme.colorScheme.onSurfaceVariant,
 ),
 ),
 // Pendências ganham a ação de quitação logo abaixo: "Receber"
 // para entradas e "Pagar" para saídas — o botão SEMPRE segue a
 // DIREÇÃO do movimento (independente de qual callback chegou).
 if (pending && (onReceive != null || onPay != null)) ...[
 const SizedBox(height: 4),
 Align(
 alignment: Alignment.centerRight,
 child: isIncome
 // Entrada pendente (fiado): receber o valor.
 ? TextButton.icon(
 style: TextButton.styleFrom(
 visualDensity: VisualDensity.compact,
 padding: const EdgeInsets.symmetric(horizontal: 8),
 ),
 onPressed: onReceive,
 icon: const Icon(Icons.done_all, size: 16),
 label: Text(context.l10n.financialReceive),
 )
 // Saída pendente (conta a pagar): quitar o débito.
 : TextButton.icon(
 style: TextButton.styleFrom(
 visualDensity: VisualDensity.compact,
 padding: const EdgeInsets.symmetric(horizontal: 8),
 ),
 onPressed: onPay,
 icon: const Icon(Icons.payments_outlined, size: 16),
 label: Text(context.l10n.financialPay),
 ),
 ),
 ],
 ],
 ),
 );
 }
}
