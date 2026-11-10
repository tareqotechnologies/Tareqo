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
import '../../widgets/premium_decor.dart';
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
  final TextEditingController _searchController = TextEditingController();
  bool _searchOpen = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openFilterSheet() async {
    final result = await showAppSheet<_AdvancedFilters>(
      context,
      builder: (_) => _AdvancedFilterSheet(initial: _advanced),
    );
    if (result == null || !mounted) return;
    setState(() {
      _advanced = result;
      // O sheet também edita a busca — mantém o campo inline em sincronia.
      _searchController.text = result.query;
    });
  }

  void _clearFilters() {
    setState(() {
      _advanced = const _AdvancedFilters();
      _searchController.clear();
      _searchOpen = false;
    });
  }

  void _toggleSearch() {
    if (_searchOpen) {
      _closeSearch();
      return;
    }
    setState(() {
      _searchOpen = true;
      _searchController.text = _advanced.query;
      _searchController.selection = TextSelection.collapsed(
        offset: _searchController.text.length,
      );
    });
  }

  void _closeSearch() {
    setState(() {
      _searchOpen = false;
      _searchController.clear();
      _advanced = _advanced.copyWith(query: '');
    });
  }

  void _onSearchChanged(String value) {
    setState(() {
      _advanced = _advanced.copyWith(query: value.trim().toLowerCase());
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

  /// Busca + filtros avançados + ordenação A-Z — a MESMA lista alimenta o
  /// subtítulo (contagem visível) e as linhas.
  List<Product> _applyFilters(List<Product> products) {
    final q = _advanced.query;
    return products.where((product) {
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
                    Quantity.lowStockThresholdUnits * Quantity.milliFactor,
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
                    Quantity.lowStockThresholdUnits * Quantity.milliFactor) ||
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
      }).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
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

    final isFiltering = _advanced.hasAny;
    final total = productsAsync.value?.length ?? 0;
    // O subtítulo reflete o que está VISÍVEL na lista (não o total) quando
    // há busca/filtros ativos.
    final visibleCount = productsAsync.value == null
        ? total
        : _applyFilters(productsAsync.value!).length;

    return AppPage(
      title: l10n.appNavProducts,
      subtitle: isFiltering
          ? l10n.productsFilteredCount(visibleCount)
          : l10n.productsHeaderCount(total),
      actions: [
        IconButton(
          tooltip: l10n.productsSearchHint,
          onPressed: _toggleSearch,
          icon: const Icon(Icons.search_rounded),
        ),
        IconButton(
          tooltip: l10n.productsFilterTooltip,
          onPressed: _openFilterSheet,
          // Ponto de estado: filtros ativos ficam visíveis sem abrir a sheet.
          icon: Badge(
            isLabelVisible: isFiltering,
            smallSize: 7,
            backgroundColor: theme.colorScheme.primary,
            child: const Icon(Icons.tune_rounded),
          ),
        ),
      ],
      useSafeArea: false,
      // CTA único: sem produtos, o FAB some — o estado vazio traz o botão
      // de cadastro centralizado (mantendo a regra canManageProducts).
      // FAB sólido oficial: laranja #FF6A2A com ícone preto.
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
          if (products.isEmpty && !isFiltering) {
            return EmptyState(
              icon: Icons.inventory_2_outlined,
              title: l10n.productsEmptyTitle,
              subtitle: l10n.productsEmptySubtitle,
              actionLabel: canManageProducts ? l10n.productsAddNew : null,
              onAction: canManageProducts ? _openAddSheet : null,
            );
          }

          final filtered = _applyFilters(products);
          final hPad = AppSpacing.pagePaddingForWidth(
            MediaQuery.sizeOf(context).width,
          );

          return Column(
            children: [
              // Busca inline (abre pela lupa da AppBar): campo discreto e
              // arredondado no topo da lista — o sheet avançado continua a
              // ser a porta dos filtros.
              if (_searchOpen)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    hPad,
                    AppSpacing.xxs,
                    hPad,
                    AppSpacing.xs,
                  ),
                  child: _ProductSearchField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    onClose: _closeSearch,
                  ),
                ),
              // Filtros ativos com resultados: limpeza a um toque, direita.
              if (isFiltering && filtered.isNotEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _clearFilters,
                      icon: const Icon(
                        Icons.filter_alt_off_outlined,
                        size: AppSizes.iconSm,
                      ),
                      label: Text(l10n.productsClearFilters),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.onSurfaceVariant,
                        minimumSize: const Size(0, AppSizes.touchTarget),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        textStyle: AppTypography.labelLarge,
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () =>
                      ref.read(productsProvider.notifier).refresh(),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
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
                            hPad,
                            AppSpacing.xxs,
                            hPad,
                            // Folga do FAB (o botão flutua sobre a lista).
                            AppSpacing.fabBottomClearance + AppSpacing.md,
                          ),
                          sliver: SliverList.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) => Divider(
                              height: 1,
                              thickness: 0.8,
                              // Recuo alinhado ao texto (thumb 52 + 12):
                              // o divisor separa linhas, não a thumbnail.
                              indent: AppSpacing.gigantic,
                              color: PremiumDecor.hairline(theme.colorScheme),
                            ),
                            itemBuilder: (context, index) {
                              final product = filtered[index];
                              return _ProductRow(
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
                ),
              ),
            ],
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

/// Chips de filtro (V4): pílulas com rótulo + ícone — o ativo usa o
/// laranja oficial (tint 14% + aro) com o rótulo em tinta (AA no claro);
/// os inativos ficam neutros. Grupo minimalista que substitui o
/// SegmentedButton para textos longos (ex.: "Peso (kg/g/l/ml)").
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
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.fast,
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
              const SizedBox(width: AppSpacing.xxs),
            ],
            Text(
              label,
              // Filtro = labelMedium (12/w500). O ativo mantém o rótulo em
              // tinta: laranja em texto pequeno não atinge AA no claro — a
              // seleção lê-se pelo tint, aro e ícone.
              style: AppTypography.labelMedium.copyWith(
                color: isSelected ? scheme.onSurface : scheme.onSurfaceVariant,
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
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        size: AppSizes.iconMd,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
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
                  const SizedBox(height: AppSpacing.md),
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
                  const SizedBox(height: AppSpacing.md),
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
                  const SizedBox(height: AppSpacing.md),
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
                  const SizedBox(height: AppSpacing.md),
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
                          const SizedBox(width: AppSpacing.sm),
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

/// Campo de busca inline — abre pela lupa da AppBar, vive acima da lista
/// enquanto activo. Pílula cheia neutra (sem borda em repouso) e aro
/// laranja oficial só com foco; o X limpa e fecha.
class _ProductSearchField extends StatelessWidget {
  const _ProductSearchField({
    required this.controller,
    required this.onChanged,
    required this.onClose,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AppRadius.full);

    return TextField(
      key: const ValueKey('productSearchField'),
      controller: controller,
      autofocus: true,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: AppTypography.bodyMedium.copyWith(color: scheme.onSurface),
      decoration: InputDecoration(
        hintText: context.l10n.productsSearchHint,
        prefixIcon: Icon(
          Icons.search_rounded,
          size: AppSizes.iconMd,
          color: scheme.onSurfaceVariant,
        ),
        suffixIcon: IconButton(
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          onPressed: onClose,
          icon: Icon(
            Icons.close_rounded,
            size: AppSizes.iconMd,
            color: scheme.onSurfaceVariant,
          ),
        ),
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.primary, width: 1.2),
        ),
      ),
    );
  }
}

