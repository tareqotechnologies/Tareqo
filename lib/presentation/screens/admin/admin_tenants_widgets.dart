part of 'admin_tenants_screen.dart';

class _AdminTenantCard extends ConsumerWidget {
  const _AdminTenantCard({
    required this.tenant,
    required this.color,
    required this.label,
    required this.planName,
    required this.onTap,
  });

  final Tenant tenant;
  final Color color;
  final String label;
  final String planName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final addOnCountAsync = ref.watch(tenantActiveAddOnIdsProvider(tenant.id));
    final addOnCount = addOnCountAsync.value?.length ?? 0;

    return AppCard(
      elevated: true,
      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.lg)),
      padding: const EdgeInsets.all(AppSpacing.md),
      borderColor: color.withValues(alpha: 0.3),
      onTap: onTap,
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
            child: Icon(Icons.business_outlined, size: 20, color: color),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tenant.businessName, style: theme.textTheme.labelMedium),
                Text(
                  '$planName · ${tenant.createdAt.day}/${tenant.createdAt.month}/${tenant.createdAt.year}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          StatusChip(label: label, color: color),
          if (addOnCount > 0) ...[
            const SizedBox(width: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.statusPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.extension_outlined,
                    size: 12,
                    color: AppColors.statusPurple,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '$addOnCount',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.statusPurple,
                      fontWeight: FontWeight.w400,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(width: AppSpacing.xs),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: tenant.ownerUserId));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.l10n.commonCopied),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            child: Icon(Icons.copy, size: 16, color: scheme.onSurfaceVariant),
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
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.lg)),
        borderColor: scheme.tertiary.withValues(alpha: 0.4),
        padding: const EdgeInsets.all(AppSpacing.md),
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
                    style: theme.textTheme.bodySmall,
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
                    Clipboard.setData(ClipboardData(text: tenant.ownerUserId));
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
            const SizedBox(height: AppSpacing.xs),
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
                  const SizedBox(width: AppSpacing.sm),
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
  const _TenantDetailSheet({required this.tenant, required this.planName});

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
              top: Radius.circular(AppRadius.xl),
            ),
          ),
          child: ListView(
            controller: scrollController,
            padding: AppSpacing.sheetPadding,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.lg),
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
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 2),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: tenant.id));
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
                  Clipboard.setData(ClipboardData(text: tenant.ownerUserId));
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

              // ── Ciclo de Facturação ──
              if (tenant.status == TenantStatus.approved &&
                  tenant.planExpiresAt != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'FACTURAÇÃO',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _BillingInfoCard(
                  tenant: tenant,
                  plan: plan,
                  dateFormat: dateFormat,
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
                for (final store in stores) _StoreTile(store: store),

              // ── Funcionários ──
              const SizedBox(height: AppSpacing.lg),
              _SectionHeader(
                icon: Icons.people_outline,
                label: l10n.adminTenantDetailEmployees,
                count: employees.length,
                countLabel: l10n.adminTenantDetailEmployeesCount(
                  employees.length,
                ),
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
                for (final entry in recentActivity) _ActivityTile(entry: entry),

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
            style: theme.textTheme.bodyMedium?.copyWith(color: color),
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
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs, horizontal: 4),
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
            Text(value, style: theme.textTheme.bodyMedium),
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
              backgroundColor: scheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
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
        Expanded(child: Text(label, style: theme.textTheme.labelMedium)),
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
            ),
          ),
        ),
      ],
    );
  }
}

/// Estado vazio de uma seção (lojas/funcionários/atividade).
class _SectionEmpty extends StatelessWidget {
  const _SectionEmpty({required this.icon, required this.message});

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
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
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
            child: Icon(Icons.store_outlined, size: 16, color: scheme.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store.name,
                  style: theme.textTheme.bodyMedium,
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
    final roleLabel = l10n.adminTenantDetailEmployeeRole(employee.role.name);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
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
                fontSize: 12,
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
            Icon(Icons.block_outlined, size: 16, color: scheme.error),
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
    final color = AppColors.decisionStatusColor(status);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
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
            child: Icon(_actionIcon(entry.action), size: 16, color: color),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.actionLabel,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (status != null)
                  Text(
                    status.toUpperCase(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: color,
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
                ),
              ),
              Text(
                timeFormat.format(entry.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
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

/// Card de informação de facturacao no detalhe do tenant.
/// Mostra trial restante, data de expiração e próxima factura.
class _BillingInfoCard extends StatelessWidget {
  const _BillingInfoCard({
    required this.tenant,
    required this.plan,
    required this.dateFormat,
  });

  final Tenant tenant;
  final Plan? plan;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final now = DateTime.now();

    final expiresAt = tenant.planExpiresAt!;
    final nextInvoice = tenant.nextInvoiceAt;

    // Determina se está no trial (14 dias iniciais).
    final isTrial =
        nextInvoice != null &&
        expiresAt.difference(tenant.approvedAt ?? tenant.createdAt).inDays <=
            kTrialDays + 1;

    final daysLeft = expiresAt.difference(now).inDays;
    final isExpiringSoon = daysLeft <= 7 && daysLeft >= 0;
    final isExpired = daysLeft < 0;

    final statusColor = isExpired
        ? scheme.error
        : isExpiringSoon
        ? scheme.tertiary
        : isTrial
        ? scheme.primary
        : scheme.primary;

    final statusText = isExpired
        ? context.l10n.adminTenantCycleExpired
        : isExpiringSoon
        ? context.l10n.adminTenantCycleExpiresIn(daysLeft)
        : isTrial
        ? context.l10n.adminTenantCycleTrialLeft(daysLeft)
        : context.l10n.adminTenantCycleActiveLeft(daysLeft);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.08),
        borderRadius: AppRadius.smAll,
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status do ciclo
          Row(
            children: [
              Icon(
                isTrial ? Icons.science_outlined : Icons.autorenew,
                size: 16,
                color: statusColor,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                statusText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Info rows
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: context.l10n.adminTenantDetailApprovedAt,
            value: dateFormat.format(tenant.approvedAt ?? tenant.createdAt),
          ),
          _InfoRow(
            icon: Icons.event_outlined,
            label: isTrial
                ? context.l10n.adminTenantsTrialEndsOn
                : context.l10n.adminTenantsPlanExpiresOn,
            value: dateFormat.format(expiresAt),
          ),
          if (nextInvoice != null)
            _InfoRow(
              icon: Icons.receipt_long_outlined,
              label: context.l10n.adminTenantsNextInvoice,
              value: dateFormat.format(nextInvoice),
            ),
          if (plan != null && plan!.priceMonthlyCents > 0) ...[
            const SizedBox(height: AppSpacing.xs),
            _InfoRow(
              icon: Icons.attach_money,
              label: context.l10n.adminTenantsMonthlyValue,
              value: Formatters.currency(plan!.priceMonthlyCents),
            ),
          ],
        ],
      ),
    );
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
            style: theme.textTheme.labelMedium,
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
              style: OutlinedButton.styleFrom(foregroundColor: scheme.error),
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
