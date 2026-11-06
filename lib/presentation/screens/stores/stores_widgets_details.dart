part of 'stores_screen.dart';

/// Sheet de detalhes de um funcionário — exibida ao tocar no card.
class _EmployeeDetailSheet extends StatelessWidget {
  const _EmployeeDetailSheet({
    required this.employee,
    required this.stores,
    required this.isOwner,
    required this.onToggle,
  });

  final StoreEmployee employee;
  final List<Store> stores;
  final bool isOwner;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final isManager = employee.role == EmployeeRole.manager;

    final storeName =
        stores.where((s) => s.id == employee.storeId).firstOrNull?.name ??
        employee.storeId;

    return Padding(
      padding: AppSpacing.sheetPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Cabeçalho: avatar + nome ──
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: scheme.primaryContainer,
                child: Text(
                  employee.fullName.isEmpty
                      ? '?'
                      : employee.fullName.substring(0, 1).toUpperCase(),
                  style: AppTypography.labelLarge.copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  employee.fullName,
                  // Nome = título do bloco (16/w500); o w300 anterior saía
                  // da escala de pesos permitida (400/500/600).
                  style: AppTypography.titleMedium,
                ),
              ),
              if (!employee.isActive)
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: scheme.error,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Detalhes ──
          DetailRow(
            labelWidth: 70,
            label: l10n.employeeDetailEmail,
            value: employee.email,
            icon: Icons.email_outlined,
          ),
          DetailRow(
            labelWidth: 70,
            label: l10n.employeeDetailStore,
            value: storeName,
            icon: Icons.store_outlined,
          ),
          DetailRow(
            labelWidth: 70,
            label: l10n.employeeDetailRole,
            value: isManager ? l10n.roleManager : l10n.roleEmployee,
            icon: isManager
                ? Icons.manage_accounts_outlined
                : Icons.person_outline,
            valueColor: isManager ? scheme.primary : null,
          ),
          DetailRow(
            labelWidth: 70,
            label: l10n.employeeDetailStatus,
            value: employee.isActive
                ? l10n.employeeDetailActive
                : l10n.employeeDetailInactive,
            icon: employee.isActive
                ? Icons.check_circle_outline
                : Icons.cancel_outlined,
            valueColor: employee.isActive ? scheme.primary : scheme.error,
          ),

          // ── Ações ──
          if (isOwner) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            if (employee.isActive)
              AppButton.danger(
                onPressed: () {
                  Navigator.of(context).pop();
                  onToggle(false);
                },
                label: l10n.employeeDeactivateAction,
                icon: const Icon(Icons.block_outlined, size: 18),
              )
            else
              AppButton.primary(
                onPressed: () {
                  Navigator.of(context).pop();
                  onToggle(true);
                },
                label: l10n.employeeReactivateAction,
                icon: const Icon(Icons.check_circle_outlined, size: 18),
              ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Sheet de detalhes de uma loja — exibida ao tocar no card.
class _StoreDetailSheet extends StatelessWidget {
  const _StoreDetailSheet({
    required this.store,
    required this.isOwner,
    required this.onEdit,
  });

  final Store store;
  final bool isOwner;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    return Padding(
      padding: AppSpacing.sheetPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Cabeçalho: avatar + nome ──
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: scheme.tertiaryContainer,
                child: Text(
                  store.name.isEmpty
                      ? '?'
                      : store.name.substring(0, 1).toUpperCase(),
                  style: AppTypography.titleMedium.copyWith(
                    color: scheme.onTertiaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Detalhes ──
          if (store.phone.isNotEmpty)
            DetailRow(
              labelWidth: 70,
              label: l10n.storeDetailPhone,
              value: store.phone,
              icon: Icons.phone_outlined,
            ),
          if (store.email.isNotEmpty)
            DetailRow(
              labelWidth: 70,
              label: l10n.storeDetailEmail,
              value: store.email,
              icon: Icons.email_outlined,
            ),
          if (store.nuit.isNotEmpty)
            DetailRow(
              labelWidth: 70,
              label: l10n.storeDetailNuit,
              value: store.nuit,
              icon: Icons.receipt_long_outlined,
            ),
          if (store.city.isNotEmpty)
            DetailRow(
              labelWidth: 70,
              label: l10n.storeDetailCity,
              value: store.city,
              icon: Icons.location_city_outlined,
            ),
          if (store.address.isNotEmpty)
            DetailRow(
              labelWidth: 70,
              label: l10n.storeDetailAddress,
              value: store.address,
              icon: Icons.place_outlined,
            ),

          if (isOwner) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            AppButton.primary(
              onPressed: () {
                Navigator.of(context).pop();
                onEdit();
              },
              label: l10n.editStoreAction,
              icon: const Icon(Icons.edit_outlined, size: 18),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
