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

/// Linha de venda no padrão do feed de atividade — ícone circular tinta,
/// título + método/ data à esquerda, valor total à direita.
///
/// Fonte reduzida em relação ao card anterior para maior densidade da lista.
/// A separação entre vendas é feita por uma Divider sutil no [SliverList]
/// do ecrã (ver [SalesScreen]).
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
    final l10n = context.l10n;
    final isCancelled = _sale.status == SaleStatus.cancelled;

    // A11y (plano UI/UX — Fase 3.1): a linha inteira é UM nó semântico.
    final semanticLabel = buildComposedLabel([
      '${_sale.paymentMethod.labelFor(l10n)}: '
          '${Formatters.currency(_sale.totalAmountCents)}',
      '${Formatters.saleLabel(_sale.number)} · ${_sale.items.length} itens',
      isCancelled ? l10n.salesStatusCancelled : l10n.salesStatusPaid,
    ]);

    return HoverableTile(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Material(
          color: _hovered
              ? theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.55,
                )
              : Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: _radius),
          child: Stack(
            children: [
              InkWell(
                onTap: _onTap ?? () => _openDetails(context),
                borderRadius: _radius,
                onFocusChange: (f) => setState(() => _focused = f),
                child: Semantics(
                  container: true,
                  excludeSemantics: true,
                  label: semanticLabel,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        // Ícone circular neutro (tinta + glifo Branco
                        // 100) — padrão do feed.
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: AppColors.darkVoid,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.north_east_rounded,
                            size: 18,
                            color: AppColors.softWhite,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Título: método de pagamento — labelSmall para
                              // reduzir o tamanho da fonte em relação ao card anterior.
                              Text(
                                _sale.paymentMethod.labelFor(l10n),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.labelMedium.copyWith(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.micro),
                              // Referência + data — labelSmall discreto.
                              Text(
                                '${Formatters.saleLabel(_sale.number)} · '
                                '${Formatters.time(_sale.dateTime)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.labelSmall.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        // Total à direita — valor de linha de transação
                        // (15/w500, tabular) em tinta: num histórico de
                        // vendas um total nunca é "ganho/perda", por isso
                        // as cores de alerta ficam fora da linha.
                        Flexible(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              Formatters.currency(_sale.totalAmountCents),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.amountInRow(
                                theme.colorScheme.onSurface,
                              ),
                            ),
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

  /// Abre o detalhe no sheet padrão de eventos (mesmo chrome da Home).
  void _openDetails(BuildContext context) =>
      showSaleDetailSheet(context, _sale);
}
