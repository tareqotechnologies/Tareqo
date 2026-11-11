part of 'admin_tenants_screen.dart';

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

    // Texto pequeno sobre o véu do cartão: vermelho/âmbar/verde do tema têm
    // contraste AA nos dois modos; o azul puro fica só no ícone.
    final statusColor = isExpired
        ? theme.expense
        : isExpiringSoon
        ? scheme.tertiary
        : isTrial
        ? scheme.onSurface
        : theme.income;

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
                size: AppSizes.iconSm,
                color: statusColor,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  statusText,
                  style: AppTypography.bodySmall.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w400,
                  ),
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
        color: scheme.primaryContainer,
        border: Border(bottom: BorderSide(color: PremiumDecor.hairline(scheme))),
      ),
      child: Row(
        children: [
          // Cancel
          IconButton(
            tooltip: l10n.commonCancel,
            icon: const Icon(Icons.close, size: AppSizes.iconMd),
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
