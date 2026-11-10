import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../domain/entities/plan_request.dart';
import '../../../domain/entities/tenant.dart';
import '../../controllers/admin_providers.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/list_skeleton.dart';
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
    final plans = ref.watch(allPlansProvider).value ?? const [];
    final l10n = context.l10n;

    String tenantName(String id) =>
        tenants.where((t) => t.id == id).firstOrNull?.businessName ?? id;

    String planName(String id) =>
        plans.where((p) => p.id == id).firstOrNull?.name ?? id;

    return Scaffold(
      // AppBar estilo iOS large title — mesmo padrão das demais telas.
      appBar: AppBar(title: Text(l10n.adminUpgradesTitle)),
      body: requestsAsync.when(
        loading: () => const ListSkeleton(items: 5),
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
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.fabBottomClearance,
              ),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: requests.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
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

  String _timeAgo() {
    final diff = DateTime.now().difference(request.createdAt);
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'agora';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    // Card premium com borda de destaque para upgrade pendente.
    return AppCard(
      elevated: true,
      borderRadius: AppRadius.lgAll,
      borderColor: theme.warning.withValues(alpha: 0.3),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: AppSizes.avatarSm,
                height: AppSizes.avatarSm,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.warning.withValues(alpha: 0.12),
                  borderRadius: AppRadius.smAll,
                ),
                child: Icon(
                  Icons.upgrade_outlined,
                  size: AppSizes.iconMd,
                  color: theme.warning,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tenantName,
                      style: AppTypography.labelLarge.copyWith(
                        color: scheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _timeAgo(),
                      style: AppTypography.bodySmall.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              StatusChip(
                label: l10n.statusPending,
                color: theme.warning,
                icon: Icons.hourglass_top,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
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
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Icon(
                  Icons.arrow_forward,
                  size: AppSizes.iconMd,
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
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: AppButton.primary(
                  onPressed: () => onDecide(true),
                  icon: const Icon(Icons.check),
                  label: l10n.adminApprove,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton.secondary(
                  onPressed: () => onDecide(false),
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.smAll,
      ),
      child: Column(
        children: [
          Text(
            isUpgrade ? l10n.adminPlanRequested : l10n.adminPlanCurrent,
            style: AppTypography.labelSmall.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.micro),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyMedium.copyWith(
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
