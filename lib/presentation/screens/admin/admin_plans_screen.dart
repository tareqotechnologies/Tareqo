import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/ids.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/money.dart';
import '../../../domain/entities/plan.dart';
import '../../../domain/entities/tenant.dart';
import '../../../domain/usecases/add_plan_use_case.dart';
import '../../controllers/account_providers.dart';
import '../../controllers/admin_providers.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/money_live_preview.dart';
import '../../widgets/error_view.dart';
import '../../widgets/list_skeleton.dart';
import '../../../core/observability/crash_reporting.dart';
import '../../widgets/admin_thin_bridge.dart';

/// Painel do super admin — gestão de planos (criar, editar, ativar/desativar).
/// Os planos limitam a estrutura de cada tenant (nº de lojas e funcionários).
class AdminPlansScreen extends ConsumerStatefulWidget {
  const AdminPlansScreen({super.key});

  @override
  ConsumerState<AdminPlansScreen> createState() => _AdminPlansScreenState();
}

class _AdminPlansScreenState extends ConsumerState<AdminPlansScreen> {
  Future<void> _openEditor([Plan? plan]) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // Thin: rotas modais não herdam o Theme local do shell — o builder
      // aplica o tema thin explicitamente.
      builder: (sheetContext) => adminThinIfNeeded(
        sheetContext,
        thinStyle: true,
        child: _PlanEditorSheet(plan: plan),
      ),
    );
    if (!mounted) return;
    ref.read(allPlansProvider.notifier).refresh();
  }

  void _showPlanDetail(Plan plan) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => adminThinIfNeeded(
        sheetContext,
        thinStyle: true,
        child: _PlanDetailSheet(
          plan: plan,
          onEdit: () {
            Navigator.of(context).pop();
            _openEditor(plan);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(allPlansProvider);
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      // Criar plano — a entrada voltou após a reformulação do painel
      // (o FAB é o padrão das telas de gestão; a lista vazia também
      // oferece a ação no EmptyState).
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(),
        tooltip: l10n.adminPlanNewTitle,
        child: const Icon(Icons.add),
      ),
      body: plansAsync.when(
        loading: () => const ListSkeleton(items: 5),
        error: (error, _) => ErrorView(
          message: l10n.adminPlansLoadError,
          details: error.toString(),
          onRetry: () => ref.invalidate(allPlansProvider),
        ),
        data: (plans) {
          if (plans.isEmpty) {
            return EmptyState(
              icon: Icons.workspaces_outline,
              title: l10n.adminPlansEmptyTitle,
              subtitle: l10n.adminPlansEmptySubtitle,
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(allPlansProvider.notifier).refresh(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── Stats compacto ──
                SliverToBoxAdapter(
                  child: _CompactStats(
                    total: plans.length,
                    active: plans.where((p) => p.isActive).length,
                    inactive: plans.where((p) => !p.isActive).length,
                  ),
                ),

                // ── Lista minimalista ──
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  sliver: SliverList.separated(
                    itemCount: plans.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, indent: 40, endIndent: 0),
                    itemBuilder: (_, i) => _PlanTile(
                      plan: plans[i],
                      onTap: () => _showPlanDetail(plans[i]),
                      onLongPress: () => _openEditor(plans[i]),
                    ),
                  ),
                ),

                // ── Bottom padding ──
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.xxl),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Stats compacto ──────────────────────────────────────────────────────────

class _CompactStats extends StatelessWidget {
  const _CompactStats({
    required this.total,
    required this.active,
    required this.inactive,
  });

  final int total;
  final int active;
  final int inactive;

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
          _Pill(
            count: total,
            label: context.l10n.commonTotal,
            color: scheme.onSurface,
          ),
          const SizedBox(width: AppSpacing.xs),
          _Pill(
            count: active,
            label: context.l10n.adminPlansActive,
            color: AppColors.success,
          ),
          const SizedBox(width: AppSpacing.xs),
          _Pill(
            count: inactive,
            label: context.l10n.adminPlansInactive,
            color: AppColors.statusError,
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.count, required this.label, required this.color});

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

// ─── Tile minimalista ────────────────────────────────────────────────────────

class _PlanTile extends ConsumerWidget {
  const _PlanTile({
    required this.plan,
    required this.onTap,
    required this.onLongPress,
  });

  final Plan plan;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    final accent = plan.isActive ? scheme.primary : scheme.outline;

    // Contar tenants neste plano.
    final tenants = ref.watch(allTenantsProvider).value ?? const <Tenant>[];
    final tenantCount = tenants.where((t) => t.planId == plan.id).length;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
        child: Row(
          children: [
            // ── Color accent bar ──
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),

            // ── Content ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + price
                  Text.rich(
                    TextSpan(
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w400,
                      ),
                      children: [
                        TextSpan(text: plan.name),
                        TextSpan(
                          text:
                              '  ${Formatters.currency(plan.priceMonthlyCents)}${context.l10n.adminPlanPerMonthSuffix}',
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // Details + tenant count
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${plan.maxStores} ${l10n.adminPlanMaxStores.toLowerCase()} · ${plan.maxEmployees} ${l10n.adminPlanMaxEmployees.toLowerCase()}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          context.l10n.adminTenantCount(tenantCount),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.primary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: AppSpacing.sm),

            // ── Status badge ──
            if (!plan.isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: scheme.errorContainer.withValues(alpha: 0.5),
                  borderRadius: AppRadius.smAll,
                ),
                child: Text(
                  l10n.adminPlanInactive,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onErrorContainer,
                    fontSize: 12,
                  ),
                ),
              ),

            Icon(Icons.chevron_right, size: 18, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

// ─── Bottom sheet de detalhes/troubleshooting ────────────────────────────────

class _PlanDetailSheet extends ConsumerWidget {
  const _PlanDetailSheet({required this.plan, required this.onEdit});

  final Plan plan;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    // Tenants neste plano.
    final tenants = ref.watch(allTenantsProvider).value ?? const <Tenant>[];
    final planTenants = tenants.where((t) => t.planId == plan.id).toList();
    final activeTenants = planTenants
        .where((t) => t.status == TenantStatus.approved)
        .toList();
    final pendingTenants = planTenants
        .where((t) => t.status == TenantStatus.pending)
        .toList();
    final rejectedTenants = planTenants
        .where((t) => t.status == TenantStatus.rejected)
        .toList();

    final accent = plan.isActive ? scheme.primary : scheme.outline;

    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                  // Accent bar
                  Container(
                    width: 4,
                    height: 36,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.name,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: plan.id));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.commonCopied),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          child: Text(
                            plan.id,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontFamily: 'monospace',
                              fontSize: 12,
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

              // ── Status chip ──
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: AppRadius.smAll,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      plan.isActive
                          ? Icons.check_circle_outline
                          : Icons.pause_circle_outline,
                      size: 16,
                      color: accent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      plan.isActive
                          ? l10n.statusApproved
                          : l10n.adminPlanInactive,
                      style: theme.textTheme.bodySmall?.copyWith(color: accent),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Info rows ──
              _InfoRow(
                icon: Icons.attach_money,
                label: l10n.adminPlanPriceLabel,
                value:
                    '${Formatters.currency(plan.priceMonthlyCents)}${context.l10n.adminPlanPerMonthSuffix}',
              ),
              _InfoRow(
                icon: Icons.store_outlined,
                label: l10n.adminPlanMaxStores,
                value: '${plan.maxStores}',
              ),
              _InfoRow(
                icon: Icons.badge_outlined,
                label: l10n.adminPlanMaxEmployees,
                value: '${plan.maxEmployees}',
              ),
              if (plan.description.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: AppRadius.smAll,
                  ),
                  child: Text(
                    plan.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],

              // ── Tenants neste plano ──
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Icon(
                    Icons.business_outlined,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      l10n.adminTenantDetailEmployees,
                      style: theme.textTheme.labelMedium?.copyWith(),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest.withValues(
                        alpha: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      context.l10n.adminTenantCount(planTenants.length),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // ── Tenant stats row ──
              Row(
                children: [
                  _TenantStatChip(
                    count: activeTenants.length,
                    label: l10n.statusApproved,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _TenantStatChip(
                    count: pendingTenants.length,
                    label: l10n.statusPending,
                    color: scheme.tertiary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _TenantStatChip(
                    count: rejectedTenants.length,
                    label: l10n.statusRejected,
                    color: scheme.error,
                  ),
                ],
              ),

              // ── Lista de tenants ──
              if (planTenants.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                for (final tenant in planTenants)
                  _TenantMiniTile(tenant: tenant),
              ] else
                _SectionEmpty(
                  icon: Icons.business_outlined,
                  message: l10n.adminTenantsEmpty,
                ),

              // ── Ações ──
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: AppButton.primary(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: l10n.commonSave,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        );
      },
    );
  }
}

// ─── Helper widgets ──────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
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
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _TenantStatChip extends StatelessWidget {
  const _TenantStatChip({
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.smAll,
      ),
      child: Text(
        '$count $label',
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _TenantMiniTile extends StatelessWidget {
  const _TenantMiniTile({required this.tenant});

  final Tenant tenant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final (color, statusLabel) = switch (tenant.status) {
      TenantStatus.pending => (scheme.tertiary, 'Pendente'),
      TenantStatus.approved => (scheme.primary, 'Ativo'),
      TenantStatus.rejected => (scheme.error, 'Rejeitado'),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: AppRadius.xsAll,
            ),
            child: Icon(Icons.business_outlined, size: 16, color: color),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tenant.businessName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  tenant.ownerUserId.substring(0, 8),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              statusLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionEmpty extends StatelessWidget {
  const _SectionEmpty({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

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

// ─── Bottom sheet de edição ──────────────────────────────────────────────────

class _PlanEditorSheet extends ConsumerStatefulWidget {
  const _PlanEditorSheet({this.plan});

  final Plan? plan;

  @override
  ConsumerState<_PlanEditorSheet> createState() => _PlanEditorSheetState();
}

class _PlanEditorSheetState extends ConsumerState<_PlanEditorSheet> {
  late final _nameController = TextEditingController(
    text: widget.plan?.name ?? '',
  );
  late final _descriptionController = TextEditingController(
    text: widget.plan?.description ?? '',
  );
  late final _priceController = TextEditingController(
    text: widget.plan == null
        ? ''
        : (widget.plan!.priceMonthlyCents / 100).toString(),
  );
  late final _maxStoresController = TextEditingController(
    text: widget.plan == null ? '1' : widget.plan!.maxStores.toString(),
  );
  late final _maxEmployeesController = TextEditingController(
    text: widget.plan == null ? '1' : widget.plan!.maxEmployees.toString(),
  );
  late bool _isActive = widget.plan?.isActive ?? true;

  bool _isSubmitting = false;
  String? _formError;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _maxStoresController.dispose();
    _maxEmployeesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final priceCents = Money.parse(_priceController.text.trim());
    final maxStores = int.tryParse(_maxStoresController.text.trim());
    final maxEmployees = int.tryParse(_maxEmployeesController.text.trim());

    if (_nameController.text.trim().isEmpty) {
      setState(() => _formError = l10n.adminPlanNameError);
      return;
    }
    if (_priceController.text.trim().isEmpty || priceCents < 0) {
      setState(() => _formError = l10n.adminPlanPriceError);
      return;
    }
    if (maxStores == null || maxStores < 1) {
      setState(() => _formError = l10n.adminPlanStoresError);
      return;
    }
    if (maxEmployees == null || maxEmployees < 1) {
      setState(() => _formError = l10n.adminPlanEmployeesError);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _formError = null;
    });

    final messenger = ScaffoldMessenger.of(context);
    final plan = Plan(
      id: widget.plan?.id ?? AppIds.newId('pl'),
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      priceMonthlyCents: priceCents,
      maxStores: maxStores,
      maxEmployees: maxEmployees,
      isActive: _isActive,
    );

    try {
      if (widget.plan == null) {
        await ref.read(addPlanUseCaseProvider).call(plan);
      } else {
        await ref.read(updatePlanUseCaseProvider).call(plan);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            widget.plan == null
                ? l10n.adminPlanCreated(plan.name)
                : l10n.adminPlanUpdated(plan.name),
          ),
        ),
      );
    } on InvalidPlanException catch (error) {
      setState(() => _formError = error.message);
    } catch (error, stackTrace) {
      CrashReporting.capture(error, stackTrace, hint: 'Erro ao salvar plano');
      setState(() {
        _formError = l10n.adminPlanSaveError;
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Form(
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
                    child: Text(
                      widget.plan == null
                          ? l10n.adminPlanNewTitle
                          : l10n.adminPlanEditTitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w400,
                      ),
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
              AppTextField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                label: l10n.adminPlanNameLabel,
                prefixIcon: Icons.workspaces_outline,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _descriptionController,
                textInputAction: TextInputAction.next,
                label: l10n.commonDescription,
                prefixIcon: Icons.notes_outlined,
              ),
              const SizedBox(height: AppSpacing.md),
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
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _maxStoresController,
                      keyboardType: TextInputType.number,
                      label: l10n.adminPlanMaxStores,
                      prefixIcon: Icons.store_outlined,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppTextField(
                      controller: _maxEmployeesController,
                      keyboardType: TextInputType.number,
                      label: l10n.adminPlanMaxEmployees,
                      prefixIcon: Icons.badge_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              // Material próprio: sem ele, o ListTile pinta fundo/ink no
              // Material ANCESTRAL (fora do DecoratedBox da sheet) e o
              // Flutter emite a assertion "ListTile background color or
              // ink splashes may be invisible" (mesmo padrão do
              // _CompactSwitch em product_list).
              Material(
                type: MaterialType.transparency,
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.adminPlanActiveTitle),
                  subtitle: Text(l10n.adminPlanActiveSubtitle),
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
              ),
              if (_formError != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _formError!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.error,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              AppButton.primary(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
                label: widget.plan == null
                    ? l10n.adminPlanCreate
                    : l10n.commonSave,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
