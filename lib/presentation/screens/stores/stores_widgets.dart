part of 'stores_screen.dart';

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.tenant,
    required this.plan,
    required this.storeCount,
    required this.employeeCount,
    required this.onUpgrade,
  });

  final Tenant tenant;
  final Plan? plan;
  final int storeCount;
  final int employeeCount;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(
        AppSpacing.pagePaddingForWidth(MediaQuery.sizeOf(context).width),
        12,
        AppSpacing.pagePaddingForWidth(MediaQuery.sizeOf(context).width),
        4,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.workspace_premium_outlined,
                color: scheme.onPrimaryContainer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  plan?.name ?? l10n.planCardTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onUpgrade,
                icon: const Icon(Icons.upgrade_outlined, size: 18),
                label: Text(l10n.planCardUpgrade),
              ),
            ],
          ),
          if (plan != null) ...[
            const SizedBox(height: 8),
            Text(
              plan!.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onPrimaryContainer.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _LimitMeter(
                    label: l10n.planCardStores,
                    used: storeCount,
                    max: plan!.maxStores,
                    scheme: scheme,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _LimitMeter(
                    label: l10n.planCardEmployees,
                    used: employeeCount,
                    max: plan!.maxEmployees,
                    scheme: scheme,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LimitMeter extends StatelessWidget {
  const _LimitMeter({
    required this.label,
    required this.used,
    required this.max,
    required this.scheme,
  });

  final String label;
  final int used;
  final int max;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final ratio = (used / max).clamp(0.0, 1.0);
    final reached = used >= max;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Flexible: em telas estreitas o cartão de plano fica com
            // colunas ~158px — sem flex o rótulo longo estourava o Row
            // (regressão encontrada nos testes de rotação).
            Flexible(
              child: Text(
                label,
                // Quebra em até 2 linhas — o rótulo do limite nunca é cortado.
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onPrimaryContainer.withValues(alpha: 0.8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '$used/$max',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: reached ? scheme.error : scheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: scheme.onPrimaryContainer.withValues(alpha: 0.15),
            color: reached ? scheme.error : scheme.primary,
          ),
        ),
      ],
    );
  }
}

/// Sheet de criação de loja.
