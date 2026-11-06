import 'package:flutter/material.dart';

import '../../core/i18n/l10n_ext.dart';
import '../../core/i18n/payment_method_l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/sale.dart';
import '../screens/sales/sale_detail_screen.dart';
import 'app_page.dart' show HoverableTile;
import 'focus_ring.dart';
import 'semantics_composed.dart';
import 'payment_filter.dart' show PaymentMethodAccent, PaymentMethodIcon;
import 'status_chip.dart';

/// Linha de venda — superfície única da lista agrupada.
///
/// Layout em duas linhas, com o montante alinhado à direita em TODAS as
/// linhas (tabular figures):
/// - Linha 1: método de pagamento (título) + valor total (destaque)
/// - Linha 2: referência · itens + estado do pagamento
///
/// A linha não desenha caixa própria: quem a hospeda (a lista de Vendas)
/// é a superfície — a separação entre vendas é uma régua de cabelo
/// fornecida pelo [SliverList.separated] do ecrã. Assim a lista lê-se como
/// um painel contínuo e não como uma pilha de cartões.
class SalesCard extends StatefulWidget {
  const SalesCard({
    super.key,
    required this.sale,
    this.onTap,
    this.borderRadius,
  });

  final Sale sale;
  final VoidCallback? onTap;

  /// Raio aplicado ao realce de toque — a primeira e a última linha do
  /// painel recebem os cantos do grupo; as do meio ficam retas.
  final BorderRadius? borderRadius;

  @override
  State<SalesCard> createState() => _SalesCardState();
}

class _SalesCardState extends State<SalesCard> {
  bool _hovered = false;

  /// Foco de teclado físico (Fase 3.3) — alimenta o anel visível.
  bool _focused = false;

  Sale get _sale => widget.sale;
  VoidCallback? get _onTap => widget.onTap;
  BorderRadius get _radius => widget.borderRadius ?? AppRadius.lgAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final accent = _sale.paymentMethod.accent(theme);
    final itemsLabel = l10n.dashboardSaleItems(_sale.items.length);
    final isCancelled = _sale.status == SaleStatus.cancelled;

    // A11y (plano UI/UX — Fase 3.1): a linha inteira é UM nó semântico —
    // "M-Pesa: R$ 4,00, S-00001 · 1 item, Pago" — em vez de método, valor,
    // número, itens e status anunciados como nós separados. Mesma
    // convenção "Tema: valor, extras" dos KPIs do dashboard.
    final semanticLabel = buildComposedLabel([
      '${_sale.paymentMethod.labelFor(l10n)}: '
          '${Formatters.currency(_sale.totalAmountCents)}',
      '${Formatters.saleLabel(_sale.number)} · $itemsLabel',
      isCancelled ? l10n.salesStatusCancelled : l10n.salesStatusPaid,
    ]);

    return HoverableTile(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Material(
          color: _hovered
              ? scheme.surfaceContainerHighest.withValues(alpha: 0.55)
              : Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: _radius),
          child: Stack(
            children: [
              InkWell(
                onTap: _onTap ?? () => _openDetails(context),
                borderRadius: _radius,
                // A11y (Fase 3.3): foco visível para teclado físico/Bluetooth.
                onFocusChange: (f) => setState(() => _focused = f),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                  // DENTRO do InkWell: o toque do card é roteado para o nó
                  // combinado — duplo-toque do leitor ativa a linha inteira.
                  child: Semantics(
                    container: true,
                    excludeSemantics: true,
                    label: semanticLabel,
                    child: Row(
                      children: [
                        // Selo do método: fundo escuro derivado da cor do
                        // provedor + ícone claro (o mesmo padrão do feed).
                        Container(
                          width: 38,
                          height: 38,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: IconTone.darkBackground(accent),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _sale.paymentMethod.icon,
                            size: 18,
                            color: IconTone.lightForeground(accent),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _sale.paymentMethod.labelFor(l10n),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      // Nome/descrição da linha = 14/w400; a
                                      // hierarquia vem do valor à direita.
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // FittedBox scaleDown: com Dynamic Type o
                                  // valor encolhe em vez de estourar a Row.
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        Formatters.currency(
                                          _sale.totalAmountCents,
                                        ),
                                        maxLines: 1,
                                        style: AppTypography.amountInRow(
                                          scheme.onSurface,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${Formatters.saleLabel(_sale.number)}'
                                      ' · $itemsLabel',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: scheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  StatusChip(
                                    label: isCancelled
                                        ? l10n.salesStatusCancelled
                                        : l10n.salesStatusPaid,
                                    color: isCancelled
                                        ? theme.expense
                                        : theme.income,
                                    icon: isCancelled
                                        ? Icons.block
                                        : Icons.check_circle_outline,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              FocusRing(visible: _focused, borderRadius: _radius),
            ],
          ),
        ),
      ),
    );
  }

  /// Abre o detalhe no sheet padrão de eventos (mesmo chrome da Home), em
  /// vez de empurrar uma página inteira por cima da lista.
  void _openDetails(BuildContext context) =>
      showSaleDetailSheet(context, _sale);
}
