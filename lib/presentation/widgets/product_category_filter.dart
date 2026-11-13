import 'package:flutter/material.dart';

import '../../core/i18n/l10n_ext.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/product_categories.dart';

/// Filtro comum ao catálogo e ao PDV. null = todas; '' = sem categoria.
/// Sem altura fixa: acompanha a escala de texto e mantém alvos de 48dp.
class ProductCategoryFilter extends StatelessWidget {
  const ProductCategoryFilter({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelected,
    this.includeUncategorized = false,
    this.horizontalPadding = 0,
    this.wrap = false,
  });

  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onSelected;
  final bool includeUncategorized;
  final double horizontalPadding;
  final bool wrap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final labels = [...categories];
    // Uma atualização/edição pode remover a última ocorrência da categoria
    // filtrada. Mantém a seleção visível até o usuário limpar/trocar o filtro.
    if (selected != null &&
        selected!.isNotEmpty &&
        !labels.any(
          (label) =>
              normalizeProductCategory(label).toLowerCase() ==
              normalizeProductCategory(selected!).toLowerCase(),
        )) {
      labels.add(selected!);
    }
    final options = <(String?, String)>[
      (null, l10n.productsFilterCategoryAll),
      if (includeUncategorized || selected == '')
        ('', l10n.productsFilterCategoryNone),
      for (final label in labels) (label, label),
    ];
    final chips = [
      for (final (value, label) in options)
        _CategoryChip(
          label: label,
          selected: value == null
              ? selected == null
              : selected != null &&
                    normalizeProductCategory(value).toLowerCase() ==
                        normalizeProductCategory(selected!).toLowerCase(),
          onTap: () => onSelected(value),
        ),
    ];
    if (wrap) {
      return Wrap(
        spacing: AppSpacing.xxs,
        runSpacing: AppSpacing.xxs,
        children: chips,
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Row(
        children: [
          for (var index = 0; index < chips.length; index++) ...[
            if (index > 0) const SizedBox(width: AppSpacing.xxs),
            chips[index],
          ],
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
        child: Material(
          color: selected
              ? scheme.primary.withValues(alpha: 0.14)
              : scheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.full),
            side: BorderSide(
              color: selected ? scheme.primary : scheme.outlineVariant,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppSizes.touchTarget,
                minWidth: AppSizes.touchTarget,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Center(
                  widthFactor: 1,
                  heightFactor: 1,
                  child: Text(
                    label,
                    style: AppTypography.labelMedium.copyWith(
                      color: selected
                          ? scheme.onSurface
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
