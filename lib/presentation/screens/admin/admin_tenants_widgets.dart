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
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.statusPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.extension_outlined,
                    size: 12,
                    color: AppColors.statusPrimary,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '$addOnCount',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.statusPrimary,
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
