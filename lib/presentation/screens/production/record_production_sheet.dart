import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/quantity.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/recipe.dart';
import '../../../domain/usecases/process_production_use_case.dart';
import '../../../domain/usecases/update_product_stock_use_case.dart';
import '../../controllers/products_providers.dart';
import '../../controllers/production_providers.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/product_type_badge.dart' show productTypeLabel;

/// Sheet de execução de uma ORDEM de produção a partir de uma ficha técnica
/// (Fase 2): escolhe quantas BASES produzir, mostra o que será consumido e o
/// custo, e confirma — a baixa FIFO dos componentes + o lote do produto
/// acabado acontecem atomicamente no caso de uso / RPC.
class RecordProductionSheet extends ConsumerStatefulWidget {
  const RecordProductionSheet({super.key, required this.recipe});

  final Recipe recipe;

  @override
  ConsumerState<RecordProductionSheet> createState() =>
      _RecordProductionSheetState();
}

class _RecordProductionSheetState extends ConsumerState<RecordProductionSheet> {
  final TextEditingController _basesController = TextEditingController(
    text: '1',
  );
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _basesController.dispose();
    super.dispose();
  }

  int get _bases => int.tryParse(_basesController.text.trim()) ?? 0;

  Future<void> _confirm(
    Product finished,
    Map<String, Product> productsById,
  ) async {
    final l10n = context.l10n;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(processProductionUseCaseProvider)
          .call(
            recipe: widget.recipe,
            finishedProduct: finished,
            components: productsById,
            batches: _bases,
          );
      if (!mounted) return;
      ref.invalidate(productionOrdersProvider);
      ref.invalidate(productsProvider);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.productionSaved)));
    } on InsufficientStockException catch (error) {
      final name = productsById[error.productId]?.name ?? error.productId;
      setState(() => _error = l10n.productionInsufficientProduct(name));
    } on InvalidProductionException catch (error) {
      setState(() => _error = error.message);
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final products = ref.watch(productsProvider).value ?? const <Product>[];
    final productsById = {for (final product in products) product.id: product};
    final finished = productsById[widget.recipe.productId];
    final bases = _bases;
    final produced = widget.recipe.yieldQuantity * (bases < 0 ? 0 : bases);

    var totalCost = 0;
    final rows = <Widget>[];
    for (final item in widget.recipe.items) {
      final component = productsById[item.productId];
      final consumed = item.quantity * (bases < 0 ? 0 : bases);
      if (component != null) {
        totalCost += Quantity.lineTotal(consumed, component.purchasePriceCents);
      }
      final insufficient =
          component != null && consumed > component.stockQuantity;
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  component?.name ?? item.productId,
                  style: AppTypography.bodySmall.copyWith(
                    color: scheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${Quantity.format(consumed, unitLabel: component?.unitLabel, language: Formatters.currentLanguage)}'
                ' / '
                '${Quantity.format(component?.stockQuantity ?? 0, unitLabel: component?.unitLabel, language: Formatters.currentLanguage)}',
                style: AppTypography.bodySmall.copyWith(
                  color: insufficient ? theme.expense : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetHeader(
          title: l10n.productionProduce,
          subtitle: finished?.name,
          onSave: (_saving || finished == null || bases <= 0)
              ? null
              : () => _confirm(finished, productsById),
          actionLabel: l10n.productionConfirm,
          isSaving: _saving,
        ),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.md,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            children: [
              if (_error != null) ...[
                Text(
                  _error!,
                  style: AppTypography.bodySmall.copyWith(color: theme.expense),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              SheetSection(
                icon: Icons.bakery_dining_outlined,
                title: l10n.productionFinishedProduct,
                children: [
                  if (finished != null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            finished.name,
                            style: AppTypography.labelLarge.copyWith(
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          productTypeLabel(context, finished.type),
                          style: AppTypography.bodySmall.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  AppTextField(
                    controller: _basesController,
                    label: l10n.productionBasesLabel,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.productionProduced(
                      Quantity.format(
                        produced,
                        unitLabel: finished?.unitLabel,
                        language: Formatters.currentLanguage,
                      ),
                    ),
                    style: AppTypography.titleMedium.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    l10n.productionCostTotal(Formatters.currency(totalCost)),
                    style: AppTypography.bodySmall.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              SheetSection(
                icon: Icons.category_outlined,
                title: l10n.productionComponents,
                children: rows.isEmpty
                    ? [
                        Text(
                          l10n.productionEmptyTitle,
                          style: AppTypography.bodySmall.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ]
                    : rows,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
