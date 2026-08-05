import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../domain/entities/tenant.dart';
import '../../controllers/account_providers.dart';
import '../../controllers/admin_providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/status_chip.dart';
import '../../../core/observability/crash_reporting.dart';

/// Painel do super admin — aprovar/rejeitar solicitações de acesso de
/// novos tenants e acompanhar o histórico de decisões.
class AdminTenantsScreen extends ConsumerStatefulWidget {
  const AdminTenantsScreen({super.key});

  @override
  ConsumerState<AdminTenantsScreen> createState() => _AdminTenantsScreenState();
}

class _AdminTenantsScreenState extends ConsumerState<AdminTenantsScreen> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final pendingAsync = ref.watch(pendingTenantsProvider);
    final allAsync = ref.watch(allTenantsProvider);
    final l10n = context.l10n;

    final pending = pendingAsync.value ?? const <Tenant>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adminTenantsTitle),
        actions: [
          IconButton(
            tooltip: l10n.commonRefresh,
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(pendingTenantsProvider.notifier).refresh();
              ref.read(allTenantsProvider.notifier).refresh();
            },
          ),
          TextButton(
            onPressed: () => setState(() => _showAll = !_showAll),
            child: Text(_showAll ? l10n.adminPendingOnly : l10n.adminAll),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_showAll && pending.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.adminAwaitingCount(pending.length),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
              ),
            ),
          Expanded(
            child: _showAll
                ? _buildList(context, allAsync, l10n.adminTenantsEmpty)
                : _buildPendingList(context, pendingAsync),
          ),
        ],
      ),
    );
  }

  /// Nome do plano pelo id (usa o provider de planos ativos).
  String _plansById(String id) =>
      ref
          .watch(plansProvider)
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
        if (tenants.isEmpty) {
          return EmptyState(
            icon: Icons.task_alt,
            title: l10n.adminNothingPendingTitle,
            subtitle: l10n.adminNothingPendingSubtitle,
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref.read(pendingTenantsProvider.notifier).refresh(),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: tenants.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _PendingTenantCard(
              tenant: tenants[index],
              planName: _plansById(tenants[index].planId),
              onApprove: () => _decide(tenants[index], approve: true),
              onReject: () => _decide(tenants[index], approve: false),
            ),
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
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorView(
        message: l10n.adminTenantsLoadError,
        details: error.toString(),
        onRetry: () => ref.invalidate(allTenantsProvider),
      ),
      data: (tenants) {
        if (tenants.isEmpty) {
          return EmptyState(icon: Icons.business_outlined, title: emptyMessage);
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          itemCount: tenants.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final tenant = tenants[index];
            final (color, label) = switch (tenant.status) {
              TenantStatus.pending => (scheme.tertiary, l10n.statusPending),
              TenantStatus.approved => (scheme.primary, l10n.statusApproved),
              TenantStatus.rejected => (scheme.error, l10n.statusRejected),
            };
            return Card(
              child: ListTile(
                leading: const Icon(Icons.business_outlined),
                title: Text(tenant.businessName),
                subtitle: Text(
                  l10n.adminPlanSolicited(
                    _plansById(tenant.planId),
                    '${tenant.createdAt.day}/${tenant.createdAt.month}',
                  ),
                ),
                trailing: StatusChip(label: label, color: color),
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
  }

  Future<String?> _askRejectionReason(String businessName) {
    final l10n = context.l10n;
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.adminRejectTitle(businessName)),
        content: TextField(
          controller: controller,
          maxLines: 3,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.adminRejectReasonLabel,
            hintText: l10n.adminRejectReasonHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(l10n.adminReject),
          ),
        ],
      ),
    );
  }
}

class _PendingTenantCard extends StatelessWidget {
  const _PendingTenantCard({
    required this.tenant,
    required this.planName,
    required this.onApprove,
    required this.onReject,
  });

  final Tenant tenant;
  final String planName;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    tenant.businessName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                StatusChip(
                  label: l10n.statusPending,
                  color: scheme.tertiary,
                  icon: Icons.hourglass_top,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              l10n.adminPlanLabel(planName),
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check),
                    label: Text(l10n.adminApprove),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close),
                    label: Text(l10n.adminReject),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: scheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
