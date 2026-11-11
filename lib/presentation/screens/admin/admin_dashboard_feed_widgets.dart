part of 'admin_dashboard_screen.dart';

class _PlanBarRow extends StatelessWidget {
  const _PlanBarRow({
    required this.planName,
    required this.count,
    required this.fraction,
    required this.color,
  });

  final String planName;
  final int count;
  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            planName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: ClipRRect(
            borderRadius: AppRadius.microAll,
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: AppSpacing.xxs + AppSpacing.micro,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text('$count', style: AppTypography.bodySmall),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Recent Activity Feed
// ═════════════════════════════════════════════════════════════════════════════

class _RecentActivityFeed extends StatelessWidget {
  const _RecentActivityFeed({
    required this.entries,
    required this.isLoading,
    required this.l10n,
  });

  final List<AuditEntry> entries;
  final bool isLoading;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (isLoading) {
      return AppCard(
        borderRadius: AppRadius.lgAll,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            for (var i = 0; i < 3; i++) ...[
              Container(
                width: double.infinity,
                height: AppSizes.avatarSm,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: AppRadius.xsAll,
                ),
              ),
              if (i < 2) const SizedBox(height: AppSpacing.xs),
            ],
          ],
        ),
      );
    }

    final recent = entries.take(5).toList();

    if (recent.isEmpty) {
      return AppCard(
        borderRadius: AppRadius.lgAll,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(
              Icons.history_outlined,
              size: AppSizes.iconMd,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                l10n.adminAuditLogEmpty,
                style: AppTypography.bodySmall.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return AppCard(
      borderRadius: AppRadius.lgAll,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < recent.length; i++) ...[
            _ActivityRow(entry: recent[i]),
            if (i < recent.length - 1)
              Divider(
                height: 1,
                indent: AppSpacing.md,
                endIndent: AppSpacing.md,
                color: PremiumDecor.hairline(scheme),
              ),
          ],
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.entry});

  final AuditEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final timeFormat = DateFormat.Hm();

    final status = entry.detail?['status'] as String?;
    final color = AppColors.decisionStatusColor(status);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Container(
            width: AppSpacing.xs,
            height: AppSpacing.xs,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              entry.actionLabel,
              style: AppTypography.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            timeFormat.format(entry.createdAt),
            style: AppTypography.bodySmall.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Quick Actions
// ═════════════════════════════════════════════════════════════════════════════

class _QuickAction {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    this.badge = 0,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final int badge;
  final VoidCallback? onTap;
}

class _QuickActionGrid extends StatelessWidget {
  const _QuickActionGrid({required this.actions});

  final List<_QuickAction> actions;

  @override
  Widget build(BuildContext context) {
    final columns = MediaQuery.sizeOf(context).width >= AppBreakpoints.mediumMin
        ? 4
        : 2;

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth =
            (constraints.maxWidth - AppSpacing.sm * (columns - 1)) / columns;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: actions.map((action) {
            return SizedBox(
              width: itemWidth,
              child: _QuickActionCard(action: action),
            );
          }).toList(),
        );
      },
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.action});

  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      borderRadius: AppRadius.lgAll,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      onTap: action.onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: AppSizes.avatarSm,
                height: AppSizes.avatarSm,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: action.color.withValues(alpha: 0.14),
                  borderRadius: AppRadius.smAll,
                ),
                child: Icon(
                  action.icon,
                  size: AppSizes.iconMd,
                  color: action.color,
                ),
              ),
              if (action.badge > 0) ...[
                const Spacer(),
                // Contagem em pílula tingida com texto neutro — a cor do
                // item fica no ícone/fundo; texto pequeno em azul sobre
                // o véu não atinge AA no claro.
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.micro,
                  ),
                  decoration: BoxDecoration(
                    color: action.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    '${action.badge}',
                    style: AppTypography.labelMedium.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            action.label,
            style: AppTypography.bodySmall.copyWith(
              color: theme.colorScheme.onSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
