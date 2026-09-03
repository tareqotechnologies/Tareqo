import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/datasources/local/addon_catalog.dart';
import '../../../domain/entities/addon.dart';
import '../../../domain/entities/tenant.dart';
import '../../controllers/addon_providers.dart';
import '../../controllers/admin_providers.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/search_field.dart';

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
      builder: (_) => _BulkAddOnSheet(
        tenantCount: _selectedTenantIds.length,
        onApply: (addOnId, activate) async {
          Navigator.of(context).pop();
          await _applyBulkAddOn(addOnId, activate);
        },
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
              ? '$addonName activado em $success tenant(s)'
              : '$addonName desactivado em $success tenant(s)',
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
                    hintText: 'Buscar tenant...',
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: bulkMode
                          ? scheme.primary.withValues(alpha: 0.12)
                          : scheme.surfaceContainerHighest
                              .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Icon(
                      bulkMode
                          ? Icons.checklist_rounded
                          : Icons.checklist_outlined,
                      size: 20,
                      color: bulkMode ? scheme.primary : scheme.onSurfaceVariant,
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
              totalCount: allAsync.value
                      ?.where((t) => t.status == TenantStatus.approved)
                      .length ??
                  0,
              onSelectAll: () => onSelectAll(
                _filterTenants(
                  allAsync.value ?? const [],
                ),
              ),
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
                  color: scheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: AppRadius.smAll,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'Toque num tenant para gerir os seus add-ons. Toque no ícone ✓ para seleção múltipla.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.primary,
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
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erro: $e')),
              data: (tenants) {
                final filtered = _filterTenants(tenants);
                if (filtered.isEmpty) {
                  return EmptyState(
                    icon: Icons.business_outlined,
                    title: 'Nenhum tenant encontrado',
                    subtitle: searchQuery.isNotEmpty
                        ? 'Tente outro termo de busca'
                        : 'Nenhum tenant aprovado ainda',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
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
    var list = tenants
        .where((t) => t.status == TenantStatus.approved)
        .toList();
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
        color: scheme.primaryContainer.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Cancelar',
            icon: const Icon(Icons.close, size: 20),
            onPressed: onCancel,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '$selectedCount / $totalCount',
            style: theme.textTheme.labelMedium?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          TextButton(
            onPressed: onSelectAll,
            child: Text(allSelected ? 'Desseleccionar' : 'Selecionar todos'),
          ),
          const Spacer(),
          if (selectedCount > 0)
            AppButton.primary(
              onPressed: onActivate,
              label: 'Activar add-on',
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
    final planName = plans
            .where((p) => p.id == tenant.planId)
            .firstOrNull
            ?.name ??
        tenant.planId;

    return GestureDetector(
      onLongPress: onLongPress,
      child: AppCard(
        elevated: true,
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        padding: const EdgeInsets.all(12),
        borderColor: isSelected
            ? scheme.primary.withValues(alpha: 0.5)
            : null,
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
              const SizedBox(width: 4),
            ],
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: AppRadius.smAll,
              ),
              child: Icon(
                Icons.business_outlined,
                size: 18,
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
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Plano: $planName',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (!bulkMode)
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
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
  const _BulkAddOnSheet({
    required this.tenantCount,
    required this.onApply,
  });

  final int tenantCount;
  final Future<void> Function(String addOnId, bool activate) onApply;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final addOns = AddOnCatalog.addOns();

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
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
                        'Activar add-on em lote',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$tenantCount tenant(s) selecionado(s)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Fechar',
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
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: AppRadius.smAll,
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.12),
              borderRadius: AppRadius.smAll,
            ),
            child: Icon(
              iconData,
              size: 18,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Name + category + price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  addon.name,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      addon.category.label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      ' · ',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      '${Formatters.currency(addon.priceMonthlyCents)}/mês',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
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
            label: 'Activar',
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.success,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: const Size(0, 32),
            ),
          ),
          const SizedBox(width: 6),
          AppButton.secondary(
            onPressed: onDeactivate,
            label: 'Desactivar',
            style: OutlinedButton.styleFrom(
              foregroundColor: scheme.error,
              padding: const EdgeInsets.symmetric(horizontal: 10),
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

// ═══════════════════════════════════════════════════════════════════════════════
// Tenant Add-On Manager — gerir add-ons de um tenant específico
// ═══════════════════════════════════════════════════════════════════════════════

class _TenantAddOnManager extends ConsumerStatefulWidget {
  const _TenantAddOnManager({
    required this.tenant,
    required this.onBack,
  });

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
          SnackBar(content: Text('Erro ao actualizar add-on: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final addOns = AddOnCatalog.addOns();

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
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
              border: Border(
                bottom: BorderSide(
                  color: scheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, size: 20),
                  onPressed: widget.onBack,
                  tooltip: 'Voltar à lista',
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.tenant.businessName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'ID: ${widget.tenant.id.length > 8 ? widget.tenant.id.substring(0, 8) : widget.tenant.id}...',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontSize: 11,
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
          _CompactStats(
            total: addOns.length,
            active: _activeAddOnIds.length,
          ),

          // Add-on list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.sm,
                        ),
                        itemCount: addOns.length,
                        separatorBuilder: (_, _) => const Divider(
                          height: 1,
                          indent: 40,
                          endIndent: 0,
                        ),
                        itemBuilder: (_, i) => _AddOnToggleTile(
                          addon: addOns[i],
                          isActive: _activeAddOnIds.contains(addOns[i].id),
                          onToggle: () => _toggleAddOn(addOns[i].id),
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
    final scheme = Theme.of(context).colorScheme;

    return Container(
      height: 44,
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      child: Row(
        children: [
          _Pill(count: total, label: 'Total', color: scheme.onSurface),
          const SizedBox(width: AppSpacing.xs),
          _Pill(
            count: active,
            label: 'Activos',
            color: AppColors.success,
          ),
          const SizedBox(width: AppSpacing.xs),
          _Pill(
            count: total - active,
            label: 'Inactivos',
            color: AppColors.statusError,
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.count,
    required this.label,
    required this.color,
  });

  final int count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$count',
          style: theme.textTheme.labelSmall?.copyWith(
            color: color,
            fontSize: 12,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 12,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ─── Add-On Toggle Tile ─────────────────────────────────────────────────────

class _AddOnToggleTile extends StatelessWidget {
  const _AddOnToggleTile({
    required this.addon,
    required this.isActive,
    required this.onToggle,
  });

  final AddOn addon;
  final bool isActive;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final iconData = _iconForName(addon.iconName);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          // Color accent bar
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: isActive ? scheme.primary : scheme.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Icon
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: (isActive ? scheme.primary : scheme.outline)
                  .withValues(alpha: 0.12),
              borderRadius: AppRadius.smAll,
            ),
            child: Icon(
              iconData,
              size: 18,
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
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      addon.category.label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      ' · ',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${Formatters.currency(addon.priceMonthlyCents)}/mês',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: AppSpacing.sm),

          // Toggle
          Switch(
            value: isActive,
            onChanged: (_) => onToggle(),
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
