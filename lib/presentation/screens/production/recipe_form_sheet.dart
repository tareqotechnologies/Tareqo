import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/ids.dart';
import '../../../core/utils/quantity.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/recipe.dart';
import '../../../domain/usecases/production_use_cases.dart';
import '../../controllers/account_providers.dart';
import '../../controllers/auth_providers.dart';
import '../../controllers/products_providers.dart';
import '../../controllers/production_providers.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_picker_field.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/app_text_field.dart';

/// Sheet de criação/edição de uma FICHA TÉCNICA (Fase 2).
///
/// [initial] nulo = nova ficha (o produto acabado é escolhido entre os
/// produtos ATIVOS e PRODUZÍVEIS — `manufactured`/`composite`); preenchido =
/// edição (o produto acabado fica FIXO e só os componentes/rendimento mudam).
class RecipeFormSheet extends ConsumerStatefulWidget {
  const RecipeFormSheet({super.key, this.initial});

  final Recipe? initial;

  @override
  ConsumerState<RecipeFormSheet> createState() => _RecipeFormSheetState();
}

/// Rascunho de um componente na ficha (produto + campo de quantidade).
class _ComponentDraft {
  _ComponentDraft({this.productId, String quantity = ''})
    : controller = TextEditingController(text: quantity);

  String? productId;
  final TextEditingController controller;

  void dispose() => controller.dispose();
}

class _RecipeFormSheetState extends ConsumerState<RecipeFormSheet> {
  late String? _productId = widget.initial?.productId;
  late final TextEditingController _yieldController = TextEditingController(
    text: widget.initial == null
        ? '1'
        : Quantity.format(
            widget.initial!.yieldQuantity,
            language: Formatters.currentLanguage,
          ),
  );
  late final List<_ComponentDraft> _components = [
    if (widget.initial != null)
      for (final item in widget.initial!.items)
        _ComponentDraft(
          productId: item.productId,
          quantity: Quantity.format(
            item.quantity,
            language: Formatters.currentLanguage,
          ),
        )
    else
      _ComponentDraft(),
  ];

  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _yieldController.dispose();
    for (final component in _components) {
      component.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final items = <RecipeItem>[];
    for (final draft in _components) {
      final productId = draft.productId;
      if (productId == null) continue;
      items.add(
        RecipeItem(
          productId: productId,
          quantity: Quantity.parse(
            draft.controller.text,
            language: Formatters.currentLanguage,
          ),
        ),
      );
    }
    final user = ref.read(authStateProvider).value;
    final storeId = user == null
        ? 'st1'
        : (ref.read(activeStoreIdProvider(user.id)) ?? 'st1');
    final base =
        widget.initial ??
        Recipe(
          id: AppIds.newId('recipe'),
          storeId: storeId,
          productId: '',
          yieldQuantity: 0,
          items: const [],
          createdAt: DateTime.now(),
        );
    final recipe = base.copyWith(
      productId: _productId ?? '',
      yieldQuantity: Quantity.parse(
        _yieldController.text,
        language: Formatters.currentLanguage,
      ),
      items: items,
      updatedAt: DateTime.now(),
    );

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(saveRecipeUseCaseProvider).call(recipe);
      if (!mounted) return;
      ref.invalidate(recipesProvider);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.productionRecipeSaved)));
    } on InvalidRecipeException catch (error) {
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
    final products = ref.watch(productsProvider).value ?? const <Product>[];
    // Produtos que podem ser o ACABADO da ficha.
    final producible = [
      for (final product in products)
        if (product.isActive && product.type.isProducible) product,
    ];
    // Componentes possíveis: ativos, exceto o acabado e os já escolhidos.
    final selected = {
      for (final draft in _components)
        if (draft.productId != null) draft.productId!,
    };
    final componentOptions = [
      for (final product in products)
        if (product.isActive && product.id != _productId) product,
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetHeader(
          title: widget.initial == null
              ? l10n.productionNewRecipe
              : l10n.productionRecipeTitle,
          onSave: _saving ? null : _save,
          actionLabel: l10n.commonSave,
          isSaving: _saving,
        ),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xl,
            ),
            children: [
              if (_error != null) ...[
                Text(
                  _error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              if (producible.isEmpty && widget.initial == null)
                SheetSection(
                  icon: Icons.info_outline,
                  title: l10n.productionNoProducibleTitle,
                  children: [
                    Text(
                      l10n.productionNoProducibleSubtitle,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                )
              else
                SheetSection(
                  icon: Icons.bakery_dining_outlined,
                  title: l10n.productionFinishedProduct,
                  children: [
                    AppPickerField<String>(
                      value: _productId,
                      isExpanded: true,
                      hint: l10n.productionFinishedProduct,
                      items: [
                        for (final product in producible)
                          DropdownMenuItem(
                            value: product.id,
                            child: Text(product.name),
                          ),
                      ],
                      onChanged: widget.initial == null
                          ? (value) => setState(() => _productId = value)
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppTextField(
                      controller: _yieldController,
                      label: l10n.productionYieldLabel,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: AppSpacing.md),
              SheetSection(
                icon: Icons.category_outlined,
                title: l10n.productionComponents,
                children: [
                  for (var i = 0; i < _components.length; i++) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AppPickerField<String>(
                            value: _components[i].productId,
                            isExpanded: true,
                            hint: l10n.productionComponentLabel,
                            items: [
                              for (final product in componentOptions)
                                if (product.id == _components[i].productId ||
                                    !selected.contains(product.id))
                                  DropdownMenuItem(
                                    value: product.id,
                                    child: Text(product.name),
                                  ),
                            ],
                            onChanged: (value) => setState(
                              () => _components[i].productId = value,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        SizedBox(
                          width: 96,
                          child: AppTextField(
                            controller: _components[i].controller,
                            hintText: l10n.productionQuantityLabel,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          tooltip: l10n.commonDelete,
                          onPressed: () => setState(() {
                            _components.removeAt(i).dispose();
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                  ],
                  Align(
                    alignment: Alignment.centerLeft,
                    child: AppButton.secondary(
                      label: l10n.productionAddComponent,
                      icon: const Icon(Icons.add, size: 18),
                      onPressed: () =>
                          setState(() => _components.add(_ComponentDraft())),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
