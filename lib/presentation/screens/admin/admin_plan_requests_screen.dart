import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../domain/entities/plan_request.dart';
import '../../../domain/entities/tenant.dart';
import '../../controllers/account_providers.dart';
import '../../controllers/admin_providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/status_chip.dart';
import '../../../core/observability/crash_reporting.dart';

/// Painel do super admin — decidir pedidos de upgrade de plano. Ao aprovar,
/// o plano do tenant é trocado para o solicitado.
class AdminPlanRequestsScreen extends ConsumerStatefulWidget {
  const AdminPlanRequestsScreen({super.key});

  @override
  ConsumerState<AdminPlanRequestsScreen> createState() =>
      _AdminPlanRequestsScreenState();
}

class _AdminPlanRequestsScreenState
    extends ConsumerState<AdminPlanRequestsScreen> {
  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(pendingPlanRequestsProvider);
    final tenants = ref.watch(allTenantsProvider).value ?? const <Tenant>[];
    final plans = ref.watch(plansProvider).value ?? const [];
    final l10n = context.l10n;

    String tenantName(String id) =>
        tenants.where((t) => t.id == id).firstOrNull?.businessName ?? id;

    String planName(String id) =>
        plans.where((p) => p.id == id).firstOrNull?.name ?? id;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.adminUpgradesTitle)),
      body: requestsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          message: l10n.adminUpgradesLoadError,
          details: error.toString(),
          onRetry: () => ref.invalidate(pendingPlanRequestsProvider),
        ),
        data: (requests) {
          if (requests.isEmpty) {
            return EmptyState(
              icon: Icons.upgrade_outlined,
              title: l10n.adminUpgradesEmptyTitle,
              subtitle: l10n.adminUpgradesEmptySubtitle,
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(pendingPlanRequestsProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: requests.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) => _RequestCard(
                request: requests[index],
                tenantName: tenantName(requests[index].tenantId),
                currentPlan: planName(requests[index].currentPlanId),
                requestedPlan: planName(requests[index].requestedPlanId),
                onDecide: (approve) => _decide(requests[index], approve),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _decide(PlanRequest request, bool approve) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    try {
      await ref
          .read(decidePlanRequestUseCaseProvider)
          .call(request.id, approve: approve);
      if (!mounted) return;
      await ref.read(pendingPlanRequestsProvider.notifier).refresh();
      await ref.read(allTenantsProvider.notifier).refresh();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            approve ? l10n.adminUpgradeApproved : l10n.adminUpgradeRejected,
          ),
        ),
      );
    } catch (error, stackTrace) {
      CrashReporting.capture(
        error,
        stackTrace,
        hint: 'Erro ao decidir upgrade',
      );
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.adminUpgradeProcessError)),
      );
    }
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.tenantName,
    required this.currentPlan,
    required this.requestedPlan,
    required this.onDecide,
  });

  final PlanRequest request;
  final String tenantName;
  final String currentPlan;
  final String requestedPlan;
  final void Function(bool approve) onDecide;

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
                    tenantName,
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
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _PlanBadge(
                    label: currentPlan,
                    isUpgrade: false,
                    l10n: l10n,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.arrow_forward,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                Expanded(
                  child: _PlanBadge(
                    label: requestedPlan,
                    isUpgrade: true,
                    l10n: l10n,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => onDecide(true),
                    icon: const Icon(Icons.check),
                    label: Text(l10n.adminApprove),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => onDecide(false),
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

class _PlanBadge extends StatelessWidget {
  const _PlanBadge({
    required this.label,
    required this.isUpgrade,
    required this.l10n,
  });

  final String label;
  final bool isUpgrade;

  /// Traduções herdadas do card pai (evita lookup extra por widget).
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = isUpgrade ? scheme.primary : scheme.outline;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            isUpgrade ? l10n.adminPlanRequested : l10n.adminPlanCurrent,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
