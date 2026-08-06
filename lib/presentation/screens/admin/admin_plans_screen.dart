import 'package:flutter/material.dart';

import '../../../core/utils/ids.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/money.dart';
import '../../../domain/entities/plan.dart';
import '../../../domain/usecases/add_plan_use_case.dart';
import '../../controllers/account_providers.dart';
import '../../controllers/admin_providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/status_chip.dart';
import '../../../core/observability/crash_reporting.dart';

/// Painel do super admin — gestão de planos (criar, editar, ativar/desativar).
/// Os planos limitam a estrutura de cada tenant (nº de lojas e funcionários).
class AdminPlansScreen extends ConsumerStatefulWidget {
  const AdminPlansScreen({super.key});

  @override
  ConsumerState<AdminPlansScreen> createState() => _AdminPlansScreenState();
}

class _AdminPlansScreenState extends ConsumerState<AdminPlansScreen> {
  Future<void> _openEditor([Plan? plan]) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PlanEditorSheet(plan: plan),
    );
    if (!mounted) return;
    ref.read(allPlansProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(allPlansProvider);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adminPlansTitle),
        actions: [
          IconButton(
            tooltip: l10n.adminPlanNewTooltip,
            icon: const Icon(Icons.add),
            onPressed: () => _openEditor(),
          ),
        ],
      ),
      body: plansAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          message: l10n.adminPlansLoadError,
          details: error.toString(),
          onRetry: () => ref.invalidate(allPlansProvider),
        ),
        data: (plans) {
          if (plans.isEmpty) {
            return EmptyState(
              icon: Icons.workspaces_outline,
              title: l10n.adminPlansEmptyTitle,
              subtitle: l10n.adminPlansEmptySubtitle,
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(allPlansProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: plans.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) => _PlanTile(
                plan: plans[index],
                onEdit: () => _openEditor(plans[index]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({required this.plan, required this.onEdit});

  final Plan plan;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    return Card(
      child: ListTile(
        onTap: onEdit,
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          child: Icon(
            Icons.workspaces_outline,
            color: scheme.onPrimaryContainer,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                plan.name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (!plan.isActive)
              StatusChip(label: l10n.adminPlanInactive, color: scheme.outline),
          ],
        ),
        subtitle: Text(
          l10n.adminPlanDetails(
            Formatters.currency(plan.priceMonthlyCents),
            plan.maxStores,
            plan.maxEmployees,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _PlanEditorSheet extends ConsumerStatefulWidget {
  const _PlanEditorSheet({this.plan});

  final Plan? plan;

  @override
  ConsumerState<_PlanEditorSheet> createState() => _PlanEditorSheetState();
}

class _PlanEditorSheetState extends ConsumerState<_PlanEditorSheet> {
  late final _nameController = TextEditingController(
    text: widget.plan?.name ?? '',
  );
  late final _descriptionController = TextEditingController(
    text: widget.plan?.description ?? '',
  );
  late final _priceController = TextEditingController(
    text: widget.plan == null
        ? ''
        : (widget.plan!.priceMonthlyCents / 100).toString(),
  );
  late final _maxStoresController = TextEditingController(
    text: widget.plan == null ? '1' : widget.plan!.maxStores.toString(),
  );
  late final _maxEmployeesController = TextEditingController(
    text: widget.plan == null ? '1' : widget.plan!.maxEmployees.toString(),
  );
  late bool _isActive = widget.plan?.isActive ?? true;

  bool _isSubmitting = false;
  String? _formError;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _maxStoresController.dispose();
    _maxEmployeesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final priceCents = Money.parse(_priceController.text.trim());
    final maxStores = int.tryParse(_maxStoresController.text.trim());
    final maxEmployees = int.tryParse(_maxEmployeesController.text.trim());

    if (_nameController.text.trim().isEmpty) {
      setState(() => _formError = l10n.adminPlanNameError);
      return;
    }
    if (_priceController.text.trim().isEmpty || priceCents < 0) {
      setState(() => _formError = l10n.adminPlanPriceError);
      return;
    }
    if (maxStores == null || maxStores < 1) {
      setState(() => _formError = l10n.adminPlanStoresError);
      return;
    }
    if (maxEmployees == null || maxEmployees < 1) {
      setState(() => _formError = l10n.adminPlanEmployeesError);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _formError = null;
    });

    final messenger = ScaffoldMessenger.of(context);
    final plan = Plan(
      id: widget.plan?.id ?? AppIds.newId('pl'),
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      priceMonthlyCents: priceCents,
      maxStores: maxStores,
      maxEmployees: maxEmployees,
      isActive: _isActive,
    );

    try {
      if (widget.plan == null) {
        await ref.read(addPlanUseCaseProvider).call(plan);
      } else {
        await ref.read(updatePlanUseCaseProvider).call(plan);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            widget.plan == null
                ? l10n.adminPlanCreated(plan.name)
                : l10n.adminPlanUpdated(plan.name),
          ),
        ),
      );
    } on InvalidPlanException catch (error) {
      setState(() => _formError = error.message);
    } catch (error, stackTrace) {
      CrashReporting.capture(error, stackTrace, hint: 'Erro ao salvar plano');
      setState(() {
        _formError = l10n.adminPlanSaveError;
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Form(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.plan == null
                          ? l10n.adminPlanNewTitle
                          : l10n.adminPlanEditTitle,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.appSheetClose,
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.adminPlanNameLabel,
                prefixIcon: const Icon(Icons.workspaces_outline),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descriptionController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.commonDescription,
                prefixIcon: const Icon(Icons.notes_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: l10n.adminPlanPriceLabel,
                prefixIcon: const Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _maxStoresController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.adminPlanMaxStores,
                      prefixIcon: const Icon(Icons.store_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _maxEmployeesController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.adminPlanMaxEmployees,
                      prefixIcon: const Icon(Icons.badge_outlined),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.adminPlanActiveTitle),
              subtitle: Text(l10n.adminPlanActiveSubtitle),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
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
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      widget.plan == null
                          ? l10n.adminPlanCreate
                          : l10n.commonSave,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