/// Linha de produto — lista densa estilo iOS (moderna e minimalista):
/// thumbnail 52 → nome + metadados → preço/stock alinhados à direita.
///
/// * Tipo estrutural aparece como TEXTO na linha de metadados (o selo
///   colorido saiu da lista — ruído desnecessário); [ProductType.resale]
///   é omitido por ser o estado comum do varejo.
/// * Inactivo vira [StatusChip] neutro ao lado dos metadados; stock baixo
///   usa `theme.expense` + ícone de aviso (cor de alerta oficial).
/// * Preço em tinta (`onSurface`) — AA no claro e no escuro; laranja
///   fica reservado a acções/destaques.
/// * A linha inteira é UM nó semântico com `InkWell` (alvo ≥48, ripple e
///   foco do tema) e a coluna direita é `FittedBox` para não estourar com
///   escala de texto 2.0 (U-03).
class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.product, this.onTap});

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

    final detail = product.code.isEmpty
        ? (product.description.isEmpty ? null : product.description)
        : product.code;
    final typeLabel = product.type == ProductType.resale
        ? null
        : productTypeLabel(context, product.type);
    // Inactivo explica-se pelo chip; aí o tipo cede o espaço ao detalhe.
    final meta = [if (!inactive) ?typeLabel, ?detail].join(' · ');

    final stockText =
        '${Quantity.format(product.stockQuantity, unitLabel: product.vendaPorFracao ? product.unitLabel : null, language: Formatters.currentLanguage)}'
        '${product.vendaPorFracao ? '' : ' ${l10n.commonUnits}'}';

    // A11y: a linha inteira é UM nó semântico (mesmo contrato do feed).
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
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              children: [
                ProductImage(
                  imagePath: product.imagePath,
                  size: 52,
                  radius: AppRadius.md,
                  iconSize: AppSizes.iconMd,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        // Rótulo de linha em 14/500: a hierarquia vem da
                        // cor, não do peso.
                        style: AppTypography.labelLarge.copyWith(
                          color: inactive
                              ? scheme.onSurfaceVariant
                              : scheme.onSurface,
                        ),
                      ),
                      if (inactive || meta.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.micro),
                        Row(
                          children: [
                            if (inactive) ...[
                              StatusChip(
                                label: l10n.productsInactive,
                                color: scheme.onSurfaceVariant,
                                icon: Icons.block_outlined,
                              ),
                              if (meta.isNotEmpty)
                                const SizedBox(width: AppSpacing.xs),
                            ],
                            if (meta.isNotEmpty)
                              Expanded(
                                child: Text(
                                  meta,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                // Valores à direita — largura fixa + FittedBox: a coluna
                // nunca empurra o texto para fora em ecrãs estreitos.
                SizedBox(
                  width: 108,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          Formatters.currency(product.salePriceCents),
                          maxLines: 1,
                          style: AppTypography.amountInRow(
                            inactive
                                ? scheme.onSurfaceVariant
                                : scheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.micro),
                      FittedBox(
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
                              style: AppTypography.labelSmall.copyWith(
                                color: lowStock
                                    ? theme.expense
                                    : scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
