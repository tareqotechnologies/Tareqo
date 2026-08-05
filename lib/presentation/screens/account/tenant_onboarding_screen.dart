import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_settings.dart';
import '../../../core/i18n/l10n_ext.dart';
import '../../../core/utils/formatters.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../domain/entities/app_user.dart';
import '../../../domain/entities/plan.dart';
import '../../../domain/usecases/request_tenant_access_use_case.dart';
import '../../controllers/account_providers.dart';

/// Onboarding do dono: escolhe o plano, o nome do negócio, a **moeda** e o
/// **idioma** do app para solicitar acesso ao ERP. A solicitação nasce
/// `pending` — o acesso é liberado após a aprovação manual do super admin
/// (prazo de até 24h). Moeda e idioma ficam gravados no tenant e passam a
/// valer assim que o dono entra no app.
class TenantOnboardingScreen extends ConsumerStatefulWidget {
  const TenantOnboardingScreen({super.key, required this.user});

  final AppUser user;

  @override
  ConsumerState<TenantOnboardingScreen> createState() =>
      _TenantOnboardingScreenState();
}

class _TenantOnboardingScreenState extends ConsumerState<TenantOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessController = TextEditingController();

  Plan? _selectedPlan;

  /// Escolhas do dono — padrões pt + BRL (alteráveis em Lojas → Ajustes
  /// depois da aprovação).
  String _language = 'pt';
  String _currencyCode = 'BRL';

  bool _isSubmitting = false;
  String? _formError;

  @override
  void dispose() {
    _businessController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPlan == null) {
      setState(() => _formError = context.l10n.onboardingChoosePlanError);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _formError = null;
    });

    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;

    try {
      final tenant =
          await ref.read(requestTenantAccessUseCaseProvider).call(
                ownerUserId: widget.user.id,
                businessName: _businessController.text.trim(),
                planId: _selectedPlan!.id,
                currencyCode: _currencyCode,
                language: _language,
              );
      if (!mounted) return;
      // O myTenantProvider reage: o AuthGate leva à tela "aguardando
      // aprovação" automaticamente (já no idioma escolhido).
      ref.invalidate(myTenantProvider(widget.user.id));
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.onboardingSuccess(tenant.businessName)),
        ),
      );
    } on InvalidTenantRequestException catch (error) {
      setState(() => _formError = error.message);
    } catch (error, stackTrace) {
      debugPrint('Erro ao solicitar acesso: $error\n$stackTrace');
      setState(() => _formError = l10n.onboardingGenericError);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final plansAsync = ref.watch(plansProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.onboardingTitle)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.storefront,
                  size: 56,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.onboardingHeading,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.onboardingSubtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _businessController,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: l10n.onboardingBusinessLabel,
                              prefixIcon:
                                  const Icon(Icons.business_outlined),
                            ),
                            validator: (value) =>
                                (value == null || value.trim().isEmpty)
                                    ? l10n.onboardingBusinessError
                                    : null,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            l10n.onboardingLanguageLabel,
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              _ChoiceChip(
                                label: l10n.languagePortuguese,
                                icon: Icons.language,
                                selected: _language == 'pt',
                                onSelected: (_) =>
                                    setState(() => _language = 'pt'),
                              ),
                              _ChoiceChip(
                                label: l10n.languageEnglish,
                                icon: Icons.translate,
                                selected: _language == 'en',
                                onSelected: (_) =>
                                    setState(() => _language = 'en'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            l10n.onboardingCurrencyLabel,
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final code
                                  in AppSettings.supportedCurrencies)
                                _ChoiceChip(
                                  label: _currencyLabel(l10n, code),
                                  icon: Icons.attach_money,
                                  selected: _currencyCode == code,
                                  onSelected: (_) =>
                                      setState(() => _currencyCode = code),
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            l10n.onboardingPlanLabel,
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 10),
                          plansAsync.when(
                            loading: () => const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            error: (error, _) => Text(
                              l10n.onboardingPlansError,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                            data: (plans) => Column(
                              children: [
                                for (final plan in plans) ...[
                                  _PlanCard(
                                    plan: plan,
                                    selected: _selectedPlan?.id == plan.id,
                                    onTap: () => setState(
                                      () => _selectedPlan = plan,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                ],
                              ],
                            ),
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
                          FilledButton.icon(
                            onPressed: _isSubmitting ? null : _submit,
                            icon: _isSubmitting
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.send_outlined),
                            label: Text(l10n.onboardingSubmit),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Rótulo localizado da moeda (ex.: "Real (BRL)" em pt, "US Dollar
  /// (USD)" em en).
  String _currencyLabel(
    AppLocalizations l10n,
    String code,
  ) {
    switch (code) {
      case 'USD':
        return l10n.currencyUsd;
      case 'EUR':
        return l10n.currencyEur;
      case 'MZN':
        return l10n.currencyMzn;
      default:
        return l10n.currencyBrl;
    }
  }
}

/// Chip de seleção estilizado (idioma/moeda).
class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ChoiceChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      selected: selected,
      selectedColor: scheme.primaryContainer,
      onSelected: onSelected,
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
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
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
          color: selected
              ? scheme.primaryContainer.withValues(alpha: 0.4)
              : scheme.surfaceContainerLow,
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
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.onboardingPlanDetails(
                      plan.maxStores,
                      plan.maxEmployees,
                    ),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            Text(
              Formatters.currency(plan.priceMonthly),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
