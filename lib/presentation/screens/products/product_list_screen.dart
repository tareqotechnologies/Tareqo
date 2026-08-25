import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../widgets/product_image.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/ids.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/quantity.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/usecases/add_product_use_case.dart';
import '../../controllers/account_providers.dart';
import '../../controllers/auth_providers.dart';
import '../../controllers/dashboard_providers.dart';
import '../../controllers/products_providers.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/list_skeleton.dart';
import '../../widgets/smart_amount.dart';
import '../../widgets/status_chip.dart';
import '../../../core/observability/crash_reporting.dart';

/// Tela de listagem de produtos — busca local, pull-to-refresh e
/// cadastro via bottom sheet. Consome apenas o estado de
/// [productsProvider] (abstrações do domínio, nunca datasources).
class ProductListScreen extends ConsumerStatefulWidget {
 const ProductListScreen({super.key});

 @override
 ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {_AdvancedFilters _advanced = const _AdvancedFilters();

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
 builder: (_) => _EditProductSheet(product: product),
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

 return Scaffold(
    appBar: AppBar(
    toolbarHeight: 72,
    titleSpacing: 20,
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.appNavProducts,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w500,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          l10n.productsHeaderCount(productsAsync.value?.length ?? 0),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
    actions: [
      IconButton(
        tooltip: l10n.productsFilterTooltip,
        onPressed: _openFilterSheet,
        icon: const Icon(Icons.tune_rounded),
      ),
    ],
  ),
 // CTA único: sem produtos, o FAB some — o estado vazio traz o botão
 // de cadastro centralizado (mantendo a regra canManageProducts).
 // FAB CIRCULAR verde (design system 2026 — igual ao app de
 // referência, que mostra apenas o sinal de +).
    floatingActionButton:
        canManageProducts
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
 final filtered = products.where((product) {
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
 (_advanced.stockType == _StockTypeFilter.weight && product.vendaPorFracao) ||
 (_advanced.stockType == _StockTypeFilter.unit && !product.vendaPorFracao);
 final matchesAvailability =
 _advanced.availability == _AvailabilityFilter.all ||
 (_advanced.availability == _AvailabilityFilter.available && product.stockQuantity > 0 && product.isActive) ||
 (_advanced.availability == _AvailabilityFilter.lowStock && product.isActive && product.stockQuantity < Quantity.lowStockThresholdUnits * Quantity.milliFactor) ||
 (_advanced.availability == _AvailabilityFilter.outOfStock && product.stockQuantity <= 0);
 final matchesPrice =
 (_advanced.minPriceCents == null || product.salePriceCents >= _advanced.minPriceCents!) &&
 (_advanced.maxPriceCents == null || product.salePriceCents <= _advanced.maxPriceCents!);
 return matchesQuery && matchesStatus && matchesStockType && matchesAvailability && matchesPrice;
 }).toList()
   ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

 return RefreshIndicator(
 onRefresh: () => ref.read(productsProvider.notifier).refresh(),
 child: CustomScrollView(
 physics: const AlwaysScrollableScrollPhysics(),
 slivers: [
 if (isFiltering)
 SliverToBoxAdapter(
   child: Padding(
     padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
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
   padding: const EdgeInsets.fromLTRB(20, 8, 20, 112),
   sliver: SliverList.separated(
     itemCount: filtered.length,
     separatorBuilder: (_, _) => const SizedBox(height: 8),
     itemBuilder: (context, index) {
       final product = filtered[index];
       return _ProductTile(
         product: product,
         onTap: canManageProducts ? () => _openEditSheet(product) : null,
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
}/// Filtro de estado do produto — usado dentro do sheet avançado.
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

/// Filtros avançados — imutável, copiado no submit.
/// Contém TODOS os filtros da tela (incluindo o antigo filtro rápido).
class _AdvancedFilters {
  const _AdvancedFilters({
    this.query = '',
    this.status = _ProductFilter.all,
    this.stockType = _StockTypeFilter.all,
    this.availability = _AvailabilityFilter.all,
    this.minPriceCents,
    this.maxPriceCents,
  });

  final String query;
  final _ProductFilter status;
  final _StockTypeFilter stockType;
  final _AvailabilityFilter availability;
  final int? minPriceCents;
  final int? maxPriceCents;

  bool get hasAny =>
      query.isNotEmpty ||
      status != _ProductFilter.all ||
      stockType != _StockTypeFilter.all ||
      availability != _AvailabilityFilter.all ||
      minPriceCents != null ||
      maxPriceCents != null;

  _AdvancedFilters copyWith({
    String? query,
    _ProductFilter? status,
    _StockTypeFilter? stockType,
    _AvailabilityFilter? availability,
    int? minPriceCents,
    int? maxPriceCents,
  }) {
    return _AdvancedFilters(
      query: query ?? this.query,
      status: status ?? this.status,
      stockType: stockType ?? this.stockType,
      availability: availability ?? this.availability,
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
      spacing: 6,
      runSpacing: 6,
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.14)
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: isSelected ? color : scheme.outlineVariant.withValues(alpha: 0.5),
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: isSelected ? color : scheme.onSurfaceVariant),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 11,
                color: isSelected ? color : scheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
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
  ConsumerState<_AdvancedFilterSheet> createState() => _AdvancedFilterSheetState();
}

class _AdvancedFilterSheetState extends ConsumerState<_AdvancedFilterSheet> {
  late final TextEditingController _nameController;
  late _ProductFilter _status;
  late _StockTypeFilter _stockType;
  late _AvailabilityFilter _availability;
  late final TextEditingController _minPriceController;
  late final TextEditingController _maxPriceController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initial.query);
    _status = widget.initial.status;
    _stockType = widget.initial.stockType;
    _availability = widget.initial.availability;
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
            onSave: _submit,
            onClose: _clear,
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                          _ProductFilter.lowStock => Icons.warning_amber_rounded,
                          _ProductFilter.inactive => Icons.visibility_off_outlined,
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
                          _StockTypeFilter.all => l10n.productsFilterStockTypeAll,
                          _StockTypeFilter.weight => l10n.productsFilterStockTypeWeight,
                          _StockTypeFilter.unit => l10n.productsFilterStockTypeUnit,
                        },
                        icon: (f) => switch (f) {
                          _StockTypeFilter.all => Icons.all_inclusive_rounded,
                          _StockTypeFilter.weight => Icons.monitor_weight_outlined,
                          _StockTypeFilter.unit => Icons.inventory_2_outlined,
                        },
                        onChanged: (f) => setState(() => _stockType = f),
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
                          _AvailabilityFilter.available => l10n.productsFilterAvailable,
                          _AvailabilityFilter.lowStock => l10n.productsFilterLowStock,
                          _AvailabilityFilter.outOfStock => l10n.productsFilterOutOfStock,
                        },
                        icon: (f) => switch (f) {
                          _AvailabilityFilter.all => Icons.all_inclusive_rounded,
                          _AvailabilityFilter.available => Icons.check_circle_outline,
                          _AvailabilityFilter.lowStock => Icons.warning_amber_rounded,
                          _AvailabilityFilter.outOfStock => Icons.remove_circle_outline,
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
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              label: l10n.productsFilterMinPrice,
                              hintText: '0,00',
                              suffixText: 'MT',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: AppTextField(
                              controller: _maxPriceController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              label: l10n.productsFilterMaxPrice,
                              hintText: '0,00',
                              suffixText: 'MT',
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

/// Linha do card de produto (estilo Apple): foto, nome + detalhe à
/// Tile de produto minimalista — estilo Google Apps (inspirado no SalesCard).
///
/// Layout em row: foto do produto (36px) à esquerda, nome + detalhe no
/// centro, preço + estoque à direita. Borda sutil com hover.
class _ProductTile extends StatefulWidget {
  const _ProductTile({required this.product, this.onTap});

  final Product product;

  /// `null` para funcionário comum (só vende — não edita produtos).
  final VoidCallback? onTap;

  @override
  State<_ProductTile> createState() => _ProductTileState();
}

class _ProductTileState extends State<_ProductTile> {
  bool _hovered = false;

  Product get _product => widget.product;
  VoidCallback? get _onTap => widget.onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    final lowStock =
        _product.stockQuantity <
        Quantity.lowStockThresholdUnits * Quantity.milliFactor;
    final inactive = !_product.isActive;

    final detail = _product.code.isEmpty
        ? (_product.description.isEmpty ? null : _product.description)
        : _product.code;

    return MouseRegion(
      cursor: _onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: _hovered
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.6)
            : scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        child: InkWell(
          onTap: _onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            child: Row(
              children: [
                // ── Foto/ícone do produto ──
                ProductImage(
                  imagePath: _product.imagePath,
                  size: 36,
                  radius: 8,
                ),
                const SizedBox(width: 12),
                // ── Coluna central: nome + detalhe + chips ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nome do produto
                      Text(
                        _product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w400,
                          color: inactive ? scheme.onSurfaceVariant : null,
                        ),
                      ),
                      if (detail != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          detail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                      if (inactive) ...[
                        const SizedBox(height: 4),
                        StatusChip(
                          label: l10n.productsInactive,
                          color: scheme.outline,
                          icon: Icons.block_outlined,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // ── Coluna direita: preço + estoque ──
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: SmartAmount(
                        cents: _product.salePriceCents,
                        alignment: Alignment.centerRight,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: inactive ? scheme.onSurfaceVariant : null,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${Quantity.format(_product.stockQuantity, unitLabel: _product.vendaPorFracao ? _product.unitLabel : null, language: Formatters.currentLanguage)}'
                      '${_product.vendaPorFracao ? '' : ' ${l10n.commonUnits}'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: lowStock ? theme.expense : scheme.onSurfaceVariant,
                        fontWeight: lowStock ? FontWeight.w500 : FontWeight.w300,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
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
class _ProductPhotoPicker extends StatelessWidget {
 const _ProductPhotoPicker({
 required this.bytes,
 required this.imagePath,
 required this.onTakePhoto,
 required this.onPickGallery,
 required this.onRemove,
 });

 final Uint8List? bytes;
 final String imagePath;
 final VoidCallback onTakePhoto;
 final VoidCallback onPickGallery;
 final VoidCallback onRemove;

 @override
 Widget build(BuildContext context) {
 final theme = Theme.of(context);
 final l10n = context.l10n;
 final hasImage = bytes != null || imagePath.isNotEmpty;

 final preview = bytes != null
 ? ClipRRect(
 borderRadius: BorderRadius.circular(16),
 child: Image.memory(
 bytes!,
 width: 76,
 height: 76,
 fit: BoxFit.cover,
 ),
 )
 : ProductImage(imagePath: imagePath, size: 76, iconSize: 30);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Preview maior (76) com borda sutil — destaque discreto da foto.
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outlineVariant,
              width: 1,
            ),
          ),
          child: preview,
        ),
        const SizedBox(width: 12),
        // Botões minimalistas: apenas ícones, sem texto — horizontais.
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Câmera
            IconButton(
              onPressed: onTakePhoto,
              icon: const Icon(Icons.photo_camera_outlined, size: 22),
              tooltip: l10n.productsPhotoTake,
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Galeria
            IconButton(
              onPressed: onPickGallery,
              icon: const Icon(Icons.photo_library_outlined, size: 22),
              tooltip: l10n.productsPhotoGallery,
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            if (hasImage) ...[
              const SizedBox(width: 6),
              // Remover
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline, size: 18),
                tooltip: l10n.productsPhotoRemove,
                style: IconButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
 }
}

/// Rótulo de seção do formulário (design system ultra-clean): pequeno
/// rótulo com letter-spacing e o ícone da seção em acento — hierarquia
/// sutil que organiza os campos sem pesar visualmente.
// Estilo minimalista para campos de formulário do produto —
// labels e texto digitado menores, poluição visual reduzida.
const _kFieldStyle = TextStyle(fontSize: 12, height: 1.4);
const _kLabelStyle = TextStyle(fontSize: 11, fontWeight: FontWeight.w400);
const _kFloatingLabelStyle = TextStyle(fontSize: 11, fontWeight: FontWeight.w500);
const _kHintStyle = TextStyle(fontSize: 11);

class _SectionLabel extends StatelessWidget {
 const _SectionLabel({required this.icon, required this.title});

 final IconData icon;  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        // Capitalização NATURAL (nunca caixa alta): rótulos de seção
        // legíveis, sem o grito visual de letras maiúsculas.
        // FittedBox: encolhe em vez de estourar em telas estreitas.
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              maxLines: 1,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class AddProductSheet extends ConsumerStatefulWidget {
 const AddProductSheet({super.key});

 @override
 ConsumerState<AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends ConsumerState<AddProductSheet> {
 final _formKey = GlobalKey<FormState>();
 final _nameController = TextEditingController();
 final _descriptionController = TextEditingController();
 final _purchasePriceController = TextEditingController();
 final _salePriceController = TextEditingController();
 final _stockController = TextEditingController();
 // W11: código de barras/PLU (5 dígitos, opcional) — usado pelas balanças
 // etiquetadoras (formato 20PPPPPWWWWW) e pelo campo do PDV.
 final _codeController = TextEditingController();

 // W11: venda por PESO (fração) + unidade de venda (kg, g, l, ml...).
 bool _vendaPorFracao = false;
 String _unitLabel = 'un';

 // W11: validade opcional do produto — o lote inicial do estoque de
 // abertura nasce com ela e o dashboard alerta quando está para expirar.
 DateTime? _expiryDate;

 // Foto do produto: bytes da foto NOVA escolhida (câmera/galeria) —
 // enviada ao storage no submit; `null` = nenhuma foto nova.
 Uint8List? _imageBytes;

 bool _isSubmitting = false;
 String? _formError;

 @override
 void dispose() {
 _nameController.dispose();
 _descriptionController.dispose();
 _purchasePriceController.dispose();
 _salePriceController.dispose();
 _stockController.dispose();
 _codeController.dispose();
 super.dispose();
 }

 /// Captura/pick de foto (câmera ou galeria) — comprimida na origem
 /// (1024px, JPEG 80) para uploads leves.
 Future<void> _pickPhoto(ImageSource source) async {
 final picked = await ImagePicker().pickImage(
 source: source,
 maxWidth: 1024,
 maxHeight: 1024,
 imageQuality: 80,
 );
 if (picked == null || !mounted) return;
 final bytes = await picked.readAsBytes();
 if (!mounted) return;
 setState(() => _imageBytes = bytes);
 }

 // Interpreta o preço digitado como CENTAVOS inteiros (W4).
 int _parsePrice(String value) => Money.parse(value);

 /// Abre o seletor de data de validade do produto (lote inicial W11).
 Future<void> _pickExpiry() async {
 final l10n = context.l10n;
 final now = DateTime.now();
 final picked = await showDatePicker(
 context: context,
 initialDate: _expiryDate ?? now.add(const Duration(days: 30)),
 firstDate: now,
 lastDate: now.add(const Duration(days: 3650)),
 helpText: l10n.productsExpiryHelp,
 );
 if (picked == null || !mounted) return;
 setState(() => _expiryDate = picked);
 }

 /// Remove a validade definida (produto não perecível).
 void _clearExpiry() {
 setState(() => _expiryDate = null);
 }

 Future<void> _submit() async {
 if (!_formKey.currentState!.validate()) return;

 setState(() {
 _isSubmitting = true;
 _formError = null;
 });

 final purchasePriceCents = _parsePrice(_purchasePriceController.text);
 final salePriceCents = _parsePrice(_salePriceController.text);
 // W11: estoque digitado em UNIDADES (ou kg) → MILÉSIMOS.
 final stockMilli = Quantity.parse(_stockController.text.trim());

 // O produto pertence à loja ativa (cada loja tem seu próprio estoque).
 final user = ref.read(authStateProvider).value;
 final storeId = user == null
 ? null
 : ref.read(activeStoreIdProvider(user.id));

 final l10n = context.l10n;

 // Foto: sobe a imagem (se houver) ANTES de persistir o produto e
 // guarda a referência (URL/caminho) em Product.imagePath.
 //
 // A foto é OPCIONAL — se o upload falhar (ex.: storage sem permissão
 // no servidor), o produto é salvo mesmo assim com aviso, em vez de
 // bloquear o cadastro inteiro (regressão 403 RLS no live).
 var uploadedImagePath = '';
 var photoFailed = false;
 try {
 final productId = AppIds.newId('p');
 final effectiveStoreId = storeId ?? 'st1';
 final bytes = _imageBytes;
 if (bytes != null) {
 try {
 uploadedImagePath = await ref
 .read(productImageStoreProvider)
 .saveImage(
 productId: productId,
 storeId: effectiveStoreId,
 bytes: bytes,
 );
 } catch (error, stackTrace) {
 photoFailed = true;
 CrashReporting.capture(
 error,
 stackTrace,
 hint: 'Foto não enviada ao adicionar produto',
 );
 }
 }

 await ref
 .read(addProductUseCaseProvider)
 .call(
 Product(
 id: productId,
 storeId: effectiveStoreId,
 name: _nameController.text.trim(),
 description: _descriptionController.text.trim(),
 imagePath: uploadedImagePath,
 purchasePriceCents: purchasePriceCents,
 salePriceCents: salePriceCents,
 stockQuantity: stockMilli,
 code: _codeController.text.trim(),
 vendaPorFracao: _vendaPorFracao,
 unitLabel: _unitLabel,
 ),
 // W11: validade opcional do lote inicial (alimenta os alertas
 // de validade do dashboard: vermelho = vencido, amarelo =
 // vence em menos de 30 dias).
 expiryDate: _expiryDate,
 );
 if (!mounted) return;
 Navigator.of(context).pop();
 ScaffoldMessenger.of(context).showSnackBar(
 SnackBar(
 content: Text(
 photoFailed ? l10n.productsAddedNoPhoto : l10n.productsAdded,
 ),
 ),
 );
 } on InvalidPriceException catch (error) {
 setState(() => _formError = error.message);
 } catch (error, stackTrace) {
 // Upload feito mas o produto não persistiu → remove a foto órfã
 // (best-effort — nunca deixa imagem sem produto no storage).
 if (uploadedImagePath.isNotEmpty) {
 unawaited(
 ref.read(productImageStoreProvider).deleteImage(uploadedImagePath),
 );
 }
 CrashReporting.capture(
 error,
 stackTrace,
 hint: 'Erro ao adicionar produto',
 );
 setState(() => _formError = l10n.productsAddError);
 } finally {
 if (mounted) setState(() => _isSubmitting = false);
 }
 }

 @override
 Widget build(BuildContext context) {
 final theme = Theme.of(context);
 final l10n = context.l10n;

 return ConstrainedBox(
 constraints: BoxConstraints(
 maxHeight: MediaQuery.sizeOf(context).height * 0.88,
 ),
 child: SingleChildScrollView(
 padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
 child: Form(
 key: _formKey,
 child: Column(
 mainAxisSize: MainAxisSize.min,
 crossAxisAlignment: CrossAxisAlignment.stretch,
 children: [
 AppSheetHeader(title: l10n.productsAddNew),
 // FOTO — seção própria no topo (preview + câmera/galeria).
 const SizedBox(height: 16),
 _ProductPhotoPicker(
 bytes: _imageBytes,
 imagePath: '',
 onTakePhoto: () => _pickPhoto(ImageSource.camera),
 onPickGallery: () => _pickPhoto(ImageSource.gallery),
 onRemove: () => setState(() => _imageBytes = null),
 ),
 const SizedBox(height: 24),
 // INFORMAÇÕES — identidade do produto.
 _SectionLabel(
 icon: Icons.inventory_2_outlined,
 title: l10n.productsSectionInfo,
 ),
 const SizedBox(height: 10),      AppTextField(
        controller: _nameController,
        textInputAction: TextInputAction.next,
        label: l10n.loginNameLabel,
        prefixIcon: Icons.inventory_2_outlined,
        style: _kFieldStyle,
        labelStyle: _kLabelStyle,
        floatingLabelStyle: _kFloatingLabelStyle,
        decorationHintStyle: _kHintStyle,
        isDense: true,
        validator: (value) => (value == null || value.trim().isEmpty)
            ? l10n.productsNameError
            : null,
      ),
      const SizedBox(height: 8),
      AppTextField(
        controller: _descriptionController,
        textInputAction: TextInputAction.next,
        label: l10n.productsDescriptionLabel,
        prefixIcon: Icons.notes_outlined,
        style: _kFieldStyle,
        labelStyle: _kLabelStyle,
        floatingLabelStyle: _kFloatingLabelStyle,
        decorationHintStyle: _kHintStyle,
        isDense: true,
      ),
      const SizedBox(height: 8),
      // W11: código de barras/PLU — usado pelas balanças
      // etiquetadoras (20PPPPPWWWWW) e pelo campo do PDV.
      AppTextField(
        controller: _codeController,
        textInputAction: TextInputAction.next,
        keyboardType: TextInputType.number,
        maxLength: 5,
        label: l10n.productsCodeLabel,
        helperText: l10n.productsCodeHint,
        prefixIcon: Icons.qr_code_2_outlined,
        style: _kFieldStyle,
        labelStyle: _kLabelStyle,
        floatingLabelStyle: _kFloatingLabelStyle,
        decorationHintStyle: _kHintStyle,
        isDense: true,
        validator: (value) {
          final digits = value?.trim() ?? '';
          if (digits.isNotEmpty &&
              !RegExp(r'^\d{1,5}$').hasMatch(digits)) {
            return l10n.productsCodeError;
          }
          return null;
        },
      ),
      const SizedBox(height: 16),
      // PREÇOS — compra e venda lado a lado.
      _SectionLabel(
        icon: Icons.payments_outlined,
        title: l10n.productsSectionPricing,
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: AppTextField(
              controller: _purchasePriceController,
              keyboardType: TextInputType.number,
              label: l10n.productsPurchasePrice,
              style: _kFieldStyle,
              labelStyle: _kLabelStyle,
              floatingLabelStyle: _kFloatingLabelStyle,
              decorationHintStyle: _kHintStyle,
              isDense: true,
              validator: (value) => _parsePrice(value ?? '') <= 0
                  ? l10n.productsPurchasePriceError
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AppTextField(
              controller: _salePriceController,
              keyboardType: TextInputType.number,
              label: l10n.productsSalePrice,
              style: _kFieldStyle,
              labelStyle: _kLabelStyle,
              floatingLabelStyle: _kFloatingLabelStyle,
              decorationHintStyle: _kHintStyle,
              isDense: true,
              validator: (value) => _parsePrice(value ?? '') <= 0
                  ? l10n.productsSalePriceError
                  : null,
            ),
          ),
        ],
      ),

      const SizedBox(height: 16),
      // ESTOQUE — quantidade + validade + venda por peso.
      _SectionLabel(
        icon: Icons.warehouse_outlined,
        title: l10n.productsSectionStock,
      ),
      const SizedBox(height: 8),
      AppTextField(
        controller: _stockController,
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
        ),
        label: l10n.productsStockQuantity,
        helperText: _vendaPorFracao
            ? l10n.productsStockWeightHint
            : null,
        prefixIcon: Icons.warehouse_outlined,
        style: _kFieldStyle,
        labelStyle: _kLabelStyle,
        floatingLabelStyle: _kFloatingLabelStyle,
        decorationHintStyle: _kHintStyle,
        isDense: true,
        validator: (value) {
 // W11: aceita decimais (ex.: 1,75) — convertido para
 // milésimos no submit; rejeita texto/números negativos.
 final quantity = Quantity.parse(value?.trim() ?? '');
 if (quantity < 0 ||
 (value != null &&
 value.trim().isNotEmpty &&
 quantity == 0)) {
 return l10n.productsStockError;
 }
 return null;
 },
 ),
 const SizedBox(height: 4),
 // W11: validade opcional — o lote inicial do estoque de
 // abertura nasce com ela; o dashboard alerta (vermelho =
 // vencido; amarelo = vence em < 30 dias) quando expira.
 // Seletor MINIMALISTA: um único campo no padrão dos demais
 // inputs (borda sutil + ícone), sem botão largo separado.
 _ExpiryField(
 expiryDate: _expiryDate,
 onPick: _pickExpiry,
 onClear: _clearExpiry,
 ),
 const SizedBox(height: 4),
 // W11: venda por PESO (fração) — o PDV passa a aceitar
 // quantidades decimais e o código de barras de balança.
 // Material explícito: o SwitchListTile pinta o fundo e o ink no
 // Material ancestral; dentro do Container colorido do app_sheet
 // (DecoratedBox) o Flutter emite a assertion "ListTile
 // background color or ink splashes may be invisible" (mesmo
 // padrão já usado no add_transaction_sheet).
 Material(
 type: MaterialType.transparency,
 child: SwitchListTile(
 contentPadding: EdgeInsets.zero,
 title: Text(l10n.productsWeighLabel),
 subtitle: Text(l10n.productsWeighHint),
 value: _vendaPorFracao,
 onChanged: (value) => setState(() {
 _vendaPorFracao = value;
 // W11: ao alternar, a unidade volta a um valor VÁLIDO da
 // lista do dropdown (kg/g/l/ml). Se ficasse 'un' (padrão
 // de unidade), o DropdownButtonFormField renderizaria com
 // um valor fora dos itens e lançaria a asserção "exactly
 // one item with value 'un'" — crash em produção.
 _unitLabel = value ? 'kg' : 'un';
 }),
 ),
 ),
 if (_vendaPorFracao) ...[DropdownButtonFormField<String>(
                  initialValue: _unitLabel,
                  decoration: InputDecoration(
                    labelText: l10n.productsUnitLabel,
                    prefixIcon: const Icon(Icons.scale_outlined),
                  ),
                  items: [
                    for (final unit in const ['kg', 'g', 'l', 'ml'])
                      DropdownMenuItem(value: unit, child: Text(unit)),
                  ],
                  onChanged: (value) =>
                      setState(() => _unitLabel = value ?? 'kg'),
                ),
              ],
              if (_formError != null) ...[
                const SizedBox(height: 14),
                Text(
                  _formError!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              AppButton.primary(
                label: l10n.productsAddSubmit,
 onPressed: _isSubmitting ? null : _submit,
 icon: _isSubmitting
 ? const SizedBox(
 height: 20,
 width: 20,
 child: CircularProgressIndicator(strokeWidth: 2),
 )
 : null,
 ),
 ],
 ),
 ),
 ),
 );
 }
}

/// Bottom sheet de EDIÇÃO de produto — dono/gerente altera nome,
/// descrição, código/PLU, preços, venda por peso, estoque (AJUSTE MANUAL:
/// cria/consome lotes FIFO) e o status ativo (desativar tira o produto do
/// PDV e das compras; o estoque é preservado para a reativação).
class _EditProductSheet extends ConsumerStatefulWidget {
 const _EditProductSheet({required this.product});

 final Product product;

 @override
 ConsumerState<_EditProductSheet> createState() => _EditProductSheetState();
}

class _EditProductSheetState extends ConsumerState<_EditProductSheet> {
 final _formKey = GlobalKey<FormState>();
 late final TextEditingController _nameController;
 late final TextEditingController _descriptionController;
 late final TextEditingController _purchasePriceController;
 late final TextEditingController _salePriceController;
 late final TextEditingController _stockController;
 late final TextEditingController _codeController;

 late bool _vendaPorFracao;
 late String _unitLabel;
 late bool _isActive;

 // Foto do produto: bytes da foto NOVA escolhida, referência ATUAL
 // persistida e referência de uma foto REMOVIDA (apagada no submit).
 Uint8List? _imageBytes;
 late String _imagePath = widget.product.imagePath;
 String _removedImagePath = '';

 bool _isSubmitting = false;
 String? _formError;

 Product get _product => widget.product;

 @override
 void initState() {
 super.initState();
 // Pré-preenche com os valores atuais (a edição nunca parte em branco).
 _nameController = TextEditingController(text: _product.name);
 _descriptionController = TextEditingController(text: _product.description);
 // Pré-preenche com o valor SEM símbolo ("13.90") — o Money.parse
 // aceita vírgula ou ponto, então o texto volta ao banco como centavos.
 _purchasePriceController = TextEditingController(
 text: Money.toReais(_product.purchasePriceCents).toStringAsFixed(2),
 );
 _salePriceController = TextEditingController(
 text: Money.toReais(_product.salePriceCents).toStringAsFixed(2),
 );
 _stockController = TextEditingController(
 text: Quantity.format(
 _product.stockQuantity,
 unitLabel: _product.vendaPorFracao ? _product.unitLabel : null,
 language: Formatters.currentLanguage,
 ).split(' ').first,
 );
 _codeController = TextEditingController(text: _product.code);
 _vendaPorFracao = _product.vendaPorFracao;
 _unitLabel = _product.vendaPorFracao ? _product.unitLabel : 'un';
 _isActive = _product.isActive;
 }

 @override
 void dispose() {
 _nameController.dispose();
 _descriptionController.dispose();
 _purchasePriceController.dispose();
 _salePriceController.dispose();
 _stockController.dispose();
 _codeController.dispose();
 super.dispose();
 }

 // Interpreta o preço digitado como CENTAVOS inteiros (W4).
 int _parsePrice(String value) => Money.parse(value);

 /// Captura/pick de foto (câmera ou galeria) — comprimida na origem
 /// (1024px, JPEG 80) para uploads leves.
 Future<void> _pickPhoto(ImageSource source) async {
 final picked = await ImagePicker().pickImage(
 source: source,
 maxWidth: 1024,
 maxHeight: 1024,
 imageQuality: 80,
 );
 if (picked == null || !mounted) return;
 final bytes = await picked.readAsBytes();
 if (!mounted) return;
 setState(() => _imageBytes = bytes);
 }

 /// Remove a foto: anota a referência atual para apagar no submit e
 /// limpa preview/estado.
 void _removePhoto() {
 setState(() {
 _removedImagePath = _imagePath;
 _imagePath = '';
 _imageBytes = null;
 });
 }

 Future<void> _submit() async {
 if (!_formKey.currentState!.validate()) return;

 setState(() {
 _isSubmitting = true;
 _formError = null;
 });

 final l10n = context.l10n;

 // Foto: sobe a imagem NOVA (se houver) ANTES de persistir; apaga a
 // imagem REMOVIDA (best-effort). O objeto/arquivo tem o MESMO caminho
 // por produto, então substituir não deixa órfão.
 //
 // A foto é OPCIONAL — se o upload falhar (ex.: storage sem permissão
 // no servidor), o produto é salvo mesmo assim com aviso, em vez de
 // bloquear a edição inteira (regressão 403 RLS no live).
 var uploadedImagePath = '';
 var photoFailed = false;
 try {
 final store = ref.read(productImageStoreProvider);
 final bytes = _imageBytes;
 final String imagePath;
 if (bytes != null) {
 try {
 uploadedImagePath = await store.saveImage(
 productId: _product.id,
 storeId: _product.storeId,
 bytes: bytes,
 );
 } catch (error, stackTrace) {
 photoFailed = true;
 CrashReporting.capture(
 error,
 stackTrace,
 hint: 'Foto não enviada ao editar produto',
 );
 }
 if (uploadedImagePath.isNotEmpty &&
 _removedImagePath.isNotEmpty &&
 _removedImagePath != uploadedImagePath) {
 unawaited(store.deleteImage(_removedImagePath));
 }
 // Falhou o upload → mantém a foto ATUAL (não apaga a existente);
 // a edição segue sem foto nova, com aviso no snackbar.
 imagePath = photoFailed && _imagePath.isNotEmpty
 ? _imagePath
 : uploadedImagePath;
 } else if (_removedImagePath.isNotEmpty) {
 unawaited(store.deleteImage(_removedImagePath));
 imagePath = '';
 } else {
 imagePath = _imagePath;
 }

 final useCase = ref.read(updateProductUseCaseProvider);
 final updated = _product.copyWith(
 name: _nameController.text.trim(),
 description: _descriptionController.text.trim(),
 imagePath: imagePath,
 purchasePriceCents: _parsePrice(_purchasePriceController.text),
 salePriceCents: _parsePrice(_salePriceController.text),
 code: _codeController.text.trim(),
 vendaPorFracao: _vendaPorFracao,
 unitLabel: _unitLabel,
 isActive: _isActive,
 );

 // 1) Campos do catálogo (nome/preços/código/fração/status ativo) —
 // o estoque NÃO entra neste update (invariante stock = Σ lotes).
 await useCase.updateDetails(updated);

 // 2) Ajuste MANUAL do estoque (apenas se o valor mudou): define a
 // quantidade exata criando/consumindo lotes FIFO na mesma transação.
 final stockMilli = Quantity.parse(_stockController.text.trim());
 if (stockMilli != _product.stockQuantity) {
 await useCase.adjustStock(
 _product.id,
 stockMilli,
 storeId: _product.storeId,
 );
 }

 if (!mounted) return;
 Navigator.of(context).pop();
 ScaffoldMessenger.of(context).showSnackBar(
 SnackBar(
 content: Text(
 photoFailed
 ? l10n.productsEditSavedNoPhoto
 : l10n.productsEditSaved,
 ),
 ),
 );
 } on InvalidPriceException catch (error) {
 setState(() => _formError = error.message);
 } catch (error, stackTrace) {
 // Upload feito mas o produto não persistiu → remove a foto órfã
 // (best-effort — nunca deixa imagem sem produto no storage).
 if (uploadedImagePath.isNotEmpty) {
 unawaited(
 ref.read(productImageStoreProvider).deleteImage(uploadedImagePath),
 );
 }
 CrashReporting.capture(error, stackTrace, hint: 'Erro ao editar produto');
 setState(() => _formError = l10n.productsEditError);
 } finally {
 if (mounted) setState(() => _isSubmitting = false);
 }
 }

 @override
 Widget build(BuildContext context) {
 final theme = Theme.of(context);
 final l10n = context.l10n;

 return ConstrainedBox(
 constraints: BoxConstraints(
 maxHeight: MediaQuery.sizeOf(context).height * 0.9,
 ),
 child: SingleChildScrollView(
 padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
 child: Form(
 key: _formKey,
 child: Column(
 mainAxisSize: MainAxisSize.min,
 crossAxisAlignment: CrossAxisAlignment.stretch,
 children: [
 AppSheetHeader(title: l10n.productsEditTitle),
 // FOTO — seção própria no topo (preview + câmera/galeria).
 const SizedBox(height: 16),
 _ProductPhotoPicker(
 bytes: _imageBytes,
 imagePath: _imagePath,
 onTakePhoto: () => _pickPhoto(ImageSource.camera),
 onPickGallery: () => _pickPhoto(ImageSource.gallery),
 onRemove: _removePhoto,
 ),
 const SizedBox(height: 24),
 // INFORMAÇÕES — identidade do produto.
 _SectionLabel(
 icon: Icons.inventory_2_outlined,
 title: l10n.productsSectionInfo,
 ),
 const SizedBox(height: 10),      AppTextField(
        controller: _nameController,
        textInputAction: TextInputAction.next,
        label: l10n.loginNameLabel,
        prefixIcon: Icons.inventory_2_outlined,
        style: _kFieldStyle,
        labelStyle: _kLabelStyle,
        floatingLabelStyle: _kFloatingLabelStyle,
        decorationHintStyle: _kHintStyle,
        isDense: true,
        validator: (value) => (value == null || value.trim().isEmpty)
            ? l10n.productsNameError
            : null,
      ),
      const SizedBox(height: 8),
      AppTextField(
        controller: _descriptionController,
        textInputAction: TextInputAction.next,
        label: l10n.productsDescriptionLabel,
        prefixIcon: Icons.notes_outlined,
        style: _kFieldStyle,
        labelStyle: _kLabelStyle,
        floatingLabelStyle: _kFloatingLabelStyle,
        decorationHintStyle: _kHintStyle,
        isDense: true,
      ),
      const SizedBox(height: 8),
      AppTextField(
        controller: _codeController,
        textInputAction: TextInputAction.next,
        keyboardType: TextInputType.number,
        maxLength: 5,
        label: l10n.productsCodeLabel,
        helperText: l10n.productsCodeHint,
        prefixIcon: Icons.qr_code_2_outlined,
        style: _kFieldStyle,
        labelStyle: _kLabelStyle,
        floatingLabelStyle: _kFloatingLabelStyle,
        decorationHintStyle: _kHintStyle,
        isDense: true,
        validator: (value) {
          final digits = value?.trim() ?? '';
          if (digits.isNotEmpty &&
              !RegExp(r'^\d{1,5}$').hasMatch(digits)) {
            return l10n.productsCodeError;
          }
          return null;
        },
      ),
      const SizedBox(height: 16),
      // PREÇOS — compra e venda lado a lado.
      _SectionLabel(
        icon: Icons.payments_outlined,
        title: l10n.productsSectionPricing,
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: AppTextField(
              controller: _purchasePriceController,
              keyboardType: TextInputType.number,
              label: l10n.productsPurchasePrice,
              style: _kFieldStyle,
              labelStyle: _kLabelStyle,
              floatingLabelStyle: _kFloatingLabelStyle,
              decorationHintStyle: _kHintStyle,
              isDense: true,
              validator: (value) => _parsePrice(value ?? '') <= 0
                  ? l10n.productsPurchasePriceError
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AppTextField(
              controller: _salePriceController,
              keyboardType: TextInputType.number,
              label: l10n.productsSalePrice,
              style: _kFieldStyle,
              labelStyle: _kLabelStyle,
              floatingLabelStyle: _kFloatingLabelStyle,
              decorationHintStyle: _kHintStyle,
              isDense: true,
              validator: (value) => _parsePrice(value ?? '') <= 0
                  ? l10n.productsSalePriceError
                  : null,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      // ESTOQUE — quantidade exata + venda por peso (FIFO).
      _SectionLabel(
        icon: Icons.warehouse_outlined,
        title: l10n.productsSectionStock,
      ),
      const SizedBox(height: 8),
      AppTextField(
        controller: _stockController,
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
        ),
        label: l10n.productsStockQuantity,
        helperText: _vendaPorFracao
            ? l10n.productsStockWeightHint
            : l10n.productsStockAdjustHint,
        prefixIcon: Icons.warehouse_outlined,
        style: _kFieldStyle,
        labelStyle: _kLabelStyle,
        floatingLabelStyle: _kFloatingLabelStyle,
        decorationHintStyle: _kHintStyle,
        isDense: true,
        validator: (value) {
          // Edição: aceita ZERO explícito (zerar o estoque é um
          // ajuste legítimo — ex.: quebra total). Vazio = 0.
          // Rejeita texto não numérico e negativos.
          final text = value?.trim() ?? '';
          if (text.isEmpty) return null;
          final normalized = text
              .replaceAll(' ', '')
              .replaceAll(',', '.');
          final parsed = double.tryParse(normalized);
          if (parsed == null || parsed < 0) {
            return l10n.productsStockError;
          }
          return null;
        },
      ),
 const SizedBox(height: 4),
 Material(
 type: MaterialType.transparency,
 child: SwitchListTile(
 contentPadding: EdgeInsets.zero,
 title: Text(l10n.productsWeighLabel),
 subtitle: Text(l10n.productsWeighHint),
 value: _vendaPorFracao,
 onChanged: (value) => setState(() {
 _vendaPorFracao = value;
 _unitLabel = value ? 'kg' : 'un';
 }),
 ),
 ),
 if (_vendaPorFracao) ...[DropdownButtonFormField<String>(
                  initialValue: _unitLabel,
                  decoration: InputDecoration(
                    labelText: l10n.productsUnitLabel,
                    prefixIcon: const Icon(Icons.scale_outlined),
                  ),
                  items: [
                    for (final unit in const ['kg', 'g', 'l', 'ml'])
                      DropdownMenuItem(value: unit, child: Text(unit)),
                  ],
                  onChanged: (value) =>
                      setState(() => _unitLabel = value ?? 'kg'),
                ),
              ],
              const SizedBox(height: 24),
              // STATUS — ativar/desativar (inativo some do PDV e das
 // compras; o estoque é preservado — a reativação devolve a
 // venda).
 _SectionLabel(
 icon: Icons.toggle_on_outlined,
 title: l10n.productsSectionStatus,
 ),
 const SizedBox(height: 10),
 Material(
 type: MaterialType.transparency,
 child: SwitchListTile(
 contentPadding: EdgeInsets.zero,
 title: Text(l10n.productsActiveLabel),
 subtitle: Text(l10n.productsActiveHint),
 value: _isActive,
 onChanged: (value) => setState(() => _isActive = value),
 ),
 ),
 if (_formError != null) ...[
 const SizedBox(height: 14),
 Text(
 _formError!,
 style: theme.textTheme.bodySmall?.copyWith(
 color: theme.colorScheme.error,
 ),
 ),
 ],
 const SizedBox(height: 20),
 AppButton.primary(
 label: l10n.productsEditSubmit,
 onPressed: _isSubmitting ? null : _submit,
 icon: _isSubmitting
 ? const SizedBox(
 height: 20,
 width: 20,
 child: CircularProgressIndicator(strokeWidth: 2),
 )
 : null,
 ),
 ],
 ),
 ),
 ),
 );
 }
}

/// Seletor de validade MINIMALISTA (W11) — um único campo compacto no
/// padrão dos demais inputs do formulário (borda sutil + ícone de calendário),
/// em vez do botão largo com texto grande e botão de limpar solto.
///
/// Vazio: mostra apenas "Definir validade" (toque abre o date picker). Com
/// data: mostra "Validade · dd/mm/aaaa" em destaque + um X discreto à direita
/// (tooltip "Remover validade") para limpar — os mesmos rótulos/tooltips de
/// antes, só que integrados num único campo.
class _ExpiryField extends StatelessWidget {
 const _ExpiryField({
 required this.expiryDate,
 required this.onPick,
 required this.onClear,
 });

 final DateTime? expiryDate;
 final VoidCallback onPick;
 final VoidCallback onClear;

 @override
 Widget build(BuildContext context) {
 final theme = Theme.of(context);
 final scheme = theme.colorScheme;
 final l10n = context.l10n;
 final hasDate = expiryDate != null;

 // Semantics: o campo inteiro é um botão (abre o date picker) — leitores
 // de tela anunciam a ação, não só o texto visível (como no X de limpar,
 // que já tem tooltip).
 return Semantics(
 button: true,
 child: InkWell(
 onTap: onPick,
 borderRadius: BorderRadius.circular(12),
 child: Container(
 // minHeight (e não altura fixa): com escala de texto alta a data
 // 'Validade · dd/mm/aaaa' quebra em 2 linhas sem cortar o texto.
 constraints: const BoxConstraints(minHeight: 56),
 padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
 decoration: BoxDecoration(
 color: scheme.surface,
 borderRadius: BorderRadius.circular(12),
 border: Border.all(color: scheme.outlineVariant),
 ),
 child: Row(
 crossAxisAlignment: CrossAxisAlignment.center,
 children: [
 Icon(
 Icons.event_outlined,
 size: 20,
 color: scheme.onSurfaceVariant,
 ),
 const SizedBox(width: 12),
 Expanded(
 child: Text(
 hasDate
 ? '${l10n.productsExpiryLabel} · '
 '${Formatters.date(expiryDate!)}'
 : l10n.productsExpiryAdd,
 // Quebra em até 2 linhas — a data nunca é cortada.
 maxLines: 2,
 overflow: TextOverflow.ellipsis,
 style: theme.textTheme.bodyMedium?.copyWith(
 color: hasDate ? scheme.onSurface : scheme.onSurfaceVariant,
 fontWeight: hasDate ? FontWeight.w500 : null,
 ),
 ),
 ),
 if (hasDate) ...[
 const SizedBox(width: 4),
 IconButton(
 tooltip: l10n.productsExpiryClear,
 icon: const Icon(Icons.close, size: 18),
 padding: EdgeInsets.zero,
 constraints: const BoxConstraints(
 minWidth: 32,
 minHeight: 32,
 ),
 onPressed: onClear,
 ),
 ],
 ],
 ),
 ),
 ),
 );
 }
}
