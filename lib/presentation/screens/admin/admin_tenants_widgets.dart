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
    final scheme = Theme.of(context).colorScheme;

    final addOnCountAsync = ref.watch(tenantActiveAddOnIdsProvider(tenant.id));
    final addOnCount = addOnCountAsync.value?.length ?? 0;

    return AppCard(
      elevated: true,
      borderRadius: AppRadius.lgAll,
      padding: const EdgeInsets.all(AppSpacing.md),
      borderColor: color.withValues(alpha: 0.3),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: AppSizes.avatarMd,
            height: AppSizes.avatarMd,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: AppRadius.smAll,
            ),
            child: Icon(
              Icons.business_outlined,
              size: AppSizes.iconMd,
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
                  style: AppTypography.labelLarge.copyWith(
                    color: scheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$planName · ${tenant.createdAt.day}/${tenant.createdAt.month}/${tenant.createdAt.year}',
                  style: AppTypography.bodySmall.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                vertical: AppSpacing.micro,
              ),
              decoration: BoxDecoration(
                color: AppColors.accentOrange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.extension_outlined,
                    size: AppSizes.iconSm,
                    color: AppColors.accentOrange,
                  ),
                  const SizedBox(width: AppSpacing.micro),
                  Text(
                    '$addOnCount',
                    style: AppTypography.labelSmall.copyWith(
                      color: scheme.onSurface,
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
            child: Icon(
              Icons.copy,
              size: AppSizes.iconSm,
              color: scheme.onSurfaceVariant,
            ),
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
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    // Card premium com borda lateral de destaque para ação pendente.
    return GestureDetector(
      onLongPress: onLongPress,
      child: AppCard(
        elevated: true,
        borderRadius: AppRadius.lgAll,
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
                  const SizedBox(width: AppSpacing.xxs),
                ],
                Expanded(
                  child: Text(
                    tenant.businessName,
                    style: AppTypography.labelLarge.copyWith(
                      color: scheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                StatusChip(
                  label: l10n.statusPending,
                  color: scheme.tertiary,
                  icon: Icons.hourglass_top,
                ),
                const SizedBox(width: AppSpacing.xxs),
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
                    size: AppSizes.iconSm,
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
                style: AppTypography.bodySmall.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            if (!selectionMode) ...[
              const SizedBox(height: AppSpacing.sm),
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
