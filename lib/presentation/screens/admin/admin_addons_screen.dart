import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/observability/crash_reporting.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/money.dart';
import '../../../domain/entities/addon_catalog.dart';
import '../../../domain/entities/addon.dart';
import '../../../domain/entities/tenant.dart';
import '../../controllers/addon_providers.dart';
import '../../controllers/admin_providers.dart';
import '../../widgets/admin_thin_bridge.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/money_live_preview.dart';
import '../../widgets/list_skeleton.dart';
import '../../widgets/premium_decor.dart';
import '../../widgets/search_field.dart';
import '../../widgets/metric_pill.dart';

/// Painel do super admin — gestão de add-ons por tenant.
///
/// Permite ao super admin:
/// - Selecionar um tenant e gerir os seus add-ons individualmente
/// - Selecionar múltiplos tenants e activar/desactivar add-ons em lote
class AdminAddOnsScreen extends ConsumerStatefulWidget {
  const AdminAddOnsScreen({super.key});

  @override
  ConsumerState<AdminAddOnsScreen> createState() => _AdminAddOnsScreenState();
}

class _AdminAddOnsScreenState extends ConsumerState<AdminAddOnsScreen> {
  Tenant? _selectedTenant;
  bool _bulkMode = false;
  final Set<String> _selectedTenantIds = {};
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _enterBulkMode(String initialId) {
    setState(() {
      _bulkMode = true;
      _selectedTenantIds.add(initialId);
    });
  }

  void _exitBulkMode() {
    setState(() {
      _bulkMode = false;
      _selectedTenantIds.clear();
    });
  }

  void _toggleTenantSelection(String id) {
    setState(() {
      if (_selectedTenantIds.contains(id)) {
        _selectedTenantIds.remove(id);
        if (_selectedTenantIds.isEmpty) _bulkMode = false;
      } else {
        _selectedTenantIds.add(id);
      }
    });
  }

  void _selectAllTenants(List<Tenant> tenants) {
    setState(() {
      if (_selectedTenantIds.length == tenants.length) {
        _selectedTenantIds.clear();
        _bulkMode = false;
      } else {
        _selectedTenantIds.addAll(tenants.map((t) => t.id));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedTenant == null) {
      return _TenantPicker(
        searchController: _searchController,
        searchQuery: _searchQuery,
        onSearchChanged: (q) => setState(() => _searchQuery = q),
        onSelectTenant: (t) => setState(() => _selectedTenant = t),
        bulkMode: _bulkMode,
        selectedIds: _selectedTenantIds,
        onEnterBulkMode: _enterBulkMode,
        onToggleSelection: _toggleTenantSelection,
        onSelectAll: _selectAllTenants,
        onExitBulkMode: _exitBulkMode,
        onBulkActivate: _showBulkAddonSheet,
      );
    }

    return _TenantAddOnManager(
      tenant: _selectedTenant!,
      onBack: () => setState(() => _selectedTenant = null),
    );
  }

  /// Abre o sheet de seleção de add-on para activação em lote.
  void _showBulkAddonSheet() {
    if (_selectedTenantIds.isEmpty) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // Thin: rotas modais não herdam o Theme local do shell.
      builder: (sheetContext) => adminThinIfNeeded(
        sheetContext,
        thinStyle: true,
        child: _BulkAddOnSheet(
          tenantCount: _selectedTenantIds.length,
          onApply: (addOnId, activate) async {
            Navigator.of(context).pop();
            await _applyBulkAddOn(addOnId, activate);
          },
        ),
      ),
    );
  }

  /// Aplica a acção de add-on a todos os tenants selecionados.
  Future<void> _applyBulkAddOn(String addOnId, bool activate) async {
    final ds = ref.read(addOnDataSourceProvider);
    final messenger = ScaffoldMessenger.of(context);
    int success = 0;

    for (final tenantId in _selectedTenantIds) {
      try {
        if (activate) {
          await ds.activate(tenantId, addOnId);
        } else {
          await ds.deactivate(tenantId, addOnId);
        }
        success++;
      } catch (_) {
        // Ignorar erros individuais — processar os restantes.
      }
    }

    // Invalidar cache dos tenants afectados.
    for (final tenantId in _selectedTenantIds) {
      ref.invalidate(tenantActiveAddOnIdsProvider(tenantId));
    }

    if (!mounted) return;
    final addon = AddOnCatalog.findById(addOnId);
    final addonName = addon?.name ?? addOnId;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          activate
              ? context.l10n.adminAddonsBulkActivated(addonName, success)
              : context.l10n.adminAddonsBulkDeactivated(addonName, success),
        ),
      ),
    );

    _exitBulkMode();
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Tenant Picker — lista de tenants com suporte a seleção múltipla
// ═══════════════════════════════════════════════════════════════════════════════

