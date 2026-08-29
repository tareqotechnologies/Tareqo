import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../domain/entities/audit_entry.dart';
import '../../../domain/entities/store.dart';
import '../../../domain/entities/plan.dart';
import '../../../domain/entities/store_employee.dart';
import '../../../domain/entities/tenant.dart';
import '../../controllers/account_providers.dart';
import '../../controllers/admin_providers.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/search_field.dart';
import '../../widgets/status_chip.dart';
import '../../../core/observability/crash_reporting.dart';

/// Painel do super admin — aprovar/rejeitar solicitações de acesso de
/// novos tenants e acompanhar o histórico de decisões.
class AdminTenantsScreen extends ConsumerStatefulWidget {
 const AdminTenantsScreen({super.key});

 @override
 ConsumerState<AdminTenantsScreen> createState() => _AdminTenantsScreenState();
}class _AdminTenantsScreenState extends ConsumerState<AdminTenantsScreen> {
  bool _showAll = false;
  bool _selectionMode = false;
  final _selectedIds = <String>{};
  final _searchController = TextEditingController();
  String _searchQuery = '';  @override
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

 final pending = pendingAsync.value ?? const <Tenant>[];

 return Scaffold(
   appBar: AppBar(
     title: Text(
       l10n.adminTenantsTitle,
       style: Theme.of(context).textTheme.labelMedium?.copyWith(
             letterSpacing: -0.5,
           ),
     ),
     actions: [
       TextButton(
         onPressed: () => setState(() => _showAll = !_showAll),
         child: Text(_showAll ? l10n.adminPendingOnly : l10n.adminAll),
       ),
     ],
   ),
  body: Stack(
    children: [
      Column(
        children: [
          // Barra de busca
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xs,
              AppSpacing.lg,
              AppSpacing.xs,
            ),
            child: SearchField(
              controller: _searchController,
              hintText: l10n.adminTenantSearchHint,
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          if (!_showAll && pending.isNotEmpty && !_selectionMode)
            Container(
              margin: const EdgeInsets.fromLTRB(20, 4, 20, 4),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .tertiaryContainer
                    .withValues(alpha: 0.4),
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
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
              onSelectAll: () => _selectAll(
                _filterTenants(pending),
              ),
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
 loading: () => const Center(child: CircularProgressIndicator()),
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
 padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
 physics: const AlwaysScrollableScrollPhysics(),
 itemCount: filtered.length,
 separatorBuilder: (_, _) => const SizedBox(height: 8),      itemBuilder: (context, index) {
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
 loading: () => const Center(child: CircularProgressIndicator()),
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
 padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
 itemCount: filtered.length,
 separatorBuilder: (_, _) => const SizedBox(height: 8),
 itemBuilder: (context, index) {
 final tenant = filtered[index];
 final (color, label) = switch (tenant.status) {
 TenantStatus.pending => (scheme.tertiary, l10n.statusPending),
 TenantStatus.approved => (scheme.primary, l10n.statusApproved),
 TenantStatus.rejected => (scheme.error, l10n.statusRejected),
 };        return AppCard(
          elevated: true,
          borderRadius: const BorderRadius.all(Radius.circular(18)),
          padding: const EdgeInsets.all(14),
          borderColor: color.withValues(alpha: 0.3),
          onTap: () => _showTenantDetail(tenant),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: AppRadius.smAll,
                ),
                child: Icon(
                  Icons.business_outlined,
                  size: 20,
                  color: color,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tenant.businessName,
                      style: theme.textTheme.labelMedium?.copyWith(
                      ),
                    ),
                    Text(
                      '${_plansById(tenant.planId)} · ${tenant.createdAt.day}/${tenant.createdAt.month}/${tenant.createdAt.year}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              StatusChip(label: label, color: color),
              const SizedBox(width: AppSpacing.xs),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(
                    ClipboardData(text: tenant.ownerUserId),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.commonCopied),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                child: Icon(
                  Icons.copy,
                  size: 16,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
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
 }  Future<String?> _askRejectionReason(String businessName) {
    final l10n = context.l10n;
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.adminRejectTitle(businessName)),
        content: AppTextField(
          controller: controller,
          maxLines: 3,
          autofocus: true,
          label: l10n.adminRejectReasonLabel,
          hintText: l10n.adminRejectReasonHint,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonCancel),
          ),
          AppButton.primary(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            label: l10n.adminReject,
          ),
        ],
      ),
    );
  }

  /// Filtra a lista de tenants por nome (busca).
  List<Tenant> _filterTenants(List<Tenant> tenants) {
    if (_searchQuery.isEmpty) return tenants;
    final query = _searchQuery.toLowerCase();
    return tenants
        .where((t) => t.businessName.toLowerCase().contains(query))
        .toList();
  }

  Future<String?> _askBulkRejectionReason(int count) {
    final l10n = context.l10n;
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.adminBulkRejectTitle(count)),
        content: AppTextField(
          controller: controller,
          maxLines: 3,
          autofocus: true,
          label: l10n.adminRejectReasonLabel,
          hintText: l10n.adminRejectReasonHint,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonCancel),
          ),
          AppButton.primary(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            label: l10n.adminReject,
          ),
        ],
      ),
    );
  }

  /// Abre o bottom sheet de detalhes do tenant para troubleshooting.
  void _showTenantDetail(Tenant tenant) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TenantDetailSheet(
        tenant: tenant,
        planName: _plansById(tenant.planId),
      ),
    );
  }
}class _PendingTenantCard extends StatelessWidget {
  const _PendingTenantCard({
    required this.tenant,
    required this.planName,
    this.onApprove,
    this.onReject,
    this.onTap,
    this.onSelect,
    this.onLongPress,
    this.selected = false,
    this.selectionMode = false,
  });

  final Tenant tenant;
  final String planName;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onTap;
  final VoidCallback? onSelect;
  final VoidCallback? onLongPress;
  final bool selected;
  final bool selectionMode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    // Card premium com borda lateral de destaque para ação pendente.
    return GestureDetector(
      onLongPress: onLongPress,
      child: AppCard(
        elevated: true,
        borderRadius: const BorderRadius.all(Radius.circular(18)),
        borderColor: scheme.tertiary.withValues(alpha: 0.4),
        padding: const EdgeInsets.all(14),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (selectionMode) ...[
                  Checkbox(
                    value: selected,
                    onChanged: (_) => onSelect?.call(),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    tenant.businessName,
                    style: theme.textTheme.bodySmall?.copyWith(
                    ),
                  ),
                ),
                StatusChip(
                  label: l10n.statusPending,
                  color: scheme.tertiary,
                  icon: Icons.hourglass_top,
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(
                      ClipboardData(text: tenant.ownerUserId),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.commonCopied),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Icon(
                    Icons.copy,
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Padding(
              padding: selectionMode
                  ? const EdgeInsets.only(left: 44)
                  : EdgeInsets.zero,
              child: Text(
                l10n.adminPlanLabel(planName),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            if (!selectionMode) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppButton.primary(
                      onPressed: onApprove,
                      icon: const Icon(Icons.check),
                      label: l10n.adminApprove,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppButton.secondary(
                      onPressed: onReject,
                      icon: const Icon(Icons.close),
                      label: l10n.adminReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: scheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet com detalhes do tenant para troubleshooting.
/// Exibe informações essenciais: proprietário, plano, lojas, funcionários,
/// atividade recente, estado, data de criação, moeda, idioma e motivo de
/// rejeição.
class _TenantDetailSheet extends ConsumerWidget {
  const _TenantDetailSheet({
    required this.tenant,
    required this.planName,
  });

  final Tenant tenant;
  final String planName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final dateFormat = DateFormat.yMMMd();

    // Dados de lojas, funcionários e atividade recente.
    final storesAsync = ref.watch(storesProvider(tenant.id));
    final employeesAsync = ref.watch(employeesProvider(tenant.id));
    final auditLogAsync = ref.watch(auditLogProvider);

    final stores = storesAsync.value ?? const <Store>[];
    final employees = employeesAsync.value ?? const <StoreEmployee>[];
    final recentActivity = (auditLogAsync.value ?? const <AuditEntry>[])
        .where((e) => e.entityId == tenant.id)
        .take(10)
        .toList();

    // Buscar plano para mostrar limits vs uso.
    final plans = ref.watch(allPlansProvider).value ?? const <Plan>[];
    final plan = plans.where((p) => p.id == tenant.planId).firstOrNull;

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
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

              // ── Header com nome + ID copiável ──
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tenant.businessName,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 2),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(
                              ClipboardData(text: tenant.id),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.commonCopied),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          child: Text(
                            tenant.id,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontFamily: 'monospace',
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.appSheetClose,
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Status + Plano ──
              Row(
                children: [
                  _DetailChip(
                    label: l10n.adminTenantDetailStatus,
                    value: switch (tenant.status) {
                      TenantStatus.pending => l10n.statusPending,
                      TenantStatus.approved => l10n.statusApproved,
                      TenantStatus.rejected => l10n.statusRejected,
                    },
                    color: switch (tenant.status) {
                      TenantStatus.pending => scheme.tertiary,
                      TenantStatus.approved => scheme.primary,
                      TenantStatus.rejected => scheme.error,
                    },
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _DetailChip(
                    label: l10n.adminTenantDetailPlan,
                    value: planName,
                    color: scheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Info rows ──
              _InfoRow(
                icon: Icons.person_outline,
                label: l10n.adminTenantDetailOwner,
                value: tenant.ownerUserId.substring(0, 8),
                onTap: () {
                  Clipboard.setData(
                    ClipboardData(text: tenant.ownerUserId),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.commonCopied),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
              _InfoRow(
                icon: Icons.calendar_today_outlined,
                label: l10n.adminTenantDetailCreated,
                value: dateFormat.format(tenant.createdAt),
              ),
              _InfoRow(
                icon: Icons.attach_money,
                label: l10n.adminTenantDetailCurrency,
                value: tenant.currencyCode,
              ),
              _InfoRow(
                icon: Icons.language,
                label: l10n.adminTenantDetailLanguage,
                value: tenant.language.toUpperCase(),
              ),
              if (tenant.approvedAt != null)
                _InfoRow(
                  icon: Icons.check_circle_outline,
                  label: l10n.adminTenantDetailApprovedAt,
                  value: dateFormat.format(tenant.approvedAt!),
                ),
              if (tenant.rejectionReason != null &&
                  tenant.rejectionReason!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: scheme.errorContainer.withValues(alpha: 0.5),
                    borderRadius: AppRadius.smAll,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.adminTenantDetailRejectionReason,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onErrorContainer,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tenant.rejectionReason!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onErrorContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // ── Uso vs Limites ──
              if (plan != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'USO vs LIMITES',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _UsageBar(
                  label: l10n.adminTenantDetailStores,
                  current: stores.length,
                  max: plan.maxStores,
                  color: scheme.primary,
                ),
                const SizedBox(height: AppSpacing.xs),
                _UsageBar(
                  label: l10n.adminTenantDetailEmployees,
                  current: employees.length,
                  max: plan.maxEmployees,
                  color: scheme.tertiary,
                ),
              ],

              // ── Lojas ──
              const SizedBox(height: AppSpacing.lg),
              _SectionHeader(
                icon: Icons.store_outlined,
                label: l10n.adminTenantDetailStores,
                count: stores.length,
                countLabel: l10n.adminTenantDetailStoresCount(stores.length),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (storesAsync.isLoading)
                const _SectionSkeleton()
              else if (stores.isEmpty)
                _SectionEmpty(
                  icon: Icons.store_outlined,
                  message: l10n.adminTenantDetailNoStores,
                )
              else
                for (final store in stores)
                  _StoreTile(store: store),

              // ── Funcionários ──
              const SizedBox(height: AppSpacing.lg),
              _SectionHeader(
                icon: Icons.people_outline,
                label: l10n.adminTenantDetailEmployees,
                count: employees.length,
                countLabel:
                    l10n.adminTenantDetailEmployeesCount(employees.length),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (employeesAsync.isLoading)
                const _SectionSkeleton()
              else if (employees.isEmpty)
                _SectionEmpty(
                  icon: Icons.people_outline,
                  message: l10n.adminTenantDetailNoEmployees,
                )
              else
                for (final employee in employees)
                  _EmployeeTile(employee: employee),

              // ── Atividade recente ──
              const SizedBox(height: AppSpacing.lg),
              _SectionHeader(
                icon: Icons.history_outlined,
                label: l10n.adminTenantDetailActivity,
                count: recentActivity.length,
                countLabel: l10n.adminTenantDetailActivityCount(
                  recentActivity.length,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (auditLogAsync.isLoading)
                const _SectionSkeleton()
              else if (recentActivity.isEmpty)
                _SectionEmpty(
                  icon: Icons.history_outlined,
                  message: l10n.adminTenantDetailNoActivity,
                )
              else
                for (final entry in recentActivity)
                  _ActivityTile(entry: entry),

              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        );
      },
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.smAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(color: color),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.smAll,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: scheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(Icons.copy, size: 14, color: scheme.onSurfaceVariant),
            ],
          ],
        ),
      ),
    );
  }
}

/// Barra de progresso de uso vs limite.
class _UsageBar extends StatelessWidget {
  const _UsageBar({
    required this.label,
    required this.current,
    required this.max,
    required this.color,
  });

  final String label;
  final int current;
  final int max;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ratio = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;
    final isFull = current >= max;

    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: scheme.surfaceContainerHighest
                  .withValues(alpha: 0.5),
              valueColor: AlwaysStoppedAnimation<Color>(
                isFull ? scheme.error : color,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '$current/$max',
          style: theme.textTheme.labelSmall?.copyWith(
            color: isFull ? scheme.error : scheme.onSurfaceVariant,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// Header de seção com ícone, label e contagem.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.count,
    required this.countLabel,
  });

  final IconData icon;
  final String label;
  final int count;
  final String countLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 18, color: scheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            countLabel,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}

/// Estado vazio de uma seção (lojas/funcionários/atividade).
class _SectionEmpty extends StatelessWidget {
  const _SectionEmpty({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: AppRadius.smAll,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: scheme.outline),
          const SizedBox(width: AppSpacing.xs),
          Text(
            message,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton de carregamento para seções.
class _SectionSkeleton extends StatelessWidget {
  const _SectionSkeleton();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: AppRadius.smAll,
      ),
    );
  }
}

/// Tile de loja no detalhe do tenant.
class _StoreTile extends StatelessWidget {
  const _StoreTile({required this.store});

  final Store store;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.5),
              borderRadius: AppRadius.xsAll,
            ),
            child: Icon(
              Icons.store_outlined,
              size: 16,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (store.city.isNotEmpty)
                  Text(
                    store.city,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tile de funcionário no detalhe do tenant.
class _EmployeeTile extends StatelessWidget {
  const _EmployeeTile({required this.employee});

  final StoreEmployee employee;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    final isActive = employee.isActive;
    final roleLabel = l10n.adminTenantDetailEmployeeRole(
      employee.role.name,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: isActive
                ? scheme.primaryContainer.withValues(alpha: 0.5)
                : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
            child: Text(
              employee.fullName.isNotEmpty
                  ? employee.fullName[0].toUpperCase()
                  : '?',
              style: TextStyle(
                fontSize: 10,
                color: isActive ? scheme.primary : scheme.outline,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  employee.fullName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isActive ? null : scheme.outline,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  roleLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (!isActive)
            Icon(
              Icons.block_outlined,
              size: 16,
              color: scheme.error,
            ),
        ],
      ),
    );
  }
}

/// Tile de atividade recente no detalhe do tenant.
class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.entry});

  final AuditEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dateFormat = DateFormat.yMMMd();
    final timeFormat = DateFormat.Hm();

    final status = entry.detail?['status'] as String?;
    final color = _statusColor(status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: AppRadius.xsAll,
            ),
            child: Icon(
              _actionIcon(entry.action),
              size: 16,
              color: color,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.actionLabel,
                  style: theme.textTheme.bodyMedium?.copyWith(
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (status != null)
                  Text(
                    status.toUpperCase(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: color,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                dateFormat.format(entry.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
              Text(
                timeFormat.format(entry.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _actionIcon(String action) {
    switch (action) {
      case 'tenant_decision':
        return Icons.person_add_outlined;
      case 'plan_request_decision':
        return Icons.upgrade_outlined;
      case 'plan_change':
        return Icons.workspaces_outlined;
      default:
        return Icons.info_outline;
    }
  }
}

/// Barra de ações para seleção em lote — aparece no topo da lista quando
/// o admin entra em modo de seleção (long press).
class _SelectionBar extends StatelessWidget {
  const _SelectionBar({
    required this.selectedCount,
    required this.totalCount,
    required this.onSelectAll,
    required this.onApprove,
    required this.onReject,
    required this.onCancel,
  });

  final int selectedCount;
  final int totalCount;
  final VoidCallback onSelectAll;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final allSelected = selectedCount == totalCount;

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
          // Cancel
          IconButton(
            tooltip: l10n.commonCancel,
            icon: const Icon(Icons.close, size: 20),
            onPressed: onCancel,
          ),
          const SizedBox(width: AppSpacing.xs),

          // Count
          Text(
            '$selectedCount / $totalCount',
            style: theme.textTheme.labelMedium?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Select all
          TextButton(
            onPressed: onSelectAll,
            child: Text(
              allSelected ? l10n.adminBulkDeselectAll : l10n.adminBulkSelectAll,
            ),
          ),

          const Spacer(),

          // Reject
          if (selectedCount > 0)
            AppButton.secondary(
              onPressed: onReject,
              label: l10n.adminBulkReject(selectedCount),
              style: OutlinedButton.styleFrom(
                foregroundColor: scheme.error,
              ),
            ),
          if (selectedCount > 0) const SizedBox(width: AppSpacing.sm),

          // Approve
          if (selectedCount > 0)
            AppButton.primary(
              onPressed: onApprove,
              label: l10n.adminBulkApprove(selectedCount),
            ),
        ],
      ),
    );
  }
}
