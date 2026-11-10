part of 'admin_tenants_screen.dart';

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
            borderRadius: AppRadius.sheetTop,
          ),
          child: ListView(
            controller: scrollController,
            padding: AppSpacing.sheetPadding,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: AppSpacing.xxxl,
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

              // ── Header com nome + ID copiável ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tenant.businessName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: scheme.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.micro),
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
                            style: AppTypography.bodySmall.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontFamily: 'monospace',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.appSheetClose,
                    icon: const Icon(Icons.close, size: AppSizes.iconMd),
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
                    color: scheme.errorContainer,
                    borderRadius: AppRadius.smAll,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.adminTenantDetailRejectionReason,
                        style: AppTypography.labelSmall.copyWith(
                          color: scheme.onErrorContainer,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.micro),
                      Text(
                        tenant.rejectionReason!,
                        style: AppTypography.bodySmall.copyWith(
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
                const AdminSectionLabel(label: 'FACTURAÇÃO'),
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
                  style: AppTypography.eyebrow(
                    scheme.onSurfaceVariant.withValues(alpha: 0.8),
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
    final scheme = Theme.of(context).colorScheme;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.micro),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: scheme.onSurface,
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
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xs,
          horizontal: AppSpacing.xxs,
        ),
        child: Row(
          children: [
            Icon(icon, size: AppSizes.iconMd, color: scheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                value,
                style: AppTypography.bodyMedium.copyWith(
                  color: scheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: AppSpacing.xxs),
              Icon(
                Icons.copy,
                size: AppSizes.iconSm,
                color: scheme.onSurfaceVariant,
              ),
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
          width: AppSpacing.gigantic + AppSpacing.md,
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: scheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: AppSpacing.xxs + AppSpacing.micro,
              backgroundColor: scheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                isFull ? scheme.error : color,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '$current/$max',
          style: AppTypography.labelMedium.copyWith(
            color: isFull ? theme.expense : scheme.onSurfaceVariant,
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
        Icon(icon, size: AppSizes.iconMd, color: scheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            label,
            style: AppTypography.labelLarge.copyWith(color: scheme.onSurface),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.micro,
          ),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Text(
            countLabel,
            style: AppTypography.labelSmall.copyWith(
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
        color: scheme.surfaceContainerHighest,
        borderRadius: AppRadius.smAll,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: AppSizes.iconSm, color: scheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
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
      height: AppSizes.touchTarget,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
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
            width: AppSpacing.xxl,
            height: AppSpacing.xxl,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: AppRadius.xsAll,
            ),
            child: Icon(
              Icons.store_outlined,
              size: AppSizes.iconSm,
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
                  style: AppTypography.labelLarge.copyWith(
                    color: scheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (store.city.isNotEmpty)
                  Text(
                    store.city,
                    style: AppTypography.bodySmall.copyWith(
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
            radius: AppSpacing.md,
            backgroundColor: isActive
                ? scheme.primaryContainer
                : scheme.surfaceContainerHighest,
            child: Text(
              employee.fullName.isNotEmpty
                  ? employee.fullName[0].toUpperCase()
                  : '?',
              style: AppTypography.labelMedium.copyWith(
                color: isActive
                    ? scheme.onPrimaryContainer
                    : scheme.onSurfaceVariant,
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
                  style: AppTypography.labelLarge.copyWith(
                    color: isActive
                        ? scheme.onSurface
                        : scheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  roleLabel,
                  style: AppTypography.bodySmall.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (!isActive)
            Icon(
              Icons.block_outlined,
              size: AppSizes.iconSm,
              color: theme.expense,
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
    final color = AppColors.decisionStatusColor(status);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: AppSpacing.xxl,
            height: AppSpacing.xxl,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: AppRadius.xsAll,
            ),
            child: Icon(
              _actionIcon(entry.action),
              size: AppSizes.iconSm,
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
                  style: AppTypography.labelLarge.copyWith(
                    color: scheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (status != null)
                  Text(
                    status.toUpperCase(),
                    style: AppTypography.labelSmall.copyWith(
                      color: scheme.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                dateFormat.format(entry.createdAt),
                style: AppTypography.bodySmall.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              Text(
                timeFormat.format(entry.createdAt),
                style: AppTypography.bodySmall.copyWith(
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
