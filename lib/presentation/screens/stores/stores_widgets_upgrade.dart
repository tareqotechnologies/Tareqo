part of 'stores_screen.dart';

/// Sheet de solicitação de upgrade de plano.
class _UpgradeSheet extends ConsumerStatefulWidget {
  const _UpgradeSheet({required this.tenant});

  final Tenant tenant;

  @override
  ConsumerState<_UpgradeSheet> createState() => _UpgradeSheetState();
}

class _UpgradeSheetState extends ConsumerState<_UpgradeSheet> {
  String? _selectedPlanId;
  bool _isSubmitting = false;
  String? _formError;

  Future<void> _submit() async {
    if (_selectedPlanId == null) {
      setState(() => _formError = context.l10n.upgradeChooseError);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _formError = null;
    });

    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;

    try {
      await ref
          .read(requestPlanUpgradeUseCaseProvider)
          .call(
            tenantId: widget.tenant.id,
            currentPlanId: widget.tenant.planId,
            requestedPlanId: _selectedPlanId!,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text(l10n.upgradeSuccess)));
    } on InvalidPlanRequestException catch (error) {
      setState(() => _formError = domainErrorMessage(error, l10n));
    } catch (error, stackTrace) {
      CrashReporting.capture(
        error,
        stackTrace,
        hint: 'Erro ao solicitar upgrade',
      );
      setState(() {
        _formError = l10n.upgradeError;
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
    final plansAsync = ref.watch(plansProvider);
    final candidates = (plansAsync.value ?? const <Plan>[])
        .where((plan) => plan.id != widget.tenant.planId && plan.isActive)
        .toList();

    return SheetForm(
      title: l10n.upgradeTitle,
      maxHeightFactor: 0.9,
      error: _formError,
      actionLabel: l10n.upgradeSubmit,
      onSubmit: _submit,
      isSubmitting: _isSubmitting,
      actionIcon: const Icon(Icons.send_outlined, size: AppSizes.iconMd),
      children: [
        Text(
          l10n.upgradeSubtitle,
          style: AppTypography.bodyMedium.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        plansAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Text(
            l10n.onboardingPlansError,
            style: AppTypography.bodySmall.copyWith(color: theme.expense),
          ),
          data: (_) {
            if (candidates.isEmpty) {
              return Text(
                l10n.upgradeMaxReached,
                style: AppTypography.bodyMedium.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              );
            }
            return Column(
              children: [
                for (final plan in candidates) ...[
                  _UpgradePlanTile(
                    plan: plan,
                    selected: _selectedPlanId == plan.id,
                    onTap: () => setState(() => _selectedPlanId = plan.id),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _UpgradePlanTile extends StatelessWidget {
  const _UpgradePlanTile({
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  final Plan plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.mdAll,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: AppRadius.mdAll,
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
          ),
          color: selected
              ? scheme.primaryContainer.withValues(alpha: 0.3)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: AppSizes.iconMd,
              color: selected ? scheme.primary : scheme.outline,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.name,
                    style: AppTypography.labelLarge.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.micro),
                  Text(
                    l10n.planDetails(plan.maxStores, plan.maxEmployees),
                    style: AppTypography.bodySmall.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            // Preço em tinta — a seleção já é comunicada pelo aro/tinte.
            Text(
              Formatters.currency(plan.priceMonthlyCents),
              style: AppTypography.amountInRow(scheme.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}
