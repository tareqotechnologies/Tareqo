import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../domain/entities/audit_entry.dart';
import '../../../domain/entities/store.dart';
import '../../../domain/entities/plan.dart';
import '../../../domain/entities/store_employee.dart';
import '../../../domain/entities/tenant.dart';
import '../../../domain/usecases/approve_tenant_use_case.dart';
import '../../controllers/account_providers.dart';
import '../../controllers/addon_providers.dart';
import '../../controllers/admin_providers.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/admin_thin_bridge.dart';
import '../../widgets/app_page.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/list_skeleton.dart';
import '../../widgets/error_view.dart';
import '../../widgets/search_field.dart';
import '../../widgets/status_chip.dart';
import '../../../core/observability/crash_reporting.dart';
part 'admin_tenants_widgets.dart';
part 'admin_tenants_widgets_sheets.dart'; // _TenantDetailSheet + detail widgets
part 'admin_tenants_widgets_billing.dart'; // _BillingInfoCard + _SelectionBar

/// Painel do super admin — aprovar/rejeitar solicitações de acesso de
/// novos tenants e acompanhar o histórico de decisões.
class AdminTenantsScreen extends ConsumerStatefulWidget {
  const AdminTenantsScreen({super.key});

  @override
  ConsumerState<AdminTenantsScreen> createState() => _AdminTenantsScreenState();
}

class _AdminTenantsScreenState extends ConsumerState<AdminTenantsScreen> {
  bool _showAll = false;
  bool _selectionMode = false;
  final _selectedIds = <String>{};
  final _searchController = TextEditingController();
  String _searchQuery = '';
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _selectionMode = false;
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll(List<Tenant> tenants) {
    setState(() {
      if (_selectedIds.length == tenants.length) {
        _selectedIds.clear();
        _selectionMode = false;
      } else {
        _selectedIds.addAll(tenants.map((t) => t.id));
      }
    });
  }

