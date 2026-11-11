import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
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
import '../../widgets/app_sheet.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/premium_decor.dart';
import '../../widgets/product_type_badge.dart' show productTypeLabel;
import '../../widgets/search_field.dart';

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
  String? _productError;
  String? _yieldError;
  String? _componentsError;

  /// Índice do componente com quantidade inválida (destaque no próprio
  /// campo, em vez de uma mensagem solta no fim da lista).
  int? _quantityErrorIndex;

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
    int? invalidQuantity;
    for (var i = 0; i < _components.length; i++) {
      final draft = _components[i];
      final productId = draft.productId;
      if (productId == null) continue;
      final quantity = Quantity.parse(
        draft.controller.text,
        language: Formatters.currentLanguage,
      );
      if (quantity <= 0) invalidQuantity ??= i;
      items.add(RecipeItem(productId: productId, quantity: quantity));
    }
    final yieldQuantity = Quantity.parse(
      _yieldController.text,
      language: Formatters.currentLanguage,
    );
    final productMissing = widget.initial == null && _productId == null;
    final yieldInvalid = yieldQuantity <= 0;
    final componentsMissing = items.isEmpty;

    // Validação LOCAL e traduzida — as mensagens do caso de uso são textos
    // técnicos em português e não devem chegar ao utilizador de en/fr.
    if (productMissing ||
        yieldInvalid ||
        componentsMissing ||
        invalidQuantity != null) {
      setState(() {
        _productError = productMissing ? l10n.productionProductRequired : null;
        _yieldError = yieldInvalid ? l10n.productionYieldRequired : null;
        _componentsError = componentsMissing
            ? l10n.productionComponentRequired
            : null;
        _quantityErrorIndex = invalidQuantity;
      });
      return;
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
      yieldQuantity: yieldQuantity,
      items: items,
      updatedAt: DateTime.now(),
    );

    setState(() {
      _saving = true;
      _error = null;
      _productError = null;
      _yieldError = null;
      _componentsError = null;
      _quantityErrorIndex = null;
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
    final scheme = theme.colorScheme;
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
              AppSpacing.xl,
              AppSpacing.md,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            children: [
              if (_error != null) ...[
                _InlineAlert(message: _error!),
                const SizedBox(height: AppSpacing.sm),
              ],
              if (producible.isEmpty && widget.initial == null)
                SheetSection(
                  icon: Icons.info_outline,
                  title: l10n.productionNoProducibleTitle,
                  children: [
                    Text(
                      l10n.productionNoProducibleSubtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                )
              else ...[
                SheetSection(
                  icon: Icons.bakery_dining_outlined,
                  title: l10n.productionFinishedProduct,
                  children: [
                    _ProductPickerField(
                      key: const Key('recipe-finished-product'),
                      products: producible,
                      value: _productId,
                      hint: l10n.productionFinishedProduct,
                      icon: Icons.bakery_dining_outlined,
                      errorText: _productError,
                      onChanged: widget.initial == null
                          ? (value) => setState(() {
                              _productId = value;
                              _productError = null;
                              // O acabado não pode ser componente da própria
                              // ficha: limpa a seleção repetida em vez de
                              // deixar o erro chegar do domínio.
                              for (final draft in _components) {
                                if (draft.productId == value) {
                                  draft.productId = null;
                                }
                              }
                            })
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppTextField(
                      controller: _yieldController,
                      label: l10n.productionYieldLabel,
                      errorText: _yieldError,
                      onChanged: (_) {
                        if (_yieldError != null) {
                          setState(() => _yieldError = null);
                        }
                      },
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
                      _ComponentCard(
                        key: ValueKey('recipe-component-$i'),
                        productId: _components[i].productId,
                        controller: _components[i].controller,
                        // Só produtos ativos, sem o acabado e sem os que já
                        // estão noutra linha (exceto a própria linha).
                        products: [
                          for (final product in componentOptions)
                            if (product.id == _components[i].productId ||
                                !selected.contains(product.id))
                              product,
                        ],
                        onChanged: (value) => setState(() {
                          _components[i].productId = value;
                          _componentsError = null;
                        }),
                        quantityError: _quantityErrorIndex == i
                            ? l10n.productionComponentQuantityRequired
                            : null,
                        onQuantityChanged: (_) {
                          if (_quantityErrorIndex == i) {
                            setState(() => _quantityErrorIndex = null);
                          }
                        },
                        onRemove: () => setState(() {
                          _components.removeAt(i).dispose();
                          _quantityErrorIndex = null;
                          if (_components.isEmpty) _componentsError = null;
                        }),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    if (_componentsError != null) ...[
                      Text(
                        _componentsError!,
                        style: AppTypography.bodySmall.copyWith(
                          color: theme.expense,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                    ],
                    AppButton.secondary(
                      label: l10n.productionAddComponent,
                      icon: const Icon(Icons.add, size: AppSizes.iconMd),
                      expanded: true,
                      onPressed: () => setState(() {
                        _components.add(_ComponentDraft());
                        _componentsError = null;
                      }),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Cartão de um componente da ficha — produto + quantidade empilhados.
///
/// Empilhar (em vez de alinhar os dois lado a lado) é o que garante o
/// requisito de zero truncagem: o nome do produto tem a largura toda para
/// quebrar em linhas e a quantidade ganha um campo completo, legível mesmo
/// com escala de texto 2.0 ou ecrã de 360dp.
class _ComponentCard extends StatelessWidget {
  const _ComponentCard({
    super.key,
    required this.productId,
    required this.controller,
    required this.products,
    required this.onChanged,
    required this.onQuantityChanged,
    required this.onRemove,
    this.quantityError,
  });

  final String? productId;
  final TextEditingController controller;
  final List<Product> products;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onQuantityChanged;
  final VoidCallback onRemove;
  final String? quantityError;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: PremiumDecor.hairline(scheme)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ProductPickerField(
                  products: products,
                  value: productId,
                  hint: l10n.productionComponentLabel,
                  icon: Icons.category_outlined,
                  onChanged: onChanged,
                ),
              ),
              const SizedBox(width: AppSpacing.xxs),
              IconButton(
                icon: const Icon(Icons.close, size: AppSizes.iconMd),
                tooltip: l10n.commonDelete,
                onPressed: onRemove,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          AppTextField(
            controller: controller,
            label: l10n.productionQuantityLabel,
            errorText: quantityError,
            onChanged: onQuantityChanged,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
          ),
        ],
      ),
    );
  }
}

/// Campo que abre a sheet de escolha de produto.
///
/// Usa [InputDecorator] (mesma moldura do [AppTextField]) com um [Text]
/// MULTILINHA no conteúdo: nomes longos quebram em linhas em vez de serem
/// cortados com "…". `onChanged` nulo mantém o campo fixo e sem chevron
/// (edição de ficha: o produto acabado não muda).
class _ProductPickerField extends StatelessWidget {
  const _ProductPickerField({
    super.key,
    required this.products,
    required this.value,
    required this.hint,
    required this.icon,
    this.onChanged,
    this.errorText,
  });

  final List<Product> products;
  final String? value;
  final String hint;
  final IconData icon;
  final ValueChanged<String>? onChanged;
  final String? errorText;

  Product? get _selected {
    for (final product in products) {
      if (product.id == value) return product;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selected = _selected;
    final enabled = onChanged != null;

    final field = InputDecorator(
      decoration: InputDecoration(
        errorText: errorText,
        errorMaxLines: 3,
        prefixIcon: Icon(icon, size: AppSizes.iconMd),
        suffixIcon: enabled
            ? Icon(
                Icons.expand_more_rounded,
                size: AppSizes.iconMd,
                color: scheme.onSurfaceVariant,
              )
            : null,
      ),
      child: Text(
        selected?.name ?? hint,
        style: AppTypography.bodyMedium.copyWith(
          color: selected == null ? scheme.onSurfaceVariant : scheme.onSurface,
        ),
      ),
    );

    if (!enabled) return field;
    return Semantics(
      button: true,
      child: InkWell(
        borderRadius: AppRadius.mdAll,
        onTap: () async {
          final picked = await showAppSheet<String>(
            context,
            builder: (_) => _ProductPickerSheet(
              title: hint,
              products: products,
              selectedId: value,
            ),
          );
          if (picked != null) onChanged!(picked);
        },
        child: field,
      ),
    );
  }
}

/// Sheet pesquisável de seleção de produto — devolve o `id` escolhido.
///
/// Cada linha mostra o nome completo (sem `maxLines`) e uma linha de apoio
/// com o papel do produto e o stock atual, na mesma linguagem do PDV.
class _ProductPickerSheet extends StatefulWidget {
  const _ProductPickerSheet({
    required this.title,
    required this.products,
    this.selectedId,
  });

  final String title;
  final List<Product> products;
  final String? selectedId;

  @override
  State<_ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<_ProductPickerSheet> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final query = _query.trim().toLowerCase();
    final results = [
      for (final product in widget.products)
        if (query.isEmpty || product.name.toLowerCase().contains(query))
          product,
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetHeader(title: widget.title),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.sm,
            AppSpacing.xl,
            0,
          ),
          child: SearchField(
            controller: _search,
            onChanged: (value) => setState(() => _query = value),
          ),
        ),
        if (results.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text(
              l10n.commonNoResults,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          )
        else
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xxs,
                AppSpacing.xl,
                AppSpacing.xl,
              ),
              itemCount: results.length,
              separatorBuilder: (context, index) =>
                  Divider(height: 1, color: PremiumDecor.hairline(scheme)),
              itemBuilder: (context, index) {
                final product = results[index];
                final stock = Quantity.format(
                  product.stockQuantity,
                  unitLabel: product.vendaPorFracao ? product.unitLabel : null,
                  language: Formatters.currentLanguage,
                );
                final stockLabel = product.vendaPorFracao
                    ? stock
                    : '$stock ${l10n.commonUnits}';
                final selected = product.id == widget.selectedId;
                return InkWell(
                  onTap: () => Navigator.of(context).pop(product.id),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                      horizontal: AppSpacing.xxs,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: AppTypography.labelLarge.copyWith(
                                  color: scheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.micro),
                              Text(
                                '${productTypeLabel(context, product.type)}'
                                ' · ${l10n.salesStockAvailable(stockLabel)}',
                                style: AppTypography.bodySmall.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (selected) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Icon(
                            Icons.check_circle_rounded,
                            size: AppSizes.iconMd,
                            color: scheme.primary,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

/// Aviso inline da sheet (erro de gravação) — tom de despesa sem peso.
class _InlineAlert extends StatelessWidget {
  const _InlineAlert({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.expense.withValues(alpha: 0.08),
        borderRadius: AppRadius.mdAll,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline,
            size: AppSizes.iconMd,
            color: theme.expense,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(color: theme.expense),
            ),
          ),
        ],
      ),
    );
  }
}
