import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/product_image.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/quantity.dart';
import '../../../domain/entities/product.dart';
import '../../controllers/account_providers.dart';
import '../../controllers/dashboard_providers.dart';
import '../../controllers/products_providers.dart';
import '../../widgets/app_page.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/list_skeleton.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/product_type_badge.dart';
import '../../widgets/semantics_composed.dart';
import 'product_form_sheets.dart';

/// Tela de listagem de produtos — busca local, pull-to-refresh e
/// cadastro via bottom sheet. Consome apenas o estado de
/// [productsProvider] (abstrações do domínio, nunca datasources).
class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  _AdvancedFilters _advanced = const _AdvancedFilters();

  Future<void> _openFilterSheet() async {
    final result = await showAppSheet<_AdvancedFilters>(
      context,
      builder: (_) => _AdvancedFilterSheet(initial: _advanced),
    );
    if (result == null || !mounted) return;
    setState(() => _advanced = result);
  }

  void _clearFilters() {
    setState(() {
      _advanced = const _AdvancedFilters();
    });
  }

  Future<void> _openAddSheet() async {
    await showAppSheet<void>(context, builder: (_) => const AddProductSheet());
    if (!mounted) return;
    ref.invalidate(productsProvider);
    ref.invalidate(dashboardKpisProvider);
  }

  Future<void> _openEditSheet(Product product) async {
    await showAppSheet<void>(
      context,
      builder: (_) => EditProductSheet(product: product),
    );
    if (!mounted) return;
    ref.invalidate(productsProvider);
    ref.invalidate(dashboardKpisProvider);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final productsAsync = ref.watch(productsProvider);
    final l10n = context.l10n;
    // Funcionário comum NÃO cria produto (só vende): o cadastro fica para
    // dono e gerente (matriz de acesso). O servidor também restringe o
    // INSERT (política products_insert via is_my_store do dono/gerente).
    final canManageProducts =
        ref.watch(currentAccessLevelProvider) != UserAccessLevel.employee;

    return AppPage(
      title: l10n.appNavProducts,
      subtitle: l10n.productsHeaderCount(productsAsync.value?.length ?? 0),
      actions: [
        IconButton(
          tooltip: l10n.productsFilterTooltip,
          onPressed: _openFilterSheet,
          icon: const Icon(Icons.tune_rounded),
        ),
      ],
      useSafeArea: false,
      // CTA único: sem produtos, o FAB some — o estado vazio traz o botão
      // de cadastro centralizado (mantendo a regra canManageProducts).
      // FAB CIRCULAR verde (design system 2026 — igual ao app de
      // referência, que mostra apenas o sinal de +).
      floatingActionButton: canManageProducts
          ? FloatingActionButton(
              heroTag: 'fab-products',
              onPressed: _openAddSheet,
              tooltip: l10n.productsAddNew,
              child: const Icon(Icons.add),
            )
          : null,
      body: productsAsync.when(
        loading: () => const ListSkeleton(),
        error: (error, _) => ErrorView(
          message: l10n.productsLoadError,
          details: error.toString(),
          onRetry: () => ref.invalidate(productsProvider),
        ),
        data: (products) {
          if (products.isEmpty) {
            return EmptyState(
              icon: Icons.inventory_2_outlined,
              title: l10n.productsEmptyTitle,
              subtitle: l10n.productsEmptySubtitle,
              actionLabel: canManageProducts ? l10n.productsAddNew : null,
              onAction: canManageProducts ? _openAddSheet : null,
            );
          }

          final q = _advanced.query;
          final isFiltering = _advanced.hasAny;
          final filtered =
              products.where((product) {
                final matchesQuery =
                    q.isEmpty ||
                    product.name.toLowerCase().contains(q) ||
                    product.description.toLowerCase().contains(q) ||
                    product.code.toLowerCase().contains(q);
                final matchesStatus = switch (_advanced.status) {
                  _ProductFilter.all => true,
                  _ProductFilter.lowStock =>
                    product.isActive &&
                        product.stockQuantity <
                            Quantity.lowStockThresholdUnits *
                                Quantity.milliFactor,
                  _ProductFilter.inactive => !product.isActive,
                };
                final matchesStockType =
                    _advanced.stockType == _StockTypeFilter.all ||
                    (_advanced.stockType == _StockTypeFilter.weight &&
                        product.vendaPorFracao) ||
                    (_advanced.stockType == _StockTypeFilter.unit &&
                        !product.vendaPorFracao);
                // Fase 1: filtra pelo tipo estrutural do produto.
                final matchesType =
                    _advanced.type == _ProductTypeFilter.all ||
                    product.type == _advanced.type.value;
                final matchesAvailability =
                    _advanced.availability == _AvailabilityFilter.all ||
                    (_advanced.availability == _AvailabilityFilter.available &&
                        product.stockQuantity > 0 &&
                        product.isActive) ||
                    (_advanced.availability == _AvailabilityFilter.lowStock &&
                        product.isActive &&
                        product.stockQuantity <
                            Quantity.lowStockThresholdUnits *
                                Quantity.milliFactor) ||
                    (_advanced.availability == _AvailabilityFilter.outOfStock &&
                        product.stockQuantity <= 0);
                final matchesPrice =
                    (_advanced.minPriceCents == null ||
                        product.salePriceCents >= _advanced.minPriceCents!) &&
                    (_advanced.maxPriceCents == null ||
                        product.salePriceCents <= _advanced.maxPriceCents!);
                return matchesQuery &&
                    matchesStatus &&
                    matchesStockType &&
                    matchesType &&
                    matchesAvailability &&
                    matchesPrice;
              }).toList()..sort(
                (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
              );

          return RefreshIndicator(
            onRefresh: () => ref.read(productsProvider.notifier).refresh(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (isFiltering)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.pagePaddingForWidth(
                          MediaQuery.sizeOf(context).width,
                        ),
                        4,
                        AppSpacing.pagePaddingForWidth(
                          MediaQuery.sizeOf(context).width,
                        ),
                        0,
                      ),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          l10n.productsFilteredCount(filtered.length),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.filter_alt_off_outlined,
                      title: l10n.productsEmptyFilteredTitle,
                      subtitle: l10n.productsEmptyFilteredSubtitle,
                      actionLabel: l10n.productsClearFilters,
                      onAction: _clearFilters,
                      outlinedAction: true,
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.pagePaddingForWidth(
                        MediaQuery.sizeOf(context).width,
                      ),
                      AppSpacing.md,
                      AppSpacing.pagePaddingForWidth(
                        MediaQuery.sizeOf(context).width,
                      ),
                      // Folga do FAB (o botão flutua sobre a lista).
                      AppSpacing.fabBottomClearance + AppSpacing.md,
                    ),
                    sliver: SliverGrid.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: AppSpacing.md,
                        mainAxisSpacing: AppSpacing.md,
                        childAspectRatio: 0.98,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final product = filtered[index];
                        return _ProductCard(
                          product: product,
                          onTap: canManageProducts
                              ? () => _openEditSheet(product)
                              : null,
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Filtro de estado do produto — usado dentro do sheet avançado.
enum _ProductFilter {
  all,
  lowStock,
  inactive;

  String label(AppLocalizations l10n) => switch (this) {
    _ProductFilter.all => l10n.productsFilterAll,
    _ProductFilter.lowStock => l10n.dashboardLowStock,
    _ProductFilter.inactive => l10n.productsFilterInactive,
  };
}

/// Filtro por TIPO estrutural do produto (Fase 1) — matéria-prima,
/// revenda, produzido, composto, embalagem. `all` não filtra.
enum _ProductTypeFilter {
  all,
  rawMaterial,
  resale,
  manufactured,
  composite,
  packaging;

  String label(AppLocalizations l10n) => switch (this) {
    _ProductTypeFilter.all => l10n.productsFilterAll,
    _ProductTypeFilter.rawMaterial => l10n.productsTypeRawMaterial,
    _ProductTypeFilter.resale => l10n.productsTypeResale,
    _ProductTypeFilter.manufactured => l10n.productsTypeManufactured,
    _ProductTypeFilter.composite => l10n.productsTypeComposite,
    _ProductTypeFilter.packaging => l10n.productsTypePackaging,
  };

  /// Tipo de domínio correspondente (`null` para `all` — não filtra).
  ProductType? get value => switch (this) {
    _ProductTypeFilter.all => null,
    _ProductTypeFilter.rawMaterial => ProductType.rawMaterial,
    _ProductTypeFilter.resale => ProductType.resale,
    _ProductTypeFilter.manufactured => ProductType.manufactured,
    _ProductTypeFilter.composite => ProductType.composite,
    _ProductTypeFilter.packaging => ProductType.packaging,
  };
}

/// Filtros avançados — imutável, copiado no submit.
/// Contém TODOS os filtros da tela (incluindo o antigo filtro rápido).
class _AdvancedFilters {
  const _AdvancedFilters({
    this.query = '',
    this.status = _ProductFilter.all,
    this.stockType = _StockTypeFilter.all,
    this.availability = _AvailabilityFilter.all,
    this.type = _ProductTypeFilter.all,
    this.minPriceCents,
    this.maxPriceCents,
  });

  final String query;
  final _ProductFilter status;
  final _StockTypeFilter stockType;
  final _AvailabilityFilter availability;
  // Fase 1: filtro por tipo estrutural do produto.
  final _ProductTypeFilter type;
  final int? minPriceCents;
  final int? maxPriceCents;

  bool get hasAny =>
      query.isNotEmpty ||
      status != _ProductFilter.all ||
      stockType != _StockTypeFilter.all ||
      availability != _AvailabilityFilter.all ||
      type != _ProductTypeFilter.all ||
      minPriceCents != null ||
      maxPriceCents != null;

  _AdvancedFilters copyWith({
    String? query,
    _ProductFilter? status,
    _StockTypeFilter? stockType,
    _AvailabilityFilter? availability,
    _ProductTypeFilter? type,
    int? minPriceCents,
    int? maxPriceCents,
  }) {
    return _AdvancedFilters(
      query: query ?? this.query,
      status: status ?? this.status,
      stockType: stockType ?? this.stockType,
      availability: availability ?? this.availability,
      type: type ?? this.type,
      minPriceCents: minPriceCents ?? this.minPriceCents,
      maxPriceCents: maxPriceCents ?? this.maxPriceCents,
    );
  }
}

enum _StockTypeFilter { all, weight, unit }

enum _AvailabilityFilter { all, available, lowStock, outOfStock }

/// Chips de filtro (canvas V3): pílulas com rótulo + contagem real — o
/// ativo usa o container verde (primaryContainer), os inativos neutros.
/// Grupo de chips de filtro minimalista — substitui o SegmentedButton
/// para textos longos (ex.: "Peso (kg/g/l/ml)").
class _FilterChipGroup<T> extends StatelessWidget {
  const _FilterChipGroup({
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
    this.icon,
  });

  final List<T> options;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;
  final IconData Function(T)? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final option in options)
          _CompactFilterChip(
            label: labelOf(option),
            isSelected: option == selected,
            color: scheme.primary,
            icon: icon?.call(option),
            onTap: () => onChanged(option),
          ),
      ],
    );
  }
}

class _CompactFilterChip extends StatelessWidget {
  const _CompactFilterChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.14)
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: isSelected
                ? color
                : scheme.outlineVariant.withValues(alpha: 0.5),
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color: isSelected ? color : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              // Filtro = labelMedium (12/w500); selecionado sobe para w600.
              style: theme.textTheme.labelMedium?.copyWith(
                color: isSelected ? color : scheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Filtro avançado de produtos — bottom sheet com todos os filtros
/// centralizados: busca por nome, status, tipo de estoque,
/// disponibilidade e faixa de preço.
class _AdvancedFilterSheet extends ConsumerStatefulWidget {
  const _AdvancedFilterSheet({required this.initial});
  final _AdvancedFilters initial;
  @override
  ConsumerState<_AdvancedFilterSheet> createState() =>
      _AdvancedFilterSheetState();
}

class _AdvancedFilterSheetState extends ConsumerState<_AdvancedFilterSheet> {
  late final TextEditingController _nameController;
  late _ProductFilter _status;
  late _StockTypeFilter _stockType;
  late _AvailabilityFilter _availability;
  late _ProductTypeFilter _type;
  late final TextEditingController _minPriceController;
  late final TextEditingController _maxPriceController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initial.query);
    _status = widget.initial.status;
    _stockType = widget.initial.stockType;
    _availability = widget.initial.availability;
    _type = widget.initial.type;
    _minPriceController = TextEditingController(
      text: widget.initial.minPriceCents != null
          ? Money.toReais(widget.initial.minPriceCents!).toStringAsFixed(2)
          : '',
    );
    _maxPriceController = TextEditingController(
      text: widget.initial.maxPriceCents != null
          ? Money.toReais(widget.initial.maxPriceCents!).toStringAsFixed(2)
          : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  int? _parsePrice(String value) {
    if (value.trim().isEmpty) return null;
    return Money.parse(value);
  }

  void _submit() {
    Navigator.of(context).pop(
      widget.initial.copyWith(
        query: _nameController.text.trim().toLowerCase(),
        status: _status,
        stockType: _stockType,
        availability: _availability,
        type: _type,
        minPriceCents: _parsePrice(_minPriceController.text),
        maxPriceCents: _parsePrice(_maxPriceController.text),
      ),
    );
  }

  void _clear() {
    setState(() {
      _nameController.clear();
      _status = _ProductFilter.all;
      _stockType = _StockTypeFilter.all;
      _availability = _AvailabilityFilter.all;
      _type = _ProductTypeFilter.all;
      _minPriceController.clear();
      _maxPriceController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetHeader(
            title: l10n.productsFilterAdvanced,
            actionLabel: l10n.productsFilterApply,
            onSave: _submit,
            onClose: _clear,
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _nameController,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: l10n.productsSearchHint,
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SheetSection(
                    icon: Icons.inventory_2_outlined,
                    title: l10n.productsSectionStatus,
                    children: [
                      _FilterChipGroup<_ProductFilter>(
                        options: _ProductFilter.values,
                        selected: _status,
                        labelOf: (f) => f.label(l10n),
                        icon: (f) => switch (f) {
                          _ProductFilter.all => Icons.all_inclusive_rounded,
                          _ProductFilter.lowStock =>
                            Icons.warning_amber_rounded,
                          _ProductFilter.inactive =>
                            Icons.visibility_off_outlined,
                        },
                        onChanged: (f) => setState(() => _status = f),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SheetSection(
                    icon: Icons.scale_outlined,
                    title: l10n.productsFilterStockType,
                    children: [
                      _FilterChipGroup<_StockTypeFilter>(
                        options: _StockTypeFilter.values,
                        selected: _stockType,
                        labelOf: (f) => switch (f) {
                          _StockTypeFilter.all =>
                            l10n.productsFilterStockTypeAll,
                          _StockTypeFilter.weight =>
                            l10n.productsFilterStockTypeWeight,
                          _StockTypeFilter.unit =>
                            l10n.productsFilterStockTypeUnit,
                        },
                        icon: (f) => switch (f) {
                          _StockTypeFilter.all => Icons.all_inclusive_rounded,
                          _StockTypeFilter.weight =>
                            Icons.monitor_weight_outlined,
                          _StockTypeFilter.unit => Icons.inventory_2_outlined,
                        },
                        onChanged: (f) => setState(() => _stockType = f),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Fase 1: filtro por TIPO estrutural do produto.
                  SheetSection(
                    icon: Icons.category_outlined,
                    title: l10n.productsFilterType,
                    children: [
                      _FilterChipGroup<_ProductTypeFilter>(
                        options: _ProductTypeFilter.values,
                        selected: _type,
                        labelOf: (f) => f.label(l10n),
                        icon: (f) => switch (f) {
                          _ProductTypeFilter.all => Icons.all_inclusive_rounded,
                          _ProductTypeFilter.rawMaterial => Icons.grain,
                          _ProductTypeFilter.resale =>
                            Icons.storefront_outlined,
                          _ProductTypeFilter.manufactured =>
                            Icons.bakery_dining_outlined,
                          _ProductTypeFilter.composite =>
                            Icons.lunch_dining_outlined,
                          _ProductTypeFilter.packaging =>
                            Icons.inventory_outlined,
                        },
                        onChanged: (f) => setState(() => _type = f),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SheetSection(
                    icon: Icons.warehouse_outlined,
                    title: l10n.productsFilterAvailability,
                    children: [
                      _FilterChipGroup<_AvailabilityFilter>(
                        options: _AvailabilityFilter.values,
                        selected: _availability,
                        labelOf: (f) => switch (f) {
                          _AvailabilityFilter.all => l10n.productsFilterAll,
                          _AvailabilityFilter.available =>
                            l10n.productsFilterAvailable,
                          _AvailabilityFilter.lowStock =>
                            l10n.productsFilterLowStock,
                          _AvailabilityFilter.outOfStock =>
                            l10n.productsFilterOutOfStock,
                        },
                        icon: (f) => switch (f) {
                          _AvailabilityFilter.all =>
                            Icons.all_inclusive_rounded,
                          _AvailabilityFilter.available =>
                            Icons.check_circle_outline,
                          _AvailabilityFilter.lowStock =>
                            Icons.warning_amber_rounded,
                          _AvailabilityFilter.outOfStock =>
                            Icons.remove_circle_outline,
                        },
                        onChanged: (f) => setState(() => _availability = f),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SheetSection(
                    icon: Icons.payments_outlined,
                    title: l10n.productsFilterPriceRange,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              controller: _minPriceController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              label: l10n.productsFilterMinPrice,
                              hintText: '0,00',
                              suffixText: Formatters.currencySymbol,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppTextField(
                              controller: _maxPriceController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              label: l10n.productsFilterMaxPrice,
                              hintText: '0,00',
                              suffixText: Formatters.currencySymbol,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card de produto PROFISSIONAL — grelha de 2 colunas (mestre UI/UX).
///
/// Layout vertical de cartão:
/// - **Foto quadrada** (canto a canto no topo do cartão, raio lg) com
///   sobreposição de selos: tipo estrutural (canto superior esquerdo)
///   e estado inativo/esgotado (canto superior direito).
/// - **Nome** (2 linhas, elipse), **código/descrição** (1 linha).
/// - **Rodapé do cartão**: preço (destaque, `amountInRow`) à esquerda e
///   stock (com ícone e estado) à direita, dentro de `Flexible` +
///   `FittedBox` para não estourar com escala de texto 2.0 (U-03).
///
/// Espaçamento profissional: grelha 2 colunas com `md` (16) de
/// cross/main-axis, padding de página por `pagePaddingForWidth` e
/// folga `fabBottomClearance` em baixo. O cartão inteiro é UM nó
/// semântico com `InkWell` (alvo ≥48, ripple e foco do tema).
class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, this.onTap});

  final Product product;

  /// `null` para funcionário comum (só vende — não edita produtos).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    final lowStock =
        product.stockQuantity <
        Quantity.lowStockThresholdUnits * Quantity.milliFactor;
    final inactive = !product.isActive;
    final outOfStock = product.stockQuantity <= 0;

    final detail = product.code.isEmpty
        ? (product.description.isEmpty ? null : product.description)
        : product.code;

    final stockText =
        '${Quantity.format(product.stockQuantity, unitLabel: product.vendaPorFracao ? product.unitLabel : null, language: Formatters.currentLanguage)}'
        '${product.vendaPorFracao ? '' : ' ${l10n.commonUnits}'}';

    // A11y: o card inteiro é UM nó semântico (mesmo contrato do feed).
    final semanticLabel = buildComposedLabel([
      detail == null ? product.name : '${product.name}: $detail',
      Formatters.currency(product.salePriceCents),
      stockText,
      if (lowStock) l10n.dashboardLowStock,
      if (inactive) l10n.productsInactive,
    ]);

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: semanticLabel,
      child: Material(
        color: scheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.max,
            children: [
              // ── Foto (topo, canto a canto) + selos sobrepostos ──
              Stack(
                children: [
                  ProductImage.fluid(
                    imagePath: product.imagePath,
                    fluidHeight: AppSpacing.huge * 2,
                    radius: AppRadius.lg,
                  ),
                  if (!inactive && product.type != ProductType.resale)
                    Positioned(
                      top: AppSpacing.xs,
                      left: AppSpacing.xs,
                      child: ProductTypeBadge(type: product.type),
                    ),
                  if (inactive || outOfStock)
                    Positioned(
                      top: AppSpacing.xs,
                      right: AppSpacing.xs,
                      child: StatusChip(
                        label: inactive
                            ? l10n.productsInactive
                            : l10n.dashboardLowStock,
                        color: inactive ? scheme.outline : theme.warning,
                        icon: inactive
                            ? Icons.block_outlined
                            : Icons.warning_amber_rounded,
                      ),
                    ),
                ],
              ),
              // ── Corpo: nome + detalhe ──
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  AppSpacing.xs,
                  AppSpacing.sm,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: inactive
                            ? scheme.onSurfaceVariant
                            : scheme.onSurface,
                      ),
                    ),
                    if (detail != null) ...[
                      const SizedBox(height: AppSpacing.micro),
                      Text(
                        detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Spacer(),
              // ── Rodapé: preço (esquerda) + stock (direita) ──
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  AppSpacing.xs,
                  AppSpacing.sm,
                  AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          Formatters.currency(product.salePriceCents),
                          maxLines: 1,
                          style: AppTypography.amountInRow(
                            inactive ? scheme.onSurfaceVariant : scheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              lowStock
                                  ? Icons.warning_amber_rounded
                                  : Icons.inventory_2_outlined,
                              size: AppSizes.iconSm,
                              color: lowStock
                                  ? theme.expense
                                  : scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: AppSpacing.xxs),
                            Text(
                              stockText,
                              maxLines: 1,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: lowStock
                                    ? theme.expense
                                    : scheme.onSurfaceVariant,
                                fontWeight: lowStock
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet de cadastro de produto.
/// Seletor de foto do produto (design minimalista): preview
/// quadrado arredondado + botões de ícone (câmera/galeria/remover) empilhados.
/// [bytes] = foto NOVA escolhida (ainda não enviada); [imagePath] = foto
/// atual persistida (modo edição).