  void _enterSelectionMode(String id) {
    setState(() {
      _selectionMode = true;
      _selectedIds.add(id);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  Future<void> _bulkApprove() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final ids = _selectedIds.toList();
    int approved = 0;
    for (final id in ids) {
      try {
        await ref.read(approveTenantUseCaseProvider).call(id);
        approved++;
      } catch (error, stackTrace) {
        CrashReporting.capture(
          error,
          stackTrace,
          hint: 'Erro ao aprovar tenant em lote',
        );
      }
    }
    _exitSelectionMode();
    if (!mounted) return;
    await ref.read(pendingTenantsProvider.notifier).refresh();
    await ref.read(allTenantsProvider.notifier).refresh();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          approved == ids.length
              ? l10n.adminBulkApproveSuccess(approved)
              : l10n.adminBulkApproveError,
        ),
      ),
    );
  }

  Future<void> _bulkReject() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final reason = await _askBulkRejectionReason(_selectedIds.length);
    if (reason == null) return;
    final ids = _selectedIds.toList();
    int rejected = 0;
    for (final id in ids) {
      try {
        await ref.read(rejectTenantUseCaseProvider).call(id, reason);
        rejected++;
      } catch (error, stackTrace) {
        CrashReporting.capture(
          error,
          stackTrace,
          hint: 'Erro ao rejeitar tenant em lote',
        );
      }
    }
    _exitSelectionMode();
    if (!mounted) return;
    await ref.read(pendingTenantsProvider.notifier).refresh();
    await ref.read(allTenantsProvider.notifier).refresh();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          rejected == ids.length
              ? l10n.adminBulkRejectSuccess(rejected)
              : l10n.adminBulkRejectError,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingAsync = ref.watch(pendingTenantsProvider);
    final allAsync = ref.watch(allTenantsProvider);
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final pending = pendingAsync.value ?? const <Tenant>[];
    final allTenants = allAsync.value ?? const <Tenant>[];
    final displayList = _showAll ? allTenants : pending;
    final filteredCount = _searchQuery.isNotEmpty
        ? _filterTenants(displayList).length
        : displayList.length;

    return AppPage(
      title: l10n.adminTenantsTitle,
      actions: [
        TextButton(
          onPressed: () => setState(() => _showAll = !_showAll),
          child: Text(_showAll ? l10n.adminPendingOnly : l10n.adminAll),
        ),
      ],
      useSafeArea: false,
      body: Stack(
        children: [
          Column(
            children: [
              // Barra de busca com contagem
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xs,
                  AppSpacing.lg,
                  AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SearchField(
                        controller: _searchController,
                        hintText: l10n.adminTenantSearchHint,
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty) ...[
                      const SizedBox(width: AppSpacing.xs),
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.xs),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest.withValues(
                              alpha: 0.5,
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                    if (_searchQuery.isNotEmpty) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: AppSpacing.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          '$filteredCount',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!_showAll && pending.isNotEmpty && !_selectionMode)
                Container(
                  margin: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.xxs,
                    AppSpacing.lg,
                    AppSpacing.xxs,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.tertiaryContainer.withValues(alpha: 0.4),
                    borderRadius: AppRadius.smAll,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          l10n.adminAwaitingCount(pending.length),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.tertiary,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_selectionMode && !_showAll)
                _SelectionBar(
                  selectedCount: _selectedIds.length,
                  totalCount: pending.length,
                  onSelectAll: () => _selectAll(_filterTenants(pending)),
                  onApprove: _bulkApprove,
                  onReject: _bulkReject,
                  onCancel: _exitSelectionMode,
                ),
              Expanded(
                child: _showAll
                    ? _buildList(context, allAsync, l10n.adminTenantsEmpty)
                    : _buildPendingList(context, pendingAsync),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Nome do plano pelo id (usa o provider de todos os planos).
  String _plansById(String id) =>
      ref
          .watch(allPlansProvider)
          .value
          ?.where((plan) => plan.id == id)
          .firstOrNull
          ?.name ??
      id;

  Widget _buildPendingList(
    BuildContext context,
    AsyncValue<List<Tenant>> async,
  ) {
    final l10n = context.l10n;

    return async.when(
      loading: () => const ListSkeleton(items: 5),
      error: (error, _) => ErrorView(
        message: l10n.adminRequestsLoadError,
        details: error.toString(),
        onRetry: () => ref.invalidate(pendingTenantsProvider),
      ),
      data: (tenants) {
        final filtered = _filterTenants(tenants);
        if (filtered.isEmpty) {
          return EmptyState(
            icon: Icons.task_alt,
            title: _searchQuery.isNotEmpty
                ? l10n.commonNoResults
                : l10n.adminNothingPendingTitle,
            subtitle: _searchQuery.isNotEmpty
                ? l10n.commonNoResultsHint
                : l10n.adminNothingPendingSubtitle,
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref.read(pendingTenantsProvider.notifier).refresh(),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final tenant = filtered[index];
              final isSelected = _selectedIds.contains(tenant.id);
              return _PendingTenantCard(
                tenant: tenant,
                planName: _plansById(tenant.planId),
                selected: isSelected,
                selectionMode: _selectionMode,
                onSelect: () => _toggleSelection(tenant.id),
                onLongPress: () => _enterSelectionMode(tenant.id),
                onApprove: _selectionMode
                    ? null
                    : () => _decide(tenant, approve: true),
                onReject: _selectionMode
                    ? null
                    : () => _decide(tenant, approve: false),
                onTap: _selectionMode
                    ? () => _toggleSelection(tenant.id)
                    : () => _showTenantDetail(tenant),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildList(
    BuildContext context,
    AsyncValue<List<Tenant>> async,
    String emptyMessage,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    return async.when(
      loading: () => const ListSkeleton(items: 5),
      error: (error, _) => ErrorView(
        message: l10n.adminTenantsLoadError,
        details: error.toString(),
        onRetry: () => ref.invalidate(allTenantsProvider),
      ),
      data: (tenants) {
        final filtered = _filterTenants(tenants);
        if (filtered.isEmpty) {
          return EmptyState(
            icon: Icons.business_outlined,
            title: _searchQuery.isNotEmpty
                ? l10n.commonNoResults
                : emptyMessage,
            subtitle: _searchQuery.isNotEmpty ? l10n.commonNoResultsHint : null,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          itemCount: filtered.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final tenant = filtered[index];
            final (color, label) = switch (tenant.status) {
              TenantStatus.pending => (scheme.tertiary, l10n.statusPending),
              TenantStatus.approved => (scheme.primary, l10n.statusApproved),
              TenantStatus.rejected => (scheme.error, l10n.statusRejected),
            };
            return _AdminTenantCard(
              tenant: tenant,
              color: color,
              label: label,
              planName: _plansById(tenant.planId),
              onTap: () => _showTenantDetail(tenant),
            );
          },
        );
      },
    );
  }

  Future<void> _decide(Tenant tenant, {required bool approve}) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    if (!approve) {
      final reason = await _askRejectionReason(tenant.businessName);
      if (reason == null) return;
      try {
        await ref.read(rejectTenantUseCaseProvider).call(tenant.id, reason);
      } catch (error, stackTrace) {
        CrashReporting.capture(
          error,
          stackTrace,
          hint: 'Erro ao rejeitar tenant',
        );
        messenger.showSnackBar(SnackBar(content: Text(l10n.adminRejectError)));
        return;
      }
    } else {
      try {
        await ref.read(approveTenantUseCaseProvider).call(tenant.id);
      } catch (error, stackTrace) {
        CrashReporting.capture(
          error,
          stackTrace,
          hint: 'Erro ao aprovar tenant',
        );
        messenger.showSnackBar(SnackBar(content: Text(l10n.adminApproveError)));
        return;
      }
    }

    if (!mounted) return;
    await ref.read(pendingTenantsProvider.notifier).refresh();
    await ref.read(allTenantsProvider.notifier).refresh();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          approve
              ? l10n.adminAccessApproved(tenant.businessName)
              : l10n.adminRequestRejected(tenant.businessName),
        ),
      ),
    );
  }

  Future<String?> _askRejectionReason(String businessName) {
    final l10n = context.l10n;
    return showInputDialog(
      context,
      title: l10n.adminRejectTitle(businessName),
      label: l10n.adminRejectReasonLabel,
      hintText: l10n.adminRejectReasonHint,
      maxLines: 3,
      confirmLabel: l10n.adminReject,
      // Thin: o dialog é rota modal — não herda o Theme do shell.
      thinStyle: true,
    );
  }

  /// Filtra a lista de tenants por nome, ID, ownerUserId, plano ou status.
  List<Tenant> _filterTenants(List<Tenant> tenants) {
    if (_searchQuery.isEmpty) return tenants;
    final query = _searchQuery.toLowerCase();
    final plans = ref.read(allPlansProvider).value ?? const <Plan>[];
    return tenants.where((t) {
      // Busca por nome do negócio
      if (t.businessName.toLowerCase().contains(query)) return true;
      // Busca por ID do tenant
      if (t.id.toLowerCase().contains(query)) return true;
      // Busca por ownerUserId
      if (t.ownerUserId.toLowerCase().contains(query)) return true;
      // Busca por nome do plano
      final planName =
          plans.where((p) => p.id == t.planId).firstOrNull?.name ?? '';
      if (planName.toLowerCase().contains(query)) return true;
      // Busca por status
      final statusLabel = switch (t.status) {
        TenantStatus.pending => 'pending pendente',
        TenantStatus.approved => 'approved ativo',
        TenantStatus.rejected => 'rejected rejeitado',
      };
      if (statusLabel.contains(query)) return true;
      return false;
    }).toList();
  }

  Future<String?> _askBulkRejectionReason(int count) {
    final l10n = context.l10n;
    return showInputDialog(
      context,
      title: l10n.adminBulkRejectTitle(count),
      label: l10n.adminRejectReasonLabel,
      hintText: l10n.adminRejectReasonHint,
      maxLines: 3,
      confirmLabel: l10n.adminReject,
      thinStyle: true,
    );
  }

  /// Abre o bottom sheet de detalhes do tenant para troubleshooting.
  void _showTenantDetail(Tenant tenant) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // Thin: rotas modais não herdam o Theme local do shell.
      builder: (sheetContext) => adminThinIfNeeded(
        sheetContext,
        thinStyle: true,
        child: _TenantDetailSheet(
          tenant: tenant,
          planName: _plansById(tenant.planId),
        ),
      ),
    );
  }
}
