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
    final l10n = context.l10n;
    final plansAsync = ref.watch(plansProvider);
    final candidates = (plansAsync.value ?? const <Plan>[])
        .where((plan) => plan.id != widget.tenant.planId && plan.isActive)
        .toList();

    return SingleChildScrollView(
      padding: AppSpacing.sheetPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(title: l10n.upgradeTitle),
          Text(
            l10n.upgradeSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          plansAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Text(
              l10n.onboardingPlansError,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            data: (_) {
              if (candidates.isEmpty) {
                return Text(
                  l10n.upgradeMaxReached,
                  style: theme.textTheme.bodyMedium,
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
                    const SizedBox(height: 12),
                  ],
                ],
              );
            },
          ),
          if (_formError != null) ...[
            const SizedBox(height: 8),
            Text(
              _formError!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 16),
          // AppButton (design system ultra-clean): altura 48, cantos 12,
          // cores sólidas — o spinner substitui o ícone durante o envio.
          AppButton.primary(
            onPressed: _isSubmitting ? null : _submit,
            icon: _isSubmitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_outlined),
            label: l10n.upgradeSubmit,
          ),
        ],
      ),
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
              color: selected ? scheme.primary : scheme.outline,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.planDetails(plan.maxStores, plan.maxEmployees),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              Formatters.currency(plan.priceMonthlyCents),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