class _TenantPicker extends ConsumerWidget {
  const _TenantPicker({
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onSelectTenant,
    required this.bulkMode,
    required this.selectedIds,
    required this.onEnterBulkMode,
    required this.onToggleSelection,
    required this.onSelectAll,
    required this.onExitBulkMode,
    required this.onBulkActivate,
  });

  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<Tenant> onSelectTenant;
  final bool bulkMode;
  final Set<String> selectedIds;
  final ValueChanged<String> onEnterBulkMode;
  final ValueChanged<String> onToggleSelection;
  final ValueChanged<List<Tenant>> onSelectAll;
  final VoidCallback onExitBulkMode;
  final VoidCallback onBulkActivate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final allAsync = ref.watch(allTenantsProvider);

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Column(
        children: [
          // Header com busca
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: SearchField(
                    controller: searchController,
                    hintText: context.l10n.adminTenantSearchHint,
                    onChanged: onSearchChanged,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                // Botão de seleção múltipla
                GestureDetector(
                  onTap: () {
                    if (bulkMode) {
                      onExitBulkMode();
                    } else {
                      // Entrar em modo bulk sem seleção inicial
                      onEnterBulkMode('');
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: bulkMode
                          ? scheme.primary.withValues(alpha: 0.12)
                          : scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Icon(
                      bulkMode
                          ? Icons.checklist_rounded
                          : Icons.checklist_outlined,
                      size: AppSizes.iconMd,
                      color: bulkMode
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // Barra de seleção múltipla
          if (bulkMode)
            _BulkSelectionBar(
              selectedCount: selectedIds.length,
              totalCount:
                  allAsync.value
                      ?.where((t) => t.status == TenantStatus.approved)
                      .length ??
                  0,
              onSelectAll: () =>
                  onSelectAll(_filterTenants(allAsync.value ?? const [])),
              onActivate: onBulkActivate,
              onCancel: onExitBulkMode,
            ),

          // Info (só quando não está em modo bulk)
          if (!bulkMode)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: AppRadius.smAll,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: AppSizes.iconSm,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        context.l10n.adminAddonsListHint,
                        style: AppTypography.bodySmall.copyWith(
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (!bulkMode) const SizedBox(height: AppSpacing.xs),

          // Tenant list
          Expanded(
            child: allAsync.when(
              loading: () => const ListSkeleton(items: 4),
              error: (e, _) => ErrorView(
                message: context.l10n.adminAddonsLoadError('$e'),
                onRetry: () => ref.invalidate(allTenantsProvider),
              ),
              data: (tenants) {
                final filtered = _filterTenants(tenants);
                if (filtered.isEmpty) {
                  return EmptyState(
                    icon: Icons.business_outlined,
                    title: context.l10n.adminAddonsNoTenantsTitle,
                    subtitle: searchQuery.isNotEmpty
                        ? context.l10n.adminAddonsNoTenantsSearchSub
                        : context.l10n.adminAddonsNoTenantsYetSub,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.xs,
                    AppSpacing.lg,
                    AppSpacing.fabBottomClearance,
                  ),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.xs),
                  itemBuilder: (_, i) {
                    final tenant = filtered[i];
                    return _TenantTile(
                      tenant: tenant,
                      bulkMode: bulkMode,
                      isSelected: selectedIds.contains(tenant.id),
                      onTap: bulkMode
                          ? () => onToggleSelection(tenant.id)
                          : () => onSelectTenant(tenant),
                      onLongPress: bulkMode
                          ? null
                          : () => onEnterBulkMode(tenant.id),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Tenant> _filterTenants(List<Tenant> tenants) {
    var list = tenants.where((t) => t.status == TenantStatus.approved).toList();
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list
          .where(
            (t) =>
                t.businessName.toLowerCase().contains(q) ||
                t.id.toLowerCase().contains(q) ||
                t.ownerUserId.toLowerCase().contains(q),
          )
          .toList();
    }
    return list;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Barra de seleção múltipla
// ═══════════════════════════════════════════════════════════════════════════════

class _BulkSelectionBar extends StatelessWidget {
  const _BulkSelectionBar({
    required this.selectedCount,
    required this.totalCount,
    required this.onSelectAll,
    required this.onActivate,
    required this.onCancel,
  });

  final int selectedCount;
  final int totalCount;
  final VoidCallback onSelectAll;
  final VoidCallback onActivate;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final allSelected = selectedCount == totalCount && totalCount > 0;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        border: Border(
          bottom: BorderSide(color: PremiumDecor.hairline(scheme)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: context.l10n.commonCancel,
            icon: const Icon(Icons.close, size: AppSizes.iconMd),
            onPressed: onCancel,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '$selectedCount / $totalCount',
            style: AppTypography.labelMedium,
          ),
          const SizedBox(width: AppSpacing.sm),
          TextButton(
            onPressed: onSelectAll,
            child: Text(
              allSelected
                  ? context.l10n.adminBulkDeselectAll
                  : context.l10n.adminBulkSelectAll,
            ),
          ),
          const Spacer(),
          if (selectedCount > 0)
            AppButton.primary(
              onPressed: onActivate,
              label: context.l10n.adminAddonsActivateBulk,
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Tenant Tile — com suporte a seleção múltipla
// ═══════════════════════════════════════════════════════════════════════════════

class _TenantTile extends ConsumerWidget {
  const _TenantTile({
    required this.tenant,
    required this.bulkMode,
    required this.isSelected,
    required this.onTap,
    this.onLongPress,
  });

  final Tenant tenant;
  final bool bulkMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final plans = ref.watch(allPlansProvider).value ?? [];
    final planName =
        plans.where((p) => p.id == tenant.planId).firstOrNull?.name ??
        tenant.planId;

    return GestureDetector(
      onLongPress: onLongPress,
      child: AppCard(
        elevated: true,
        borderRadius: AppRadius.mdAll,
        padding: const EdgeInsets.all(AppSpacing.sm),
        borderColor: isSelected ? scheme.primary.withValues(alpha: 0.5) : null,
        onTap: onTap,
        child: Row(
          children: [
            // Checkbox no modo bulk
            if (bulkMode) ...[
              Checkbox(
                value: isSelected,
                onChanged: (_) => onTap(),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: AppSpacing.xxs),
            ],
            Container(
              width: AppSizes.avatarSm,
              height: AppSizes.avatarSm,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: AppRadius.smAll,
              ),
              child: Icon(
                Icons.business_outlined,
                size: AppSizes.iconMd,
                color: scheme.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tenant.businessName,
                    style: AppTypography.labelLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.micro),
                  Text(
                    context.l10n.adminPlanLabel(planName),
                    style: AppTypography.bodySmall.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (!bulkMode)
              Icon(
                Icons.chevron_right_rounded,
                size: AppSizes.iconMd,
                color: scheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Bulk Add-On Sheet — seleção de add-on para activação em lote
// ═══════════════════════════════════════════════════════════════════════════════

class _BulkAddOnSheet extends StatelessWidget {
  const _BulkAddOnSheet({required this.tenantCount, required this.onApply});

  final int tenantCount;
  final Future<void> Function(String addOnId, bool activate) onApply;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // Só add-ons com funcionalidade REAL podem ser activados (os
    // BLOCKED — ex.: dependência externa/schema inexistente — ficam
    // fora do catálogo operável: nunca vender/activar o que não existe).
    final addOns = AddOnCatalog.addOns().where((a) => a.isAvailable).toList();

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppRadius.sheetTop,
      ),
      child: SingleChildScrollView(
        padding: AppSpacing.sheetPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: AppSizes.avatarSm,
                height: AppSpacing.xxs,
                margin: const EdgeInsets.only(
                  top: AppSpacing.sm,
                  bottom: AppSpacing.lg,
                ),
                decoration: BoxDecoration(
                  color: PremiumDecor.hairline(scheme),
                  borderRadius: AppRadius.microAll,
                ),
              ),
            ),

            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.adminAddonsBulkSheetTitle,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.micro),
                      Text(
                        context.l10n.adminAddonsBulkSheetCount(tenantCount),
                        style: AppTypography.bodySmall.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: context.l10n.appSheetClose,
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Lista de add-ons
            for (final addon in addOns) ...[
              _BulkAddOnOption(
                addon: addon,
                onActivate: () => onApply(addon.id, true),
                onDeactivate: () => onApply(addon.id, false),
              ),
              if (addon != addOns.last) const SizedBox(height: AppSpacing.xs),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Bulk Add-On Option — cada add-op com botões de activar/desactivar
// ═══════════════════════════════════════════════════════════════════════════════

class _BulkAddOnOption extends StatelessWidget {
  const _BulkAddOnOption({
    required this.addon,
    required this.onActivate,
    required this.onDeactivate,
  });

  final AddOn addon;
  final VoidCallback onActivate;
  final VoidCallback onDeactivate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final iconData = _iconForName(addon.iconName);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: AppRadius.smAll,
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: AppSizes.avatarSm,
            height: AppSizes.avatarSm,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.12),
              borderRadius: AppRadius.smAll,
            ),
            child: Icon(iconData, size: AppSizes.iconMd, color: scheme.primary),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Name + category + price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  addon.name,
                  style: AppTypography.labelLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.micro),
                Row(
                  children: [
                    Text(
                      addon.category.label,
                      style: AppTypography.bodySmall.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      ' · ',
                      style: AppTypography.bodySmall.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${Formatters.currency(addon.priceMonthlyCents)}/mês',
                      style: AppTypography.bodySmall.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: AppSpacing.sm),

          // Buttons
          AppButton.secondary(
            onPressed: onActivate,
            label: context.l10n.adminAddonsActivateBtn,
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.income,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              minimumSize: const Size(0, 32),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          AppButton.secondary(
            onPressed: onDeactivate,
            label: context.l10n.adminAddonsDeactivateBtn,
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.expense,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              minimumSize: const Size(0, 32),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForName(String name) {
    switch (name) {
      case 'receipt_long':
        return Icons.receipt_long_outlined;
      case 'request_quote':
        return Icons.request_quote_outlined;
      case 'analytics':
        return Icons.analytics_outlined;
      case 'groups':
        return Icons.groups_outlined;
      case 'storefront':
        return Icons.storefront_outlined;
      case 'phone_android':
        return Icons.phone_android_outlined;
      default:
        return Icons.extension_outlined;
    }
  }
}

// ─── Sheet de edição de preço ───────────────────────────────────────────

/// Sheet de edição do preço mensal de um add-on (super admin).
/// Mesmo padrão visual do `_PlanEditorSheet` (gestão de planos).
class _AddOnPriceSheet extends ConsumerStatefulWidget {
  const _AddOnPriceSheet({required this.addon});

  final AddOn addon;

  @override
  ConsumerState<_AddOnPriceSheet> createState() => _AddOnPriceSheetState();
}

class _AddOnPriceSheetState extends ConsumerState<_AddOnPriceSheet> {
  late final _priceController = TextEditingController(
    text: (widget.addon.priceMonthlyCents / 100).toString(),
  );

  bool _isSubmitting = false;
  String? _formError;

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final priceCents = Money.parse(_priceController.text.trim());

    if (_priceController.text.trim().isEmpty || priceCents < 0) {
      setState(() => _formError = l10n.adminPlanPriceError);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _formError = null;
    });

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(allAddOnsProvider.notifier)
          .updatePrice(widget.addon.id, priceCents);
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n.adminAddonsPriceUpdated(
              widget.addon.name,
              Formatters.currency(priceCents),
            ),
          ),
        ),
      );
    } catch (error, stackTrace) {
      CrashReporting.capture(
        error,
        stackTrace,
        hint: 'Erro ao salvar preço do add-on',
      );
      if (!mounted) return;
      setState(() => _formError = l10n.adminAddonsPriceSaveError);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SheetForm(
      title: l10n.adminAddonsEditPriceTitle,
      headerSubtitle: widget.addon.name,
      error: _formError,
      actionLabel: l10n.commonSave,
      onSubmit: _submit,
      isSubmitting: _isSubmitting,
      children: [
        SheetSection(
          icon: Icons.sell_outlined,
          children: [
            AppTextField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              label: l10n.adminPlanPriceLabel,
              prefixIcon: Icons.attach_money,
            ),
            // A2: mostra ao vivo o preço que será registado.
            MoneyLivePreview(controller: _priceController),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Tenant Add-On Manager — gerir add-ons de um tenant específico
// ═══════════════════════════════════════════════════════════════════════════════

class _TenantAddOnManager extends ConsumerStatefulWidget {
  const _TenantAddOnManager({required this.tenant, required this.onBack});

  final Tenant tenant;
  final VoidCallback onBack;

  @override
  ConsumerState<_TenantAddOnManager> createState() =>
      _TenantAddOnManagerState();
}

class _TenantAddOnManagerState extends ConsumerState<_TenantAddOnManager> {
  bool _loading = true;
  Set<String> _activeAddOnIds = {};

  @override
  void initState() {
    super.initState();
    _loadActiveAddOns();
  }

  Future<void> _loadActiveAddOns() async {
    setState(() {
      _loading = true;
    });
    try {
      final ds = ref.read(addOnDataSourceProvider);
      final ids = await ds.getActiveAddOnIds(widget.tenant.id);
      if (mounted) {
        setState(() {
          _activeAddOnIds = ids;
          _loading = false;
        });
      }
    } catch (e) {
      // Se a tabela não existe ou RLS bloqueia, mostrar lista vazia
      // em vez de erro — o admin pode activar/desactivar normalmente.
      if (mounted) {
        setState(() {
          _activeAddOnIds = {};
          _loading = false;
        });
      }
    }
  }

  Future<void> _toggleAddOn(String addOnId) async {
    final ds = ref.read(addOnDataSourceProvider);
    final isActive = _activeAddOnIds.contains(addOnId);
    try {
      if (isActive) {
        await ds.deactivate(widget.tenant.id, addOnId);
      } else {
        await ds.activate(widget.tenant.id, addOnId);
      }
      ref.invalidate(tenantActiveAddOnIdsProvider(widget.tenant.id));
      await _loadActiveAddOns();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.adminAddonsUpdateError('$e'))),
        );
      }
    }
  }

  /// Abre o sheet de edição do preço mensal do add-on (super admin).
  Future<void> _editPrice(AddOn addon) async {
    await showAppSheet<void>(
      context,
      builder: (sheetContext) => adminThinIfNeeded(
        sheetContext,
        thinStyle: true,
        child: _AddOnPriceSheet(addon: addon),
      ),
    );
    if (!mounted) return;
    // Recarrega a lista com o preço actualizado.
    await ref.read(allAddOnsProvider.notifier).refresh();
    await _loadActiveAddOns();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // Catálogo EFECTIVO (overrides do banco — preço editado pelo admin);
    // fallback no seed estático enquanto carrega/erro.
    final catalog = ref.watch(allAddOnsProvider).value;
    final addOns = (catalog ?? AddOnCatalog.addOns())
        .where((a) => a.isAvailable)
        .toList();

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Column(
        children: [
          // Header with back button and tenant info
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              border: Border(
                bottom: BorderSide(color: PremiumDecor.hairline(scheme)),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    size: AppSizes.iconMd,
                  ),
                  onPressed: widget.onBack,
                  tooltip: context.l10n.adminBackToList,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.tenant.businessName,
                        style: AppTypography.labelLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${context.l10n.commonId}: ${widget.tenant.id.length > 8 ? widget.tenant.id.substring(0, 8) : widget.tenant.id}...',
                        style: AppTypography.bodySmall.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Stats
          _CompactStats(total: addOns.length, active: _activeAddOnIds.length),

          // Add-on list
          Expanded(
            child: _loading
                ? const ListSkeleton(items: 4)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.fabBottomClearance,
                    ),
                    itemCount: addOns.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      indent: AppSpacing.xxxl,
                      endIndent: 0,
                      color: PremiumDecor.hairline(scheme),
                    ),
                    itemBuilder: (_, i) => _AddOnToggleTile(
                      addon: addOns[i],
                      isActive: _activeAddOnIds.contains(addOns[i].id),
                      onToggle: () => _toggleAddOn(addOns[i].id),
                      onEditPrice: () => _editPrice(addOns[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Stats ──────────────────────────────────────────────────────────────────

class _CompactStats extends StatelessWidget {
  const _CompactStats({required this.total, required this.active});

  final int total;
  final int active;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      child: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          MetricPill(
            count: total,
            label: context.l10n.commonTotal,
            color: scheme.onSurface,
          ),
          MetricPill(
            count: active,
            label: context.l10n.adminAddonsActivePill,
            color: theme.income,
          ),
          MetricPill(
            count: total - active,
            label: context.l10n.adminAddonsInactivePill,
            color: theme.expense,
          ),
        ],
      ),
    );
  }
}
// ─── Add-On Toggle Tile ─────────────────────────────────────────────────────

class _AddOnToggleTile extends StatelessWidget {
  const _AddOnToggleTile({
    required this.addon,
    required this.isActive,
    required this.onToggle,
    required this.onEditPrice,
  });

  final AddOn addon;
  final bool isActive;
  final VoidCallback onToggle;
  final VoidCallback onEditPrice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final iconData = _iconForName(addon.iconName);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          // Color accent bar
          Container(
            width: AppSpacing.xxs,
            height: AppSpacing.xxxl,
            decoration: BoxDecoration(
              color: isActive ? scheme.primary : scheme.outline,
              borderRadius: AppRadius.microAll,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Icon
          Container(
            width: AppSizes.avatarSm,
            height: AppSizes.avatarSm,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: (isActive ? scheme.primary : scheme.outline).withValues(
                alpha: 0.12,
              ),
              borderRadius: AppRadius.smAll,
            ),
            child: Icon(
              iconData,
              size: AppSizes.iconMd,
              color: isActive ? scheme.primary : scheme.outline,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  addon.name,
                  style: AppTypography.labelLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.micro),
                Row(
                  children: [
                    Text(
                      addon.category.label,
                      style: AppTypography.bodySmall.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      ' · ',
                      style: AppTypography.bodySmall.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${Formatters.currency(addon.priceMonthlyCents)}/mês',
                      style: AppTypography.bodySmall.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: AppSpacing.sm),

          // Editar preço (super admin) — toque no valor abre o sheet.
          IconButton(
            tooltip: context.l10n.adminAddonsEditPriceTooltip,
            icon: const Icon(Icons.edit_outlined, size: AppSizes.iconSm),
            color: scheme.onSurfaceVariant,
            onPressed: onEditPrice,
          ),

          const SizedBox(width: AppSpacing.xs),

          // Toggle
          Switch(value: isActive, onChanged: (_) => onToggle()),
        ],
      ),
    );
  }

  IconData _iconForName(String name) {
    switch (name) {
      case 'receipt_long':
        return Icons.receipt_long_outlined;
      case 'request_quote':
        return Icons.request_quote_outlined;
      case 'analytics':
        return Icons.analytics_outlined;
      case 'groups':
        return Icons.groups_outlined;
      case 'storefront':
        return Icons.storefront_outlined;
      case 'phone_android':
        return Icons.phone_android_outlined;
      default:
        return Icons.extension_outlined;
    }
  }
}
